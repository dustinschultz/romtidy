<#
Copyright 2021 Dustin Schultz
 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
    http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#                         ROM TIDY
#
# Tidies ROMs from packs (like no-intro) according to setup (see bottom of script)
#
# Author: Dustin Schultz
# Disclaimer: First time writing a Powershell script (figured I'd challenge myself)
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Creates a Filename to File hash
#
# key = Filename, value = FileObj
#
function Create-Name-FileObject-Hash {

    param(
        [Parameter(Mandatory=$true)]
        $Files
    )

    $FilesHash = @{}

    $Files | % { $FilesHash.Add($_.Name, $_) }

    return $FilesHash
}

# Remove BIOS
#
# Example
# - [BIOS] foo.zip
#
function Remove-Bios {
    param(
        [Parameter(Mandatory=$true)]
        $RomDir
    )

    Write-Host "Removing BIOS"
    Get-ChildItem $RomDir | Where{$_.Name -match "\[BIOS\]"} | ForEach-Object { Write-Host "Removing $_"; Remove-Item -LiteralPath $_.FullName -Force }
}

# Remove releases of a certain type (e.g. Beta)
#
# Example
# - Game (USA) (Proto).zip
# - Game (Europe) (Proto 1).zip
# - Game (USA) (Sample).zip
# - Game (Japan) (Beta).zip
#
function Remove-Type {
    param(
        [Parameter(Mandatory=$true)]
        $RomDir,
        [Parameter(Mandatory=$true)]
        $Type
    )

    Write-Host "Removing $Type releases"
    Get-ChildItem $RomDir | Where{$_.Name -match "\($([regex]::escape($Type))?\s?[0-9]*\)"} | ForEach-Object { Write-Host "Removing $_"; Remove-Item -LiteralPath $_.FullName -Force }
    Write-Host "---"
}

# Remove similar Region1 (e.g. USA) / Region2 (e.g. Europe) releases, keeping Region1
#
# Example:
# - Game (Europe).zip
# - Game (USA).zip
#
function Remove-Region-Similar {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir,
        [Parameter(Mandatory=$true)]
        $Region1,
        [Parameter(Mandatory=$true)]
        $Region2,
        [Parameter(Mandatory=$false)]
        $CompareRomanAndEnglishNumerals=$true
    )

    Write-Host "Removing Similar $Region1/$Region2 releases"

    $FilesBothRegions = Get-ChildItem $RomDir | Where{$_.Name -match "$([regex]::escape($Region1))|$([regex]::escape($Region2))"}

    if ($FilesBothRegions -eq $null) {
        $FilesBothRegions = @()
    }

    $AllFilesHash = Create-Name-FileObject-Hash -Files $FilesBothRegions

    $FilesToRemove = @()
    # $EnglishToRoman = @{ 1 = "I"; 2 = "II"; 3 = "III"; 4 = "IV"; 5 = "V"; 6 = "VI"; 7 = "VII"; 8 = "VIII"; 9 = "IX"; 10 = "X" }

    for ( $index = 0; $index -lt $FilesBothRegions.count; $index++) {
        if ($FilesBothRegions[$index].Name -match "$([regex]::escape($Region1))") {
            $FileOtherRegion = $FilesBothRegions[$index].Name -replace "$([regex]::escape($Region1))", "$Region2"

            if ($AllFilesHash.ContainsKey($FileOtherRegion)) {
                $FilesToRemove += $AllFilesHash[$FileOtherRegion]
            }

        }
    }

    $FilesToRemove | ForEach-Object { Write-Host "Removing $_"; Remove-Item -LiteralPath $_.FullName -Force }

    Write-Host "---"
}

#
# Unzips all files to the $RomDir using 7Zip
#
function Unzip-All {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir
    )

    Write-Host "Unzipping all files"

    $7z = "C:\Program Files\7-Zip\7z.exe"
    
    $7zipExists = Test-Path $7z

    if ($7zipExists -ne $true) {
        Write-Host "7zip not found at $7z. Unable to unzip. Install 7zip from https://www.7-zip.org/ and rerun."
        Exit
    }

    if ((Get-ChildItem $RomDir -Filter *.zip).count -gt 0) {
        & $7z e "$RomDir\*.zip" -o"$RomDir"
    }

    Write-Host "---"

}

#
# Removes all zip files from $RomDir
#
function Remove-All-Zip {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir
    )

    Write-Host "Removing all zip files"
    remove-item "$RomDir\*" -include *.zip
    Write-Host "---"
}

#
# Creates $Dir if it doesn't exist
#
function Create-Dir-If-Not-Exists {

    param(
        [Parameter(Mandatory=$true)]
        $Dir
    )

    if (!(Test-Path $Dir)) {
        Write-Host "Creating directory: $Dir"
        New-Item -ItemType Directory -Force -Path $Dir
        Write-Host "---"
    }
}

#
# Creates a directory, if it doesn't exist, for each character in [0-9A-Z]
#
function Create-Top-Level-Alphanumeric-Dirs {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir
    )

    Write-Host "Create top-level alphanumeric directories"

    # Numbers
    48..57 | % { Create-Dir-If-Not-Exists "$RomDir\$([char]$_)" }

    # Letters
    65..90 | % { Create-Dir-If-Not-Exists "$RomDir\$([char]$_)" }

    Write-Host "---"
}

#
# Moves all files starting with $StartsWith to $RomDir\$StartsWith
# 
function Move-Files-Starting-With-To-Dir {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir,
        [Parameter(Mandatory=$true)]
        $StartsWith
    )

    $FileFilter = "$StartsWith*"
    $DestDir = "$RomDir\$StartsWith"

    Get-ChildItem $RomDir -File -Filter $FileFilter | Move-Item -Destination $DestDir

}

#
# Organizes files by moving them into the directory that matches the first letter of the file
#
function Organize-Files {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir
    )

    Write-Host "Organizing files into alphanumeric directories"
    # Numbers
    48..57 | % { Move-Files-Starting-With-To-Dir $RomDir "$([char]$_)" }

    # Letters
    65..90 | % { Move-Files-Starting-With-To-Dir $RomDir "$([char]$_)" }
    Write-Host "---"

}

#
# Removes all directories with no files
#
function Remove-Empty-Dirs {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir
    )

    Write-Host "Removing all empty directories"
    Get-ChildItem $RomDir | Where-Object { (Get-ChildItem "$RomDir\$_").count -eq 0 } | Remove-Item
    Write-Host "---"
}

#
# Validates all folders in $RomDir and warns if the number of files is greater than $Count
#
function Validate-And-Warn-Too-Many-Files {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir,
        [Parameter(Mandatory=$true)]
        $Count
    )

    Write-Host "Inspect the following directories as they are over the $Count per folder limit:"
    Get-ChildItem $RomDir | Where-Object { (Get-ChildItem "$RomDir\$_").count -ge $Count } | Write-Host
    Write-Host "---"
}

function main {

    param(
        [Parameter(Mandatory=$true)]
        $RomDir
    )

    # Remove all BIOS files
    Remove-Bios -RomDir $RomDir

    # Remove certain types of files (e.g. beta releases)
    Remove-Type -RomDir $RomDir -Type "Proto"
    Remove-Type -RomDir $RomDir -Type "Beta"
    Remove-Type -RomDir $RomDir -Type "Sample"
    Remove-Type -RomDir $RomDir -Type "Demo"
    Remove-Type -RomDir $RomDir -Type "Test"
    Remove-Type -RomDir $RomDir -Type "Unl"

    # Remove similar files that only differ by region"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Japan)"    
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Europe)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Germany)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(France)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Italy)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Australia)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Sweden)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Spain)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Japan, Europe)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Japan, Korea)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Asia, Korea)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Asia) (En)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Europe, Korea)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Japan) (En)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Europe) (En,Fr,De)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Europe) (En,Fr,De,Es,It)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Korea) (En,Ko)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA)" -Region2 "(Europe) (En,Fr,De,Es)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Europe)" -Region2 "(Japan)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Europe)" -Region2 "(Brazil)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Europe)" -Region2 "(Europe)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Europe)" -Region2 "(Japan, Korea)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Europe) (En,Fr,De,Es)" -Region2 "(Korea) (En,Fr,De,Es)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Europe) (En,Fr,De,Es)" -Region2 "(Japan) (En,Ja)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Korea)" -Region2 "(Europe)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(USA, Europe, Korea)" -Region2 "(Brazil)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Japan)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Germany)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Korea)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Spain)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Japan) (En)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Brazil)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(France)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Australia)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe)" -Region2 "(Japan, Korea)"
    Remove-Region-Similar -RomDir $RomDir -Region1 "(Europe) (En,Fr,De,Es,It)" -Region2 "(Brazil)"

    Unzip-All -RomDir $RomDir
    Remove-All-Zip -RomDir $RomDir

    Create-Top-Level-Alphanumeric-Dirs -RomDir $RomDir
    Organize-Files -RomDir $RomDir
    Remove-Empty-Dirs -RomDir $RomDir

    Validate-And-Warn-Too-Many-Files -RomDir $RomDir -Count 1024

}

# Run with dir
# main -RomDir "c:\tmp\NES"

# Prompt for dir
main