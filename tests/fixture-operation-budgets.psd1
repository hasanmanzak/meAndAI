@{
    SchemaVersion = [long]2
    Capability = 'test-runtime-efficiency'
    Measurements = @(
        @{
            Id = 'feat-0039-v0127-fixtures'
            BaseCommit = '6b01299cfe484c900944b7435d4fef43b11fc38d'
            ObserverDigest = 'sha256:ed9a8290b24b191274f35c4bef2cd9af14157e2927be94848a2561a54294e04b'
        }
        @{
            Id = 'feat-0040-v0130-graph-transport'
            BaseCommit = '299b8982cd57961e2b3a6136b07af3bfb49a16d1'
            ObserverDigest = 'sha256:1f0471fbe882ce959afe52f65713a4f3332c3ba0bc1616db0c5b256687fcf4a8'
        }
    )
    ObservationOwners = @(
        @{
            Owner = 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
            Routes = @(
                @{
                    Route = 'Shard=All'
                    Arguments = @()
                    RequiresObservation = $true
                    Counters = @(
                        @{
                            Name = 'reusable-fixture-family.init'
                            Maximum = [long]11
                        }
                    )
                }
                @{
                    Route = 'Shard=WindowsNative'
                    Arguments = @('-Shard', 'WindowsNative')
                    RequiresObservation = $false
                    Counters = @()
                }
            )
        }
        @{
            Owner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
            Routes = @(
                @{
                    Route = 'Shard=All'
                    Arguments = @()
                    RequiresObservation = $true
                    Counters = @(
                        @{
                            Name = 'graph.acquisition'
                            Maximum = [long]3
                        }
                        @{
                            Name = 'process.child'
                            Maximum = [long]4
                        }
                        @{
                            Name = 'reusable-fixture-family.bundle'
                            Maximum = [long]2
                        }
                        @{
                            Name = 'reusable-fixture-family.clone'
                            Maximum = [long]2
                        }
                        @{
                            Name = 'reusable-fixture-family.init'
                            Maximum = [long]3
                        }
                        @{
                            Name = 'reusable-fixture-family.push'
                            Maximum = [long]36
                        }
                    )
                }
            )
        }
        @{
            Owner = 'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1'
            Routes = @(
                @{
                    Route = 'default'
                    Arguments = @()
                    RequiresObservation = $true
                    Counters = @(
                        @{
                            Name = 'instruction-graph.blob-process-start'
                            Maximum = [long]2
                        }
                        @{
                            Name = 'instruction-graph.blob-request'
                            Maximum = [long]4
                        }
                    )
                }
            )
        }
        @{
            Owner = 'tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1'
            Routes = @(
                @{
                    Route = 'default'
                    Arguments = @()
                    RequiresObservation = $true
                    Counters = @(
                        @{
                            Name = 'contract.self-check'
                            Maximum = [long]1
                        }
                    )
                }
            )
        }
    )
    ClosureTargets = @(
        @{
            Owner = 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
            Route = 'Shard=All'
            Counter = 'reusable-fixture-family.init'
            Baseline = [long]47
            Maximum = [long]11
            Instrumented = $true
            MeasurementId = 'feat-0039-v0127-fixtures'
            WorkId = 'SUBF-0075'
        }
        @{
            Owner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
            Route = 'Shard=All'
            Counter = 'reusable-fixture-family.init'
            Baseline = [long]38
            Maximum = [long]3
            Instrumented = $true
            MeasurementId = 'feat-0039-v0127-fixtures'
            WorkId = 'SUBF-0076'
        }
        @{
            Owner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
            Route = 'Shard=All'
            Counter = 'reusable-fixture-family.clone'
            Baseline = [long]72
            Maximum = [long]2
            Instrumented = $true
            MeasurementId = 'feat-0039-v0127-fixtures'
            WorkId = 'SUBF-0076'
        }
        @{
            Owner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
            Route = 'Shard=All'
            Counter = 'reusable-fixture-family.bundle'
            Baseline = [long]2
            Maximum = [long]2
            Instrumented = $true
            MeasurementId = 'feat-0039-v0127-fixtures'
            WorkId = 'SUBF-0076'
        }
        @{
            Owner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
            Route = 'Shard=All'
            Counter = 'reusable-fixture-family.push'
            Baseline = [long]36
            Maximum = [long]36
            Instrumented = $true
            MeasurementId = 'feat-0039-v0127-fixtures'
            WorkId = 'SUBF-0076'
        }
        @{
            Owner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
            Route = 'Shard=All'
            Counter = 'process.child'
            Baseline = [long]6
            Maximum = [long]4
            Instrumented = $true
            MeasurementId = 'feat-0039-v0127-fixtures'
            WorkId = 'SUBF-0076'
        }
        @{
            Owner = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
            Route = 'Shard=All'
            Counter = 'graph.acquisition'
            Baseline = [long]5
            Maximum = [long]3
            Instrumented = $true
            MeasurementId = 'feat-0039-v0127-fixtures'
            WorkId = 'SUBF-0076'
        }
        @{
            Owner = 'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1'
            Route = 'default'
            Counter = 'instruction-graph.blob-process-start'
            Baseline = [long]4
            Maximum = [long]2
            Instrumented = $true
            MeasurementId = 'feat-0040-v0130-graph-transport'
            WorkId = 'SUBF-0078'
        }
        @{
            Owner = 'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1'
            Route = 'default'
            Counter = 'instruction-graph.blob-request'
            Baseline = [long]4
            Maximum = [long]4
            Instrumented = $true
            MeasurementId = 'feat-0040-v0130-graph-transport'
            WorkId = 'SUBF-0078'
        }
    )
}
