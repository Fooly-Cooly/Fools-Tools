[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$SourcePath,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [int]$IconIndex = -1,  # Default to -1 (Extract ALL icons in the file)

    [Parameter(Mandatory=$false)]
    [ValidateSet("ICO", "PNG", "Both")]
    [string]$Format = "ICO",

    [Parameter(Mandatory=$false)]
    [switch]$SplitSizes
)

# 1. Resolve Native Win32 API Methods via C#
$Win32IconExtractor = @"
using System;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class Win32IconHelper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int PrivateExtractIcons(
        string lpszFile,
        int nIconIndex,
        int cxIcon,
        int cyIcon,
        IntPtr[] phicon,
        int[] piconid,
        int nIcons,
        int flags
    );

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyIcon(IntPtr hIcon);

    // Get Total Count of Icon Resource Groups in File
    public static int GetTotalIconCount(string filePath) {
        return PrivateExtractIcons(filePath, 0, 0, 0, null, null, 0, 0);
    }

    public static List<Bitmap> ExtractIconSizes(string filePath, int index) {
        List<Bitmap> bitmaps = new List<Bitmap>();
        int[] targetSizes = new int[] { 256, 128, 64, 48, 32, 16 };

        foreach (int size in targetSizes) {
            IntPtr[] phicon = new IntPtr[1];
            int[] piconid = new int[1];

            int count = PrivateExtractIcons(filePath, index, size, size, phicon, piconid, 1, 0);

            if (count > 0 && phicon[0] != IntPtr.Zero) {
                using (Icon ico = Icon.FromHandle(phicon[0])) {
                    using (Bitmap tempBmp = ico.ToBitmap()) {
                        // DEEP CLONE to break native GDI+ memory locks
                        Bitmap safeBitmap = new Bitmap(tempBmp.Width, tempBmp.Height, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
                        using (Graphics g = Graphics.FromImage(safeBitmap)) {
                            g.DrawImage(tempBmp, 0, 0, tempBmp.Width, tempBmp.Height);
                        }
                        bitmaps.Add(safeBitmap);
                    }
                }
                DestroyIcon(phicon[0]);
            }
        }
        return bitmaps;
    }

    public static void SaveMultiSizeIcon(List<Bitmap> bitmaps, string outputPath) {
        using (FileStream fs = new FileStream(outputPath, FileMode.Create))
        using (BinaryWriter bw = new BinaryWriter(fs)) {
            bw.Write((short)0); // Reserved
            bw.Write((short)1); // Image Type (1 = ICO)
            bw.Write((short)bitmaps.Count);

            int offset = 6 + (bitmaps.Count * 16);
            List<byte[]> imageBuffers = new List<byte[]>();

            foreach (Bitmap bmp in bitmaps) {
                using (MemoryStream ms = new MemoryStream()) {
                    bmp.Save(ms, System.Drawing.Imaging.ImageFormat.Png);
                    byte[] pngBytes = ms.ToArray();
                    imageBuffers.Add(pngBytes);

                    bw.Write((byte)(bmp.Width >= 256 ? 0 : bmp.Width));
                    bw.Write((byte)(bmp.Height >= 256 ? 0 : bmp.Height));
                    bw.Write((byte)0);
                    bw.Write((byte)0);
                    bw.Write((short)1);
                    bw.Write((short)32);
                    bw.Write((int)pngBytes.Length);
                    bw.Write((int)offset);

                    offset += pngBytes.Length;
                }
            }

            foreach (byte[] buffer in imageBuffers) {
                bw.Write(buffer);
            }
        }
    }
}
"@

Add-Type -TypeDefinition $Win32IconExtractor -ReferencedAssemblies "System.Drawing"

# 2. Resolve Environment Variables & Paths
$ResolvedSource = [System.Environment]::ExpandEnvironmentVariables($SourcePath)

if (-not (Test-Path $ResolvedSource)) {
    Write-Error "Source file or resource target could not be found: $ResolvedSource"
    return
}

# 3. Determine Output Directory
$SourceItem = Get-Item $ResolvedSource
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputDir = Get-Location
} else {
    $OutputDir = [System.Environment]::ExpandEnvironmentVariables($OutputPath)
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
}

# 4. Query Total Icons & Determine Index Loop Range
$TotalIconsInFile = [Win32IconHelper]::GetTotalIconCount($SourceItem.FullName)

if ($TotalIconsInFile -eq 0) {
    Write-Warning "No icon resources found inside $ResolvedSource."
    return
}

$IndicesToExtract = @()
if ($IconIndex -lt 0) {
    Write-Host "[INFO] No index specified. Extracting ALL $TotalIconsInFile icon(s) from $ResolvedSource..." -ForegroundColor Yellow
    $IndicesToExtract = 0..($TotalIconsInFile - 1)
} else {
    if ($IconIndex -ge $TotalIconsInFile) {
        Write-Error "Index $IconIndex is out of range. File contains $TotalIconsInFile icon(s) (Indices: 0 to $($TotalIconsInFile - 1))."
        return
    }
    $IndicesToExtract = @($IconIndex)
}

# 5. Extraction Loop
foreach ($CurrentIdx in $IndicesToExtract) {
    $BaseName = "$($SourceItem.BaseName)_icon_$CurrentIdx"
    Write-Host "`n[EXTRACTING] Processing $($SourceItem.Name) (Index: $CurrentIdx/$($TotalIconsInFile - 1))..." -ForegroundColor Cyan

    $Bitmaps = [Win32IconHelper]::ExtractIconSizes($SourceItem.FullName, $CurrentIdx)

    if ($Bitmaps.Count -eq 0) {
        Write-Warning "Skipping index $CurrentIdx (No bitmap sizes returned)."
        continue
    }

    try {
        # Generate Multi-size .ICO Container
        if ($Format -eq "ICO" -or $Format -eq "Both") {
            if (-not $SplitSizes) {
                $IcoPath = Join-Path $OutputDir "$BaseName.ico"
                [Win32IconHelper]::SaveMultiSizeIcon($Bitmaps, $IcoPath)
                Write-Host "[SUCCESS] Single Multi-Res ICO: $IcoPath" -ForegroundColor Green
            }
        }

        # Generate Individual PNGs or Split ICO Sizes
        if ($Format -eq "PNG" -or $Format -eq "Both" -or $SplitSizes) {
            foreach ($bmp in $Bitmaps) {
                $SizeName = "${BaseName}_$($bmp.Width)x$($bmp.Height)"
                
                if ($Format -eq "PNG" -or $Format -eq "Both") {
                    $PngPath = Join-Path $OutputDir "$SizeName.png"
                    $bmp.Save($PngPath, [System.Drawing.Imaging.ImageFormat]::Png)
                    Write-Host "[SUCCESS] PNG Extracted: $PngPath" -ForegroundColor Green
                }

                if ($SplitSizes -and ($Format -eq "ICO" -or $Format -eq "Both")) {
                    $SingleIcoPath = Join-Path $OutputDir "$SizeName.ico"
                    $SingleList = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
                    $SingleList.Add($bmp)
                    [Win32IconHelper]::SaveMultiSizeIcon($SingleList, $SingleIcoPath)
                    Write-Host "[SUCCESS] Split ICO Extracted: $SingleIcoPath" -ForegroundColor Green
                }
            }
        }
    }
    finally {
        foreach ($bmp in $Bitmaps) {
            $bmp.Dispose()
        }
    }
}