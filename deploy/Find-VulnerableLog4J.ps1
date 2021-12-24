<#
.SYNOPSIS
Look for vulnerable Log4J class files from directories of running processes and installed software

.DESCRIPTION
This script is intended to be used with CAST (CrowdStrike Archive Scanning Tool) to:
 - Identify likely locations where Java archives vulnerable to CVE-2021-44228 based on:
   - Directories of running processes
   - Software installation directories
 - Enumerate JAR/WAR files contained in the locations identified above
 - Execute CAST against the combined list of files
 - Send JSON objects for known vulnerable class files of interest to standard out 
 - Capture the full output of CAST to a temporary file for collection post-execution
 - Delete the CAST binary from disk if present to clean up after scanning

.OUTPUTS
This script will capture the results from CAST in the file "cast_results.json" in the temporary directory specified by the variable $TempDirectoryPath.
    
.NOTES
File Name  : Find-VulnerableLog4J.ps1
Contact    : CrowdStrike Professional Services

Copyright (c) 2021 CrowdStrike Services
#>

# Update $TempDirectoryPath to the location on disk where "cast.exe" will be uploaded
$TempDirectoryPath = ""

# These are class names that are of particular interest as they can be leveraged for Remote Code Execution (RCE)
$JavaClassFilter = "(JmsAppender|JndiManager|NetUtils)"

try {
    
    $castPath = Join-Path $TempDirectoryPath "cast.exe"
    $OutputPath = Join-Path $TempDirectoryPath "cast_results.json"
    $ExpectedHash = "86FE23EAF103F69DA6D81ED95CF2418185DC879B00D8D22156B1496E4DD0FEFA"
    $Filter = '\.(jar|war)$'

    if ((Test-Path -Path $castPath) -eq $false) {
        # Check that cast.exe is present in same directory as script
        throw "cast.exe not found. Please ensure that this file is located in the same directory as the script."
    }
    # Verify hash of cast.exe
    $LocalSha256 = ([System.BitConverter]::ToString(
        (New-Object System.Security.Cryptography.SHA256CryptoServiceProvider).ComputeHash(
        [System.IO.File]::ReadAllBytes($castPath)))).Replace("-", "")
    if (-not($LocalSha256)) {
        throw "Failed to calculate SHA256 hash."
    }
    elseif ($LocalSha256 -ne $ExpectedHash) {
        throw "Checksum mismatch."
    }
    [array] $Directories = try {
        # Check installed app and running process directories
        (Get-CimInstance -ClassName Win32_Product -Filter "InstallLocation like '%'").InstallLocation
        (Get-CimInstance -ClassName Win32_Process -ErrorAction Stop -Filter "ExecutablePath like '%'" |
            Where-Object { $_.ProcessId -ne 0 -and $_.ProcessId -ne 4 }).ExecutablePath | Split-Path
    }
    catch {
        (Get-WmiObject -Class Win32_Product -Filter "InstallLocation like '%'").InstallLocation
        (Get-WmiObject -Class Win32_Process -ErrorAction Stop -Filter "ExecutablePath like '%'"  |
            Where-Object { $_.ProcessId -ne 0 -and $_.ProcessId -ne 4 }).ExecutablePath | Split-Path
    }
    # Combine our list of directories into a unique list for searching
    [array] $Directories = ($Directories | ForEach-Object {$_.Replace("\\?\","")}) | Sort-Object -Unique
    Write-Output "`nSearching $(($Directories | Measure-Object).Count) directories for files matching '$Filter'..."

    [array] $Files = try {
         @($Directories).foreach{
            # Collect matching file paths inside directories
            (Get-ChildItem -LiteralPath $_ -Force -ErrorAction SilentlyContinue -Recurse |
                Where-Object { $_.Name -match $Filter }).FullName
        }
    }
    catch {
        $Directories | ForEach-Object {
            # Collect matching file paths inside directories
            (Get-ChildItem -LiteralPath $_ -Force -ErrorAction SilentlyContinue -Recurse | 
                Where-Object { $_.Name -match $Filter }).FullName }
    }
    [array] $Files = $Files | Sort-Object -Unique
    Write-Output "`nIdentified $(($Files | Measure-Object).Count) files to scan."
    [array] $ScanGroups = for ($i = 0; $i -lt ($Files | Measure-Object).Count; $i += 20) {
        ($Files[$i..($i + 19)] | ForEach-Object {
            "'$_'"
        }) -join ' '
    }
    $ScanGroups | ForEach-Object {
        Invoke-Expression "& '$castPath' scan $_" | ForEach-Object {
            if (-not [string]::IsNullOrEmpty($_)) {
                $_ | Out-File -Append -FilePath $OutputPath -Encoding ASCII
            }
            if ($_ -match $JavaClassFilter) {
                Write-Output $_
            }
        }
    }
}
catch {
    Write-Error "$($_.Exception.Message)"
    exit -1
}

finally {
    if (Test-Path $OutputPath) {
        Write-Output "`nIdentified potentially vulnerable JAR file(s)!"
        Write-Output "`nResults of scan available in $OutputPath"
    }
    if (Test-Path $castPath) {
        try {
            Remove-Item $castPath
            Write-Output "`nSuccessfully removed $castPath"
        }
        catch {
            Write-Output "`nPotentially unable to remove $castPath"
        }
    }
}
