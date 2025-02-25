#!/bin/bash

# Update system and install Java
apt-get update && apt-get install -y openjdk-17-jdk wget unzip

# Set Java environment variables
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Install Gradle
wget https://services.gradle.org/distributions/gradle-8.3-bin.zip
unzip gradle-8.3-bin.zip -d /opt/
export PATH=/opt/gradle-8.3/bin:$PATH

# Install Android SDK
mkdir -p /opt/android-sdk
cd /opt/android-sdk
wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
unzip commandlinetools-linux-8512546_latest.zip -d tools
export ANDROID_HOME=/opt/android-sdk
export PATH=$ANDROID_HOME/tools/bin:$PATH
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.1"

# Build APK
cd /app/android-project
./gradlew assembleDebug
