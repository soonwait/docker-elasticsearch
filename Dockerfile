FROM alpine:latest

# Update image and install base packages
RUN apk update && \
    apk upgrade && \
    apk add bash curl openjdk8 openssl && \
    rm -rf /var/cache/apk/*

# Install elasticsearch user
RUN adduser -D -u 1000 -h /usr/share/elasticsearch elasticsearch


#FROM docker.elastic.co/elasticsearch/elasticsearch-alpine-base:latest
LABEL maintainer="Elastic Docker Team <docker@elastic.co>"

ARG ELASTIC_VERSION=5.3.0
ARG ES_DOWNLOAD_URL=https://artifacts.elastic.co/downloads/elasticsearch
ARG ES_JAVA_OPTS

ENV PATH /usr/share/elasticsearch/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk

WORKDIR /usr/share/elasticsearch

# Download/extract defined ES version. busybox tar can't strip leading dir.
#https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.3.0.tar.gz
RUN wget ${ES_DOWNLOAD_URL}/elasticsearch-${ELASTIC_VERSION}.tar.gz && \
    EXPECTED_SHA=$(wget -O - ${ES_DOWNLOAD_URL}/elasticsearch-${ELASTIC_VERSION}.tar.gz.sha1) && \
    test $EXPECTED_SHA == $(sha1sum elasticsearch-${ELASTIC_VERSION}.tar.gz | awk '{print $1}') && \
    tar zxf elasticsearch-${ELASTIC_VERSION}.tar.gz && \
    chown -R elasticsearch:elasticsearch elasticsearch-${ELASTIC_VERSION} && \
    mv elasticsearch-${ELASTIC_VERSION}/* . && \
    rmdir elasticsearch-${ELASTIC_VERSION} && \
    rm elasticsearch-${ELASTIC_VERSION}.tar.gz

RUN set -ex && for esdirs in config data logs; do \
        mkdir -p "$esdirs"; \
        chown -R elasticsearch:elasticsearch "$esdirs"; \
    done

# Install analysis-ik
# install like this version less then 5.5.1
# https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v5.3.0/elasticsearch-analysis-ik-5.3.0.zip
RUN wget https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v${ELASTIC_VERSION}/elasticsearch-analysis-ik-${ELASTIC_VERSION}.zip
RUN ls . && \
    ls ./plugins && \
    mkdir -p ./plugins/ik && \
    unzip -o elasticsearch-analysis-ik-${ELASTIC_VERSION}.zip -d ./plugins/ik && \
    chown -R elasticsearch:elasticsearch ./plugins/ik && \
    rm -f elasticsearch-analysis-ik-${ELASTIC_VERSION}.zip

USER elasticsearch
# Install xpack
#RUN eval ${ES_JAVA_OPTS:-} elasticsearch-plugin install --batch x-pack

# Install analysis-ik
# install like this version great than 5.5.1
#RUN eval ${ES_JAVA_OPTS:-} elasticsearch-plugin install --batch https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v${ELASTIC_VERSION}/elasticsearch-analysis-ik-${ELASTIC_VERSION}.zip
#RUN wget https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v5.3.0/elasticsearch-analysis-ik-5.3.0.zip

COPY elasticsearch.yml config/
COPY log4j2.properties config/
COPY bin/es-docker bin/es-docker

USER root
RUN chown elasticsearch:elasticsearch config/elasticsearch.yml config/log4j2.properties bin/es-docker &&     chmod 0750 bin/es-docker

USER elasticsearch
CMD ["/bin/bash", "bin/es-docker"]

EXPOSE 9200 9300
