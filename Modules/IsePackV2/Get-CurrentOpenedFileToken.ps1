function Get-CurrentOpenedFileToken {
    <#
    .Synopsis
        Gets the PowerShell Parser Tokens for the current file
    .Description
        Converts the current file into a list of powershell tokens
        Scripters can use these tokens to figure out exact context within a script
    .Example
        Get-CurrentOpenedFileToken 
    .Link
        Get-TokenFromFile
    #>
    param()
    $scriptBlock = Get-CurrentDocument -Text
    $scriptBlock = [ScriptBLock]::Create($scriptBlock)
    Get-ScriptToken -ScriptBlock $scriptBlock
}
