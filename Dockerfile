# The MIT License
#
#  Copyright (c) 2015-2020, CloudBees, Inc. and other Jenkins contributors
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
ARG JAVA_VERSION=17.0.6_10
FROM eclipse-temurin:"${JAVA_VERSION}"-jdk-alpine

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN addgroup -g "${gid}" "${group}" \
  && adduser -h /home/"${user}" -u "${uid}" -G "${group}" -D "${user}"

ARG AGENT_WORKDIR=/home/"${user}"/agent

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV TZ=Etc/UTC

## Always use the latest Alpine packages: no need for versions
# hadolint ignore=DL3018
RUN apk add --no-cache \
      curl \
      bash \
      git \
      git-lfs \
      musl-locales \
      openssh-client \
      openssl \
      procps \
      tzdata \
      tzdata-utils \
    && rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar* /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ARG VERSION=3107.v665000b_51092

ADD --chown="${user}":"${group}" "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar" /usr/share/jenkins/agent.jar
RUN chmod 0644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

USER "${user}"
ENV AGENT_WORKDIR="${AGENT_WORKDIR}"
RUN mkdir /home/"${user}"/.jenkins && mkdir -p "${AGENT_WORKDIR}"

WORKDIR /home/"${user}"
ENV user=${user}
LABEL \
    org.opencontainers.image.vendor="Jenkins project" \
    org.opencontainers.image.title="Official Jenkins Agent Base Docker image" \
    org.opencontainers.image.description="This is a base image, which provides the Jenkins agent executable (agent.jar)" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.url="https://www.jenkins.io/" \
    org.opencontainers.image.source="https://github.com/jenkinsci/docker-agent" \
    org.opencontainers.image.licenses="MIT"

ARG version=3107.v665000b_51092-5
LABEL Description="This is a base image, which allows connecting Jenkins agents via JNLP protocols" Vendor="Jenkins project" Version="$version"

ARG user=jenkins

USER root
COPY jenkins-agent /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent &&\
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

COPY apache-maven-3.9.1-bin.tar.gz .
RUN tar -zxf apache-maven-3.9.1-bin.tar.gz && \
     mv apache-maven-3.9.1 /usr/local && \
     rm -f apache-maven-3.9.1-bin.tar.gz && \
     ln -s /usr/local/apache-maven-3.9.1/bin/mvn /usr/bin/mvn && \
     ln -s /usr/local/apache-maven-3.9.1 /usr/local/apache-maven && \
     mkdir -p /usr/local/apache-maven/repo && \
     chmod 666 /usr/local/apache-maven/repo && \
     chown jenkins:jenkins /usr/local/apache-maven/repo

VOLUME /usr/local/apache-maven/repo
VOLUME /home/"${user}"/.jenkins
VOLUME "${AGENT_WORKDIR}"

COPY settings.xml /usr/local/apache-maven/conf/settings.xml

USER jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
