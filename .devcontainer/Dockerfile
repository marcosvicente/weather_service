ARG RUBY_VERSION=3.2.10
FROM ruby:${RUBY_VERSION}-bookworm

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev libvips-dev libyaml-dev nodejs npm pkg-config postgresql-client sudo && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 vscode && \
    useradd --uid 1000 --gid vscode --create-home --shell /bin/bash vscode && \
    echo "vscode ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

WORKDIR /workspace
USER vscode
