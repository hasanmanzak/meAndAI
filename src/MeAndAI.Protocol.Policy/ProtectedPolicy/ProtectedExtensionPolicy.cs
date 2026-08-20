using System.Security.Cryptography;
using System.Text;
using System.Numerics;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Policy
{

    public static class ProtectedExtensionPolicy
    {
        private const string ExportKey = "protocol.policy.extension-protected";
        private const string ExportVersion = "1";
        private const string IssuerKeyId =
            "protocol.authority.unprovisioned.extension-policy.v1";
        private const string Algorithm = "ed25519";
        private const string PublicKeyHex =
            "4C4B29AD97DBDEFA3087835D1AEAB0221EE8AE4DF5D692D84360D74F607D7365";

        static ProtectedExtensionPolicy()
        {
            var publicKey = Convert.FromHexString(PublicKeyHex);
            var activation = new ProtectedPolicy.ExtensionActivationEnvelopeVerifier(
                IssuerKeyId,
                publicKey);
            var pack = new ProtectedPolicy.ProtectedPolicyPackEnvelopeVerifier(
                IssuerKeyId,
                publicKey);
            var disposition = new ProtectedPolicy.ProtectedDispositionEnvelopeVerifier(
                IssuerKeyId,
                publicKey);
            var predecessor = new ProtectedPolicy.PredecessorTrustEnvelopeVerifier(
                IssuerKeyId,
                publicKey);
            var digest = ComputeEmptyExportDigest(publicKey);
            Export = ExtensionPolicyPackExport.Create(
                ExportKey,
                ExportVersion,
                digest,
                IssuerKeyId,
                Algorithm,
                publicKey,
                activation,
                pack,
                disposition,
                predecessor,
                Array.Empty<ExtensionEvaluatorRegistration>());
        }

        public static ExtensionPolicyPackExport Export { get; }

        private static ExactSha256Digest ComputeEmptyExportDigest(byte[] publicKey)
        {
            var components = new[]
            {
            Component(
                "protocol.verifier.extension-activation",
                nameof(ProtectedPolicy.ExtensionActivationEnvelopeVerifier)),
            Component(
                "protocol.verifier.protected-policy-pack",
                nameof(ProtectedPolicy.ProtectedPolicyPackEnvelopeVerifier)),
            Component(
                "protocol.verifier.protected-disposition",
                nameof(ProtectedPolicy.ProtectedDispositionEnvelopeVerifier)),
            Component(
                "protocol.verifier.predecessor-trust",
                nameof(ProtectedPolicy.PredecessorTrustEnvelopeVerifier)),
        };
            var publicKeyDigest = ExactSha256Digest.FromHashBytes(SHA256.HashData(publicKey));
            return ProtectedPolicyFrame.Hash("protocol.extension-policy-pack/1\n", stream =>
            {
                ProtectedPolicyFrame.String(stream, ExportKey);
                ProtectedPolicyFrame.String(stream, ExportVersion);
                ProtectedPolicyFrame.String(stream, IssuerKeyId);
                ProtectedPolicyFrame.String(stream, Algorithm);
                ProtectedPolicyFrame.Digest(stream, publicKeyDigest);
                foreach (var component in components)
                {
                    WriteComponent(stream, component);
                }

                ProtectedPolicyFrame.UInt32(stream, 0);
            });
        }

        private static ComponentTypeIdentity Component(string key, string typeName) =>
            ComponentTypeIdentity.Create(
                key,
                "1",
                "MeAndAI.Protocol.Policy",
                $"MeAndAI.Protocol.Policy.ProtectedPolicy.{typeName}");

        private static void WriteComponent(
            MemoryStream stream,
            ComponentTypeIdentity component)
        {
            ProtectedPolicyFrame.String(stream, component.ComponentKey);
            ProtectedPolicyFrame.String(stream, component.ComponentVersion);
            ProtectedPolicyFrame.String(stream, component.AssemblyName);
            ProtectedPolicyFrame.String(stream, component.TypeName);
        }
    }

}

namespace MeAndAI.Protocol.Policy.ProtectedPolicy
{

    internal abstract class ProtectedAuthorityEnvelopeVerifierBase :
        IPolicyOwnedProtectedPolicyComponent
    {
        private const string Algorithm = "ed25519";
        private readonly string _issuerKeyId;
        private readonly byte[] _publicKey;
        private readonly string _contractKey;

        protected ProtectedAuthorityEnvelopeVerifierBase(
            string issuerKeyId,
            IEnumerable<byte> publicKey,
            string contractKey)
        {
            _issuerKeyId = issuerKeyId ?? throw new ArgumentNullException(nameof(issuerKeyId));
            _publicKey = publicKey?.ToArray() ?? throw new ArgumentNullException(nameof(publicKey));
            if (_publicKey.Length != 32)
            {
                throw new ArgumentException("An Ed25519 public key must contain exactly 32 bytes.", nameof(publicKey));
            }

            _contractKey = contractKey;
        }

        protected bool VerifyEnvelope(
            ExactSha256Digest payloadDigest,
            ProtectedAuthorityEnvelope envelope,
            ExactSha256Digest? expectedAuthorityRecordDigest,
            long? expectedAuthorityEpoch)
        {
            if (payloadDigest is null || envelope is null ||
                !string.Equals(envelope.IssuerKeyId, _issuerKeyId, StringComparison.Ordinal) ||
                !string.Equals(envelope.Algorithm, Algorithm, StringComparison.Ordinal) ||
                !string.Equals(envelope.ContractKey, _contractKey, StringComparison.Ordinal) ||
                !string.Equals(envelope.ContractVersion, "1", StringComparison.Ordinal) ||
                !envelope.PayloadDigest.Equals(payloadDigest) ||
                envelope.AuthorityRecordDigest.Value.All(static value => value == '0') ||
                envelope.AuthorityEpoch <= 0 ||
                expectedAuthorityRecordDigest is not null &&
                    !envelope.AuthorityRecordDigest.Equals(expectedAuthorityRecordDigest) ||
                expectedAuthorityEpoch.HasValue &&
                    envelope.AuthorityEpoch != expectedAuthorityEpoch.Value)
            {
                return false;
            }

            var signature = envelope.GetSignatureCopy();
            var signingBytes = SigningBytes(envelope);
            return Ed25519Verifier.Verify(signature, signingBytes, _publicKey);
        }

        internal bool VerifyKnownAnswer(
            ExactSha256Digest payloadDigest,
            ProtectedAuthorityEnvelope envelope) =>
            VerifyEnvelope(
                payloadDigest,
                envelope,
                expectedAuthorityRecordDigest: null,
                expectedAuthorityEpoch: null);

        ComponentTypeIdentity IPolicyOwnedProtectedPolicyComponent
            .VerifyRuntimeComponentIdentity(ComponentTypeIdentity expectedIdentity)
        {
            ArgumentNullException.ThrowIfNull(expectedIdentity);
            var runtimeType = GetType();
            return ComponentTypeIdentity.Create(
                expectedIdentity.ComponentKey,
                expectedIdentity.ComponentVersion,
                runtimeType.Assembly.GetName().Name!,
                runtimeType.FullName!);
        }

        private static byte[] SigningBytes(ProtectedAuthorityEnvelope envelope)
        {
            using var stream = new MemoryStream();
            stream.Write(Encoding.ASCII.GetBytes(
                "protocol.protected-authority-envelope-signing/1\n"));
            ProtectedPolicyFrame.String(stream, envelope.IssuerKeyId);
            ProtectedPolicyFrame.String(stream, envelope.Algorithm);
            ProtectedPolicyFrame.String(stream, envelope.ContractKey);
            ProtectedPolicyFrame.String(stream, envelope.ContractVersion);
            ProtectedPolicyFrame.Digest(stream, envelope.PayloadDigest);
            ProtectedPolicyFrame.Digest(stream, envelope.AuthorityRecordDigest);
            ProtectedPolicyFrame.Int64(stream, envelope.AuthorityEpoch);
            return stream.ToArray();
        }
    }

    internal static class Ed25519Verifier
    {
        private static readonly BigInteger Prime = (BigInteger.One << 255) - 19;
        private static readonly BigInteger Order =
            (BigInteger.One << 252) + BigInteger.Parse("27742317777372353535851937790883648493");
        private static readonly BigInteger D = Mod(
            -121665 * Invert(121666));
        private static readonly BigInteger SquareRootMinusOne = BigInteger.ModPow(
            2,
            (Prime - 1) / 4,
            Prime);
        private static readonly Point BasePoint = new(
            BigInteger.Parse(
                "15112221349535400772501151409588531511454012693041857206046113283949847762202"),
            BigInteger.Parse(
                "46316835694926478169428394003475163141307993866256225615783033603165251855960"));

        internal static bool Verify(
            ReadOnlySpan<byte> signature,
            ReadOnlySpan<byte> message,
            ReadOnlySpan<byte> publicKey)
        {
            if (signature.Length != 64 || publicKey.Length != 32)
            {
                return false;
            }

            var scalar = new BigInteger(
                signature[32..],
                isUnsigned: true,
                isBigEndian: false);
            if (scalar >= Order ||
                !TryDecode(publicKey, out var authority) ||
                !TryDecode(signature[..32], out var encodedR))
            {
                return false;
            }

            var challengeInput = new byte[64 + message.Length];
            signature[..32].CopyTo(challengeInput);
            publicKey.CopyTo(challengeInput.AsSpan(32));
            message.CopyTo(challengeInput.AsSpan(64));
            var challenge = new BigInteger(
                SHA512.HashData(challengeInput),
                isUnsigned: true,
                isBigEndian: false) % Order;

            var left = Multiply(BasePoint, scalar * 8);
            var right = Add(
                Multiply(encodedR, 8),
                Multiply(authority, challenge * 8));
            return left.Equals(right);
        }

        private static bool TryDecode(ReadOnlySpan<byte> encoded, out Point point)
        {
            var yBytes = encoded.ToArray();
            var sign = (yBytes[31] & 0x80) != 0;
            yBytes[31] &= 0x7f;
            var y = new BigInteger(yBytes, isUnsigned: true, isBigEndian: false);
            if (y >= Prime)
            {
                point = default;
                return false;
            }

            var ySquared = Mod(y * y);
            var xSquared = Mod((ySquared - 1) * Invert(D * ySquared + 1));
            var x = BigInteger.ModPow(xSquared, (Prime + 3) / 8, Prime);
            if (Mod(x * x - xSquared) != 0)
            {
                x = Mod(x * SquareRootMinusOne);
            }
            if (Mod(x * x - xSquared) != 0 || x == 0 && sign)
            {
                point = default;
                return false;
            }
            if (x.IsEven == sign)
            {
                x = Prime - x;
            }

            point = new Point(x, y);
            return IsOnCurve(point);
        }

        private static Point Multiply(Point point, BigInteger scalar)
        {
            var result = Point.Identity;
            var addend = point;
            while (scalar > 0)
            {
                if (!scalar.IsEven)
                {
                    result = Add(result, addend);
                }

                addend = Add(addend, addend);
                scalar >>= 1;
            }

            return result;
        }

        private static Point Add(Point left, Point right)
        {
            var product = D * left.X * right.X * left.Y * right.Y;
            return new Point(
                Mod((left.X * right.Y + left.Y * right.X) * Invert(1 + product)),
                Mod((left.Y * right.Y + left.X * right.X) * Invert(1 - product)));
        }

        private static bool IsOnCurve(Point point) =>
            Mod(-point.X * point.X + point.Y * point.Y - 1 -
                D * point.X * point.X * point.Y * point.Y) == 0;

        private static BigInteger Invert(BigInteger value) =>
            BigInteger.ModPow(Mod(value), Prime - 2, Prime);

        private static BigInteger Mod(BigInteger value)
        {
            var result = value % Prime;
            return result.Sign < 0 ? result + Prime : result;
        }

        private readonly record struct Point(BigInteger X, BigInteger Y)
        {
            internal static Point Identity => new(BigInteger.Zero, BigInteger.One);
        }
    }

    internal sealed class ExtensionActivationEnvelopeVerifier :
        ProtectedAuthorityEnvelopeVerifierBase,
        IProtectedExtensionActivationVerifier
    {
        internal ExtensionActivationEnvelopeVerifier(
            string issuerKeyId,
            IEnumerable<byte> publicKey)
            : base(issuerKeyId, publicKey, "protocol.extension-activation-proof")
        {
        }

        public bool Verify(
            ProtectedExtensionActivationPayload payload,
            ProtectedAuthorityEnvelope activationProof) =>
            payload is not null && VerifyEnvelope(
                payload.PayloadDigest,
                activationProof,
                payload.ExpectedAuthorityRecordDigest,
                payload.ActivationEpoch);
    }

    internal sealed class ProtectedPolicyPackEnvelopeVerifier :
        ProtectedAuthorityEnvelopeVerifierBase,
        IProtectedPolicyPackVerifier
    {
        internal ProtectedPolicyPackEnvelopeVerifier(
            string issuerKeyId,
            IEnumerable<byte> publicKey)
            : base(issuerKeyId, publicKey, "protocol.protected-policy-pack-proof")
        {
        }

        public bool Verify(
            ProtectedPolicyPackBinding protectedBinding,
            ProtectedAuthorityEnvelope packProof) =>
            protectedBinding is not null && VerifyEnvelope(
                protectedBinding.BindingDigest,
                packProof,
                expectedAuthorityRecordDigest: null,
                expectedAuthorityEpoch: null);
    }

    internal sealed class ProtectedDispositionEnvelopeVerifier :
        ProtectedAuthorityEnvelopeVerifierBase,
        IProtectedDispositionAuthorityVerifier
    {
        internal ProtectedDispositionEnvelopeVerifier(
            string issuerKeyId,
            IEnumerable<byte> publicKey)
            : base(
                issuerKeyId,
                publicKey,
                "protocol.protected-disposition-authority-proof")
        {
        }

        public bool Verify(
            ProtectedDispositionAuthorityPayload payload,
            ProtectedAuthorityEnvelope proof) =>
            payload is not null && VerifyEnvelope(
                payload.PayloadDigest,
                proof,
                payload.ExpectedAuthorityRecordDigest,
                payload.AuthorityEpoch);
    }

    internal sealed class PredecessorTrustEnvelopeVerifier :
        ProtectedAuthorityEnvelopeVerifierBase,
        IPredecessorTrustVerifier
    {
        internal PredecessorTrustEnvelopeVerifier(
            string issuerKeyId,
            IEnumerable<byte> publicKey)
            : base(issuerKeyId, publicKey, "protocol.predecessor-trust-proof")
        {
        }

        public bool Verify(
            PredecessorTrustPayload payload,
            ProtectedAuthorityEnvelope proof) =>
            payload is not null && VerifyEnvelope(
                payload.PayloadDigest,
                proof,
                payload.ExpectedAuthorityRecordDigest,
                payload.AuthorityEpoch);
    }

}
