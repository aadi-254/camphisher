#!/bin/bash

# Check if cloudflared is installed, if not install it
if ! command -v cloudflared &> /dev/null; then
    echo "🌐 cloudflared not found, installing..."
    
    # Install cloudflared (Cloudflare Tunnel)
    if [ "$(uname)" == "Darwin" ]; then
        brew install cloudflare/cloudflare/cloudflared
    elif [ "$(uname)" == "Linux" ]; then
        curl -s https://pkg.cloudflare.com/install.sh | sudo bash
        sudo apt-get install -y cloudflared
    else
        echo "Unsupported OS for cloudflared installation."
        exit 1
    fi
fi

# Check if PHP is installed, if not install it
if ! command -v php &> /dev/null; then
    echo "🚀 PHP not found, installing PHP..."
    
    if [ "$(uname)" == "Darwin" ]; then
        brew install php
    elif [ "$(uname)" == "Linux" ]; then
        sudo apt update
        sudo apt install -y php php-cli php-xml php-mbstring
    else
        echo "Unsupported OS for PHP installation."
        exit 1
    fi
fi

# Create uploads folder if needed
mkdir -p uploads

# Start the PHP built-in server with YOUR FILE
MAIN_PHP_FILE="index.php"  # <=== Change this if your main file is different

if [ ! -f "$MAIN_PHP_FILE" ]; then
    echo "❌ Error: $MAIN_PHP_FILE not found!"
    exit 1
fi

echo "🚀 Starting PHP server with $MAIN_PHP_FILE on localhost:8080..."
php -S localhost:8080 "$MAIN_PHP_FILE" > /dev/null 2>&1 &
PHP_PID=$!

# Start Cloudflare Tunnel
echo "🌐 Starting Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:8080 --logfile tunnel.log --loglevel info > /dev/null 2>&1 &
CLOUDFLARED_PID=$!

# Give Cloudflare Tunnel time to start
sleep 5

# Get the public URL
CLOUDFLARE_URL=$(grep -o 'https://[^"]*\.trycloudflare\.com' tunnel.log | head -n 1)

if [ -z "$CLOUDFLARE_URL" ]; then
    echo "⚠️ Could not detect Cloudflare URL. Check manually."
else
    echo "✅ Public URL: $CLOUDFLARE_URL"
    # Try opening automatically
    if command -v xdg-open > /dev/null; then
        xdg-open "$CLOUDFLARE_URL"
    elif command -v firefox > /dev/null; then
        firefox "$CLOUDFLARE_URL"
    elif command -v google-chrome > /dev/null; then
        google-chrome "$CLOUDFLARE_URL"
    else
        echo "🌐 Please open manually."
    fi
fi

# Clean shutdown on Ctrl+C
trap 'echo; echo "🛑 Stopping servers..."; kill $PHP_PID $CLOUDFLARED_PID 2>/dev/null; exit 0' SIGINT

# Optional: Watch any file (example: ips.txt)
IPS_FILE="ips.txt"
echo "📡 Monitoring IPs from $IPS_FILE..."
while [ ! -f "$IPS_FILE" ]; do
    sleep 1
done
echo "📄 Monitoring $IPS_FILE..."
tail -f "$IPS_FILE"
