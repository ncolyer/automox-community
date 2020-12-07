<#
#-------------------------------------------------------------[License]------------------------------------------------------------

MIT License

Copyright (c) 2020 Nicholas Colyer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

* The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#-----------------------------------------------------------[Description]----------------------------------------------------------

.SYNOPSIS
Java SE Runtime Environment 8 Update (271) Script (Java-SE-8-Patch-Script_Update-271)

.DESCRIPTION
This script will update the java version installed with the patch manually uploaded to the Automox Console.
Defaults are set but parameter override is available if custom-paramters are required.

.OUTPUTS
  Exit 0
  Exit 1 && Exception (Message)

.NOTES
  Version:        1.0
  Creation Date:  12/04/2020
  Author:         Nicholas Colyer
  Purpose/Change: Initial script development
  Email:          nicholas.colyer@automox.com, contact@nicholascolyer.com
  Url:            https://github.com/ncolyer/automox-community

.METADATA
  Platform:       Microsoft Windows
  Release:        10
  Build:          >=1507
  Tags:           Java 8, Build 271 Update, Powershell

.EXAMPLE
  ./Java-SE-8-Patch-Script_Update-271.ps1

#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------
#region parameters

Param (

  [string]$compliantPatchFile    = "jre-8u271-windows-i586.exe",
  [string]$compliantProductValue = "Java 8 Update 271",
  [string]$productFilter         = 'Java [0-9] Update(.*)',
  [string]$compliantTestCmd      = "java -version",
  [string]$compliantTestCmdValue = "build 1.8.0_271",
  [string]$pathFilter            = "%java%"  

)

#endregion
#-----------------------------------------------------------[Functions]------------------------------------------------------------
#region functions

Function Get-InstalledSoftware {
  <#

  .SYNOPSIS 
  Displays all software listed in the registry on a given computer.

  .DESCRIPTION
  Uses the SOFTWARE registry keys (both 32 and 64bit) to list the name, version, vendor, and uninstall string for each software entry on a given computer.

  .PARAMETER ComputerName
  [String] A string input representing the target device computer name

  .EXAMPLE
  C:\PS> Get-InstalledSoftware -ComputerName SERVER1
  This shows the software installed on SERVER1. 

  .NOTES
  This function is courtesy of stackoverflow community as a superior alternative to WMI/Win32_Product

  .LINKS
  https://stackoverflow.com/questions/25268491/alternative-to-win32-product 

  #>

  Param (
  
    [Parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)][string[]]$ComputerName
  
  )

  Process {
    foreach ($Computer in $ComputerName)
    {
      #Open Remote Base
      $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer)

      #Check if it's got 64bit regkeys
      $keyRootSoftware = $reg.OpenSubKey("SOFTWARE")
      [bool]$is64 = ($keyRootSoftware.GetSubKeyNames() | ? {$_ -eq 'WOW6432Node'} | Measure-Object).Count
      $keyRootSoftware.Close()

      #Get all of they keys into a list
      $softwareKeys = @()
      if ($is64){
        $pathUninstall64 = "SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
        $keyUninstall64 = $reg.OpenSubKey($pathUninstall64)
        $keyUninstall64.GetSubKeyNames() | % {
          $softwareKeys += $pathUninstall64 + "\\" + $_
        }
        $keyUninstall64.Close()
      }
      
      $pathUninstall32 = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
      $keyUninstall32 = $reg.OpenSubKey($pathUninstall32)
      $keyUninstall32.GetSubKeyNames() | % {
        $softwareKeys += $pathUninstall32 + "\\" + $_
      }
      
      $keyUninstall32.Close()

      #Get information from all the keys
      $softwareKeys | % {
        $subkey=$reg.OpenSubKey($_)
          if ($subkey.GetValue("DisplayName")){
            $installDate = $null
              if ($subkey.GetValue("InstallDate") -match "/"){
                $installDate = Get-Date $subkey.GetValue("InstallDate")
              }
              elseif ($subkey.GetValue("InstallDate").length -eq 8){
                  $installDate = Get-Date $subkey.GetValue("InstallDate").Insert(6,".").Insert(4,".")
              }
              New-Object PSObject -Property @{
                ComputerName = $Computer
                Name = $subkey.GetValue("DisplayName")
                Version = $subKey.GetValue("DisplayVersion")
                Vendor = $subkey.GetValue("Publisher")
                UninstallString = $subkey.GetValue("UninstallString")
                InstallDate = $installDate
              }
          }

          $subkey.Close()
      }
      $reg.Close()
    }
  }
}


function Get-CompliantStatus {
  <#

  .SYNOPSIS
  Get-CompliantStatus of device

  .DESCRIPTION
  Determines device compliance by checking registry and commandline for correct version information.
  Both CLI and registry target values are required to return true matches for a compliant result.

  .PARAMETER productFilter
    [String] Qualifying Product Candidate Filter (RegEx)
      
  .PARAMETER compliantProductValue
    [String] Compliant Product Version Value (Exact Match)

  .PARAMETER compliantTestCmd
    [String] Commandline Syntax for Enumerating Version Value

  .PARAMETER compliantTestCmdValue
    [String] Commandline Complaint Version Value Result

  #>

  Param (
    
    [Parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)][string[]]$productFilter,        
    [Parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)][string[]]$compliantProductValue,
    [Parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)][string[]]$compliantTestCmd,
    [Parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)][string[]]$compliantTestCmdValue

    )

  $installedSoftware = Get-InstalledSoftware $env:COMPUTERNAME

  # Any Java Version Installed?
  If ($installedSoftware | Select-String -Pattern $productFilter){

    # Patch Compliant
    If ($installedSoftware | Select-String -Pattern $compliantProductValue){

      $compliantInstallPkgMgr = $true

    }

  } else {

    Write-Output "No candidate Java installed."
    exit 0

  }

  # Commandline Compliant
  If(([string](& cmd /c $compliantTestCmd 2>&1)) -match $compliantTestCmdValue){

    $compliantInstallCli = $true

  }

  if($compliantInstallCli -and $compliantInstallPkgMgr){

    return $true

  }

  return $false

}


function Start-Install {
  <#

    .SYNOPSIS
    Start-Install of compliant patch

    .DESCRIPTION
    Start-Install will install the compliant patch file supplied on the device

    .PARAMETER compliantPatchFile
    [String] Compliant Product Version Patchfile - Uploaded to Automox Console

  #>

  Param (
    
    [Parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)][string[]]$compliantPatchFile
        
  )

  if(Start-Process -FilePath ".\$compliantPatchFile" "/s" -Wait){

    Remove-Item -Path ".\$compliantPatchFile" -Force -ErrorAction SilentlyContinue

  }

}


function Invoke-PatchNow ($compliantPatchFile, $pathFilter) {
  <#

    .SYNOPSIS
    Invoke-PatchNow evaluation logic

    .DESCRIPTION
    Invoke-PatchNow will evaluate device compliance and take required action

    .PARAMETER compliantPatchFile
    [String] Patch file uploaded to Automox console for candidate installation

    .PARAMETER pathFilter
    [String] Execution path filter for terminating and potential conflicting processes

  #>

  if ((Get-CompliantStatus $compliantProductValue $productFilter $compliantTestCmd $compliantTestCmdValue) -eq $false){

    # Terminate Any Potential File/Locking Processes
    (Get-WmiObject -Class win32_process -Filter "ExecutablePath like '%$pathFilter%'") | ForEach-Object {($_.terminate())}

    Start-Install $compliantPatchFile

    if ((Get-CompliantStatus $compliantProductValue $productFilter $compliantTestCmd $compliantTestCmdValue) -eq $false){
      Write-Output "Could not patch automatically. Please manually patch device."
      exit 1
    }

  }

  # Already Compliant
  exit 0

}

#endregion
#-----------------------------------------------------------[Execution]------------------------------------------------------------
#region execution

Try {

  Invoke-PatchNow

} Catch {

  Write-Output $_.Exception
  exit 1

}

#endregion
