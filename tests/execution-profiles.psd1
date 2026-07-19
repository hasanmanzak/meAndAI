@{
    SchemaVersion = 1
    Profiles = @(
        @{
            Name = 'Full'
            Selection = 'All'
            Suites = @()
        }
        @{
            Name = 'WindowsNative'
            Selection = 'Explicit'
            Suites = @(
                @{
                    Owner = 'tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1'
                    Arguments = @('-Shard', 'WindowsNative')
                }
                @{
                    Owner = 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
                    Arguments = @('-Shard', 'WindowsNative')
                }
            )
        }
    )
}
