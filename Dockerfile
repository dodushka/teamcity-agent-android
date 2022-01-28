FROM jetbrains/teamcity-minimal-agent:latest
USER root
LABEL maintainer="Aurelian Dumanovschi <aurasd@gmail.com>"

ARG JDK_URL='https://corretto.aws/downloads/resources/11.0.14.9.1/amazon-corretto-11.0.14.9.1-linux-x64.tar.gz'
ARG MD5SUM='bc1bc7203435fb7eaca360f581af73f3'

ENV USER teamcity
ENV GRADLE_USER_HOME /opt/gradle
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_TOOLS_VERSION 6200805
ENV SHELL /bin/bash
ENV PATH "$ANDROID_HOME/emulator:$PATH"
ENV PATH "$ANDROID_HOME/platform-tools:$PATH"
ENV PATH "$ANDROID_HOME/tools/bin:$PATH"
ENV PATH "$ANDROID_HOME/tools:$PATH"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget file language-pack-en unzip lxc curl\
    && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

#Install firebase
RUN yes | curl -sL https://firebase.tools | bash


# Create user
RUN adduser --disabled-password --gecos "" $USER \
	&& usermod -a -G sudo $USER

# Fix locale.
ENV LANG en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
RUN locale-gen en_US && update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

# Configure gradle
RUN mkdir -p $GRADLE_USER_HOME \
    && chmod 777 $GRADLE_USER_HOME
COPY gradle.properties $GRADLE_USER_HOME/gradle.properties

# Install Android command line tools
RUN mkdir -p $ANDROID_HOME \
    && chmod 777 $ANDROID_HOME \
    && wget -nc https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip \
    && unzip commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -d $ANDROID_HOME \
    && rm commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip \
    && chmod +x $ANDROID_HOME/tools

# Install Android licenses to not accept them manually during builds
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} --licenses

# Install ndk
RUN $ANDROID_HOME/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} "extras;google;m2repository" \
    && $ANDROID_HOME/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME}  "extras;google;google_play_services" \
    && $ANDROID_HOME/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} "patcher;v4" \
    && chown -R $USER:$USER $ANDROID_HOME


