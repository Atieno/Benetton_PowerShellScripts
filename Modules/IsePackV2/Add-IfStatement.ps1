function Add-IfStatement
{
    <#
    .Synopsis
        Adds an if Statement to the ISE
    .Description
        Adds an if Statement to the ISE
    .Example
        Add-IfStatement
    #>
	param()
	
	process {
		Add-TextToCurrentDocument -Text "if ( <# This Happens #>) { <# Then Do This #> }"
	}
}

