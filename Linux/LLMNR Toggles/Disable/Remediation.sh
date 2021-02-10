#!/bin/bash

# LLMNR - Remediation : This will disable LLMNR. (restart required)
test_val='^LLMNR=no'
test_cfg='/etc/systemd/resolved.conf'

sed -i 's/.*LLMNR=.*/LLMNR=no/g' $test_cfg

# Case-insensitvely check for value
if ($(grep -qi "$test_val" $test_cfg)); then
  # Compliant
  exit 0
else
  # Non-Compliant
  echo "LLMNR could not be toggled off."
  exit 1
fi