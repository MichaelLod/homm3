FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# Install system dependencies and desktop environment
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    nodejs \
    npm \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-ttf-dev \
    libsdl2-mixer-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libffi-dev \
    libbz2-dev \
    zlib1g-dev \
    libpng-dev \
    libzip-dev \
    libminizip-dev \
    python3 \
    python3-pip \
    libboost-filesystem-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-program-options-dev \
    libboost-locale-dev \
    libboost-iostreams-dev \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    supervisor \
    fluxbox \
    xterm \
    net-tools \
    nano \
    qt5-qmake \
    qtbase5-dev \
    qtbase5-dev-tools \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC and websockify
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify \
    && cd /opt/novnc && npm install --production || true

# Set up VNC
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\n[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup\n[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources\nfluxbox &\n' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Create directories for VCMI
RUN mkdir -p /opt/vcmi /app/saves /app/config

# Build VCMI
WORKDIR /opt
RUN git clone --depth 1 --recursive https://github.com/vcmi/vcmi.git vcmi-src \
    && cd vcmi-src \
    && mkdir build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && cmake --build . -j$(nproc) \
    && cmake --install . --prefix /opt/vcmi \
    && cd /opt && rm -rf vcmi-src

# Set up VCMI data directory structure
# VCMI will look for data files in ~/.vcmi/Data or configurable paths
RUN mkdir -p /root/.vcmi

# Set up supervisor for managing services
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script and desktop launcher
COPY start.sh /start.sh
COPY create-desktop.sh /create-desktop.sh
COPY setup-homm3-files.sh /setup-homm3-files.sh
RUN chmod +x /start.sh /create-desktop.sh /setup-homm3-files.sh

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

