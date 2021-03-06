function Show-CustomAction
{
    param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [String]
    $ActionName,
    
    # If a property name is provided, then the custom action will show the contents
    # of the property
    [Parameter(Mandatory=$true,
        ParameterSetName='Property',
        Position=0,
        ValueFromPipelineByPropertyName=$true)]
    [String]
    $Property,
        
    # If a script block is provided, then the custom action shown in formatting
    # will be the result of the script block.            
    [Parameter(Mandatory=$true,
        ParameterSetName='ScriptBlock',
        Position=0,
        ValueFromPipelineByPropertyName=$true)]
    [ScriptBlock]
    $ScriptBlock,
    
    # If this is set, collections will not be enumerated, and the custom action
    # will be shown once no matter how many items were returned from the 
    # scriptblock or property.  If this is not set, then the custom action will
    # be shown as once for each item in the results of running the script block or
    # the contents of the property.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $DoNotEnumerate
    )
    
    process {
        $EnumerationChunk = "<EnumerateCollection/>"
        $ControlChunk = "<CustomControlName>$ActionName</CustomControlName>"
        if ($DoNotEnumerator) {  $EnumerationChunk = "" }
        if ($psCmdlet.PArameterSetName -eq "Property") {
@"
<ExpressionBinding>
    <PropertyName>$Property</PropertyName>
    $EnumerationChunk
    $ControlChunk
</ExpressionBinding>
"@            
        } elseif ($psCmdlet.ParameterSetName -eq "ScriptBlock") {
@"
<ExpressionBinding>
    <ScriptBlock>$([Security.SecurityElement]::Escape($ScriptBlock))</ScriptBlock>
    $EnumerationChunk
    $ControlChunk
</ExpressionBinding>
"@        
        }
    }
}