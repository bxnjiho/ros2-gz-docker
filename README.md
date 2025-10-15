# ROS 2 + Gazebo (Harmonic) in Docker

This repo runs **ROS 2 Humble + Gazebo Harmonic** in a single container and exposes a lightweight **XFCE desktop via noVNC** (browser)

- Works **natively on Apple Silicon (M1/M2/M3/M4)** and Intel.
- Windows users run it via **Docker Desktop + WSL2**.
- One command to build, one to start, open `http://localhost:8080`.

---

## Prerequisites

### macOS
- **Docker Desktop** (latest)
- Optional: **VS Code**

### Windows 10/11
- **Docker Desktop** with **WSL2 backend** enabled
- **Ubuntu** (WSL) installed from Microsoft Store
- Git (either in WSL Ubuntu or Windows)

---

## Quick Start (Local Build)

```bash
# Clone and enter repo
git clone <this-repo-url>
cd <repo>

# Create a workspace folder for your code
mkdir -p ws/src

# Build and start
docker compose build --no-cache
docker compose up -d

# Open the desktop in your browser:
# http://localhost:8080  
