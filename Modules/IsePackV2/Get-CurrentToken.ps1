function Get-CurrentToken {    
    <#
    .Synopsis
        Gets the current token within a file
    .Description
        Gets the current token within a file
    .Example
        Get-CurrentToken
    #>
    param(
    # The tokens for the file
    $tokens,
    # The line within the file
    $line,
    # The column within the file
    $column
    )
    
	process {
		if (-not $tokens) {
			$tokens = Get-CurrentOpenedFileToken
		}
		
		$position = Get-EditorCaretPosition
		$line = $position.CaretLine
		$column = $position.CaretColumn
		foreach ($t in $tokens) {
			if (-not $t) { continue }
	        if ($t.StartLine -gt $line -or 
                $t.StartLine -eq $line -and $t.StartColumn -ge $column) {
                $lastToken
                break
            }
            $lastToken = $t
    	}

	}
}
