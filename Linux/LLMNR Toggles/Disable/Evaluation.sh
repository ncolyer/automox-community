#!/bin/bash

# LLMNR - Evaluation : This will check whether LLMNR has been disabled.
test_val='^LLMNR=no'
test_cfg='/etc/systemd/resolved.conf'

# Case-insensitvely check for value
if ($(grep -qi "$test_val" $test_cfg)); then
  # Compliant
  exit 0
else
  # Non-Compliant
  exit 1
fi