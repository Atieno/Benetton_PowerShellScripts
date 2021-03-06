function Edit-Command
{
    param(
    [Parameter(ParameterSetName='Function',Mandatory=$true,ValueFromPipeline=$true)]
    $Function
    )
    
    process {
        if ($psCmdlet.ParameterSetName -eq "Function") {
            if ($Function.ScriptBlock.File) {
                psedit $function.ScriptBlock.File
            }
        }        
    }
}