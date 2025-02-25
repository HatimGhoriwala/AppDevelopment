#!/bin/bash
set -e  # Stop script if any command fails

# Define local installation paths inside the project directory
export ANDROID_HOME=$PWD/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# Create SDK directory inside the project
mkdir -p $ANDROID_HOME

# Download and extract Android SDK tools inside project directory
wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
unzip commandlinetools-linux-8512546_latest.zip -d $ANDROID_HOME
mkdir -p $ANDROID_HOME/cmdline-tools/latest
mv $ANDROID_HOME/cmdline-tools $ANDROID_HOME/cmdline-tools/latest

# Accept Android SDK licenses
yes | sdkmanager --licenses || true

# Install required SDK components
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# Setup Gradle Wrapper
cd /app/android-project || exit 1
chmod +x gradlew
./gradlew assembleDebug
