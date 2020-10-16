#############################################
$regPath = "HKLM:\Software\policies\Microsoft\Windows NT\DNSClient"
$regProperty = "EnableMulticast"
$desiredValue = '1'
#############################################
# Compare current with desired and exit accordingly.
# 1 for Compliant, 0 for Non-Compliant
try {
  # Retrieve current value for comparison
  $currentValue = (Get-ItemProperty -Path $regPath -Name $regProperty -ErrorAction Stop).$regProperty
}
catch [Exception]{
  write-output "$_.Exception.Message"
  exit 1
}
if ($currentValue -eq $desiredValue) {
  # already disabled
  exit 0
} else {
  # not disabled
  exit 1
}
