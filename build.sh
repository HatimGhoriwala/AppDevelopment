#!/bin/bash

set -e  # Stop script if any command fails

# Install dependencies
apt-get update && apt-get install -y wget unzip

# Setup Android SDK
export ANDROID_SDK_ROOT=/opt/android-sdk
mkdir -p $ANDROID_SDK_ROOT
cd $ANDROID_SDK_ROOT

wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
unzip commandlinetools-linux-8512546_latest.zip -d $ANDROID_SDK_ROOT
mv cmdline-tools tools
mkdir cmdline-tools/latest
mv tools cmdline-tools/latest

export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH

# Install SDK components
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# Setup Gradle
cd /app/android-project
chmod +x gradlew
./gradlew assembleDebug
