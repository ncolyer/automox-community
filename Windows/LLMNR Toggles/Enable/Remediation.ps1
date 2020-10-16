#############################################
$regPath = "HKLM:\SOFTWARE\policies\Microsoft\Windows NT\DNSClient"
$regProperty = "EnableMulticast"
$desiredValue = '1'
#############################################
try {
  If (-not(Test-Path $regPath)){
    New-Item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name $regProperty -Value $desiredValue -PropertyType DWORD -Force | Out-Null
  }
  Set-ItemProperty -Path $regPath -Name $regProperty -Value $desiredValue
  exit 0
}
catch [Exception]{
  write-output "$_.Exception.Message"
  exit 1
}
