function Copy-Colored
{
    <#
    .Synopsis
        Copies the currently selected text in the current file with colorization
    .Description
        Copies the currently selected text in the current file with colorization.
        This allows for a user to paste colorized scripts into Word or Outlook
    .Example
        Copy-Colored  
    #>
    param()
    
    function Colorize
    {
        # colorize a script file or function

        param([string]$Text, [int]$Start = -1, [int]$End = -1, [int]$FontSize = 12)
        trap { break }
        $rtb = New-Object Windows.Forms.RichTextBox    
        $rtb.Font = New-Object Drawing.Font "Consolas", $FontSize 
        $rtb.Text = $Text

        # Now parse the text and report any errors...
        $parse_errs = $null
        $tokens = [system.management.automation.psparser]::Tokenize($rtb.Text,
            [ref] $parse_errs)

        if ($parse_errs) {
            $parse_errs
            return
        }
        $ColorPalette = New-ScriptPalette 

        # iterate over the tokens an set the colors appropriately...
        foreach ($t in $tokens) {
            $rtb.Select($t.start, $t.length)
            $color = $ColorPalette[$t.Type.ToString()]            
            if ($color) {
                $rtb.selectioncolor = [drawing.color]::FromArgb($color.A, 
                    $color.R, 
                    $color.G, 
                    $color.B)
            }
        }
        if ($start -eq -1 -and $end -eq -1) {
            $rtb.select(0,$rtb.Text.Length)
        } else {
            $rtb.select($start, $end)
        }
        $rtb.Copy()
    }
    
    $text = Get-CurrentOpenedFileText    
    $selectedText = Select-CurrentText -NotInOutput -NotInCommandPane
           
    if (-not $selectedText) {
        $TextToColor = ($Text -replace '\r\n', "`n")
    } else {        
        $TextToColor = ($selectedText -replace '\r\n', "`n")
    }
    Colorize $TextToColor  
}

function Write-ColorizedHTML {
    <#
    .Synopsis
        Writes Windows PowerShell as colorized HTML
    .Description
        Outputs a Windows PowerShell script as colorized HTML.
        The script is wrapped in <PRE> tags with <SPAN> tags defining color regions.
    .Example
        Write-ColoredHTML {Get-Process}
    #>
    param(
        # The Text to colorize
        [Parameter(Mandatory=$true)]
        [String]$Text,
        # The starting within the string to colorize
        [Int]$Start = -1,
        # the end within the string to colorize
        [Int]$End = -1)
    
    trap { break } 
    #
    # Now parse the text and report any errors...
    #
    $parse_errs = $null
    $tokens = [Management.Automation.PsParser]::Tokenize($text,
        [ref] $parse_errs)
 
    if ($parse_errs) {
        $parse_errs
        return
    }
    $stringBuilder = New-Object Text.StringBuilder
    $null = $stringBuilder.Append("<pre class='PowerShellColorizedScript'>")
    # iterate over the tokens an set the colors appropriately...
    $lastToken = $null
    foreach ($t in $tokens)
    {
        if ($lastToken) {
            $spaces = " " * ($t.Start - ($lastToken.Start + $lastToken.Length))
            $null = $stringBuilder.Append($spaces)
        }
        if ($t.Type -eq "NewLine") {
            $null = $stringBuilder.Append("            
")
        } else {
            $chunk = $text.SubString($t.start, $t.length)
            $color = $psise.Options.TokenColors[$t.Type]            
            $redChunk = "{0:x2}" -f $color.R
            $greenChunk = "{0:x2}" -f $color.G
            $blueChunk = "{0:x2}" -f $color.B
            $colorChunk = "#$redChunk$greenChunk$blueChunk"
            $null = $stringBuilder.Append("<span style='color:$colorChunk'>$chunk</span>")                    
        }                       
        $lastToken = $t
    }
    $null = $stringBuilder.Append("</pre>")
    $stringBuilder.ToString()
}    

function Copy-ColoredHTML 
{
    <#
    .Synopsis
        Copies the currently selected text in the current file as colorized HTML
    .Description
        Copies the currently selected text in the current file as colorized HTML
        This allows for a user to paste colorized scripts into web pages or blogging 
        software
    .Example
        Copy-ColoredHTML
    #>
    param()
    
	$currentText = Select-CurrentText -NotInCommandPane -NotInOutput
	if (-not $currentText) {
		# Try the current file
		$currentFile = Get-CurrentOpenedFileText		
		$text = $currentFile
	} else {
		$text = $currentText
	}
	if (-not $text) {  return }
	
	$sb = [ScriptBlock]::Create($text)
	$Error | Select-object -last 1 | ogv
	
	$colorizedHTML = Write-ColorizedHTML -Text "$sb"
	[Windows.Clipboard]::SetText($colorizedHTML )
	return        
}


function New-ScriptPalette
{
    param(
    $Attribute = "#FFADD8E6",
    $Command = "#FF0000FF",
    $CommandArgument = "#FF8A2BE2",   
    $CommandParameter = "#FF000080",
    $Comment = "#FF006400",
    $GroupEnd = "#FF000000",
    $GroupStart = "#FF000000",
    $Keyword = "#FF00008B",
    $LineContinuation = "#FF000000",
    $LoopLabel = "#FF00008B",
    $Member = "#FF000000",
    $NewLine = "#FF000000",
    $Number = "#FF800080",
    $Operator = "#FFA9A9A9",
    $Position = "#FF000000",
    $StatementSeparator = "#FF000000",
    $String = "#FF8B0000",
    $Type = "#FF008080",
    $Unknown = "#FF000000",
    $Variable = "#FFFF4500"        
    )
    
    process {
        $NewScriptPalette= @{}
        foreach ($parameterName in $myInvocation.MyCommand.Parameters.Keys) {
            $var = Get-Variable -Name $parameterName -ErrorAction SilentlyContinue
            if ($var -ne $null -and $var.Value) {
                if ($var.Value -is [Collections.Generic.KeyValuePair[System.Management.Automation.PSTokenType,System.Windows.Media.Color]]) {
                    $NewScriptPalette[$parameterName] = $var.Value.Value
                } elseif ($var.Value -as [Windows.Media.Color]) {
                    $NewScriptPalette[$parameterName] = $var.Value -as [Windows.Media.Color]
                }
            }
        }
        $NewScriptPalette    
    }
}
                                                 
