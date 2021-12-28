# PSColorText

__ARCHIVED__: Using [$PSStyle](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ansi_terminals?view=powershell-7.2#psstyle) instead.

## What is it?

A module that allows you to define the colour of your text as part
of your output string. Saving you from multiple calls to Write-Host
to build up a single line of text.

## Background

Everyone loves coloured text, it makes reading things easier, highlights
important information and impresses your users (hopefully).

I found writing coloured text in PowerShell to be tedious. Certainly once
you get past the phase of having a single line of colour and want to start
having coloured elements in your lines.

I wrote this module to scratch that itch.

## Usage

![Basic Usage](./res/basic_usage.png)

### Syntax

The module uses the token `!(fg,bg)` to indicate color changes in a string. 
Where `fg` is the foreground colour and `bg` is the background colour. 

The colors are limited to the `[ConsoleColor]` type.

It supports a number of permutations.

| Example     | Output  | Notes  |
| ----------- | ------- | ------ |
| `An !(red,blue)example` |  ![](./res/example_1.png) | Basic usage, specify foreground and background |
| `An !(cyan)example` |  ![](./res/example_2.png) | Specify just foreground |
| `An !(,red)example` |  ![](./res/example_3.png) | Specify just background |
| `A !(black,yellow)new(!*,*) example` |  ![](./res/example_4.png) | Reset to initial colors |
| `!(red)* !(yellow)* !(green)*` |  ![](./res/example_5.png) | Change colour as often as you need |

