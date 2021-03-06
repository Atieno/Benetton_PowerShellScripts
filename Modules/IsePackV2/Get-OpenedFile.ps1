function Get-OpenedFile
{
    param(
    )
    
    if ($Host.Name -eq 'PowerGUIScriptEditorHost') {
        foreach ($win in $pgse.DocumentWindows) {
            New-Object PSObject -Property @{
                Tab = ''
                Path = Split-Path $_.document.path
                File = Split-Path $_.document.path -Leaf
            }
        }
    } elseif ($host.Name -eq 'Windows PowerShell ISE Host') {
        foreach ($tab in $psIse.PowerShellTabs) {
            $sortedFiles = $tab.Files | 
                Sort-Object 
                
            foreach ($_ in $sortedFiles) {
                New-Object PSObject -Property @{
                    Tab = $tab.DisplayName 
                    Path = Split-Path $_.fullpath -ErrorAction SilentlyContinue
                    File = Split-Path $_.fullpath -ErrorAction SilentlyContinue
                }
            }
        }
    }
} 
