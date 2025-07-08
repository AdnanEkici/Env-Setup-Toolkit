#!/bin/bash

# Define colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
ORANGE='\033[38;5;214m'
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


summarize_script() {
    # ------------------------------------------------------------------------------
    # Function: summarize_script
    # Description:
    #   Displays an overview of the script's purpose, actions, and dependencies.
    #   It also prompts the user for confirmation before proceeding with the 
    #   Docker installation.
    #
    # Actions:
    #   1. Removes conflicting Docker-related packages.
    #   2. Sets up the Docker repository and installs Docker components.
    #   3. Adds the current user to the Docker group.
    #   4. Tests the Docker installation.
    #   5. Suggests a system reboot to apply group changes.
    #
    # Dependencies:
    #   - curl
    #   - build-essential
    #   - Ubuntu (or a compatible Linux distribution)
    #
    # User Input:
    #   Prompts the user to confirm whether they want to proceed with installation.
    #
    # Exit Code:
    #   Exits with status 0 if the user declines the installation.
    # ------------------------------------------------------------------------------
    print_message "${BLUE}This script will install Docker and set up the required Docker groups on your system."
    print_message "${YELLOW}It will perform the following actions:"
    echo "1. Remove conflicting Docker-related packages"
    echo "2. Set up Docker repository and install Docker components"
    echo "3. Add your user to the Docker group"
    echo "4. Test the Docker installation"
    echo "5. Optionally reboot your system to apply group changes"

    print_message "${YELLOW}This script requires the following dependencies:"
    echo "1. curl"
    echo "2. build-essential"
    echo "3. Ubuntu"

    print_message "${CYAN}Do you want to proceed with the installation? (y/n): "
    read -p "" choice
    if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
        print_message "${RED}Operation canceled."
        exit 0
    fi
}

print_error() {
    # ------------------------------------------------------------------------------
    # Function: print_error
    # Description: 
    #   Displays an error message in red and prompts the user to press a key 
    #   before exiting the script with an error status.
    #
    # Parameters:
    #   $1 - The error message to be displayed.
    #
    # Usage:
    #   print_error "An error occurred while installing Docker."
    #
    # Exit Code:
    #   Exits with status code 1 after displaying the message.
    # ------------------------------------------------------------------------------
    local error_message="$1"
    
    if [ -n "$error_message" ]; then
        print_message "${RED}$error_message"
    fi

    print_message "${ORANGE}Press a key to exit...$"
    read dummy_var
    exit 1
}

remove_conflicting_packages() {
    # ------------------------------------------------------------------------------
    # Function: remove_conflicting_packages
    # Description:
    #   Removes any conflicting Docker-related packages that might interfere with 
    #   the installation of Docker. The user is prompted for confirmation before 
    #   proceeding with the removal.
    #
    # Actions:
    #   - Prompts the user to confirm the removal.
    #   - Iterates through a predefined list of conflicting packages and removes them.
    #
    # Packages Removed:
    #   - docker.io
    #   - docker-doc
    #   - docker-compose
    #   - docker-compose-v2
    #   - podman-docker
    #   - containerd
    #   - runc
    #
    # User Input:
    #   - 'Y' or 'y' to proceed with package removal.
    #   - Any other key to skip the removal process.
    #
    # Exit Code:
    #   - The function does not exit the script but skips package removal if declined.
    # ------------------------------------------------------------------------------
    print_message "${BLUE}Removing conflicting Docker-related packages..."

    print_message "${CYAN}Do you want to proceed? (y/n):: "
    read -p "" choice

    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
            sudo apt-get remove -y $pkg
        done
        print_message "${GREEN}Conflicting packages removed successfully."
    else
        print_message "${YELLOW}Operation skipped. No packages were removed."
    fi
}

setup_docker_repo() {
    # ------------------------------------------------------------------------------
    # Function: setup_docker_repo
    # Description:
    #   Sets up the Docker repository by updating package lists, installing
    #   necessary dependencies, and downloading the Docker GPG key.
    #
    # Actions:
    #   - Updates package lists.
    #   - Installs required dependencies (ca-certificates, curl).
    #   - Creates the keyrings directory if it doesn’t exist.
    #   - Downloads and verifies the Docker GPG key.
    #   - Sets correct permissions for the GPG key.
    #
    # Exit Code:
    #   Calls print_error and exits if the GPG key download fails.
    # ------------------------------------------------------------------------------
    print_message "${BLUE}Updating package lists..."
    sudo apt-get update
    print_message "${GREEN}Package lists updated successfully."

    print_message "${BLUE}Installing required dependencies..."
    sudo apt-get install -y ca-certificates curl
    print_message "${GREEN}Dependencies installed."

    print_message "${BLUE}Creating keyrings directory..."
    sudo install -m 0755 -d /etc/apt/keyrings
    print_message "${GREEN}Keyrings directory created."

    print_message "${BLUE}Downloading Docker GPG key..."
    if sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
        print_message "${GREEN}Docker GPG key downloaded successfully."
    else
        print_error "Failed to download Docker GPG key."
    fi

    print_message "${BLUE}Setting correct permissions for Docker GPG key..."
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    print_message "${GREEN}Permissions set successfully."

    print_message "${GREEN}Docker repository setup completed."
}

add_docker_repo() {
    # ------------------------------------------------------------------------------
    # Function: add_docker_repo
    # Description:
    #   Adds the official Docker repository to the system’s APT sources.
    #
    # Actions:
    #   - Adds the Docker repository URL with the correct architecture.
    #   - Updates package lists to recognize Docker packages.
    #
    # Exit Code:
    #   - Calls print_error and exits if package list update fails.
    # ------------------------------------------------------------------------------
    print_message "${BLUE}Adding Docker repository..."
    
    if echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
        print_message "${GREEN}Docker repository added successfully."
    else
        print_message "${RED}Failed to add Docker repository."
        exit 1
    fi

    print_message "${BLUE}Updating package lists..."
    if sudo apt-get update; then
        print_message "${GREEN}Package lists updated successfully."
    else
        print_error "Failed to update package lists."
    fi
}

install_docker() {
    # ------------------------------------------------------------------------------
    # Function: install_docker
    # Description:
    #   Installs Docker and its necessary components.
    #
    # Actions:
    #   - Installs Docker Engine, CLI, and additional plugins.
    #
    # Exit Code:
    #   - Calls print_error and exits if installation fails.
    # ------------------------------------------------------------------------------
    print_message "${YELLOW}Starting Docker installation..."

    if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        print_message "${GREEN}Docker and required components installed successfully."
    else
        print_error "Failed to install Docker and components."
    fi
}

add_user_to_docker_group() {
    # ------------------------------------------------------------------------------
    # Function: add_user_to_docker_group
    # Description:
    #   Adds the current user to the Docker group to allow non-root access.
    #
    # Actions:
    #   - Creates the Docker group if it does not exist.
    #   - Adds the user to the Docker group.
    #   - Activates new group membership for the current session.
    #
    # Exit Code:
    #   - Prints an error message if adding the user to the group fails.
    # ------------------------------------------------------------------------------
    print_message "${BLUE}Adding user to Docker group..."

    if sudo groupadd docker; then
        print_message "${GREEN}Docker group created (if it didn't exist)."
    else
        print_message "${YELLOW}Docker group already exists."
    fi


    if sudo usermod -aG docker "$USER"; then
        print_message "${GREEN}User added to the Docker group successfully."
    else
        print_message "${RED}Failed to add user to Docker group."
    fi

    newgrp docker <<EOF
        if [ \$? -eq 0 ]; then
            echo -e "${GREEN}Group membership activated for the current session."
        else
            echo -e "${RED}Failed to activate new group membership."
        fi
EOF
}

test_docker_installation() {
    # ------------------------------------------------------------------------------
    # Function: test_docker_installation
    # Description:
    #   Runs a test container to verify that Docker is installed and working.
    #
    # Actions:
    #   - Runs the official "hello-world" Docker container.
    #
    # Exit Code:
    #   - Calls print_error and exits if Docker is not working.
    # ------------------------------------------------------------------------------
    print_message "${BLUE}Testing Docker installation..."

    if docker run hello-world; then
        print_message "${GREEN}Docker is working correctly!"
    else
        print_error "Docker is not working correctly. Please check your installation."
    fi
}

ask_reboot() {
    # ------------------------------------------------------------------------------
    # Function: ask_reboot
    # Description:
    #   Prompts the user to reboot the system to apply group membership changes.
    #
    # Actions:
    #   - Asks the user if they want to reboot.
    #   - If the user agrees, reboots the system.
    #   - If declined, reminds the user to reboot manually later.
    #
    # Exit Code:
    #   - If the user chooses to reboot, the system restarts.
    # ------------------------------------------------------------------------------
    print_message "${YELLOW}Do you want to reboot now to apply the group changes? (y/n)"
    read -p "" choice

    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
        print_message "${PURPLE}Rebooting the system...${RESET}"
        sudo reboot
    else
        print_message "${GREEN}Please reboot the system later for the changes to take effect."
    fi
}

main() {
    # ------------------------------------------------------------------------------
    # Function: main
    # Description:
    #   The main function that runs the script in order.
    # ------------------------------------------------------------------------------
    summarize_script
    remove_conflicting_packages
    setup_docker_repo
    add_docker_repo
    install_docker
    add_user_to_docker_group
    test_docker_installation
    ask_reboot
}

main
