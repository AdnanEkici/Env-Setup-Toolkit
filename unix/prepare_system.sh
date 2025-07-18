#!/bin/bash

# ------------------------------------------------------------------------------
# Script: prepare_system.sh
# Description:
#   This script installs essential development tools and dependencies on an
#   Ubuntu system. It ensures that the necessary packages are installed while
#   minimizing unnecessary recommendations.
# ------------------------------------------------------------------------------

# Define color codes
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
ORANGE='\033[38;5;214m'
CYAN='\033[36m'
RESET='\033[0m'


print_message() {
    # ------------------------------------------------------------------------------
    # Function: print_message
    # Description:
    #   Prints a formatted message with a specified color.
    # 
    # Parameters:
    #   $1 - Color code
    #   $2 - Message to print
    # ------------------------------------------------------------------------------
    echo "$1$2${RESET}"
}


show_summary() {
    # ------------------------------------------------------------------------------
    # Function: show_summary
    # Description:
    #   Displays an introduction message explaining what the script will do.
    # ------------------------------------------------------------------------------
    print_message "${BLUE}" "This script will install essential development tools and dependencies."
    print_message "${YELLOW}" "The following actions will be performed:"
    echo "1. Update package lists and upgrade the system"
    echo "2. Install required development tools and libraries"
    echo
    print_message "${ORANGE}" "The following packages will be installed:"
    echo "   - software-properties-common"
    echo "   - autotools-dev"
    echo "   - build-essential"
    echo "   - libssl-dev"
    echo "   - net-tools"
    echo "   - git"
    echo "   - openssh-server"
    echo "   - openssh-client"
    echo "   - nano"
    echo "   - wget"
    echo "   - qtbase5-dev"
    echo "   - gdb"
    echo "   - libgl1"
    echo "   - cmake"
    echo "   - htop"
    echo "   - code"
    echo "   - curl"
    echo "   - tmux"
    echo "   - install_oh_my_bash"
    echo

    # Ask for confirmation
    read -p "$(echo "${CYAN}Do you want to proceed? (y/n): ${RESET}")" choice
    if [ "$choice" = "n" ] || [ "$choice" = "n" ]; then
        print_message "${RED}" "Installation aborted."
        exit 1
    fi
}


update_system() {
    # ------------------------------------------------------------------------------
    # Function: update_system
    # Description:
    #   Updates the package list and upgrades installed packages.
    # ------------------------------------------------------------------------------
    print_message "${PURPLE}" "Updating package lists..."
    sudo apt-get update && print_message "${GREEN}" "Package lists updated successfully."

    print_message "${PURPLE}" "Upgrading installed packages..."
    sudo apt-get upgrade -y && print_message "${GREEN}" "System upgraded successfully."
}



install_packages() {
    # ------------------------------------------------------------------------------
    # Function: install_packages
    # Description:
    #   Installs necessary development tools and libraries using both 
    #   APT (for system packages) and Snap (for additional software like VS Code).
    #   Checks if a package is already installed before proceeding.
    # ------------------------------------------------------------------------------

    print_message "${BLUE}" "Installing essential development tools and libraries..."

    # ------------------------------------------------------------------------------
    # Install APT packages
    # ------------------------------------------------------------------------------
    while read -r pkg; do
        if dpkg -l | grep -qw "$pkg"; then
            print_message "${YELLOW}" "$pkg is already installed. Skipping..."
        else
            print_message "${CYAN}" "Installing: $pkg..."
            if sudo apt-get install -y --no-install-recommends "$pkg"; then
                print_message "${GREEN}" "$pkg installed successfully."
            else
                print_message "${RED}" "Failed to install $pkg."
            fi
        fi
    done <<EOF
software-properties-common
autotools-dev
build-essential
libssl-dev
net-tools
git
openssh-server
openssh-client
nano
wget
curl
qtbase5-dev
gdb
libgl1
cmake
tmux
htop
EOF

    # ------------------------------------------------------------------------------
    # Install Snap packages
    # ------------------------------------------------------------------------------
    print_message "${BLUE}" "Installing Snap packages..."

    while read -r snap_pkg; do
        if snap list | grep -qw "$snap_pkg"; then
            print_message "${YELLOW}" "$snap_pkg is already installed. Skipping..."
        else
            print_message "${CYAN}" "Installing: $snap_pkg..."
            if sudo snap install --classic "$snap_pkg"; then
                print_message "${GREEN}" "$snap_pkg installed successfully."
            else
                print_message "${RED}" "Failed to install $snap_pkg."
            fi
        fi
    done <<EOF
    code
EOF
}

install_oh_my_bash() {
    # ------------------------------------------------------------------------------
    # Function: install_oh_my_bash
    # Description:
    #   Installs Oh My Bash if it is not already installed.
    # ------------------------------------------------------------------------------

    if [ -d "$HOME/.oh-my-bash" ]; then
        print_message "${BLUE}" "Oh My Bash is already installed. Skipping..."
    else
        print_message "${CYAN}" "Installing Oh My Bash..."
        if bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"; then
            print_message "${GREEN}" "Oh My Bash installed successfully!"
        else
            print_message "${RED}" "Failed to install Oh My Bash."
        fi
    fi
}

main() {
    # ------------------------------------------------------------------------------
    # Function: main
    # Description:
    #   The main function that runs the script in order.
    # ------------------------------------------------------------------------------
    show_summary
    update_system
    install_packages
    install_oh_my_bash
    print_message "${GREEN}" "All essential software installed successfully!"
}

main
