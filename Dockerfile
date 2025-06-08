FROM ruby:3.4

WORKDIR /app

RUN gem install bundler

COPY lib/mini_apivore/version.rb /app/lib/mini_apivore/version.rb
COPY mini-apivore.gemspec /app/
COPY Gemfile* /app/
COPY Rakefile /app/

RUN bundle install