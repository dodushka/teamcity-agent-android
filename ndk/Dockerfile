FROM auras/teamcity-android-agent:latest

LABEL maintainer="Aurelian Dumanovschi <aurasd@gmail.com>"

ENV ANDROID_NDK_HOME /opt/android-sdk-linux/ndk-bundle
ENV NDK_HOME /opt/android-sdk-linux/ndk-bundle

RUN apt-get update \
	&& apt-get install -y --no-install-recommends build-essential \
    && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install ndk	# Install ndk
RUN $ANDROID_HOME/tools/bin/sdkmanager "cmake;3.6.4111459" \	
    && $ANDROID_HOME/tools/bin/sdkmanager "lldb;2.3" \	
    && $ANDROID_HOME/tools/bin/sdkmanager "ndk-bundle" \	
    && chown -R $USER:$USER $ANDROID_HOME