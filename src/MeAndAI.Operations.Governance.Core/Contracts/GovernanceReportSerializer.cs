using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public static class GovernanceReportSerializer
{
    public static string Serialize(GovernanceReport report)
    {
        ArgumentNullException.ThrowIfNull(report);

        var semanticBytes = WriteReport(report, reportDigest: null);
        var reportDigest = ExactSha256Digest
            .FromHashBytes(SHA256.HashData(semanticBytes))
            .Value;
        var reportBytes = WriteReport(report, reportDigest);
        return Encoding.UTF8.GetString(reportBytes) + "\n";
    }

    private static byte[] WriteReport(
        GovernanceReport report,
        string? reportDigest)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            writer.WriteStartObject();
            writer.WriteNumber("schema", report.Schema);
            writer.WriteString("application", report.Application.Value);
            writer.WriteString("stage", report.Stage.Value);
            writer.WriteString("profile", report.Profile.Value);

            writer.WriteStartObject("snapshot");
            writer.WriteString("mode", report.SnapshotMode);
            writer.WriteString(
                "evidenceDigest",
                report.SnapshotEvidenceDigest);
            writer.WriteEndObject();

            writer.WriteStartObject("policy");
            writer.WriteString(
                "catalogVersion",
                report.PolicyCatalogVersion);
            writer.WriteString(
                "catalogMetadataDigest",
                report.PolicyCatalogMetadataDigest);
            writer.WriteStartArray("evaluatedRuleIds");
            foreach (var ruleId in report.EvaluatedRuleIds)
            {
                writer.WriteStringValue(ruleId);
            }

            writer.WriteEndArray();
            writer.WriteEndObject();

            writer.WriteString("verdict", report.Verdict.Value);
            writer.WriteString("coverage", report.Coverage);
            writer.WriteString("engineState", report.EngineState.Value);
            writer.WriteString("authorityState", report.AuthorityState.Value);

            writer.WriteStartObject("counts");
            writer.WriteNumber(
                "evaluatedRules",
                report.Counts.EvaluatedRules);
            writer.WriteNumber(
                "missingRules",
                report.Counts.MissingRules);
            writer.WriteNumber(
                "unmappedRules",
                report.Counts.UnmappedRules);
            writer.WriteNumber(
                "blockingFindings",
                report.Counts.BlockingFindings);
            writer.WriteNumber(
                "advisoryFindings",
                report.Counts.AdvisoryFindings);
            writer.WriteEndObject();

            writer.WriteStartArray("findings");
            foreach (var finding in report.Findings)
            {
                writer.WriteStartObject();
                writer.WriteString("ruleId", finding.RuleId);
                writer.WriteString(
                    "canonicalScenarioId",
                    finding.CanonicalScenarioId);
                writer.WriteString(
                    "canonicalScenarioOwner",
                    finding.CanonicalScenarioOwner);
                writer.WriteString("code", finding.Code);
                writer.WriteString("severity", finding.Severity.Value);
                writer.WriteString(
                    "enforcement",
                    finding.Enforcement.Value);
                writer.WriteString("relativePath", finding.RelativePath);
                if (finding.Location.Line is int line)
                {
                    writer.WriteNumber("line", line);
                }
                else
                {
                    writer.WriteNull("line");
                }

                if (finding.Location.Anchor is string anchor)
                {
                    writer.WriteString("anchor", anchor);
                }
                else
                {
                    writer.WriteNull("anchor");
                }

                writer.WriteStartObject("evidence");
                writer.WriteString(
                    "scope",
                    finding.Evidence.Scope.Value);
                writer.WriteString(
                    "digest",
                    finding.Evidence.Digest.Value);
                writer.WriteEndObject();
                writer.WriteStartArray("unsatisfiedRequirements");
                foreach (var requirement in
                         finding.UnsatisfiedRequirements)
                {
                    writer.WriteStartObject();
                    writer.WriteString("kind", requirement.Kind.Value);
                    writer.WriteString("name", requirement.Name);
                    writer.WriteEndObject();
                }

                writer.WriteEndArray();
                writer.WriteEndObject();
            }

            writer.WriteEndArray();
            if (reportDigest is not null)
            {
                writer.WriteString("reportDigest", reportDigest);
            }

            writer.WriteEndObject();
        }

        return stream.ToArray();
    }
}
