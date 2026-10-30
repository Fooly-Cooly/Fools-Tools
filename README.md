# Fools-Tools

A versatile, lightweight, and portable Windows utility suite featuring modern CLI wrappers, pure terminal administration tools, media processors, and an automated regression test harness.

FoolsTools combines native Windows Batch scripts, PowerShell automation engines, and portable standalone binaries into a cohesive toolset designed for both interactive desktop usage and command-line scripting across Windows 7 through Windows 11.

---

## Features

- **System Administration & Maintenance**:
  - `appx`: Pure terminal console manager for Universal Windows Platform (UWP) and AppX Store applications with multi-select range removal and offline de-provisioning.
  - `dism-pkg`: Windows DISM servicing package manager and WinSxS component store cleaner.
  - `clean-up`: Safe disk cleanup, temporary file pruning, and locked icon/thumbnail cache rebuilder.
  - `reg-tweaks`: Curated Windows registry tweaks, shell context menu extensions, and privacy settings manager with interactive range selection and CLI automation.
  - `show-ip`: Dual-stack local gateway and public WAN IP discovery with 2.5-second resilient timeout.
  - `sys-info`: Hardware specification and OS diagnostic tool featuring colorized Windows ASCII branding.
  - `sudo`: Transparent UAC administrator privilege elevation forwarder.
  - `clear`: Lightweight terminal screen clear alias (`CLS`).

- **Archival & File Organization**:
  - Unified multi-format compression engine supporting 7z, ZIP, CB7, CBR, CBZ, and GZ.
  - Action presets for maximum archival (`/A`), comic optimization (`/C`), and store-only (`/S`).
  - Automated generation of self-extracting SFX installers.
  - `file-to-folder`: Pure batch file organizer that sorts loose files into folders matching their basenames, with move/copy modes, dry-run simulation, and extension filtering.

- **Media & Image Processing**:
  - `video`: Unified FFmpeg media suite for MP3 audio extraction, frame dumps, GIF conversion, and video muting.
  - `gif`: Lossless GIF optimization, video conversion (MP4/WebM), APNG generation, and frame sequence extraction powered by Gifsicle and FFmpeg.
  - `webp`: Multi-threaded lossless WebP converter for BMP, GIF, and PNG images with optional recycle bin pruning.
  - `extract-icon`: High-resolution PE icon and bitmap extractor supporting `.ico`, `.png`, and multi-resolution split extraction.

- **Networking, Hashing & Utilities**:
  - `hash`: High-speed in-memory compiled C# streaming hash engine supporting CRC32, MD5, SHA-1, SHA-256, SHA-384, SHA-512, XXHSUM, directory manifests, integrity auditing, and orphaned hash purging.
  - `webserver`: Zero-dependency static HTTP/HTTPS file server built on `.NET HttpListener` with dark-mode directory browser, CORS headers, and self-signed SSL.
  - `pig-latin`: Bi-directional English <-> Pig Latin text translator supporting classic and hyphenated syntax, file processing, and clipboard synchronization.

---

## Directory Structure

```text
Code_Tool_FoolsTools/
├── INSTALL.cmd            # Registers 'cmd' and 'bin' directories in User PATH
├── UNINSTALL.cmd          # Removes 'cmd' and 'bin' directories from User PATH
├── README.md              # Project overview, usage, and command reference
├── cmd/                   # Public CLI endpoints intended for PATH
│   ├── 7z.cmd, zip.cmd... # Archival wrappers (7z, zip, gz, cb7, cbr, cbz)
│   ├── appx.cmd           # Universal Windows Platform (UWP) package manager
│   ├── clean-up.cmd       # Disk clean-up, temp pruning & cache maintenance
│   ├── clear.cmd          # Fast terminal clear alias (CLS)
│   ├── dism-pkg.cmd       # Windows DISM servicing package & WinSxS manager
│   ├── extract-icon.cmd   # Windows PE icon and bitmap extraction utility
│   ├── file-to-folder.cmd # Automatic file-to-directory organizer (Move/Copy/Filter)
│   ├── gif.cmd            # Lossless GIF optimization & format converter
│   ├── hash.cmd           # Fast table-based hashing & manifest auditing
│   ├── pig-latin.cmd      # Bi-directional English <-> Pig Latin translator
│   ├── reg-tweaks.cmd     # Windows system registry tweaks & shell extension manager
│   ├── show-ip.cmd        # Dual-stack internal & external IP discovery
│   ├── sudo.cmd           # UAC administrator elevation forwarder
│   ├── sys-info.cmd       # Screenfetch / Archey hardware spec utility
│   ├── video.cmd          # Unified FFmpeg media converter & extraction suite
│   ├── webserver.cmd      # Zero-dependency local HTTP/HTTPS file server
│   └── webp.cmd           # Lossless WebP converter & compression utility
├── bin/                   # Standalone 32-bit and 64-bit portable executables
│   ├── 7za.exe, 7za64.exe # Standalone 7-Zip archivers
│   ├── gifsicle.exe, etc. # GIF optimization binaries (32-bit & 64-bit)
│   ├── nircmd.exe, etc.   # Windows shell automation utilities
│   ├── xxhsum64.exe       # Fast 64-bit xxHash checksum utility
│   └── webp, webp64       # Standalone WebP toolchains
├── lib/
│   ├── bat/               # Reusable core Batch library routines (get*, is*, archive)
│   ├── ps1/               # High-performance PowerShell engines & manifests
│   └── tests/             # Automated test suite (21 test suites, 100% pass)
└── docs/                  # Documentation, references, and third-party licenses
```

---

## Installation & Setup

1. **Clone or Download the Repository**:
   ```cmd
   git clone https://github.com/Fooly-Cooly/Fools-Tools.git
   ```

2. **Add to PATH**:
   Run `INSTALL.cmd` from the project root. This registers both `cmd\` and `bin\` into your user environment `PATH`.

3. **Verify Installation**:
   Open a new Command Prompt or PowerShell terminal and run:
   ```cmd
   show-ip
   ```

4. **Uninstalling**:
   Run `UNINSTALL.cmd` to safely remove the registered `PATH` entries.

---

## Command Reference (`cmd/`)

All tools support `-?`, `/h`, or `--help` for syntax instructions, integrate automatic double-click pause detection when launched from File Explorer, and adhere to standard exit codes.

### Archival Commands

| Command | Description | Syntax Example |
| :--- | :--- | :--- |
| `7z` | 7z archive creation, extraction, and conversion | `7z archive.7z /AA` |
| `zip` | ZIP archive management | `zip files.zip /AA` |
| `cb7` / `cbr` / `cbz` | Comic book archive creation and conversion | `cbz comic.cbz /AC` |
| `gz` | Gzip stream compression | `gz file.tar.gz /AS` |

*Archival Flags*: `/[FileFlag][ActionFlag][ProfileFlag]`
- **File Flags**: `A` (All in folder), `F` (Individual folders), `I` (Individual files), `S` (Single target).
- **Action Flags**: `A` (Archive), `C` (Convert), `E` (Extract), `S` (Self-extracting SFX).
- **Profile Flags**: `A` (Archival / maximum), `C` (Comic optimized), `S` (Store).

### Media & Imaging

| Command | Description | Common Usage |
| :--- | :--- | :--- |
| `video` | Unified media tool for MP3 audio extraction, frame dumps, GIF conversion, and video muting | `video input.mp4 -mp3`<br>`video input.mp4 -thumb`<br>`video input.mp4 -gif`<br>`video input.mp4 -frames` |
| `gif` | Lossless GIF optimization, video conversion (MP4/WebM), APNG creation, and frame extraction | `gif animation.gif -optimize`<br>`gif animation.gif -mp4`<br>`gif animation.gif -apng`<br>`gif animation.gif -frames` |
| `webp` | Multi-threaded lossless WebP converter for BMP, GIF, and PNG images | `webp image.png`<br>`webp -r photo.png`<br>`webp /A`<br>`webp /R -r` |
| `extract-icon` | Extracts high-resolution `.ico` and `.png` icons and bitmaps from PE binaries | `extract-icon app.exe out_dir`<br>`extract-icon app.exe out_dir -Format Both -SplitSizes` |

### System Administration & Tweaks

| Command | Description | Common Usage |
| :--- | :--- | :--- |
| `appx` | Pure terminal manager for UWP and AppX packages with range removal and de-provisioning | `appx`<br>`appx -List`<br>`appx -Remove "*Xbox*"`<br>`appx -Remove "*Zune*" -AllUsers` |
| `dism-pkg` | Servicing package inspector, superseded update pruner, and WinSxS component cleaner | `dism-pkg`<br>`dism-pkg -List`<br>`dism-pkg -Analyze`<br>`dism-pkg -Clean -ResetBase` |
| `reg-tweaks` | Windows registry tweaks, shell context menus, and privacy settings manager | `reg-tweaks`<br>`reg-tweaks -List`<br>`reg-tweaks -Apply Disable_Cortana`<br>`reg-tweaks -RestartExplorer` |
| `clean-up` | Prunes user and system temporary files, empty directories, and resets thumbnail/icon caches | `clean-up`<br>`clean-up /T`<br>`clean-up /I`<br>`clean-up /C "D:\Media"`<br>`clean-up /A` |
| `show-ip` | Resolves local gateway adapter IP, subnet, MAC, and public WAN IP addresses | `show-ip`<br>`show-ip -4`<br>`show-ip -Json`<br>`show-ip -Raw` |
| `sys-info` | Queries CPU, GPU, RAM, disk, and motherboard specs with colorized ASCII logo | `sys-info`<br>`sys-info -NoColor` |
| `sudo` | Spawns commands, batch files, or executables in an elevated Administrator shell | `sudo regedit.exe` |
| `clear` | Fast terminal screen clear alias | `clear` |

### File & Text Utilities

| Command | Description | Common Usage |
| :--- | :--- | :--- |
| `file-to-folder` | Sorts loose files into folders named after their basenames | `file-to-folder "movie.mkv"`<br>`file-to-folder -a`<br>`file-to-folder -ext png -a`<br>`file-to-folder -s -a` |
| `hash` | In-memory compiled C# streaming hash engine supporting CRC32, MD5, SHA1-512, XXHSUM, manifests, and sync | `hash file.iso`<br>`hash MD5 file.iso -a`<br>`hash CRC32 *.zip -s`<br>`hash /A -s`<br>`hash /SYNC /PURGE` |
| `webserver` | Zero-dependency local static HTTP/HTTPS file server with dark-mode browser | `webserver`<br>`webserver 9000`<br>`webserver 8080 "C:\MySite" -Cors`<br>`webserver -Https` |
| `pig-latin` | Bi-directional English <-> Pig Latin text translator with hyphenated/classic syntax | `pig-latin "Hello world"`<br>`pig-latin "Hello world" -hyphen`<br>`pig-latin notes.txt -hyphen -o output.txt`<br>`pig-latin "Secret" -clip` |

---

## Core Batch Library (`lib/bat/`)

Reusable subroutines designed to be `CALL`ed from other scripts with standardized return mechanisms:

| Script | Contract | Purpose | Syntax |
| :--- | :--- | :--- | :--- |
| `archive.cmd` | Runner | Unified compression and extraction core | `archive.cmd Ext [Target] /Flag` |
| `getArch.cmd` | Getter | Resolves CPU architecture (`64` or empty for 32-bit) | `getArch.cmd OutputVar` |
| `getArgCount.cmd` | Getter | Counts arguments passed to a routine | `getArgCount.cmd OutputVar [args...]` |
| `getCFGVal.cmd` | Getter | Parses INI/CFG key-value pairs | `getCFGVal.cmd OutputVar File Section Key` |
| `getFileCount.cmd` | Getter | Counts non-hidden files in a directory | `getFileCount.cmd OutputVar Folder` |
| `getFileSize.cmd` | Getter | Reads file size in bytes | `getFileSize.cmd OutputVar File` |
| `getIP.cmd` | Getter | Retrieves internal or external IP address | `getIP.cmd [OutputVar] [Type]` |
| `getOSVer.cmd` | Getter | Retrieves Windows NT kernel version (e.g. `10.0`) | `getOSVer.cmd OutputVar` |
| `getRegVal.cmd` | Getter | Reads registry value into variable | `getRegVal.cmd OutputVar Key [Val]` |
| `getShortcut.cmd` | Getter | Resolves target path of a `.lnk` shortcut | `getShortcut.cmd OutputVar Path` |
| `getSID.cmd` | Getter | Retrieves Windows Security Identifier (SID) | `getSID.cmd OutputVar [User]` |
| `isAdmin.cmd` | Checker | Tests admin rights (0 = admin, 1 = standard, 2 = error) | `isAdmin.cmd` |
| `isDoubleClick.cmd` | Checker | Detects Explorer double-click (0 = double-click, 1 = terminal) | `isDoubleClick.cmd [ScriptName]` |
| `isFile.cmd` | Checker | Tests if target is a file (0 = file, 1 = folder, 2 = error) | `isFile.cmd Path` |
| `isFolder.cmd` | Checker | Tests if target is a folder (0 = folder, 1 = file, 2 = error) | `isFolder.cmd Path` |

---

## Automated Test Suite (`lib/tests/`)

FoolsTools includes 21 automated regression test suites providing 100% test coverage across all library routines and major CLI wrappers.

### Running Tests
- **Interactive Inspection**: Double-click any test script in `lib/tests/` (e.g. `test-reg-tweaks.cmd`). The script automatically pauses on exit for review.
- **CLI Runner**: Run directly in Command Prompt or PowerShell:
  ```cmd
  lib\tests\test-reg-tweaks.cmd
  ```
- **Execute All Suites**:
  ```powershell
  Get-ChildItem lib\tests\test-*.cmd | ForEach-Object { cmd /c "<nul call `"$($_.FullName)`"" }
  ```

---

## License

This project is licensed under the **GNU General Public License v3.0**.

> [!NOTE]
> The project license applies to creations within this project that include the copyright notice:  
> `Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly`
>
> Third-party binaries bundled within `bin/` retain their respective author licenses, detailed under [`docs/`](docs/).
