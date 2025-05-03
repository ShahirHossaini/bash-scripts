#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to print messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1"
}

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

log_message "Starting ClamAV installation on Ubuntu..."

# Step 1: Update the package list
log_message "Updating package list..."
apt-get update -y

# Step 2: Install ClamAV and its daemon
log_message "Installing ClamAV and its daemon..."
apt-get install -y clamav clamav-daemon

# Step 3: Stop ClamAV services to update virus database
log_message "Stopping ClamAV services for database update..."
systemctl stop clamav-freshclam.service

# Step 4: Update ClamAV virus database
log_message "Updating ClamAV virus database. This may take a while..."
freshclam

# Step 5: Restart ClamAV services
log_message "Restarting ClamAV services..."
systemctl start clamav-freshclam.service
systemctl enable clamav-freshclam.service

# Step 6: Verify the installation
log_message "Verifying ClamAV installation..."
clamscan --version

log_message "ClamAV installation and setup completed successfully."

# Provide usage instructions
echo -e "\nUsage instructions:"
echo "1. To scan a directory: sudo clamscan -r /path/to/directory"
echo "2. To scan a file: sudo clamscan /path/to/file"
echo "3. Logs are stored in /var/log/clamav/"
echo "4. Update the virus database regularly using 'sudo freshclam'."

