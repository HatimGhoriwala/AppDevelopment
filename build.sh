#!/bin/bash
set -e  # Stop script if any command fails

# Install Java (OpenJDK 11)
apt-get update && apt-get install -y openjdk-11-jdk

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Define Android SDK paths
export ANDROID_HOME=$PWD/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# Create SDK directory if it doesn't exist
mkdir -p $ANDROID_HOME/cmdline-tools

# Download and extract Android SDK tools
wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O sdk-tools.zip
unzip -q sdk-tools.zip -d $ANDROID_HOME/cmdline-tools/

# Ensure correct folder structure
mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest

# Accept licenses
yes | sdkmanager --licenses || true

# Install required SDK components
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# Navigate to Android project directory
cd /opt/render/project/src/android-project || exit 1

# Give Gradle wrapper executable permissions
chmod +x gradlew
./gradlew assembleDebug
