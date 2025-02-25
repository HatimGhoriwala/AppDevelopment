#!/bin/bash
set -e  # Stop script if any command fails

# Create directory for Java
mkdir -p $PWD/jdk

# Download and extract AdoptOpenJDK (now Eclipse Temurin)
wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.18%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.18_10.tar.gz -O jdk.tar.gz
tar -xzf jdk.tar.gz -C $PWD/jdk --strip-components=1

# Set JAVA_HOME to extracted JDK
export JAVA_HOME=$PWD/jdk
export PATH=$JAVA_HOME/bin:$PATH

# Verify Java installation
java -version

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