function Edit-Script
{	
	<#
	.Synopsis
	    Edits a script in the current PowerShell Editor
	.Description
	    Opens a script for editing    
	.Example
	    Edit-Script .\Edit-Script.ps1

	.Example
	    Get-ChildItem -filter *.ps1 | Edit-Script
	#>	
	param(
    # The name of the file that being edited
	[Parameter(Position=0, 
		ValueFromPipelineByPropertyName=$true)]
	[Alias('FullName')]
	[string]
	$File,

    # If set, will create the file if it doesn't exist
    [Switch]
    $Force,

    # If set, will insert text after the script is opened
    [string]
    $InsertText
	)
	
	process {
		
		$resolvedFile = Get-Item $File -ErrorAction SilentlyContinue				
		if (-not $resolvedFile) { 
            if (-not $Force) { 
                return 
            } else {
                $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($file).toString()
                $Resolvedfile = New-Item -ItemType File -Path $resolvedPath -Force                
            }
        }
		if (-not $resolvedFile.FullName) {
			Write-Error "$resolvedFile exists, but is not a path that can be edited"
			return
		}
		
		if ($Host.Name -eq 'PowerGUIScriptEditorHost') {
			$null = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance.DocumentWindows.Add($resolvedFile.FullName)
		} elseif ($Host.Name -eq 'Windows PowerShell ISE Host') {
			$openedfile = $psise.CurrentPowerShellTab.Files.Add($resolvedFile.FullName) 
            if ($InsertText) {
                $openedfile.Editor.InsertText($InsertText)
            }
		}
	}
}
