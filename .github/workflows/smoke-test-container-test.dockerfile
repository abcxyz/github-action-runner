FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get -y install file wget ca-certificates curl jq coreutils gnupg --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
