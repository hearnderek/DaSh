param(
    [string]$FunctionName,
    [string]$FunctionArg,
    [string]$CI_Share = "\\chic-jenk-dev1\CI_Share",
    [string]$src = $PSScriptRoot + "\src"
)

#---------------------- User functions --------------------*
if(!($FunctionName))
{
    $interactive = $true
}
else
{
  "$FunctionName and $FunctionArg args found"
}
if(!(Test-Path($src)))
{
    mkdir $src
}

$ScriptName = $MyInvocation.MyCommand.Name

# I'm marking Get-List as parsable via gci via where Options -like 'Private'
function Private:Remotes
{
    ""
    $locals = Get-Upgradable
    foreach($remote in Get-Remotes)
    {
        if( $locals | where { $remote -like $_ } )
        {  
            [Console]::ForegroundColor = [System.ConsoleColor]::Gray
            "[X] - $remote"
        }
        else
        {
            [Console]::ForegroundColor = [System.ConsoleColor]::Green
            "[ ] - $remote"
        }
        
        [Console]::ResetColor()
    }
    
    ""
}

# I'm marking Get-List as parsable via gci via where Options -like 'Private'
function Private:Install
{
    param([string]$PackageName)

    if(!($PackageName))
    {
        $locals = Get-Locals
        $packages = Get-Installable | where { !( $locals -contains $_ )}
        if($packages.Length -eq 0)
        {
            ""
            "You already installed all available packages"
             Invoke-Function Remotes

            return
        }
        $PackageName = (Get-Choice $packages -message "Which Package would you like to INSTALL?" -Cancel -ALL)
    }

    $source = Join-Path $CI_Share $PackageName

    switch ($PackageName) {
        "ALL"    { Sync-All }
        "Cancel" { return }
        Default  { Sync-Package $PackageName }
    }
}

# I'm marking Get-List as parsable via gci via where Options -like 'Private'
function Private:Destroy
{
    param([string]$PackageName)
    [string[]]$deletable = Get-Deletable
    if($deletable.Length -eq 0)
    {
        ""
        "You have nothing that can be removed"
        Invoke-Function Locals

        return
    }

    if( !($PackageName) )
    {
        $PackageName = (Get-Choice $deletable  -message "Which Package would you like to DESTROY?" -Cancel) 
    }
    
    if(!($PackageName -like "Cancel"))
    {
        Remove-Item (Join-Path $src $PackageName) -Confirm -Force
    }
}

# I'm marking Get-List as parsable via gci via where Options -like 'Private'
function Private:Update
{
    param([string]$PackageName)
    
    if(!($PackageName))
    {
        $PackageName = (Get-Choice (Get-Upgradable) -message "Which Package would you like to UPDATE?" -Cancel -ALL)
    }

    switch ($PackageName) {
        "DaSh"   { Sync-CurrentDaSh }
        "ALL"    { Sync-All }
        "Cancel" { return }
        Default  { Sync-Package $PackageName }
    }
}

# I'm marking Get-List as parsable via gci via where Options -like 'Private'
function Private:Start
{
    param(
        [string]$PackageName,
        [string]$ToolName
    )

    [string[]]$Startable = Get-Startable
    if($Startable.Length -eq 0)
    {
        ""
        "You have nothing that can be started"
        Invoke-Function Locals

        return
    }

    if(!($PackageName))
    {
        $PackageName = Read-Package
    }

    if(!($Package -like "Cancel"))
    {
        Invoke-PackageTool -Package $PackageName -Tool $ToolName
    }
}

# I'm marking Get-List as parsable via gci via where Options -like 'Private'
function Private:Locals
{
    ""
    [string[]]$locals = Get-Locals
    if($locals.Length -eq 0)
    {
        "You have no packages yet. Try installing one!"
    }
    else 
    {
        [Console]::ForegroundColor = [System.ConsoleColor]::Yellow
        $locals
        [Console]::ResetColor()
    }
    ""
}

# I'm marking Get-List as parsable via gci via where Options -like 'Private'
function Private:Close
{
    switch ((Get-Random -Maximum 20)) {
        0 {  
            "                                            o           "
            " _________________________________        __|__         "
            "( At least it's not onboarding... ) ---  |     |        "
            " ---------------------------------       | | | |        "
            "                                         |_____|        "
            "        0101010001100101          .____ ___|_|___ ___.  "
            "        0110001101101000         ( )___)         |)___) "
            "        0010000001001000          | | |    </3    | | | "
            "        0110010101110010          |_| |   _____   | |_| "
            "        0110010101110011         (| |) |_|     |_| (| |)"
            "        0111100100101110              _|_|_   _|_|_     "
            "                                                        "
        }
        1 {  
            " ________________________________ "  
            "(    See you space cowboy...     )"
            " -------------------------------- "  
            "        \  (____)                 "
            "         \ |^ ^ |\_______         "
            "           (oo ,)\       )\/\     "
            "                 ||----- |        "
            "                 ||     ||        "
        }
        2 {
            "             ,.                "
            "            (_|,.              "
            "   Oink!   ,' /, )_______   _  "
            "        __j o````-'        ``.'-)'"
            "       (`")                 \'  "
            "        ``-j                |   "
            "          ``-._(           /    "
            "             |_\  |--^.  /     "
            "            /_]'|_| /_)_/      "
            "               /_]'  /_]'      "
            "                               "
        }
        Default {
            " ________________________________ "  
            "(    See you space cowboy...     )"
            " -------------------------------- "  
            "        \   ^__^                  "
            "         \  (oo)\_______          "
            "            (__)\       )\/\'      "
            "                ||----w |         "
            "                ||     ||         "
        }
    }

    Exit
}

#---------------------- Internal functions --------------------*

function Sync-All
{
    Sync-CurrentDaSh
    foreach($PackageName in Get-Locals)
    {
        Sync-Package $PackageName
    }
}

function Sync-Package
{
    param([string]$PackageName)

    $source = Join-Path $CI_Share $PackageName
    $srcDesc = Join-Path $src $PackageName

    if(!(Test-Path($srcDesc)))
    {
        mkdir $srcDesc
    }

    ROBOCOPY $source $srcDesc /XF /XA:H /MIR
}

function Sync-CurrentDaSh
{
    ROBOCOPY (Join-Path $CI_Share DaSh) $PSScriptRoot /XF /XA:H
}

# Returns [string[]]
function Get-UserFunctions
{
    Get-ChildItem function: | where Options -like 'Private'
}

function Invoke-Function 
{
    param([Parameter(Mandatory=$True)][string]$funcName,[string] $arg)

    $func = Get-UserFunctions | where Name -like $funcName
    if($func)
    {
        if($arg)
        {
	    "$funcName with $arg"
            & $func $arg
        }
        else
        {
            & $func
        }
    }
}

function Get-Choice 
{
    param(
        [Parameter(Mandatory=$True)][string[]] $opts,
        $message = "What would you like to do?",
        [switch]$Cancel,
        [switch]$ALL
    )
    
    if($ALL)
    {
        $opts = @("ALL") + $opts
    }

    if($Cancel)
    {
        $opts += "Cancel"
    }

    if($opts.Length -eq 1)
    {
        return $opts[0]
    }

    [char[]]$usedChars = @()
    $i = 1
    $optionVals = $opts | ForEach-Object `
    { 
        $val = $_;
        if($val -contains '*-*')
        {
            $split = ($_ -split "-")

            $fstHalf = $split[0]
            $sndHalf = $split[1]
            if($usedChars -contains $sndHalf[0])
            {
                for($j = 1; $j -lt $sndHalf.Length;$j++)
                {
                    if( !($usedChars -contains $sndHalf[$j]) )
                    {
                        $usedChars += $sndHalf[$j]
                        $sndHalf = $sndHalf.Substring(0, $j) + "&" + $sndHalf.Substring($j,$sndHalf.Length-$j)
                        break;
                    }
                }
            }
            else 
            {
                $usedChars += $sndHalf[0]
                $sndHalf = "&"+$sndHalf
            }
            $fstHalf+"-"+$sndHalf
        }
        else 
        {
            $newval = $val
            if($usedChars -contains $val[0])
            {
                for([int]$j = 1; $j -lt $val.Length;$j++)
                {
                    if( !($usedChars -contains $val[$j] ))
                    {
                        $usedChars += $val[$j]
                        $val = $val.Substring(0, $j) + "&" + $val.Substring($j,$val.Length-$j)
                        break;
                    }
                }
                $newval = $val
            }
            else 
            {
                $newval = "&"+$val
                $usedChars += $val[0]
            }
            return $newval
        }
    }
    $title = "-" * $message.Length
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($optionVals)

    $choice = $host.ui.PromptForChoice($title, $message, $options, 0) 
    
    return (($optionVals[$choice]).Replace("&",""))
}

function Read-Package
{
  Get-Choice (Get-Locals) -message "Which Package would you like to select?" -Cancel 
}

function Get-PackageTools
{
    param(
        [string] $Package
    )

    if(!($Package))
    {
        $Package = Read-Package
    }

    $PackageSrc = Join-Path $src $Package
    return (Get-ChildItem $PackageSrc | where {$_.Name -like "*.exe" -or $_.Name -like "*.ps1" -or $_.Name -like "*.bat"} ).Name
}

function Invoke-PackageTool
{
    param(
        [string] $Package,
        [string] $ToolName
    )

    if(!($Package))
    {
        $Package = Read-Package
    }

    $prv = $PWD
    
    $PackageSrc = Join-Path $src $Package
    
    if(!($ToolName))
    {
        $tools = @()
        $tools += Get-PackageTools -Package $Package

        if($tools.Length -ne 1)
        {
            $selected = Get-Choice ($tools) -message "Which Tool would you like to RUN?" -Cancel

            if($selected -like "Cancel")
            {
                return
            }
        }
        else 
        {
            $selected = $tools[0]
        }

	$ToolName = $selected
        $Tool = Join-Path $PackageSrc $selected
    }
    
    if(!(Test-Path $Tool) -and (Test-Path(Join-Path $PackageSrc $Tool)))
    {
        $Tool = Join-Path $PackageSrc $ToolName
    }

    cd $PackageSrc

    "Running: $Tool"
    ""
    & $Tool
    cd $prv
}

function Get-Remotes
{
    return ((Get-ChildItem $CI_Share -Directory).Name)
}

function Get-Locals
{
    if( !( Test-Path $src ))
    {
        return @()
    }
    return ((Get-ChildItem $src -Directory).Name)
}

function Get-Upgradable
{
    [string[]]$l = @()
    $l += Get-Locals
    $l += "DaSh"
    return $l
}

function Get-Installable
{
    return (Get-Remotes | where {!($_ -like "DaSh")})
}

function Get-Deletable
{
    return Get-Locals
}

function Get-Startable
{
    return Get-Locals
}

function Get-Help
{
    $userFunctions = Get-UserFunctions
    $functionNames = ($userFunctions).Name

    $functionChoice = Get-Choice $functionNames -message "The Share:"

    Invoke-Function ($userFunctions | ? name -like $functionChoice)
}

#--------------------- Main ----------------------#

if(!($FunctionName))
{
    Get-Help
}
elseif($FunctionArg)
{
    "Invokeing with $FunctionArg"
    Invoke-Function -funcName $FunctionName -arg $FunctionArg
}
else
{
    Invoke-Function -funcName $FunctionName
}

# Recursive call to start itself
if ($interactive) 
{
    & (Join-Path $PSScriptRoot $ScriptName)
}
