#!/bin/bash

# Define logfile with a unique name
logfile="/tmp/clamav_$(hostname)_$(date "+%Y%m%d_%H%M%S_%Z").log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1"
}

# Write diagnostic information to the logfile
{
    log_message "Starting ClamAV diagnostics collection..."
    log_message "Hostname: $(hostname)"
    log_message "Date and Time: $(date)"
    
    log_message "Listing installed ClamAV packages..."
    dpkg-query --no-pager --list "clamav*" || log_message "Error: Failed to list ClamAV packages."
    
    log_message "Checking ClamAV daemon status..."
    sudo systemctl -l --no-pager status clamav-daemon || log_message "Error: ClamAV daemon status check failed."
    
    log_message "Displaying last 10 lines of ClamAV log..."
    sudo tail -n 10 /var/log/clamav/clamav.log || log_message "Error: Failed to read ClamAV log."
    
    log_message "Displaying last 30 lines of daily ClamAV scan log..."
    sudo tail -n 30 /var/log/clamav/daily_clamscan.log || log_message "Error: Failed to read daily ClamAV scan log."

    log_message "ClamAV diagnostics collection completed."
} | tee "$logfile"

# Print the log file location for reference
echo "Log file saved at: $logfile"

