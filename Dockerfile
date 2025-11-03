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
    liblzma-dev \
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
    qtbase5-dev \
    qt5-qmake \
    qttools5-dev \
    qttools5-dev-tools \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    libqt5opengl5-dev \
    libqt5svg5-dev \
    libtbb-dev \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC and websockify
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify \
    && cd /opt/novnc && npm install --production || true

# Set up VNC
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\n[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup\n[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources\nfluxbox &\nexec bash\n' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Create directories for VCMI
RUN mkdir -p /opt/vcmi /app/saves /app/config

# Build VCMI - split into separate layers for better caching
WORKDIR /opt
# Layer 1: Clone VCMI source (cached unless VCMI repo changes)
RUN git clone --depth 1 --recursive https://github.com/vcmi/vcmi.git vcmi-src
# Layer 2: Configure CMake (cached unless VCMI source or build system changes)
WORKDIR /opt/vcmi-src
RUN mkdir build
WORKDIR /opt/vcmi-src/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release
# Layer 3: Build VCMI (cached unless source or CMake config changes)
RUN cmake --build . -j$(nproc)
# Layer 4: Install VCMI (cached unless build artifacts change)
RUN cmake --install . --prefix /opt/vcmi
# Layer 5: Clean up source (this layer is cheap, but keeps image size smaller)
WORKDIR /opt
RUN rm -rf /opt/vcmi-src

# Set up VCMI data directory structure
# VCMI will look for data files in ~/.vcmi/Data or configurable paths
RUN mkdir -p /root/.vcmi

# Application files - these come last so they don't invalidate the VCMI build cache
# Set up supervisor for managing services
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script and desktop launcher
COPY start.sh /start.sh
COPY start-vnc.sh /start-vnc.sh
COPY start-novnc.sh /start-novnc.sh
COPY create-desktop.sh /create-desktop.sh
COPY setup-homm3-files.sh /setup-homm3-files.sh
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

