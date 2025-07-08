# Dev Bootstrap Scripts

A curated collection of Bash scripts to automate system setup, development environment configuration, and essential tooling on Ubuntu. This repository is designed to be modular, readable, and easily extendable — more scripts will be added over time.

---

## What’s Included

| Script Name                | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| `build_opencv.sh`         | Downloads, builds, and optionally installs OpenCV with optional CUDA support. |
| `docker_install.sh`       | Cleans up old Docker installations, sets up the repo, installs Docker, and verifies setup. |
| `prepare_system.sh`     | Installs commonly used development packages, tools, and terminal utilities. |

---

## Quick Start

Clone the repository:

```bash
git clone https://github.com/your-username/dev-bootstrap-scripts.git
cd dev-bootstrap-scripts
```

Run any script with:
```bash
chmod +x script_name.sh
./script_name.sh
```

## Prerequisites

- **Ubuntu 20.04+** (or compatible Debian-based system)
- **sudo privileges** (required for installing system packages)
- **Internet connection** (for downloading dependencies)
