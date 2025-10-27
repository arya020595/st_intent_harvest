# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.7
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim

# Rails app lives here
WORKDIR /rails

# Set development environment (can be overridden at runtime)
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    PATH="/rails/bin:/usr/local/bundle/bin:$PATH"

# Install packages needed for development and runtime
# Includes dos2unix for Windows line ending support and bash
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    bash \
    build-essential \
    git \
    libpq-dev \
    libvips \
    pkg-config \
    libyaml-dev \
    dos2unix \
    curl \
    postgresql-client \
    vim \
    nano \
    less && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems (do this before copying app code for better caching)
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Fix line endings for all scripts (Windows compatibility)
# Convert line endings first, then make executable
RUN find ./bin -type f -exec dos2unix {} \; 2>/dev/null || true && chmod +x ./bin/*

# Precompile bootsnap for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Create necessary directories with proper permissions
# Run as root to avoid Windows volume mount permission issues
RUN mkdir -p tmp/pids tmp/sockets tmp/cache log storage && \
    chmod -R 777 tmp log storage

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]