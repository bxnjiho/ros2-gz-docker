# ---- ROS 2 Humble + Gazebo Harmonic + noVNC (multi-arch; native on Apple Silicon) ----
FROM ros:humble-ros-base

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    DISPLAY=:1 \
    VNC_RESOLUTION=1280x800 \
    ROS_DOMAIN_ID=42 \
    RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# Base utilities + OSRF Gazebo repo + ROS desktop + Gazebo Harmonic + GUI stack
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl gnupg lsb-release ca-certificates \
      git build-essential python3-colcon-common-extensions \
      xfce4 xfce4-terminal dbus-x11 \
      novnc websockify tigervnc-standalone-server tigervnc-common tigervnc-tools x11-xserver-utils \
      mesa-utils \
      dos2unix \
  && curl -sSL https://packages.osrfoundation.org/gazebo.gpg \
       -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
           https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
       > /etc/apt/sources.list.d/gazebo-stable.list \
  && apt-get update && apt-get install -y --no-install-recommends \
       ros-humble-desktop \
       ros-humble-gazebo-ros-pkgs \
       ros-humble-gazebo-ros \
       ros-humble-gazebo-ros-pkg-examples \
  && rm -rf /var/lib/apt/lists/*

# Create a non-root user and a workspace
RUN useradd -ms /bin/bash dev
WORKDIR /home/dev/ws
RUN mkdir -p /home/dev/ws/src && chown -R dev:dev /home/dev

# Startup script (noVNC + VNC + XFCE)
RUN cat >/usr/local/bin/start.sh <<'EOF' && chmod +x /usr/local/bin/start.sh
#!/usr/bin/env bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"
RES="${VNC_RESOLUTION:-1280x800}"
VNC_PASS="${VNC_PASSWORD:-changeme}"
NOVNC_PORT="${NOVNC_PORT:-8080}"

# Prepare VNC for the 'dev' user
install -d -m 700 -o dev -g dev /home/dev/.vnc
echo "$VNC_PASS" | vncpasswd -f > /home/dev/.vnc/passwd
chown dev:dev /home/dev/.vnc/passwd
chmod 600 /home/dev/.vnc/passwd

# Clean up any stale server, then start a fresh one
su - dev -c "vncserver -kill ${DISPLAY}" >/dev/null 2>&1 || true
su - dev -c "vncserver ${DISPLAY} -geometry ${RES} -depth 24 -localhost no"

# Start XFCE on that display
su - dev -c "export DISPLAY=${DISPLAY}; startxfce4 >/home/dev/.xfce.log 2>&1 &"

# Find a usable noVNC launcher and start it
NOVNC_LAUNCHER=""
if [ -x /usr/share/novnc/utils/novnc_proxy ]; then
  NOVNC_LAUNCHER=/usr/share/novnc/utils/novnc_proxy
elif [ -x /usr/share/novnc/utils/novnc_proxy.py ]; then
  NOVNC_LAUNCHER=/usr/share/novnc/utils/novnc_proxy.py
else
  NOVNC_LAUNCHER=/usr/share/novnc/utils/launch.sh
fi
"$NOVNC_LAUNCHER" --vnc localhost:5901 --listen 0.0.0.0:${NOVNC_PORT} &
sleep 1

echo "------------------------------------------------------------------"
echo " ROS 2 + Gazebo desktop is ready."
echo " Open:  http://localhost:${NOVNC_PORT}"
echo " (VNC password: ${VNC_PASS})"
echo " To run Gazebo: open a Terminal inside the web desktop and run 'gz sim'"
echo "------------------------------------------------------------------"

# Keep the container running
tail -f /dev/null
EOF

# Fix line endings (convert CRLF to LF)
RUN dos2unix /usr/local/bin/start.sh

# Default ROS env in dev's shell
RUN bash -lc 'echo "source /opt/ros/humble/setup.bash" >> /home/dev/.bashrc' && \
    chown dev:dev /home/dev/.bashrc

EXPOSE 8080
CMD ["/usr/local/bin/start.sh"]