#!/bin/sh
set -eu

echo "Stage: PRE-Xcode Build running.... "

# for future reference
# https://developer.apple.com/documentation/xcode/environment-variable-reference

# Install dependencies via Homebrew for Xcode Cloud
echo "[Xcode Cloud] Installing dependencies via Homebrew..."

# Install Node.js if not available
if ! command -v node >/dev/null 2>&1; then
  echo "[Xcode Cloud] Installing Node.js via Homebrew..."
  brew install node
else
  echo "[Xcode Cloud] Node.js already available: $(node -v)"
fi

# Install pnpm if not available
if ! command -v pnpm >/dev/null 2>&1; then
  echo "[Xcode Cloud] Installing pnpm via Homebrew..."
  brew install pnpm
else
  echo "[Xcode Cloud] pnpm already available: $(pnpm -v)"
fi

# Install CocoaPods if not available
if ! command -v pod >/dev/null 2>&1; then
  echo "[Xcode Cloud] Installing CocoaPods via Homebrew..."
  brew install cocoapods
else
  echo "[Xcode Cloud] CocoaPods already available: $(pod --version)"
fi

# Store the repository root for later use
REPO_ROOT=$(cd ../../../.. && pwd)
echo "[Xcode Cloud] Repository root: $REPO_ROOT"

# Install JavaScript dependencies from monorepo root
echo "[Xcode Cloud] Installing JavaScript dependencies..."
cd "$REPO_ROOT"
echo "[Xcode Cloud] Current directory: $(pwd)"
pnpm install --frozen-lockfile
pnpm build:packages

# Navigate to FRW submodule for environment file generation
cd "$REPO_ROOT/apps/react-native/ios/FRW/App/Env/"
echo "[Xcode Cloud] Current directory for env files: $(pwd)" 

LOCAL_ENV_FILE=./LocalEnv

GOOGLE_OAUTH2_FILE_DEV=./Dev/GoogleOAuth2.plist
GOOGLE_SERVICE_FILE_DEV=./Dev/GoogleService-Info.plist
SERVICE_CONFIG_FILE_DEV=./Dev/ServiceConfig.plist

GOOGLE_OAUTH2_FILE_PROD=./Prod/GoogleOAuth2.plist
GOOGLE_SERVICE_FILE_PROD=./Prod/GoogleService-Info.plist
SERVICE_CONFIG_FILE_PROD=./Prod/ServiceConfig.plist


if [ ! -f $LOCAL_ENV_FILE ] 
then
	echo "Generating LocalEnv..."
	base64 -D -o $LOCAL_ENV_FILE <<< $LOCAL_ENV
fi

if [ ! -f $GOOGLE_OAUTH2_FILE_DEV ] 
then
	echo "DEV: Generating GoogleOAuth2..."
	base64 -D -o $GOOGLE_OAUTH2_FILE_DEV <<< $GOOGLE_OAUTH2_DEV
fi

if [ ! -f $GOOGLE_SERVICE_FILE_DEV ] 
then
	echo "DEV: Generating GoogleService-Info..."
	base64 -D -o $GOOGLE_SERVICE_FILE_DEV <<< $GOOGLE_SERVICE_DEV
fi

if [ ! -f $SERVICE_CONFIG_FILE_DEV ] 
then
	echo "DEV: Generating ServiceConfig..."
	base64 -D -o $SERVICE_CONFIG_FILE_DEV <<< $SERVICE_CONFIG_DEV
fi

if [ ! -f $GOOGLE_OAUTH2_FILE_PROD ] 
then
	echo "PROD: Generating GoogleOAuth2..."
	base64 -D -o $GOOGLE_OAUTH2_FILE_PROD <<< $GOOGLE_OAUTH2_PROD
fi

if [ ! -f $GOOGLE_SERVICE_FILE_PROD ] 
then
	echo "PROD: Generating GoogleService-Info..."
	base64 -D -o $GOOGLE_SERVICE_FILE_PROD <<< $GOOGLE_SERVICE_PROD
fi

if [ ! -f $SERVICE_CONFIG_FILE_PROD ] 
then
	echo "PROD: Generating ServiceConfig..."
	base64 -D -o $SERVICE_CONFIG_FILE_PROD <<< $SERVICE_CONFIG_PROD
fi


echo "[Xcode Cloud] Installing iOS dependencies..."

# Go back to React Native app directory for bundling
cd "$REPO_ROOT/apps/react-native"
echo "[Xcode Cloud] Current directory for bundling: $(pwd)"
pnpm bundle:ios

# Go to iOS directory and install pods
cd "$REPO_ROOT/apps/react-native/ios"
echo "[Xcode Cloud] Current directory for CocoaPods: $(pwd)"

# Ensure correct bundler version is available
echo "[Xcode Cloud] Installing correct bundler version..."
if ! command -v bundle >/dev/null 2>&1; then
  echo "[Xcode Cloud] Installing bundler via Homebrew..."
  brew install ruby
fi

# Install the specific bundler version required by Gemfile.lock to user directory
gem install bundler:2.7.1 --user-install -N

# Install Ruby gems
echo "[Xcode Cloud] Installing Ruby dependencies..."
bundle install || {
  echo "[Xcode Cloud] Bundle install failed, trying to update bundler..."
  bundle update --bundler
  bundle install
}

# Install CocoaPods dependencies
echo "[Xcode Cloud] Installing CocoaPods dependencies..."
bundle exec pod install --repo-update

echo "Stage: PRE-Xcode Build is completed..."

exit 0
