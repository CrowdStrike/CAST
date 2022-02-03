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
    $ExpectedHash = "4c9f7c2adbea3d84bac8f8c0ff0ae8418a2e477b6f5abef6b813a4ea40e98433"

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
    } elseif ($LocalSha256 -ne $ExpectedHash) {
        throw "Checksum mismatch."
    }
    # Check installed app and running process directories
    [array] $Directories = ('Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*').foreach{
        (Get-ItemProperty -Path "Registry::\HKEY_LOCAL_MACHINE\$_" | Where-Object InstallLocation).InstallLocation
        foreach ($UserSid in (Get-WmiObject Win32_UserProfile | Where-Object { $_.SID -like 'S-1-5-21-*' }).SID) {
            (Get-ItemProperty -Path "Registry::\HKEY_USERS\$UserSid\$_" | Where-Object InstallLocation).InstallLocation
        }
    }
    $Directories += (Get-Process | Where-Object { $_.Path }).Path | Split-Path
    $Directories = $Directories | Sort-Object -Unique | Where-Object { Test-Path $_ -EA SilentlyContinue }
    
    Write-Output "`nSearching $(($Directories | Measure-Object).Count) directories..."
    for ($i = 0; $i -lt ($Directories | Measure-Object).Count; $i += 20) {
        [string] $Group = ($Directories[$i..($i + 19)] | Where-Object { -not [string]::IsNullOrEmpty($_) } |
            ForEach-Object { ,"'$($_.TrimEnd('\'))'" }) -join ' '
        if ($Group) {
            Invoke-Expression "& '$castPath' scan $Group" | ForEach-Object {
                $_ | Out-File -Append -FilePath $OutputPath -Encoding ASCII
                if ($_ -match $JavaClassFilter) {
                    Write-Output $_
                }
            }
        }
    }
} catch {
    Write-Error "$($_.Exception.Message)"
    exit -1
} finally {
    if (Test-Path $OutputPath) {
        Write-Output "`nIdentified potentially vulnerable JAR file(s)!"
        Write-Output "`nResults of scan available in $OutputPath"
    }
    if (Test-Path $castPath) {
        try {
            Remove-Item $castPath
            Write-Output "`nSuccessfully removed $castPath"
        } catch {
            Write-Output "`nPotentially unable to remove $castPath"
        }
    }
}
