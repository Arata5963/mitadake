# 本番環境用Dockerfile
# マルチステージビルドで軽量なイメージを作成

ARG RUBY_VERSION=3.3.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# ランタイムパッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl ca-certificates libjemalloc2 libvips imagemagick libpq5 \
    python3 python3-pip && \
    update-ca-certificates && \
    pip3 install --break-system-packages youtube-transcript-api && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 環境変数設定
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test" \
    RAILS_SERVE_STATIC_FILES="1"

# ビルドステージ
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# 最終ステージ
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# 非rootユーザーで実行（セキュリティ）
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["bash", "-c", "bin/rails server -b 0.0.0.0 -p ${PORT:-3000}"]
