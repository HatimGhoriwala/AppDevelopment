FROM node:18

# Install dependencies (curl, unzip, and Java)
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Set Android SDK environment
ENV ANDROID_HOME=/usr/local/android-sdk
ENV PATH=$PATH:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/latest/bin

# Install Android SDK
WORKDIR /tmp
RUN mkdir -p ${ANDROID_HOME} && \
    curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip sdk-tools.zip -d ${ANDROID_HOME} && \
    rm sdk-tools.zip && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
    mv ${ANDROID_HOME}/cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/ || true && \
    yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0" || { echo "sdkmanager failed"; exit 1; }

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