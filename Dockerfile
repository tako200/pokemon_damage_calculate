FROM ruby:4.0 AS base

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*


# 初回ビルド
# docker build --target rails-new -t rails-new .
FROM base AS rails-new

RUN gem install rails

# 実行場所は最上位のディレクトリ
# docker run --rm -v "$PWD/app:/app" rails-new
CMD ["rails", "new", ".", "--database=postgresql"]


# 通常ビルド
# docker build --target development -t rails-app .
FROM base AS development

COPY app/Gemfile app/Gemfile.lock ./

RUN bundle install

COPY app .

CMD ["rails", "server", "-b", "0.0.0.0"]