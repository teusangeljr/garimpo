#!/usr/bin/env bash
# exit on error
set -o errexit

# Install Python dependencies
pip install -r requirements.txt

CHROME_DIR="/opt/render/project/src/.chrome"
CHROME_BIN="$CHROME_DIR/opt/google/chrome/google-chrome"
CHROMEDRIVER_BIN="$CHROME_DIR/chromedriver"

# ── 1. Instala o Chrome ──────────────────────────────────────
if [ ! -f "$CHROME_BIN" ]; then
  echo "...Downloading Chrome..."
  mkdir -p $CHROME_DIR
  wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  dpkg -x google-chrome-stable_current_amd64.deb $CHROME_DIR
  rm google-chrome-stable_current_amd64.deb
  echo "...Chrome installed at $CHROME_BIN"
else
  echo "...Chrome already installed."
fi

# ── 2. Instala o ChromeDriver compatível ─────────────────────
if [ ! -f "$CHROMEDRIVER_BIN" ]; then
  echo "...Detecting Chrome version..."
  CHROME_VERSION=$("$CHROME_BIN" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
  CHROME_MAJOR=$(echo "$CHROME_VERSION" | cut -d. -f1)
  echo "   Chrome: $CHROME_VERSION (major: $CHROME_MAJOR)"

  echo "...Fetching matching ChromeDriver version..."
  # Chrome for Testing API (Chrome 115+)
  DRIVER_VERSION=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR}" 2>/dev/null || echo "")

  if [ -z "$DRIVER_VERSION" ]; then
    # Fallback: latest stable known version
    DRIVER_VERSION=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions.json" \
      | python3 -c "import json,sys; print(json.load(sys.stdin)['channels']['Stable']['version'])")
    echo "   Fallback to Stable: $DRIVER_VERSION"
  else
    echo "   ChromeDriver version: $DRIVER_VERSION"
  fi

  echo "...Downloading ChromeDriver $DRIVER_VERSION..."
  wget -q "https://storage.googleapis.com/chrome-for-testing-public/${DRIVER_VERSION}/linux64/chromedriver-linux64.zip" \
    -O /tmp/chromedriver.zip
  unzip -q /tmp/chromedriver.zip -d /tmp/
  mv /tmp/chromedriver-linux64/chromedriver "$CHROMEDRIVER_BIN"
  chmod +x "$CHROMEDRIVER_BIN"
  rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64

  echo "...ChromeDriver installed at $CHROMEDRIVER_BIN"
else
  echo "...ChromeDriver already installed."
fi

echo "Build complete."
