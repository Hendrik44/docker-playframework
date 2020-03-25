# AlpineLinux with a glibc-2.25-r0 and Oracle Java 7
FROM alpine:3.6

MAINTAINER David Fernandez <dfernandez@socialmetrix.com>
# AKA @rdavix, this version is a fork of docker-alpine-java, but with alpine 3.5 and glibc 2.25

# Java Version and other ENV
ENV JAVA_VERSION_MAJOR=7 \
    JAVA_VERSION_MINOR=80 \
    JAVA_VERSION_BUILD=15 \
    JAVA_PACKAGE=jdk \
    JAVA_JCE=standard \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    GLIBC_VERSION=2.25-r0 \
    LANG=C.UTF-8

# do all in one step
COPY jdk-7u80-linux-x64.tar.gz /tmp/
RUN set -ex && \
    apk upgrade --update && \
    apk add --update libstdc++ curl ca-certificates bash wget gzip tar && \
    update-ca-certificates && \
   for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    mkdir /opt && \
    gunzip /tmp/jdk-7u80-linux-x64.tar.gz && \
    tar -C /opt -xf /tmp/jdk-7u80-linux-x64.tar && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" >&2 && \
      curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
        http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security; \
    fi && \
    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security && \
    apk del curl glibc-i18n && \
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar \
           /tmp/* /var/cache/apk/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

RUN mkdir -p /app

RUN apk upgrade \
      && apk --no-cache add --virtual build-dependencies unzip \
      && apk --no-cache add curl python

ENV PLAY_VERSION 1.2.7.2

RUN curl --location -s https://downloads.typesafe.com/play/${PLAY_VERSION}/play-${PLAY_VERSION}.zip > /tmp/play-${PLAY_VERSION}.zip \
      && unzip -q /tmp/play-${PLAY_VERSION}.zip -d /opt \
      && rm -rf /tmp/play-${PLAY_VERSION}.zip \
            /opt/play-${PLAY_VERSION}/COPYING \
            /opt/play-${PLAY_VERSION}/documentation \
            /opt/play-${PLAY_VERSION}/framework/test \
            /opt/play-${PLAY_VERSION}/play.bat \
            /opt/play-${PLAY_VERSION}/python/*.dll \
            /opt/play-${PLAY_VERSION}/python/python.* \
            /opt/play-${PLAY_VERSION}/README.textile \
            /opt/play-${PLAY_VERSION}/samples \
            /opt/play-${PLAY_VERSION}/support

RUN apk del --purge build-dependencies \
      && rm -fr /var/cache/apk/*

ENV PATH /opt/play-${PLAY_VERSION}:$PATH

WORKDIR /app

EXPOSE 9000

CMD ["play"]
