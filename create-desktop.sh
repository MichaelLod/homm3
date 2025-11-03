#!/bin/bash
# Create desktop launcher for VCMI

mkdir -p ~/Desktop

cat > ~/Desktop/VCMI.sh << 'EOF'
#!/bin/bash
cd ~
export DISPLAY=:1
vcmiclient
EOF

chmod +x ~/Desktop/VCMI.sh

# Create a simple menu entry
mkdir -p ~/.fluxbox
cat > ~/.fluxbox/menu << 'EOF'
[begin] (Fluxbox)
  [exec] (Terminal) {xterm}
  [exec] (VCMI Client) {vcmiclient}
  [exec] (VCMI Server) {xterm -e vcmiserver}
  [separator]
  [exit] (Exit)
[end]
EOF

