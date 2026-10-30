<#
.SYNOPSIS
    Bi-directional Pig Latin Translation Engine for FoolsTools.

.DESCRIPTION
    Translates English to Pig Latin (standard or hyphenated syntax) and translates
    Pig Latin back to English. Preserves capitalization, formatting, punctuation,
    and contractions. Supports direct text, text files, interactive input, and clipboard.

.PARAMETER Text
    Text string or file path to translate.

.PARAMETER ToPigLatin
    Translates from English to Pig Latin (default mode).

.PARAMETER FromPigLatin
    Translates from Pig Latin back to English.

.PARAMETER Hyphen
    Uses hyphenated Pig Latin syntax (e.g. 'ame-lay' instead of 'amelay').

.PARAMETER OutFile
    Writes translation output directly to the specified file path.

.PARAMETER Clip
    Copies the translated result to the Windows clipboard.

.PARAMETER VowelSuffix
    Suffix used for words starting with a vowel (default: 'way').

.PARAMETER NoColor
    Disables console color output.

.EXAMPLE
    Translate-PigLatin.ps1 "Hello world! This is a test."

.EXAMPLE
    Translate-PigLatin.ps1 "Hello world!" -Hyphen

.EXAMPLE
    Translate-PigLatin.ps1 -From "Ellohay orldway!"

.EXAMPLE
    Translate-PigLatin.ps1 "document.txt" -OutFile "document_pig.txt"

Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
Contact: foolycooly1764@gmail.com
#>

Set-StrictMode -Off

# Ensure UTF-8 output encoding
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
try { [Console]::OutputEncoding = $utf8NoBom } catch {}

# ==============================================================================
# 1. Parameter Normalization
# ==============================================================================
$Mode         = "AUTO"   # AUTO, TO, FROM
$UseHyphen    = $false
$VowelSuffix  = "way"
$TargetText   = $null
$TargetFile   = $null
$OutFile      = $null
$CopyToClip   = $false
$ReadStdin    = $false
$NoColor      = $false

$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', '-help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: pig-latin [[Options] Target]

   Bi-directional English <-> Pig Latin translator. Supports direct text,
   text files, drag-and-drop, and interactive prompts.

   Options / Flags:
      -to, -e2p                  : Translate English to Pig Latin (default)
      -from, -p2e                : Translate Pig Latin to English
      -hyphen, -hyp, -dash       : Use hyphenated syntax (e.g. 'ame-lay' vs 'amelay')
      -suffix <way|yay|ay>       : Vowel suffix for English->Pig Latin (default: way)
      -o, -out <filepath>        : Save translation to an output file
      -clip                      : Copy translated result to Windows clipboard
      -nc, -nocolor              : Disable console color formatting
      -?, -h, --help             : Display this syntax help

   Examples:
      pig-latin "Hello world! This is a test."
      pig-latin "Hello world!" -hyphen
      pig-latin "Ello-hay orld-way!" -from
      pig-latin notes.txt
      pig-latin notes.txt -hyphen -o notes_pig.txt
      pig-latin "Secret message" -clip

Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
Contact: foolycooly1764@gmail.com

"@
}

$argList = [System.Collections.ArrayList]@($args)
$textTokens = New-Object System.Collections.Generic.List[string]
$i = 0

while ($i -lt $argList.Count) {
    $token = [string]$argList[$i]
    $lower = $token.ToLower()

    if ($HelpSwitches -contains $lower) {
        Show-Usage
        exit 0
    }
    elseif (@('-to', '-e2p', '/to') -contains $lower) {
        $Mode = "TO"
    }
    elseif (@('-from', '-p2e', '/from') -contains $lower) {
        $Mode = "FROM"
    }
    elseif (@('-hyphen', '-hyp', '-dash', '--hyphen') -contains $lower) {
        $UseHyphen = $true
    }
    elseif (@('-clip', '/clip', '--clip') -contains $lower) {
        $CopyToClip = $true
    }
    elseif (@('-stdin', '-pipe', '--stdin', '--pipe') -contains $lower) {
        $ReadStdin = $true
    }
    elseif (@('-nc', '-nocolor', '--nocolor') -contains $lower) {
        $NoColor = $true
    }
    elseif (@('-suffix', '--suffix') -contains $lower) {
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $VowelSuffix = $next.ToLower()
                $i++
            }
        }
    }
    elseif (@('-o', '-out', '--out', '/o') -contains $lower) {
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $OutFile = $next
                $i++
            }
        }
    }
    else {
        # Check if argument is an existing file
        if (-not $TargetFile -and (Test-Path -LiteralPath $token -PathType Leaf)) {
            $TargetFile = (Resolve-Path -LiteralPath $token).Path
        } else {
            $textTokens.Add($token)
        }
    }
    $i++
}

if ($textTokens.Count -gt 0 -and -not $TargetText) {
    $TargetText = ($textTokens -join " ")
}

# ==============================================================================
# 2. Output & Clipboard Helpers
# ==============================================================================
function Write-Color([string]$Text, [System.ConsoleColor]$Color = [System.ConsoleColor]::Gray) {
    if ($NoColor) {
        Write-Host $Text
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Copy-ToClipboard([string]$Text) {
    try {
        if (Get-Command "Set-Clipboard" -ErrorAction SilentlyContinue) {
            $Text | Set-Clipboard
        } else {
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo.FileName = "clip.exe"
            $proc.StartInfo.UseShellExecute = $false
            $proc.StartInfo.RedirectStandardInput = $true
            $proc.Start() | Out-Null
            $sw = $proc.StandardInput
            $sw.Write($Text)
            $sw.Close()
            $proc.WaitForExit()
        }
        Write-Color "[CLIPBOARD] Translated text copied to clipboard." Green
    } catch {
        Write-Color "[WARNING] Could not copy to clipboard: $($_.Exception.Message)" Yellow
    }
}

# ==============================================================================
# 3. Translation Core Algorithms
# ==============================================================================
function Convert-WordToPigLatin([string]$w, [bool]$hyphen = $false, [string]$vSuffix = "way") {
    if ([string]::IsNullOrWhiteSpace($w)) { return $w }
    $isUpper = ($w -ceq $w.ToUpper())
    $isTitle = (-not $isUpper -and [char]::IsUpper($w[0]))
    $vowels  = "aeiouAEIOU"

    $result = ""

    # Words starting with a vowel
    if ($vowels.IndexOf($w[0]) -ge 0) {
        $suf = if ($isUpper) { $vSuffix.ToUpper() } else { $vSuffix.ToLower() }
        $result = if ($hyphen) { $w + "-" + $suf } else { $w + $suf }
    } else {
        # Words starting with consonant cluster
        $idx = 0
        while ($idx -lt $w.Length) {
            $c = $w[$idx]
            # 'y' after index 0 acts as a vowel
            if ($vowels.IndexOf($c) -ge 0 -or ($idx -gt 0 -and ($c -eq 'y' -or $c -eq 'Y'))) {
                break
            }
            # Handle 'qu' cluster (e.g. 'quiet' -> 'ietquay', 'quick' -> 'ickquay')
            if (($c -eq 'q' -or $c -eq 'Q') -and ($idx + 1 -lt $w.Length) -and ($w[$idx+1] -eq 'u' -or $w[$idx+1] -eq 'U')) {
                $idx += 2
                break
            }
            $idx++
        }

        if ($idx -ge $w.Length) {
            # No vowels found (e.g. 'my', 'by')
            $suf = if ($isUpper) { "AY" } else { "ay" }
            $result = if ($hyphen) { $w + "-" + $suf } else { $w + $suf }
        } else {
            $prefix = $w.Substring(0, $idx)
            $stem   = $w.Substring($idx)
            $suf    = if ($isUpper) { "AY" } else { "ay" }
            $result = if ($hyphen) { $stem + "-" + $prefix.ToLower() + $suf } else { $stem + $prefix.ToLower() + $suf }
        }
    }

    if ($isUpper) {
        return $result.ToUpper()
    } elseif ($isTitle) {
        return $result.Substring(0,1).ToUpper() + $result.Substring(1).ToLower()
    } else {
        return $result.ToLower()
    }
}

function Convert-WordFromPigLatin([string]$w) {
    if ([string]::IsNullOrWhiteSpace($w)) { return $w }
    $isUpper = ($w -ceq $w.ToUpper())
    $isTitle = (-not $isUpper -and [char]::IsUpper($w[0]))
    $lower   = $w.ToLower()
    $result  = $w

    # Comprehensive set of English word stems starting with 'w'
    $wStems = @(
        'alk','all','ander','ant','ar','arm','arn','as','ash','aste','atch','ater','ave','ay',
        'eak','eapon','ear','eather','eb','edding','eek','eight','eighty','elcome','ell','ent','ere','est','et',
        'ide','idow','ife','ild','ill','in','ind','indow','ine','ing','inner','inter','ipe','ire','ise','ish','itch','ith','ithin','ithout','itness',
        'olf','oman','omen','on','onder','ood','ool','ord','ore','ork','orker','orld','orm','orn','orry','orse','orst','orth','ould','ound'
    )

    # 1. Hyphenated syntax: stem-cluster(ay) (e.g. ame-lay, apple-way, ing-stray)
    if ($lower -match '^([a-z'']+)-([a-z]+)$') {
        $stem   = $matches[1]
        $suffix = $matches[2]
        if ($suffix -match '^(.*)ay$') {
            $cluster = $matches[1]
            if ($cluster -eq 'w') {
                if ($wStems -contains $stem) {
                    $result = "w" + $stem
                } else {
                    $result = $stem
                }
            } elseif ($cluster -eq 'y' -or $cluster -eq '') {
                $result = $stem
            } else {
                $result = $cluster + $stem
            }
        }
    }
    # 2. Unhyphenated syntax: vowel-started word ending with way/yay (e.g. appleway)
    elseif ($lower -match '^([a-z'']+)(way|yay)$' -and 'aeiou'.IndexOf($matches[1][0]) -ge 0) {
        $stem = $matches[1]
        $suf  = $matches[2]
        if ($suf -eq 'way' -and ($wStems -contains $stem)) {
            $result = "w" + $stem
        } else {
            $result = $stem
        }
    }
    # 3. Unhyphenated syntax: consonant-started word ending with ...ay (e.g. amelay, ingstray)
    elseif ($lower -match '^([a-z'']+)ay$') {
        $body = $matches[1]
        $onsets = @(
            'spl','str','scr','spr','shr','thr',
            'ch','sh','th','wh','ph','qu','sc','sk','sl','sm','sn','sp','st','sw',
            'bl','cl','fl','gl','pl','br','cr','dr','fr','gr','pr','tr','tw','dw',
            'b','c','d','f','g','h','j','k','l','m','n','p','r','s','t','v','w','x','y','z'
        )
        $matchedOnset = $null
        foreach ($o in $onsets) {
            if ($body.EndsWith($o) -and $body.Length -gt $o.Length) {
                $matchedOnset = $o
                break
            }
        }
        if ($matchedOnset) {
            $stem   = $body.Substring(0, $body.Length - $matchedOnset.Length)
            $result = $matchedOnset + $stem
        }
    }

    if ($isUpper) {
        return $result.ToUpper()
    } elseif ($isTitle) {
        return $result.Substring(0,1).ToUpper() + $result.Substring(1).ToLower()
    } else {
        return $result.ToLower()
    }
}

function Convert-Text([string]$text, [string]$direction, [bool]$hyphen, [string]$vSuffix) {
    if ([string]::IsNullOrEmpty($text)) { return "" }
    # Tokenizer pattern preserving words, hyphenated pairs, contractions, whitespace, and punctuation
    $pattern = "([a-zA-Z]+(?:'[a-zA-Z]+)?(?:-[a-zA-Z]+)?|[^a-zA-Z]+)"
    $tokens  = [regex]::Matches($text, $pattern)
    $sb      = New-Object System.Text.StringBuilder

    foreach ($m in $tokens) {
        $val = $m.Value
        if ($val -match "^[a-zA-Z]+(?:'[a-zA-Z]+)?(?:-[a-zA-Z]+)?$") {
            if ($direction -eq "FROM") {
                $translated = Convert-WordFromPigLatin $val
            } else {
                $translated = Convert-WordToPigLatin $val $hyphen $vSuffix
            }
            $sb.Append($translated) | Out-Null
        } else {
            $sb.Append($val) | Out-Null
        }
    }
    return $sb.ToString()
}

# ==============================================================================
# 4. Interactive File Menu Workflow
# ==============================================================================
function Invoke-FileWorkflow([string]$filePath) {
    Write-Host ""
    Write-Color "============================================================" Cyan
    Write-Color "         Fool's Tools - Pig Latin Translator" Yellow
    Write-Color "============================================================" Cyan
    Write-Color "File: $filePath" Gray
    Write-Host ""
    Write-Color "  [1] Translate to Pig Latin (Standard: amelay)" Gray
    Write-Color "  [2] Translate to Pig Latin (Hyphenated: ame-lay)" Gray
    Write-Color "  [3] Translate from Pig Latin to English" Gray
    Write-Color "  [Q] Quit" Gray
    Write-Host ""

    $choice = Read-Host "Select translation option [1-3, Q]"
    $choiceTrim = $choice.Trim().ToUpper()

    $dir = "TO"
    $hyp = $false

    if ($choiceTrim -eq 'Q') {
        exit 0
    } elseif ($choiceTrim -eq '1') {
        $dir = "TO"
        $hyp = $false
    } elseif ($choiceTrim -eq '2') {
        $dir = "TO"
        $hyp = $true
    } elseif ($choiceTrim -eq '3') {
        $dir = "FROM"
    } else {
        Write-Color "[ERROR] Invalid option." Red
        exit 1
    }

    $rawContent = [System.IO.File]::ReadAllText($filePath)
    $translated = Convert-Text $rawContent $dir $hyp $VowelSuffix

    # Print preview
    Write-Host ""
    Write-Color "--- Translation Preview ---" Cyan
    Write-Host $translated
    Write-Host ""

    $ext = [System.IO.Path]::GetExtension($filePath)
    $dirName = [System.IO.Path]::GetDirectoryName($filePath)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $defaultOut = [System.IO.Path]::Combine($dirName, ($baseName + "_piglatin" + $ext))

    $savePrompt = Read-Host "Save translation to file? (Y/N) [Default: $defaultOut]"
    if ($savePrompt -match '^[Yy]$' -or ($savePrompt -eq '' -and -not [string]::IsNullOrWhiteSpace($defaultOut))) {
        [System.IO.File]::WriteAllText($defaultOut, $translated, $utf8NoBom)
        Write-Color "[SAVED] File written to: $defaultOut" Green
    }

    if ($CopyToClip) {
        Copy-ToClipboard $translated
    } else {
        $clipPrompt = Read-Host "Copy translation to clipboard? (Y/N)"
        if ($clipPrompt -match '^[Yy]$') {
            Copy-ToClipboard $translated
        }
    }
}

# ==============================================================================
# 5. Interactive Standalone Menu Workflow
# ==============================================================================
function Show-InteractiveMenu {
    Clear-Host
    Write-Color "============================================================" Cyan
    Write-Color "         Fool's Tools - Pig Latin Translator" Yellow
    Write-Color "============================================================" Cyan
    Write-Host ""
    Write-Color "  [1] English -> Pig Latin (Standard: amelay)" Gray
    Write-Color "  [2] English -> Pig Latin (Hyphenated: ame-lay)" Gray
    Write-Color "  [3] Pig Latin -> English" Gray
    Write-Color "  [4] Translate a Text File" Gray
    Write-Color "  [Q] Quit" Gray
    Write-Host ""

    $choice = Read-Host "Select an option [1-4, Q]"
    $choiceTrim = $choice.Trim().ToUpper()

    if ($choiceTrim -eq 'Q') {
        exit 0
    }
    elseif ($choiceTrim -eq '4') {
        $fPath = Read-Host "Enter or drag-and-drop file path"
        $fClean = $fPath.Trim('"', "'")
        if (Test-Path -LiteralPath $fClean -PathType Leaf) {
            Invoke-FileWorkflow $fClean
        } else {
            Write-Color "[ERROR] File not found: '$fClean'" Red
        }
        exit 0
    }
    elseif (@('1', '2', '3') -contains $choiceTrim) {
        $dir = if ($choiceTrim -eq '3') { "FROM" } else { "TO" }
        $hyp = ($choiceTrim -eq '2')

        Write-Host ""
        $inputString = Read-Host "Enter text to translate"
        if ([string]::IsNullOrWhiteSpace($inputString)) {
            Write-Color "No text entered." Yellow
            exit 0
        }

        $result = Convert-Text $inputString $dir $hyp $VowelSuffix
        Write-Host ""
        Write-Color "Translation:" Yellow
        Write-Host $result -ForegroundColor Cyan
        Write-Host ""

        $clipPrompt = Read-Host "Copy translation to clipboard? (Y/N)"
        if ($clipPrompt -match '^[Yy]$') {
            Copy-ToClipboard $result
        }
    }
}

# ==============================================================================
# 6. Main Execution Dispatcher
# ==============================================================================
# Target is direct text from CLI
if ($TargetText) {
    $dir = if ($Mode -eq "FROM") { "FROM" } else { "TO" }
    $result = Convert-Text $TargetText $dir $UseHyphen $VowelSuffix

    if ($OutFile) {
        [System.IO.File]::WriteAllText($OutFile, $result, $utf8NoBom)
        Write-Color "[SAVED] Translation written to: $OutFile" Green
    } else {
        Write-Color $result Cyan
    }
    if ($CopyToClip) { Copy-ToClipboard $result }
    exit 0
}

# Target is an existing file
if ($TargetFile) {
    # If explicit CLI flags were provided, process directly
    if ($Mode -ne "AUTO" -or $UseHyphen -or $OutFile) {
        $raw = [System.IO.File]::ReadAllText($TargetFile)
        $dir = if ($Mode -eq "FROM") { "FROM" } else { "TO" }
        $result = Convert-Text $raw $dir $UseHyphen $VowelSuffix

        if ($OutFile) {
            [System.IO.File]::WriteAllText($OutFile, $result, $utf8NoBom)
            Write-Color "[SAVED] Translation written to: $OutFile" Green
        } else {
            Write-Host $result
        }
        if ($CopyToClip) { Copy-ToClipboard $result }
        exit 0
    } else {
        # Interactive file prompt (similar to video and gif)
        Invoke-FileWorkflow $TargetFile
        exit 0
    }
}

# Explicit Stdin / Pipeline flag (-stdin / -pipe)
if ($ReadStdin) {
    $pipedInput = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrEmpty($pipedInput)) {
        $dir = if ($Mode -eq "FROM") { "FROM" } else { "TO" }
        $result = Convert-Text $pipedInput $dir $UseHyphen $VowelSuffix
        if ($OutFile) {
            [System.IO.File]::WriteAllText($OutFile, $result, $utf8NoBom)
            Write-Color "[SAVED] Translation written to: $OutFile" Green
        } else {
            [Console]::Out.Write($result)
        }
        if ($CopyToClip) { Copy-ToClipboard $result }
    }
    exit 0
}

# No input provided: Launch interactive menu
Show-InteractiveMenu
