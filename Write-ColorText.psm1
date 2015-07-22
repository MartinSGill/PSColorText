function Write-ColorText
{
    <#
        .SYNOPSIS
        Writes text to the console using tags in the string itself
        to indicate the output color of the text. Can replace
        Write-Host cmdlet.

        MIT License
        Copyright © 2014-2015, Martin Gill. All Rights Reserved.

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

        .EXAMPLE
        PS C:\> Write-ColorText "This is a test !(gray)[ !(red)fail!(gray) ]"

        .EXAMPLE
        PS C:\> Write-ColorText "This is a test !(gray)[!(black,green) fail !(gray,*)]"

        .INPUTS
        System.String

        .OUTPUTS
        None

        .NOTES
        LICENSE

        The MIT License (MIT)

        Copyright (c) 2014-2015, Martin Gill. All Rights Reserved.

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in
        all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
        THE SOFTWARE.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $String,

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
                $foreground = $match.Groups['foreground'].Value
                $background = $match.Groups['background'].Value

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
            $script:currentForeground = $script:initialForeground
            $script:currentBackground = $script:initialBackground

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

