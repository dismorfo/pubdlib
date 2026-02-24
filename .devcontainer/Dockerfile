FROM ruby:2.7-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    libmariadb-dev \
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /workspaces/pubdlib

WORKDIR /workspaces/pubdlib

COPY Gemfile Gemfile.lock ./
RUN bundle install

CMD ["/bin/bash"]
