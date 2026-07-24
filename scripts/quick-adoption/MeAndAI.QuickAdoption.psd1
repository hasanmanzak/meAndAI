@{
    RootModule = 'MeAndAI.QuickAdoption.psm1'
    ModuleVersion = '0.14.3'
    GUID = 'f6392442-30ae-4c8c-82ce-cb4bf67a3c15'
    Author = 'meAndAI maintainers'
    CompanyName = 'meAndAI'
    Copyright = '(c) meAndAI maintainers'
    Description = 'Verified quick-adoption runtime.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Invoke-MeAndAIQuickAdoption')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('meAndAI', 'adoption')
            ProjectUri = 'https://github.com/hasanmanzak/meAndAI'
        }
    }
}
