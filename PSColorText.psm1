#requires -Version 3

function Write-ColorText
{
    <#
            .SYNOPSIS
            Writes text to the console using tags in the string itself
            to indicate the output color of the text. Can replace
            Write-Host cmdlet.

            .DESCRIPTION
            This script allows you to use custom markup to more easily
            write multi-colored text to the console. Can replace
            Write-Host cmdlet.

            It uses the general format of:
        
            !(foreground,background) 
      
            to define a color setting.

            both background and foreground can be omitted, but the comma
            is required if you specify a background color.
            The following are all valid:

            !(red)
            !(,red)
            !(blue,)
            !(yellow,black)

            If you don't specify a color it will continue using the current
            color. If you specify "*" as a color it will revert to the default
            color.

            You can escape the markup using an additional '!':

            !!(red)

            .PARAMETER String
            The string to write out.

            .PARAMETER NoColor
            Disable color output.

            .PARAMETER NoNewLine
            Do not append a newline after writing out text.

            .PARAMETER ForegroundColor
            Initial Foreground color.

            .PARAMETER BackgroundColor
            Initial Background color.

            .EXAMPLE
            PS C:\> Write-ColorText "This is a test !(gray)[ !(red)fail!(gray) ]"

            .EXAMPLE
            PS C:\> Write-ColorText "This is a test !(gray)[!(black,green) fail !(gray,*)]"

            .INPUTS
            System.String

            .OUTPUTS
            None
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $String,

        [ConsoleColor]
        $ForegroundColor,

        [ConsoleColor]
        $BackgroundColor,

        [switch]
        $NoNewline,

        [switch]
        $NoColor
    )
    
    begin 
    {
        function Test-Values
        {
            $matches = @($script:regex.Matches($String))
      
            # do some validation
            foreach ($match in $matches)
            {
                $foreground = $match.Groups['foreground'].Value.ToLower()
                $background = $match.Groups['background'].Value.ToLower()

                $success = $script:colors.Contains($foreground) -or $foreground -eq '*' -or $foreground -eq [string]::Empty
                if (!$success)
                {
                    $errorString = "Unrecognised Color: '{0}' : char: {1}`n" -f $foreground, $match.Index
                    $errorString += $String + "`n"
                    $errorString += (' ' * $match.Index) + ('~' * $match.Length)
                    throw $errorString
                }

                $success = $script:colors.Contains($background) -or $background -eq '*' -or $background -eq [string]::Empty
                if (!$success)
                {
                    $errorString = "Unrecognised Color: '{0}' : char: {1}`n" -f $background, $match.Index
                    $errorString += $String + "`n"
                    $errorString += (' ' * $match.Index) + ('~' * $match.Length)
                    throw $errorString
                }
            }
        } # function Test-Values

        function Resolve-Color
        {
            param($value, $bg = $false)

            if ($value -eq '*')
            {
                if ($bg)
                {
                    return $script:initialBackground
                }
                else
                {
                    return $script:initialForeground
                }
            }
            elseif ($value -eq [string]::Empty)
            {
                if ($bg)
                {
                    return $script:currentBackground
                }
                else
                {
                    return $script:currentForeground
                }
            }
      
            return $value
        } # Resolve-Color

        try 
        {
            $script:regex = [regex] '(?im)(?<!!)!\((?<foreground>(?:\w*|\*))(?:,(?<background>(?:\w*|\*)))?\)'
            $script:initialForeground = $host.UI.RawUI.ForegroundColor
            $script:initialBackground = $host.UI.RawUI.BackgroundColor

            $script:colors = [ConsoleColor].GetEnumNames() | ForEach-Object -Process {
                $_.ToLower()
            }
        } 
        catch 
        {
            throw
        }
    }
    process 
    {
        try 
        {
            if ($ForegroundColor)
            {
                $script:currentForeground = $ForegroundColor
            }
            else
            {
                $script:currentForeground = $script:initialForeground
            }

            if ($BackgroundColor)
            {
                $script:currentBackground = $BackgroundColor
            }
            else
            {
                $script:currentBackground = $script:initialBackground
            }

            Test-Values

            $matches = @($script:regex.Matches($String))
            $lastPos = 0

            foreach ($match in $matches)
            {
                if ($NoColor -or ($script:currentForeground.ToString() -eq '-1' -and $script:currentBackground.ToString() -eq '-1'))
                {
                    Write-Host -Object $String.Substring($lastPos, $match.Index - $lastPos) -NoNewline
                }
                elseif ($script:currentForeground.ToString() -eq '-1')
                {
                    Write-Host -Object $String.Substring($lastPos, $match.Index - $lastPos) -NoNewline -BackgroundColor $script:currentBackground
                }
                elseif ($script:currentBackground.ToString() -eq '-1')
                {
                    Write-Host -Object $String.Substring($lastPos, $match.Index - $lastPos) -NoNewline -ForegroundColor $script:currentForeground
                }
                else
                {
                    Write-Host -Object $String.Substring($lastPos, $match.Index - $lastPos) -NoNewline -BackgroundColor $script:currentBackground -ForegroundColor $script:currentForeground
                }

                $lastPos = $match.Index + $match.Length 
                $script:currentForeground = Resolve-Color $match.Groups['foreground'].Value $false
                $script:currentBackground = Resolve-Color $match.Groups['background'].Value $true
            }

            if ($NoColor -or ($script:currentForeground.ToString() -eq '-1' -and $script:currentBackground.ToString() -eq '-1'))
            {
                Write-Host -Object $String.Substring($lastPos) -NoNewline
            }
            elseif ($script:currentForeground.ToString() -eq '-1')
            {
                Write-Host -Object $String.Substring($lastPos) -BackgroundColor $script:currentBackground -NoNewline
            }
            elseif ($script:currentBackground.ToString() -eq '-1')
            {
                Write-Host -Object $String.Substring($lastPos) -ForegroundColor $script:currentForeground -NoNewline
            }
            else
            {
                Write-Host -Object $String.Substring($lastPos) -BackgroundColor $script:currentBackground -ForegroundColor $script:currentForeground -NoNewline
            }

            if (!$NoNewline.IsPresent)
            {
                Write-Host -Object ''
            }
        } 
        catch 
        {
            throw
        }
    }
    end 
    {
        try 
        {
            $host.UI.RawUI.ForegroundColor = $script:initialForeground
            $host.UI.RawUI.BackgroundColor = $script:initialBackground
        } 
        catch 
        {
            throw
        }
    }
}

Function Write-ColorLine
{
    <#
    .SYNOPSIS
        Utility to assemble a single line of colored text
        from component items.
    .DESCRIPTION
        Long description
    .EXAMPLE
    .INPUTS
        ColorLine Item(s)
        cf. New-ColorLineItem
    .OUTPUTS
    .NOTES
        A "powerline compatible" font is required to really
        benefit from this function.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [psobject[]]$items,
        [ConsoleColor]$defaultBackgroundColor = 'black',
        [Switch]$NoNewLine
    )
        
    $sym = ''
    $back = $defaultBackgroundColor
        
    foreach ($item in $items)
    {
        $fore = $back
        $back = $item.bg
        Write-ColorText "!($fore,$back)$sym" -NoNewLine
        $fore = $item.fg
        $back = $item.bg
        Write-ColorText ("!($fore,$back)" + $item.text) -NoNewline
    }
    Write-ColorText "!($back,$defaultBackgroundColor)$sym" -NoNewLine:$NoNewLine
}

Function New-ColorLineItem
{
    <#
    .SYNOPSIS
        Utility to create a ColorLineItem custom object. 
    .DESCRIPTION
        Easily create a color line obkect.
        These objects have the structure
        @{ bg, fg, text }
        where bg is the background color
        fg is the foreground color
        and text is the display text.
    .EXAMPLE
        C:\PS> <example usage>
        Explanation of what the example does
    .INPUTS
    .OUTPUTS
        PsCustomObject
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [Alias('fg')]
        [ConsoleColor]$ForegroundColor,
            
        [Parameter(Mandatory=$true)]
        [Alias('bg')]
        [ConsoleColor]$BackgroundColor,
        
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
        
    [PSCustomObject]@{fg = $ForegroundColor; bg = $BackgroundColor; text = $text};
}

Export-ModuleMember Write-ColorText, Write-ColorLine, New-ColorLineItem
