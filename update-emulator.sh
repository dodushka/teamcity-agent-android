#!/bin/bash
if [ -n "$EMULATOR_PLATFORM" ]; then
    export EMULATOR_PACKAGE="system-images;$EMULATOR_PLATFORM;$EMULATOR_VARIANT;$EMULATOR_ABI"
    export EMULATOR_VARIANT_ABI="$EMULATOR_VARIANT/$EMULATOR_ABI"
    echo "Updating emulator package $EMULATOR_PACKAGE"
    $ANDROID_HOME/tools/bin/sdkmanager "emulator"
    $ANDROID_HOME/tools/bin/sdkmanager "platforms;$EMULATOR_PLATFORM"
    $ANDROID_HOME/tools/bin/sdkmanager "$EMULATOR_PACKAGE"
    chown -R $USER:$USER $ANDROID_HOME
    chown $USER:$USER /dev/kvm
fi

./docker-entrypoint.sh