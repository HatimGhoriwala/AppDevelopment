FROM node:18

RUN apt-get update && \
    apt-get install -y openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

ENV ANDROID_HOME=/usr/local/android-sdk
RUN mkdir -p ${ANDROID_HOME} && \
    cd ${ANDROID_HOME} && \
    curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip sdk-tools.zip && \
    rm sdk-tools.zip && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
    mv cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/ && \
    yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

ENV PATH=$PATH:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/latest/bin

WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN chmod +x ./templates/gradlew
EXPOSE 3000
CMD ["node", "server.js"]