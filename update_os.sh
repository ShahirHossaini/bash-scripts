#!/bin/bash

# Define colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or use sudo.${RESET}"
  exit 1
fi

echo -e "${GREEN}Starting the OS update process...${RESET}"

# Update package list
echo -e "${GREEN}Updating package list...${RESET}"
if apt update; then
  echo -e "${GREEN}Package list updated successfully.${RESET}"
else
  echo -e "${RED}Failed to update package list. Please check your network connection.${RESET}"
  exit 1
fi

# Upgrade installed packages
echo -e "${GREEN}Upgrading installed packages...${RESET}"
if apt upgrade -y; then
  echo -e "${GREEN}Packages upgraded successfully.${RESET}"
else
  echo -e "${RED}Failed to upgrade packages.${RESET}"
  exit 1
fi

# Full upgrade (optional, for Debian-based systems)
echo -e "${GREEN}Performing a full upgrade...${RESET}"
if apt full-upgrade -y; then
  echo -e "${GREEN}Full upgrade completed successfully.${RESET}"
else
  echo -e "${RED}Failed to perform a full upgrade.${RESET}"
  exit 1
fi

# Clean up unnecessary packages
echo -e "${GREEN}Cleaning up unnecessary packages...${RESET}"
if apt autoremove -y && apt clean; then
  echo -e "${GREEN}System cleanup completed successfully.${RESET}"
else
  echo -e "${RED}Failed to clean up the system.${RESET}"
  exit 1
fi

echo -e "${GREEN}OS update process completed!${RESET}"

