FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# Install system dependencies and desktop environment
# Note: Removed build dependencies since we're using pre-built VCMI from PPA
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    nodejs \
    npm \
    python3 \
    python3-pip \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    supervisor \
    fluxbox \
    xterm \
    net-tools \
    nano \
    xdotool \
    && rm -rf /var/lib/apt/lists/*

# Install VCMI from PPA (pre-built, much faster than building from source)
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:vcmi/ppa -y && \
    apt-get update && \
    apt-get install -y vcmi && \
    # VCMI installs to /usr/games, add symlinks to /usr/bin for convenience
    ln -sf /usr/games/vcmiclient /usr/bin/vcmiclient && \
    ln -sf /usr/games/vcmiserver /usr/bin/vcmiserver && \
    ln -sf /usr/games/vcmieditor /usr/bin/vcmieditor 2>/dev/null || true && \
    rm -rf /var/lib/apt/lists/*

# Install noVNC and websockify
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify \
    && cd /opt/novnc && npm install --production || true \
    && echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=vnc.html" /><script>window.location.href="vnc.html";</script></head><body>Redirecting to <a href="vnc.html">noVNC</a>...</body></html>' > /opt/novnc/index.html

# Set up VCMI auto-load script
# Since VCMI doesn't support --load, we use xdotool to automatically navigate the menu
RUN echo '#!/bin/bash\n# Auto-load latest hotseat save game\n# Check if auto-load should be skipped (for new games)\nif [ -f "$HOME/.vcmi/skip-autoload" ]; then\n    echo "Auto-load skipped (new game requested)"\n    rm -f "$HOME/.vcmi/skip-autoload"\n    DISPLAY=:1 vcmiclient &\n    exit 0\nfi\n\nSAVE_DIR="$HOME/.vcmi/Saves"\nLATEST_SAVE=$(find "$SAVE_DIR" -type f \\( -name "*.vcg" -o -name "*.VCMI" -o -name "*.save" \\) -printf "%T@ %p\\n" 2>/dev/null | sort -n | tail -1 | cut -d" " -f2-)\n\nif [ -n "$LATEST_SAVE" ] && [ -f "$LATEST_SAVE" ]; then\n    echo "Latest save found: $(basename "$LATEST_SAVE")"\n    # Start VCMI\n    DISPLAY=:1 vcmiclient &\n    VCMI_PID=$!\n    # Wait for VCMI to start\n    sleep 8\n    # Auto-navigate menu: Load Game -> Hotseat -> Select latest\n    export DISPLAY=:1\n    # Press Escape to close any dialogs, then navigate to Load Game\n    xdotool search --onlyvisible --name "VCMI" key --window %@ Escape 2>/dev/null || true\n    sleep 1\n    # Press L for Load Game (if main menu)\n    xdotool search --onlyvisible --name "VCMI" key --window %@ l 2>/dev/null || true\n    sleep 1\n    # Press Down arrow to select Hotseat (usually first option)\n    xdotool search --onlyvisible --name "VCMI" key --window %@ Down Return 2>/dev/null || true\n    sleep 2\n    # Press Home to go to first file, then navigate to last (newest)\n    xdotool search --onlyvisible --name "VCMI" key --window %@ Home 2>/dev/null || true\n    sleep 0.5\n    # Scroll to bottom for latest save\n    xdotool search --onlyvisible --name "VCMI" key --window %@ End 2>/dev/null || true\n    sleep 0.5\n    # Press Return to load\n    xdotool search --onlyvisible --name "VCMI" key --window %@ Return 2>/dev/null || true\n    echo "Attempted to auto-load save game"\nelse\n    echo "No save game found, starting VCMI normally"\n    DISPLAY=:1 vcmiclient &\nfi\n' > /usr/local/bin/vcmiclient-autoload && chmod +x /usr/local/bin/vcmiclient-autoload

# Create script to start VCMI with new game (skip auto-load)
RUN echo '#!/bin/bash\n# Start VCMI for new game (skip auto-load)\ntouch "$HOME/.vcmi/skip-autoload"\nDISPLAY=:1 vcmiclient &\n' > /usr/local/bin/vcmiclient-newgame && chmod +x /usr/local/bin/vcmiclient-newgame

# Set up VNC
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\n[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup\n[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources\nfluxbox &\nsleep 3\n# Start VCMI automatically, loading latest hotseat save if available\n/usr/local/bin/vcmiclient-autoload &\n# Keep session alive\nwhile true; do sleep 3600; done\n' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Create directories for VCMI (VCMI from PPA installs to /usr/games and /usr/bin)
RUN mkdir -p /app/saves /app/config

# Set up VCMI data directory structure
# VCMI will look for data files in ~/.vcmi/Data or configurable paths
RUN mkdir -p /root/.vcmi

# Application files - these come last so they don't invalidate the VCMI build cache
# Set up supervisor for managing services
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script and desktop launcher (copy all at once, then chmod in one step)
COPY start.sh start-vnc.sh start-novnc.sh create-desktop.sh setup-homm3-files.sh /
RUN chmod +x /start.sh /start-vnc.sh /start-novnc.sh /create-desktop.sh /setup-homm3-files.sh

# Expose VNC port (Railway will provide PORT env var)
EXPOSE 6080

# Set working directory
WORKDIR /app

# Note: Volumes are configured via Railway dashboard, not Dockerfile VOLUME
# Railway will mount volumes to:
# - /data - for HoMM 3 game files
# - /app/saves - for save games
# - /app/config - for VCMI configuration

CMD ["/start.sh"]

