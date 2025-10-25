# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.7
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Add Bundler bin to PATH so Rails commands work without bundle exec
ENV PATH="/usr/local/bundle/bin:$PATH"

# ============================================================
# 🏗️ Build Stage (compile gems and assets)
# ============================================================
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips pkg-config libyaml-dev dos2unix

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# ✅ Ensure Windows line endings are converted (safety for Windows users)
RUN dos2unix ./bin/*

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ============================================================
# 🧰 Final Runtime Stage
# ============================================================
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client dos2unix && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems and application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# ✅ Double-safety: convert any CRLF line endings that might sneak in
RUN dos2unix /rails/bin/*

# Create and set permissions for the 'rails' user (non-root)
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]