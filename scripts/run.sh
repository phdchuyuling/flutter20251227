#!/bin/bash
set -e

# Define variables
FLUTTER_DIR="$HOME/flutter"
PROJECT_DIR="/workspaces/flutter20251227"

# Install Flutter if not exists
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
fi

# Add Flutter to PATH
export PATH="$FLUTTER_DIR/bin:$PATH"

# Check Flutter version
flutter --version

# Enable web support
flutter config --enable-web

# Navigate to project directory
cd "$PROJECT_DIR"

# Ensure web assets are generated (flutter.js, icons, etc.)
echo "Generating web assets..."
flutter create . --platforms web

# Fix base href in index.html if needed
if [ -f "web/index.html" ]; then
    sed -i 's|<base href="\$FLUTTER_BASE_HREF">|<base href="/">|g' web/index.html
fi

# Get dependencies
flutter pub get

# Run the app
echo "Starting Flutter Web Server..."
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
