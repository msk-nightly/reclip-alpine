#!/bin/sh
# Needs to be updated
set -euo pipefail
cd "$(dirname "$0")"

# Check prerequisites
missing=""

if ! command -v python3 &> /dev/null; then
    missing="$missing python3"
fi

# if ! command -v yt-dlp &> /dev/null; then
#     missing="$missing yt-dlp"
# fi

if ! command -v ffmpeg &> /dev/null; then
    missing="$missing ffmpeg"
fi

if [ -n "$missing" ]; then
    echo "Missing required tools:$missing"
    echo ""
    if command -v apk &> /dev/null; then
        echo "Intall with:  apk add$missing"
    elif command -v brew &> /dev/null; then
        echo "Install with:  brew install$missing"
    elif command -v apt &> /dev/null; then
        echo "Install with:  apt install$missing"
    else
        echo "Please install:$missing"
    fi
    exit 1
fi

# Set up venv and install Python deps
if [ ! -d "venv" ]; then
    echo "Setting up virtual environment..."
    python3 -m venv venv
    . venv/bin/activate
    pip install -q --no-cache-dir -U --pre -r requirements.txt
    cp templates/yt-dlp.conf venv/bin/
else
    . venv/bin/activate
fi

# Keep yt-dlp fresh — sites (Instagram, Facebook, etc.) break its extractors
# frequently, and the usual fix is simply updating yt-dlp. Skip with RECLIPPY_NO_UPDATE=1.
if [ -z "$RECLIPPY_NO_UPDATE" ]; then
    echo "Updating yt-dlp..."
    pip install -q -U yt-dlp || echo "\nCouldn't update yt-dlp :( Continuing with the existing version...\n"
fi

PORT="${PORT:-8899}"
export PORT

echo ""
echo "  ReClippy is running at http://localhost:$PORT"
echo ""
gunicorn -b 0.0.0.0:8899 -w 1 --threads 4 --timeout 600 --access-logfile - app:app
