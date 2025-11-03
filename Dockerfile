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
    && rm -rf /var/lib/apt/lists/*

# Install VCMI from PPA (pre-built, much faster than building from source)
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:vcmi/ppa -y && \
    apt-get update && \
    apt-get install -y vcmi && \
    rm -rf /var/lib/apt/lists/*

# Install noVNC and websockify
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify \
    && cd /opt/novnc && npm install --production || true \
    && echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=vnc.html" /><script>window.location.href="vnc.html";</script></head><body>Redirecting to <a href="vnc.html">noVNC</a>...</body></html>' > /opt/novnc/index.html

# Set up VNC
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\n[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup\n[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources\nfluxbox &\n# Keep session alive - use tail -f instead of exec bash for better compatibility\nwhile true; do sleep 3600; done\n' > /root/.vnc/xstartup && \
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

