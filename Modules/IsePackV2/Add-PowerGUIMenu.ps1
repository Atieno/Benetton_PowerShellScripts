function Add-PowerGUIMenu {
    <#
    .Synopsis
        Helper function to add menus to the PowerGUI Script Editor
    .Description
        Makes adding menus to the PowerGUI Script Editor
        easier.  Add-PowerGUIMenu accepts a hashtable of menus.  
        Each key is the name of the menu.
            Keys are automatically alphabetized, unless the 
        Each value can be one of three things:
            - A Script Block
                Selecting the menu item will run the script block
            - A Hashtable
                The value will be used to create a nested menu
            - A Script Block with a note property of ShortcutKey
                Selecting the menu item will run the script block.
                The ShortcutKey will be used to assign a shortcut key to the item
    .Example
        Add-PowerGuiMenu -Name "Get" @{
            "Process" = { Get-Process } 
            "Service" = { Get-Service } 
            "Hotfix" = {Get-Hotfix}
        }
    .Example
        Add-PowerGuiMenu -Name "Verb" @{
            Get = @{
                Process = { Get-Process }
                Service = { Get-Service } 
                Hotfix = { Get-Hotfix } 
            }
            Import = @{
                Module = { Import-Module } 
            }
        }
    #>
    [CmdletBinding(DefaultParameterSetName='AddMenuItem')] 
    param(
        #The name of the menu to create 
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String]
        $Name,
        # The contents of the menu
        [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipelineByPropertyName=$true,
                ParameterSetName='AddMenuItem')]
        [Hashtable]$Menu,
        
        # The Menu File
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='MenuFile')]
        [Alias('Fullname')]
        [string]
		$MenuFile,
		
        # The root of the menu.  This is used automatically by Add-IseMenu when it 
        # creates nested menus.
        [Parameter(ParameterSetName='AddMenuItem')]
		[PSObject]
        $Root,
        # If PassThru is set, the menu items will be outputted to the pipeline        
        [switch]$PassThru,
        # If Merge is set, menu items will be merged with existing menus rather than
        # recreating the entire menu.
        [switch]$Merge,        
		
		# If DoNotSort is set, menu items will not be sorted alphabetically
		[switch]$doNotSort
    )
    

    begin {
    	$pgSE= [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		Set-StrictMode -Off
		$myCommandName = $MyInvocation.InvocationName
		
	}
	
	process {
        if ($psCmdlet.ParameterSetName -eq 'MenuFile') {
            $resolvedPsPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($MenuFile)
            $Menu = & $MenuFile
        }
		$menuPointer = $null
		if (-not $Root) {
			# The "root" is actually a list of menu names that lead to the current item
			$existingMenu = $pgSE.Menus | Where-Object { $_.Command.FullName -eq "Menu.${Name}" }
			if ($existingMenu) {
				 if (-not $Merge) 
				 {
					$existingMenu.Items.Clear()
				 }
				 $menuPointer = $existingMenu 
			} else {
				$menuPointer = New-Object Quest.PowerGUI.SDK.MenuCommand "Menu","$Name" -Property @{
					Text = $Name.Replace("_", "&")
				}
				$pgSE.Menus.Add($menuPointer)
			}
		} else {
			if ($Root -is [string] -and $newMenu) {
				$Root = $newMenu
			}
			$menuPointer = $Root 
			<#
			$currentItem = $null
			for ($i = 0; $i -lt $Root.Count; $i++) {
				if ($i -eq 0) {
					# First case, root is the menu
					$currentItem = $pgSE.Menus | Where-Object { $_.Command.FullName  -eq $Root[$i] }					
				} else {
					$currentItem = $currentItem.Items | Where-Object { $_.Command.FullName -eq $Root[$i] } 
				}				
				if (-not $currentItem) { break }
			}
			if ($currentItem) {
				$menuPointer = $currentItem
			}
			#>
			
		}
		
		    
	    $menuItems = $Menu.GetEnumerator()
		if (-not $doNotSort) {
        	$menuItems = $menu.GetEnumerator() | 
            	Sort-Object Key
    	} else {
        	$menuItems = $menu.GetEnumerator()            
    	}
		foreach ($menuItem in $menuItems) {
            switch ($menuItem.Value) {
                { $_ -is [Hashtable] } {
                    # Nested menu, recurse
					$newMenu = New-Object Quest.PowerGUI.SDK.MenuCommand "Menu","$($menuItem.Key)" -Property @{
						Text = $menuItem.Key.Replace("_", "&")
					}                    					
					$r = $root + "Menu.$($MenuItem.Key)"
                    Add-PowerGUIMenu -Name $menuItem.Key -Menu:$_ -root $newMenu -merge:$merge -passThru:$passThru
					
					if (-not $Root) { 
						$pgSE.Menus.Item("Menu.${Name}").Items.Add($newMenu)
					} else {
						$menuPointer.Items.Add($newMenu)
					}	
					break
				}
				default {		
					
					$scriptBlock= [ScriptBlock]::Create(					
					"
					[Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance.Execute({$_},`$true)					
					"															
					)
					# To correctly add and remove command entries, they have to be unique.
					# To uniquify them, make the command the full path to the object
					# by peeking up the callstack and finding out the names of the parent menus
					# Nifty trick, right?									
					$restOfName = @(Get-PSCallStack | 
						Where-Object { $_.InvocationInfo.InvocatioName -eq $myCommand } |
						Select-Object -ExpandProperty InvocationInfo | 
						ForEach-Object { $_.BoundParameters.Name } |
						Where-Object { $_ })
						
					$restOfName += $menuItem.Key
						
					
					$ofs = "."				
					$fullname = "Menu.${restOfName}"
					$itemCommand = New-Object Quest.PowerGUI.SDK.ItemCommand "Menu","$restOfName" -Property @{
						Text = $menuItem.Key.Replace("_", "&")
						ScriptBlock = $scriptBlock
					}
					$oldCommands = $pgSE.Commands | 
						Where-Object { $_.FullName -eq $fullname }
						
					if ($oldCommands) {
						foreach ($cmd in $oldCommands) {
							$null = $pgSE.Commands.Remove($cmd)
						}
					}
										
					if ($_.ShortcutKey) {
						# Add a shortcut key
						$saferKey = $_.ShortcutKey.Replace("ALT", "Alt").Replace("CONTROL", "Control").Replace("SHIFT", "Shift").Replace("LEFT","Left").Replace("RIGHT", "Right")
						$itemCommand.AddShortcut($saferKey)							
					}
					if ($_.Image) {
						# Add an image
						# Expand the image string.  By doing this here it enables the menu to use $psScriptRoot
						# which lets images be stored within a module
						$expandedImageString = $ExecutionContext.InvokeCommand.ExpandString($_.Image)
						$existsAndValidPAth = Resolve-Path $expandedImageString -ErrorAction SilentlyContinue
						$realItem= Get-Item $existsAndValidPAth 
						if ($existsAndValidPAth ) {
							$image = [Drawing.Image]::FromFile($realItem.Fullname)
							if ($image) {
								$itemCommand.Image = $image
							}
						}
					}					
										
					$null = $pgSE.Commands.Add($itemCommand)
					if (-not $Root) { 
						$pgSE.Menus.Item("Menu.${Name}").Items.Add($itemCommand)
					} else {
						$MenuPointer.Items.Add($itemCommand)
					}

					
															
					if ($passThru) { $itemCommand }
				}								
            }
		}
	}
}