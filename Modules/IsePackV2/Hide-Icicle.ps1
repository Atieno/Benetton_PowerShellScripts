function Hide-Icicle
{
    <#
    .Synopsis
        Hides an icicle
    .Description
        Hides an icicle.  Icicles are little apps for the PowerShell ISE.
    .Example
        Get-Icicle | Hide-Icicle
        # Hides all icicles
    .Link
        Show-Icicle
    .Link
        Get-Icicle
    .Link
        Add-Icicle
    .Link
        Remove-Icicle
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]    
    [OutputType([Nullable])]
    param(
    # The Icicle that will be hidden.
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateScript({
        if ($_ -isnot [Microsoft.PowerShell.Host.ISE.ISEAddOnTool]) {
            throw "Must be an ISE Add On"
        }
        return $true
    })]
    $Icicle,

    # If set, will output the icicle
    [Switch]
    $PassThru
    )
    
    process {
        if ($psCmdlet.ShouldProcess($icicle.Name)) { 
            $Icicle.IsVisible = $false
            if ($PassThru) {
                $Icicle
            }
        }

    }
}

