FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# Force rebuild - invalidate cache
RUN echo "Build timestamp: $(date)" > /tmp/build-info.txt

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
    unzip \
    p7zip-full \
    && rm -rf /var/lib/apt/lists/*

# Install gdown for downloading from Google Drive
RUN pip3 install --no-cache-dir gdown

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
    && echo '<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><script>if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)){window.location.href="mobile.html";}else{window.location.href="vnc.html";}</script></head><body>Redirecting... <a href="vnc.html">Desktop</a> | <a href="mobile.html">Mobile</a></body></html>' > /opt/novnc/index.html

# Set up VCMI scripts and VNC xstartup (copy from files instead of inline echo)
RUN mkdir -p /root/.vnc /usr/local/bin
COPY vcmiclient-autoload.sh /usr/local/bin/vcmiclient-autoload
COPY vcmiclient-newgame.sh /usr/local/bin/vcmiclient-newgame
COPY xstartup.sh /root/.vnc/xstartup
COPY download-homm3-files.sh /usr/local/bin/download-homm3-files
COPY enable-hota-mod.sh /usr/local/bin/enable-hota-mod
COPY restart-vcmi.sh /usr/local/bin/restart-vcmi
COPY check-vcmi-mods.sh /usr/local/bin/check-vcmi-mods
RUN chmod +x /usr/local/bin/vcmiclient-autoload /usr/local/bin/vcmiclient-newgame /root/.vnc/xstartup /usr/local/bin/download-homm3-files /usr/local/bin/enable-hota-mod /usr/local/bin/restart-vcmi /usr/local/bin/check-vcmi-mods

# Create directories for VCMI (VCMI from PPA installs to /usr/games and /usr/bin)
# Note: All persistent data is now in /data volume (created at runtime)

# Set up VCMI data directory structure
# VCMI will look for data files in ~/.vcmi/Data or configurable paths
RUN mkdir -p /root/.vcmi

# Application files - these come last so they don't invalidate the VCMI build cache
# Set up supervisor for managing services
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script and desktop launcher (copy all at once, then chmod in one step)
COPY start.sh start-vnc.sh start-novnc.sh create-desktop.sh setup-homm3-files.sh setup-hota-mod.sh install-hota.sh download-homm3-files.sh mobile-vnc-wrapper.html /
RUN chmod +x /start.sh /start-vnc.sh /start-novnc.sh /create-desktop.sh /setup-homm3-files.sh /setup-hota-mod.sh /install-hota.sh /download-homm3-files.sh \
    && cp /mobile-vnc-wrapper.html /opt/novnc/mobile.html

# Expose VNC port (Railway will provide PORT env var)
EXPOSE 6080

# Set working directory
WORKDIR /app

# Add build metadata
RUN echo "Build completed at $(date)" >> /tmp/build-info.txt && \
    cat /tmp/build-info.txt

# Note: Volumes are configured via Railway dashboard, not Dockerfile VOLUME
# Railway will mount one volume to /data with subdirectories:
# - /data/Data - for HoMM 3 game files
# - /data/mods - for VCMI mods (HotA, etc.)
# - /data/saves - for save games
# - /data/config - for VCMI configuration

CMD ["/start.sh"]

