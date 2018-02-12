FROM jetbrains/teamcity-agent:10.0.3

# Install Google Cloud SDK

RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

RUN sudo apt-get update && sudo apt-get install -y google-cloud-sdk && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true

ARG sdk_version=sdk-tools-linux-3859397.zip
ARG android_home=/opt/android/sdk

# SHA-256 444e22ce8ca0f67353bda4b85175ed3731cae3ffa695ca18119cbacef1c1bea0

RUN sudo apt-get update && \
    sudo apt-get install --yes \
        xvfb gcc-multilib lib32z1 lib32stdc++6 build-essential \
        libcurl4-openssl-dev libglu1-mesa libxi-dev libxmu-dev \
        libglu1-mesa-dev

# Download and install Android SDK
RUN sudo mkdir -p ${android_home} && \
    curl --silent --show-error --location --fail --retry 3 --output /tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
    unzip -q /tmp/${sdk_version} -d ${android_home} && \
    rm /tmp/${sdk_version}

# Set environmental variables
ENV ANDROID_HOME ${android_home}
ENV ADB_INSTALL_TIMEOUT 120
ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg

RUN yes | sdkmanager --licenses && sdkmanager --update

# Update SDK manager and install system image, platform and build tools
RUN sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator" \
  "extras;android;m2repository" \
  "extras;google;m2repository" \
  "extras;google;google_play_services"

RUN sdkmanager \
  "build-tools;25.0.0" \
  "build-tools;25.0.1" \
  "build-tools;25.0.2" \
  "build-tools;25.0.3" \
  "build-tools;26.0.1" \
  "build-tools;26.0.2" \
  "build-tools;27.0.0" \
  "build-tools;27.0.1" \
  "build-tools;27.0.2" \
  "build-tools;27.0.3"

RUN sdkmanager "platforms;android-27"

# Fastlane
RUN sudo apt-get install ruby ruby-dev ruby-build
RUN sudo gem install fastlane
