#!/usr/bin/env bash
set -e

# Start a VNC server on :1
mkdir -p /home/dev/.vnc
echo "changeme" | vncpasswd -f > /home/dev/.vnc/passwd
chown -R dev:dev /home/dev/.vnc
chmod 600 /home/dev/.vnc/passwd
# Kill any stale servers, then start new
vncserver -kill :1 || true
sudo -u dev vncserver :1 -geometry ${VNC_RESOLUTION:-1280x800} -depth 24

# Launch XFCE in that display
sudo -u dev bash -lc "export DISPLAY=:1; startxfce4 &"

# Start noVNC on 0.0.0.0:8080 pointing to the VNC server (:1 -> 5901)
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:8080 &
sleep 1

# Keep container in foreground: a simple ROS env shell
export DISPLAY=:1
echo "Container ready. Open http://localhost:8080 for desktop."
tail -f /dev/null
