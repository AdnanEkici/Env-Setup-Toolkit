#!/bin/bash

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
    echo -e "$1$2${RESET}"
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

check_and_install() {
    local package=$1

    if dpkg -l | grep -q "^ii  $package "; then
        print_message "$CYAN" "[✔] $package is already installed."
    else
        print_message "$YELLOW" "[✘] $package is not installed. Installing..."
        sudo apt install -y "$package"
    fi
}

warn_env_paths() {
    print_message "$YELLOW" "[⚠] Warning: Ensure the following paths are correctly set before using OpenCV with CUDA."
    print_message "$CYAN" "  export CUDNN_PATH=/usr/local/cuda/lib64"
    print_message "$CYAN" "  export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH"
    print_message "$CYAN" "  export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH"
    print_message "$ORANGE" "[!] If you experience issues, add these lines to your ~/.bashrc or ~/.zshrc and run:"
    print_message "$CYAN" "    source ~/.bashrc"
    print_message "$CYAN" "    source ~/.zshrc"
}

check_optional() {
    local package=$1

    if dpkg -l | grep -q "^ii  $package "; then
        print_message "$CYAN" "[✔] $package is already installed."
    else
        read -p "Do you want to install $package? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            print_message "$YELLOW" "Installing $package..."
            sudo apt install -y "$package"
        else
            print_message "$ORANGE" "Skipping $package."
        fi
    fi
}

install_packages() {
    local required_packages=("g++" "cmake" "make" "wget" "unzip" "git")
    local optional_packages=("cmake-qt-gui")

    for package in "${required_packages[@]}"; do
        check_and_install "$package"
    done


    for package in "${optional_packages[@]}"; do
        check_optional "$package"
    done
}

check_cuda() {
    if command -v nvcc &> /dev/null; then
        print_message "$CYAN" "[✔] CUDA is installed."
        nvcc --version | grep "release"  # Show CUDA version
    else
        print_message "$RED" "[✘] CUDA is NOT installed!"
    fi
}

check_cudnn() {
    if [[ -f "/usr/include/cudnn.h" || -f "/usr/local/cuda/include/cudnn.h" ]]; then
        print_message "$CYAN" "[✔] cuDNN is installed."
        cat /usr/include/cudnn_version.h 2>/dev/null | grep "#define CUDNN_MAJOR" | head -n 1 || echo "Version info not found."
    else
        print_message "$RED" "[✘] cuDNN is NOT installed!"
    fi
}

check_nvidia_driver() {
    if command -v nvidia-smi &> /dev/null; then
        print_message "$CYAN" "[✔] NVIDIA driver is installed."
        nvidia-smi | grep "Driver Version"
    else
        print_message "$RED" "[✘] NVIDIA driver is NOT installed!"
    fi
}

check_cuda_support() {
    read -p "Do you want to check for CUDA support? (y/n): " enable_cuda

    if [[ "$enable_cuda" == "y" || "$enable_cuda" == "Y" ]]; then
        check_nvidia_driver
        check_cuda
        check_cudnn
    else
        print_message "$ORANGE" "Skipping CUDA checks."
    fi
}

install_packages() {
    local required_packages=("g++" "cmake" "make" "wget" "unzip" "git")
    local optional_packages=("cmake-qt-gui")

    # Install required packages
    for package in "${required_packages[@]}"; do
        check_and_install "$package"
    done

    # Ask about optional packages
    for package in "${optional_packages[@]}"; do
        check_optional "$package"
    done
}

download_and_extract_opencv() {
    local opencv_url="https://github.com/opencv/opencv/archive/4.x.zip"
    local contrib_url="https://github.com/opencv/opencv_contrib/archive/4.x.zip"
    
    local opencv_zip="opencv.zip"
    local contrib_zip="opencv_contrib.zip"
    
    local opencv_dir="opencv-4.x"
    local contrib_dir="opencv_contrib-4.x"

    # Check if OpenCV directory is not empty
    if [[ -d "$opencv_dir" && "$(ls -A "$opencv_dir")" ]]; then
        print_message "$CYAN" "[✔] $opencv_dir already exists and is not empty. Skipping download and extraction."
    else
        # Download OpenCV
        if [[ -f "$opencv_zip" ]]; then
            print_message "$CYAN" "[✔] $opencv_zip already exists. Skipping download."
        else
            print_message "$YELLOW" "[↓] Downloading OpenCV..."
            wget -O "$opencv_zip" "$opencv_url"
        fi

        # Download OpenCV Contrib
        if [[ -f "$contrib_zip" ]]; then
            print_message "$CYAN" "[✔] $contrib_zip already exists. Skipping download."
        else
            print_message "$YELLOW" "[↓] Downloading OpenCV Contrib..."
            wget -O "$contrib_zip" "$contrib_url"
        fi

        # Extract OpenCV
        if [[ -d "$opencv_dir" ]]; then
            print_message "$CYAN" "[✔] $opencv_dir already extracted. Skipping extraction."
        else
            print_message "$YELLOW" "[→] Extracting OpenCV..."
            unzip "$opencv_zip"
        fi

        # Extract OpenCV Contrib
        if [[ -d "$contrib_dir" ]]; then
            print_message "$CYAN" "[✔] $contrib_dir already extracted. Skipping extraction."
        else
            print_message "$YELLOW" "[→] Extracting OpenCV Contrib..."
            unzip "$contrib_zip"
        fi

        # Remove zip files
        if [[ -f "$opencv_zip" ]]; then
            print_message "$ORANGE" "[✔] Removing $opencv_zip."
            rm "$opencv_zip"
        fi

        if [[ -f "$contrib_zip" ]]; then
            print_message "$ORANGE" "[✔] Removing $contrib_zip."
            rm "$contrib_zip"
        fi
    fi

    print_message "$GREEN" "OpenCV and OpenCV Contrib are ready!"
}

check_and_install_packages() {
    # Array of packages to check and install
    local packages=(
        "ffmpeg"
        "libgstreamer-plugins-base1.0-dev"
        "intltool"
        "libavcodec-dev"
        "libavformat-dev"
        "libwxgtk3.2-dev"
        "build-essential"
        "libgtk-3-dev"
        "cmake"
        "git"
        "libgtk2.0-dev"
        "pkg-config"
        "libswscale-dev"
        "libgtkglext1"
        "libgtkglext1-dev"
        "vtk"   # For pip3 installation
        "python3-virtualenv"
        "libgl1-mesa-dev"
        "libglu1-mesa-dev"
        "libgstreamer1.0-dev"
        "libgstreamer-plugins-base1.0-dev"
        "libgstreamer-plugins-bad1.0-dev"
        "gstreamer1.0-plugins-base"
        "gstreamer1.0-plugins-good"
        "gstreamer1.0-plugins-bad"
        "gstreamer1.0-plugins-ugly"
        "gstreamer1.0-libav"
        "gstreamer1.0-tools"
        "gstreamer1.0-x"
        "gstreamer1.0-alsa"
        "gstreamer1.0-gl"
        "gstreamer1.0-gtk3"
        "gstreamer1.0-qt5"
        "gstreamer1.0-pulseaudio"
        "libtheora-dev"
        "libvorbis-dev"
        "libxvidcore-dev"
        "x264"
        "v4l-utils"
        "libfaac-dev"
        "libmp3lame-dev"
        "libopencore-amrnb-dev"
        "libopencore-amrwb-dev"
        "libv4l-dev"
        "libtbb-dev"
        "libswscale-dev"
        "libtiff-dev"
        "libopencv-dev"
        "libatlas-base-dev"
        "gfortran"
        "libprotobuf-dev"
        "protobuf-compiler"
        "libgoogle-glog-dev"
        "libgflags-dev"
        "libgphoto2-dev"
        "libeigen3-dev"
        "libhdf5-dev"
        "doxygen"
        "checkinstall"  # For easier package management
    )

    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "$package"; then
            print_message "$CYAN" "[✔] $package is already installed. Skipping installation."
        else
            print_message "$YELLOW" "[↓] Installing $package..."
            if [[ "$package" == "vtk" ]]; then
                pip3 install vtk  # Handle pip installation separately
            else
                sudo apt-get install -y "$package"
            fi
        fi
    done

    print_message "$GREEN" "All requested packages have been checked and installed where necessary!"
}

install_cuda_dependencies() {
    # Ask user if they want to install additional dependencies for CUDA support
    read -p "Do you want to install additional dependencies for CUDA support? (y/n): " install_cuda_deps

    if [[ "$install_cuda_deps" == "y" || "$install_cuda_deps" == "Y" ]]; then
        check_and_install_packages  # Call the function to check and install packages
    else
        print_message "$ORANGE" "Skipping installation of CUDA dependencies."
    fi
}

build_opencv() {
    local opencv_dir="opencv-4.x"
    local build_dir="$opencv_dir/build"
    local contrib_path="opencv_contrib-4.x"
    
    # Ask user if they want to enable CUDA support
    read -p "Do you want to enable CUDA support? (y/n): " enable_cuda

    # Set CUDA options based on user input
    if [[ "$enable_cuda" == "y" || "$enable_cuda" == "Y" ]]; then
        local cuda_arch_bin=$(nvidia-smi --query-gpu=compute_cap --format=csv | sed -n 2p)
        check_cuda_support
        warn_env_paths
        cuda_options="-D WITH_CUDA=ON \
                      -D WITH_CUDNN=ON \
                      -D OPENCV_DNN_CUDA=ON \
                      -D CUDA_ARCH_BIN=$cuda_arch_bin"
        install_cuda_dependencies
        read -p "Do you want to set -D WITH_FFMPEG=ON? This may cause errors if required packages are missing. (y/n): " use_ffmpeg
        
        if [[ "$use_ffmpeg" == "y" || "$use_ffmpeg" == "Y" ]]; then
            ffmpeg_option="-D WITH_FFMPEG=ON"
            print_message "$ORANGE" "Warning: Setting WITH_FFMPEG=OFF may lead to missing functionality."
        else
            ffmpeg_option="-D WITH_FFMPEG=OFF"
        fi
    else
        cuda_options="-D WITH_CUDA=OFF \
                      -D WITH_CUDNN=OFF \
                      -D OPENCV_DNN_CUDA=OFF"
    fi

    # Check if OpenCV directory exists
    if [[ -d "$opencv_dir" ]]; then
        # Check if the build directory exists and if Makefile is present
        if [[ -d "$build_dir" && -f "$build_dir/Makefile" ]]; then
            print_message "$CYAN" "[✔] OpenCV has already been built. Skipping build process."
        else
            cd "$opencv_dir" || { print_message "$RED" "[✘] Failed to enter directory $opencv_dir."; exit 1; }

            # Create build directory and navigate into it
            mkdir -p build && cd build || { print_message "$RED" "[✘] Failed to create or enter build directory."; exit 1; }

            # Run cmake with user-specified options
            print_message "$YELLOW" "[→] Configuring cmake..."
            cmake -D CMAKE_BUILD_TYPE=RELEASE \
                  -D CMAKE_INSTALL_PREFIX=/usr/local \
                  -D WITH_TBB=ON \
                  -D ENABLE_FAST_MATH=1 \
                  -D CUDA_FAST_MATH=1 \
                  -D WITH_CUBLAS=1 \
                  $cuda_options \
                  -D BUILD_opencv_cudacodec=OFF \
                  -D CMAKE_C_COMPILER=gcc-12 \
                  -D CMAKE_CXX_COMPILER=g++-12 \
                  -D WITH_V4L=ON \
                  -D WITH_QT=OFF \
                  $ffmpeg_option \
                  -D WITH_OPENGL=ON \
                  -D WITH_GSTREAMER=ON \
                  -D OPENCV_GENERATE_PKGCONFIG=ON \
                  -D OPENCV_PC_FILE_NAME=opencv.pc \
                  -D OPENCV_ENABLE_NONFREE=ON \
                  -D OPENCV_EXTRA_MODULES_PATH="../../$contrib_path/modules" \
                  -D INSTALL_PYTHON_EXAMPLES=OFF \
                  -D INSTALL_C_EXAMPLES=OFF \
                  -D BUILD_EXAMPLES=OFF \
                  -D BUILD_opencv_python3=ON \
                  -D PYTHON_EXECUTABLE=$(which python3) \
                  -D PYTHON3_PACKAGES_PATH=$(python3 -c "import site; print(site.getsitepackages()[0])") \
                  -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") ..

            if [ $? -ne 0 ]; then
                print_error "CMake configuration failed. Please check the output for details."
                exit 1
            fi

            # Compile with make
            print_message "$YELLOW" "[→] Compiling with make..."
            if ! make -j$(nproc); then
                print_error "Error during the build process. Exiting."
                exit 1
            fi

            # Prompt user for system-wide installation
            read -p "Do you want to install OpenCV system-wide with 'sudo make install'? (y/n): " install_opencv

            if [[ "$install_opencv" == "y" || "$install_opencv" == "Y" ]]; then
                # Check if OpenCV is already installed
                if pkg-config --modversion opencv4 >/dev/null 2>&1; then
                    installed_version=$(pkg-config --modversion opencv4)
                    print_message "$GREEN" "[✔] OpenCV is already installed (version $installed_version)."
                else
                    print_message "$YELLOW" "[→] Installing OpenCV system-wide..."
                    if sudo make install && sudo ldconfig; then
                        print_message "$GREEN" "[✔] OpenCV installed successfully!"
                    else
                        print_error "OpenCV installation failed."
                    fi
                fi
            else
                print_message "$ORANGE" "[!] OpenCV installation skipped. You can install it later by running 'sudo make install'."
            fi
        fi
    else
        print_message "$RED" "[✘] $opencv_dir does not exist. Please ensure it is downloaded and extracted."
    fi
}

verify_opencv_build() {
    print_message "$YELLOW" "[→] Verifying OpenCV build..."

    # Navigate to OpenCV build directory
    local build_dir="opencv-4.x/build"

    if [[ ! -d "$build_dir" ]]; then
        print_message "$RED" "[✘] OpenCV build directory not found: $build_dir"
        return 1
    fi

    cd "$build_dir" || { print_message "$RED" "[✘] Failed to enter OpenCV build directory."; return 1; }

    # Check key files and directories
    print_message "$CYAN" "[ℹ] Checking build artifacts..."
    ls bin lib OpenCVConfig*.cmake OpenCVModules.cmake || print_message "$RED" "[✘] Some build files are missing!"

    # Run OpenCV core test if binary exists
    if [[ -f "bin/opencv_test_core" ]]; then
        print_message "$YELLOW" "[→] Running OpenCV core test..."
    else
        print_message "$ORANGE" "[!] opencv_test_core binary not found. Test skipped."
    fi

    # Verify OpenCV installation
    print_message "$YELLOW" "[→] Checking system-wide OpenCV installation..."
    if pkg-config --modversion opencv4 >/dev/null 2>&1; then
        installed_version=$(pkg-config --modversion opencv4)
        print_message "$GREEN" "[✔] OpenCV is installed (version $installed_version)."
    else
        print_message "$RED" "[✘] OpenCV is NOT installed system-wide!"
    fi

}

install_packages
download_and_extract_opencv
build_opencv
verify_opencv_build
