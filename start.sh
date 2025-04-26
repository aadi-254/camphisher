#!/bin/bash

# Check if cloudflared is installed, if not install it
if ! command -v cloudflared &> /dev/null; then
    echo "🌐 cloudflared not found, installing..."
    
    # Install cloudflared (Cloudflare Tunnel)
    if [ "$(uname)" == "Darwin" ]; then
        # macOS installation
        brew install cloudflare/cloudflare/cloudflared
    elif [ "$(uname)" == "Linux" ]; then
        # Linux installation
        curl -s https://pkg.cloudflare.com/install.sh | sudo bash
        sudo apt-get install cloudflared
    else
        echo "Unsupported OS for cloudflared installation."
        exit 1
    fi
fi

# Check if PHP is installed, if not install it
if ! command -v php &> /dev/null; then
    echo "🚀 PHP not found, installing PHP..."
    
    # Install PHP
    if [ "$(uname)" == "Darwin" ]; then
        # macOS installation (using brew)
        brew install php
    elif [ "$(uname)" == "Linux" ]; then
        # Ubuntu/Debian-based installation
        sudo apt update
        sudo apt install php php-cli php-xml php-mbstring
    else
        echo "Unsupported OS for PHP installation."
        exit 1
    fi
fi

# Clone the repository (you should replace this with your own repository)
REPO_URL="https://github.com/yourusername/yourrepository.git"
TARGET_DIR="myproject"

# Check if the repository exists locally, if not, clone it
if [ ! -d "$TARGET_DIR" ]; then
    echo "📥 Cloning your repository..."
    git clone "$REPO_URL" "$TARGET_DIR"
else
    echo "Repository already exists. Skipping cloning."
fi

# Change directory to the project
cd "$TARGET_DIR" || exit

# Ensure the 'uploads' directory exists for image saving
mkdir -p uploads

# Start PHP server in the background
echo "🚀 Starting PHP server at localhost:8080..."
php -S localhost:8080 > /dev/null 2>&1 &
PHP_PID=$!

# Start Cloudflare Tunnel
echo "🌐 Starting Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:8080 --logfile tunnel.log --loglevel info > /dev/null 2>&1 &
CLOUDFLARED_PID=$!

# Give Cloudflare Tunnel time to start
sleep 5

# Fetch Public URL from tunnel.log
CLOUDFLARE_URL=$(grep -o 'https://[^"]*\.trycloudflare\.com' tunnel.log | head -n 1)

if [ -z "$CLOUDFLARE_URL" ]; then
    echo "⚠️ Could not detect Cloudflare URL. Check manually."
else
    echo "✅ Public URL: $CLOUDFLARE_URL"
    # Open in browser (Firefox or Chrome or default)
    if command -v xdg-open > /dev/null; then
        xdg-open "$CLOUDFLARE_URL"
    elif command -v firefox > /dev/null; then
        firefox "$CLOUDFLARE_URL"
    elif command -v google-chrome > /dev/null; then
        google-chrome "$CLOUDFLARE_URL"
    else
        echo "🌐 Please open it manually in your browser."
    fi
fi

# Trap to clean up the processes when Ctrl+C is pressed
trap 'echo; echo "🛑 Stopping servers..."; kill $PHP_PID $CLOUDFLARED_PID 2>/dev/null; exit 0' SIGINT

# Monitor the IPs (you can adjust this to fit your file)
IPS_FILE="ips.txt"
echo "📡 Monitoring IPs from $IPS_FILE..."
while [ ! -f "$IPS_FILE" ]; do
    sleep 1
done
echo "📄 Monitoring $IPS_FILE..."
tail -f "$IPS_FILE"
