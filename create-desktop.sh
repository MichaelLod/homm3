#!/bin/bash
# Create desktop launcher for VCMI

mkdir -p ~/Desktop

cat > ~/Desktop/VCMI-LoadLastSave.sh << 'EOF'
#!/bin/bash
cd ~
export DISPLAY=:1
vcmiclient-autoload
EOF

cat > ~/Desktop/VCMI-NewGame.sh << 'EOF'
#!/bin/bash
cd ~
export DISPLAY=:1
vcmiclient-newgame
EOF

chmod +x ~/Desktop/VCMI-LoadLastSave.sh ~/Desktop/VCMI-NewGame.sh

# Create a simple menu entry
mkdir -p ~/.fluxbox
cat > ~/.fluxbox/menu << 'EOF'
[begin] (Fluxbox)
  [exec] (Terminal) {xterm}
  [submenu] (VCMI)
    [exec] (VCMI - Load Last Save) {vcmiclient-autoload}
    [exec] (VCMI - New Game) {vcmiclient-newgame}
    [exec] (VCMI - Normal Start) {vcmiclient}
  [end]
  [exec] (VCMI Server) {xterm -e vcmiserver}
  [separator]
  [exit] (Exit)
[end]
EOF

