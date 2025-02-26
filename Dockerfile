FROM node:18

# Install dependencies
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Set Java environment (correct path for Debian-based node:18)
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Set Android SDK environment
ENV ANDROID_HOME=/usr/local/android-sdk
ENV PATH=$PATH:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/latest/bin

# Install Android SDK
WORKDIR /tmp
RUN mkdir -p ${ANDROID_HOME} && \
    curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm sdk-tools.zip && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/ && \
    yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Set up application
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN chmod +x ./templates/gradlew

# Expose port
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]