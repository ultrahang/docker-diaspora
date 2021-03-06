FROM ruby:2.4-slim-stretch

LABEL maintainer="ultrahang"
LABEL source="https://github.com/ultrahang/docker-diaspora"

ARG DIASPORA_VER=0.8.0.0

ENV RAILS_ENV=production \
    UID=942 \
    GID=942

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libxslt-dev \
    imagemagick \
    ghostscript \
    curl \
    libmagickwand-dev \
    git \
    libpq-dev \
    nodejs \
    wget \
    libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup --GID ${GID} diaspora \
    && adduser --uid ${UID} --gid ${GID} \
    --home /diaspora --shell /bin/sh \
    --disabled-password --gecos "" diaspora

USER diaspora

WORKDIR /diaspora
RUN git clone -b master https://github.com/diaspora/diaspora.git
RUN mv /diaspora/diaspora/* /diaspora/
RUN mkdir /diaspora/log \
    && cp config/database.yml.example config/database.yml

RUN gem install bundler \
    && script/configure_bundler \
    && bin/bundle install --full-index -j$(getconf _NPROCESSORS_ONLN)

VOLUME /diaspora/public
