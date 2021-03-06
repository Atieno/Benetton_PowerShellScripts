function Add-SwitchStatement
{
    <#
    .Synopsis
        Adds a Switch Statement to the current file
    .Description
        Adds a Switch statement to the current file within the integrated scripting environment
    .Example
        Add-SwitchStatement 
    #>
    param()
	
	Add-TextToCurrentDocument -Text "
switch (`$condition) {
	'APossibility' {
	}
	default {
	}
}
"	
}
