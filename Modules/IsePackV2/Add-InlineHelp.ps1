function Add-InlineHelp {
    <#
    .Synopsis
        Adds a template for inline help into the current file.
    .Description
        Adds a template for inline help into the current file in 
        the Integrated Scripting Environment
    .Example
        Add-InlineHelp   
    #>
    param()    
	
	Add-TextToCurrentDocument "
	<#
    .Synopsis
        A Quick Description of what the command does
    .Description
        A Detailed Description of what the command does
    .Example
        An example of using the command        
    #>
	"
}