FROM ubuntu:14.04

MAINTAINER Aurelian Dumanovschi <aurasd@gmail.com>

ENV AGENT_DIR  /opt/buildAgent
ENV USER teamcity
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV JRE_HOME /usr/lib/jvm/java-8-oracle/jre
ENV GRADLE_HOME /opt/gradle
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_NDK_HOME /opt/android-sdk-linux/ndk-bundle
ENV NDK_HOME /opt/android-sdk-linux/ndk-bundle
ENV ANDROID_SDK_TOOLS_VERSION 3859397

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		lxc iptables aufs-tools ca-certificates curl wget software-properties-common language-pack-en \
	&& rm -rf /var/lib/apt/lists/*

# Fix locale.
ENV LANG en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
RUN locale-gen en_US && update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Install java-8-oracle
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
	&& echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections \
	&& add-apt-repository -y ppa:webupd8team/java \
	&& apt-get update \
  	&& apt-get install -y --no-install-recommends \
      oracle-java8-installer ca-certificates-java \
  	&& rm -rf /var/lib/apt/lists/* /var/cache/oracle-jdk8-installer/*.tar.gz /usr/lib/jvm/java-8-oracle/src.zip /usr/lib/jvm/java-8-oracle/javafx-src.zip \
      /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts \
  	&& ln -s /etc/ssl/certs/java/cacerts /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts \
  	&& update-ca-certificates

# Install docker
ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.12.6
ENV DOCKER_SHA256 cadc6025c841e034506703a06cf54204e51d0cadfae4bae62628ac648d82efdd
RUN set -x \
  && curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION.tgz" -o docker.tgz \
  && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
  && tar -xzvf docker.tgz \
  && mv docker/* /usr/local/bin/ \
  && rmdir docker \
  && rm docker.tgz \
  && docker -v

RUN groupadd docker && adduser --disabled-password --gecos "" teamcity \
	&& sed -i -e "s/%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/" /etc/sudoers \
	&& usermod -a -G docker,sudo $USER

# Install jq (from github, repo contains ancient version)
RUN curl -o /usr/local/bin/jq -SL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
	&& chmod +x /usr/local/bin/jq

# Install ruby build repositories
RUN apt-add-repository ppa:brightbox/ruby-ng \
	&& apt-get update \
    && apt-get upgrade -y \
	&& apt-get install -y ruby2.3 ruby2.3-dev ruby ruby-switch unzip \
	iptables lxc fontconfig libffi-dev build-essential git \
	&& rm -rf /var/lib/apt/lists/*

# Install fastlane
RUN ruby-switch --set ruby2.3
RUN gem install fastlane -NV --no-rdoc --no-ri

# Import the Let's Encrypt Authority certificate for Java to accept TeamCity server certificate
RUN curl -o /root/lets-encrypt.der https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.der \
 && $JRE_HOME/bin/keytool -trustcacerts -keystore $JRE_HOME/lib/security/cacerts -storepass changeit \
    -noprompt -importcert -alias lets-encrypt-x3-cross-signed -file /root/lets-encrypt.der \
 && rm /root/lets-encrypt.der

RUN mkdir -p $GRADLE_HOME
RUN mkdir -p $ANDROID_HOME

# Install Android command line tools
RUN wget -nc https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip \
    && unzip sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip -d $ANDROID_HOME \
    && rm sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip \
    && chmod +x $ANDROID_HOME/tools/android

# Install Android licenses to not accept them manually during builds
ADD licenses.tar.gz $ANDROID_HOME/

# Install ndk
RUN $ANDROID_HOME/tools/bin/sdkmanager "extras;google;m2repository" \
    && $ANDROID_HOME/tools/bin/sdkmanager "cmake;3.6.3155560" \
    && $ANDROID_HOME/tools/bin/sdkmanager "lldb;2.3" \
    && $ANDROID_HOME/tools/bin/sdkmanager "ndk-bundle" \
    && $ANDROID_HOME/tools/bin/sdkmanager "patcher;v4" \
    && chown -R $USER:$USER $ANDROID_HOME

# Install the magic wrapper.
ADD wrapdocker /usr/local/bin/wrapdocker
ADD docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /var/lib/docker
VOLUME /opt/buildAgent
VOLUME /opt/android-sdk-linux

EXPOSE 9090