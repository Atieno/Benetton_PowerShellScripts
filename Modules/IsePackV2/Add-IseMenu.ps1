function Add-IseMenu {
    <#
    .Synopsis
        Helper function to add menus to the ISE
    .Description
        Makes adding menus to the Windows PowerShell Integrated Scripting Environment (ISE)
        easier.  Add-IseMenu accepts a hashtable of menus.  
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
        Add-IseMenu -Name "Get" @{
            "Process" = { Get-Process } 
            "Service" = { Get-Service } 
            "Hotfix" = {Get-Hotfix}
        }
    .Example
        Add-IseMenu -Name "Verb" @{
            Get = @{
                Process = { Get-Process }
                Service = { Get-Service } 
                Hotfix = { Get-Hotfix } 
            }
            Import = @{
                Module = { Import-Module } 
            }
        }
    .Example
        Add-IseMenu -Name "Favorites" @{
            "Edit Profile" = { psedit $profile } | 
                Add-Member NoteProperty ShortcutKey "CTRL + E" -PassThru
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
        $Root,
        # If PassThru is set, the menu items will be outputted to the pipeline        
        [switch]$PassThru,
        # If Merge is set, menu items will be merged with existing menus rather than
        # recreating the entire menu.
        [switch]$Merge        
    )
    
    process {
        Set-StrictMode -Off
        if ($psCmdlet.ParameterSetName -eq 'MenuFile') {
            $resolvedPsPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($MenuFile)
            $Menu = . $MenuFile
        }
        if (-not $psise) { return }
        if (-not $root) { 
            $root = $psise.CustomMenu
            if (-not $root) {
                $root = $psise.CurrentPowerShellTab.AddOnsMenu
            }
            if (-not $root) {
                $root = $psise.CustomMenu
            }    
        }
        $iseMenu = $root.Submenus | Where-Object {
            $_.DisplayName -eq $name
        }
        if (-not $iseMenu) {
            $iseMenu = $root.Submenus.Add($name, $null, $null)
        }
        if (-not $merge) {
            $iseMenu.Submenus.Clear()
        }
        if (-not $doNotSort) {
            $menuItems = $menu.GetEnumerator() | 
                Sort-Object Key
        } else {
            $menuItems = $menu.GetEnumerator()            
        }
        $menuItems | 
            ForEach-Object {
                $itemName = $_.Key
                switch ($_.Value) {
                    { $_ -is [Hashtable] } {
                        # Nested menu, recurse
                        $subMenu = $iseMenu.SubMenus.Add($itemName, $null, $null)
                        Add-IseMenu -Name $itemName $_ -root $iseMenu -passThru:$passThru
                    }
                    { $_.ShortcutKey } {
                        $scriptBlock= [ScriptBlock]::Create($_)
                        $m = $iseMenu.Submenus.Add($itemName, $scriptBlock, $_.ShortcutKey)
                        if ($passThru) { $m }
                    }
                    default {
                        $scriptBlock= [ScriptBlock]::Create($_)
                        $m= $iseMenu.Submenus.Add($itemName, $scriptBlock, $null)
                        if ($passThru) { $m }
                    }                 
                }
            }
    }
    

}