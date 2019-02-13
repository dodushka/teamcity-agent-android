FROM auras/teamcity-android-agent:latest

LABEL maintainer="Aurelian Dumanovschi <aurasd@gmail.com>"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libpulse0 libx11-6 libgl1-mesa-glx mesa-utils pciutils \
    && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Prepare for the emulator
RUN mkdir $ANDROID_HOME/system-images \
    && mkdir /home/$USER/.android \
    && mkdir /home/$USER/.android/avd \
    && ln -s $ANDROID_HOME/system-images /home/$USER/.android/avd/system-images \
    && chown -R $USER:$USER $ANDROID_HOME \
    && chown -R $USER:$USER /home/$USER/.android

# Install the emulator updater.
COPY update-emulator.sh /update-emulator.sh
RUN chmod +x /update-emulator.sh

ENTRYPOINT ["/update-emulator.sh"]