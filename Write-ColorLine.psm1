Function Write-ColorLine
{
    Param(
        $items,
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
        
    return [PSCustomObject]@{fg = $ForegroundColor; bg = $BackgroundColor; text = $text}
}