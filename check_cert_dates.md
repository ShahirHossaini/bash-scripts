#manual: ./check_cert_dates.sh <path>

#!/bin/bash

# Define colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

# Check if openssl is installed
if ! command -v openssl &> /dev/null; then
  echo -e "${RED}Error: openssl is not installed. Please install it and try again.${RESET}"
  exit 1
fi

# Function to check certificate dates
check_certificate_dates() {
  local cert_file=$1

  if [[ ! -f "$cert_file" ]]; then
    echo -e "${RED}Error: Certificate file ${cert_file} not found.${RESET}"
    return 1
  fi

  echo -e "${YELLOW}Checking certificate: ${cert_file}${RESET}"

  # Extract dates
  not_before=$(openssl x509 -in "$cert_file" -noout -dates | grep "notBefore=" | sed 's/notBefore=//')
  not_after=$(openssl x509 -in "$cert_file" -noout -dates | grep "notAfter=" | sed 's/notAfter=//')

  if [[ -z "$not_before" || -z "$not_after" ]]; then
    echo -e "${RED}Error: Unable to retrieve certificate dates.${RESET}"
    return 1
  fi

  # Display results
  echo -e "${GREEN}Valid From:${RESET} $not_before"
  echo -e "${GREEN}Valid Until:${RESET} $not_after"

  # Check expiration status
  expiration_date=$(date -d "$not_after" +%s)
  current_date=$(date +%s)
  days_left=$(( (expiration_date - current_date) / 86400 ))

  if (( days_left > 0 )); then
    echo -e "${GREEN}Days Remaining:${RESET} ${days_left} days"
  else
    echo -e "${RED}Certificate has expired!${RESET}"
  fi

  return 0
}

# Main script
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <certificate-file>${RESET}"
  exit 1
fi

cert_file=$1
check_certificate_dates "$cert_file"

