using System.Reflection;
using System.Text.Json;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Results;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class OperationResultTests
{
    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void ResultIdentitiesAreClosedAndCaseSensitive()
    {
        Assert.Same(OperationOutcome.Succeeded, OperationOutcome.Parse("succeeded"));
        Assert.Same(OperationOutcome.Canceled, OperationOutcome.Parse("canceled"));
        Assert.Same(
            OperationFailureCode.MalformedInput,
            OperationFailureCode.Parse("input.malformed"));
        Assert.Same(
            OperationFailureCode.DependencyFailed,
            OperationFailureCode.Parse("dependency.failed"));

        Assert.Throws<ArgumentOutOfRangeException>(
            () => OperationOutcome.Parse("Succeeded"));
        Assert.Throws<ArgumentOutOfRangeException>(
            () => OperationFailureCode.Parse("dependency.error"));
        Assert.Throws<ArgumentNullException>(() => OperationOutcome.Parse(null!));
        Assert.Throws<ArgumentNullException>(
            () => OperationFailureCode.Parse(null!));
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void MalformedInputHasOneDeterministicRejectedShape()
    {
        var result = OperationResult<PublicReceipt>.Rejected(
            OperationStageId.Plan,
            OperationFailureCode.MalformedInput);

        Assert.Same(OperationStageId.Plan, result.Stage);
        Assert.Same(OperationOutcome.Rejected, result.Outcome);
        Assert.Same(OperationFailureCode.MalformedInput, result.FailureCode);
        Assert.Null(result.Value);
        Assert.Equal("plan:rejected:input.malformed", result.ToString());
        Assert.Equal(
            result,
            OperationResult<PublicReceipt>.Rejected(
                OperationStageId.Plan,
                OperationFailureCode.MalformedInput));
        Assert.Equal(
            "{\"Stage\":{\"Value\":\"plan\"},\"Outcome\":{\"Value\":\"rejected\"},\"Value\":null,\"FailureCode\":{\"Value\":\"input.malformed\"}}",
            JsonSerializer.Serialize(result));
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void ResultPayloadMustBeAReferenceType()
    {
        var parameter = typeof(OperationResult<>).GetGenericArguments().Single();

        Assert.True(
            parameter.GenericParameterAttributes.HasFlag(
                GenericParameterAttributes.ReferenceTypeConstraint));
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void BaseResultSchemaHasNoFreeTextOrExceptionField()
    {
        var properties = typeof(OperationResult<>).GetProperties()
            .Select(property => property.Name)
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            ["FailureCode", "Outcome", "Stage", "Value"],
            properties);
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public void ResultFactoriesRejectImpossibleStateCombinations()
    {
        Assert.Throws<ArgumentNullException>(
            () => OperationResult<PublicReceipt>.Succeeded(
                OperationStageId.Plan,
                null!));
        Assert.Throws<ArgumentOutOfRangeException>(
            () => OperationResult<PublicReceipt>.Rejected(
                OperationStageId.Plan,
                OperationFailureCode.DependencyFailed));
        Assert.Throws<ArgumentOutOfRangeException>(
            () => OperationResult<PublicReceipt>.Failed(
                OperationStageId.Plan,
                OperationFailureCode.CapabilityDenied));
    }

    internal sealed record PublicReceipt(string Identifier);
}
