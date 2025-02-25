#!/bin/bash
set -e  # Stop script if any command fails

echo "🚀 Starting Build Process..."

# 🟢 Step 1: Install Java JDK
echo "📦 Setting up Java JDK..."
mkdir -p $PWD/jdk

if [ ! -f "jdk.tar.gz" ]; then
  wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.18%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.18_10.tar.gz -O jdk.tar.gz
fi

tar -xzf jdk.tar.gz -C $PWD/jdk --strip-components=1

export JAVA_HOME=$PWD/jdk
export PATH=$JAVA_HOME/bin:$PATH

echo "✅ Java Version:"
java -version || { echo "❌ ERROR: Java setup failed!"; exit 1; }

# 🟢 Step 2: Install Gradle (if missing)
echo "📦 Checking for Gradle installation..."
if ! command -v gradle &>/dev/null; then
  echo "⚠️ Gradle not found! Installing Gradle..."
  wget https://services.gradle.org/distributions/gradle-8.3-bin.zip -O gradle.zip
  mkdir -p /opt/gradle
  unzip -q gradle.zip -d /opt/gradle
  export PATH="/opt/gradle/gradle-8.3/bin:$PATH"
  echo "✅ Gradle Installed Successfully!"
fi

echo "✅ Gradle Version:"
gradle -v || { echo "❌ ERROR: Gradle installation failed!"; exit 1; }

# 🟢 Step 3: Setup Android SDK
echo "📦 Setting up Android SDK..."
export ANDROID_HOME=$PWD/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

mkdir -p $ANDROID_HOME/cmdline-tools

if [ ! -f "sdk-tools.zip" ]; then
  wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O sdk-tools.zip
fi

unzip -q sdk-tools.zip -d $ANDROID_HOME/cmdline-tools/

# Fix folder structure
mv -f $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest || true

# Accept Licenses
yes | sdkmanager --licenses || true

# Install required SDK components
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# 🟢 Step 4: Navigate to Android Project
ANDROID_PROJECT_DIR="/opt/render/project/src/android-project"

echo "📁 Navigating to Android project directory: $ANDROID_PROJECT_DIR"
mkdir -p $ANDROID_PROJECT_DIR
cd $ANDROID_PROJECT_DIR || { echo "❌ ERROR: Failed to access Android project directory!"; exit 1; }

# 🟢 Step 5: Generate `gradlew` if missing
if [ ! -f "gradlew" ]; then
  echo "⚠️ WARNING: 'gradlew' not found! Initializing Gradle Wrapper..."
  
  # Ensure there's a Gradle project structure
  if [ ! -f "build.gradle" ] && [ ! -f "settings.gradle" ] && [ ! -d "app" ]; then
    echo "❌ ERROR: No Android Gradle project found! Exiting..."
    exit 1
  fi

  # Initialize Gradle Wrapper
  gradle wrapper || { echo "❌ ERROR: Failed to generate Gradle Wrapper!"; exit 1; }
fi

# 🟢 Step 6: Build the Android App
echo "🔨 Giving Gradle permissions & building project..."
chmod +x gradlew
./gradlew assembleDebug || { echo "❌ ERROR: Gradle build failed!"; exit 1; }

echo "✅ Build completed successfully!"
