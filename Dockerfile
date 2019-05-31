FROM hashicorp/terraform:0.11.14 AS terraform

FROM ruby:2.5-alpine

# Install pre-requisites for building unf_ext gem
RUN apk --update add --virtual build_deps \
    build-base ruby-dev libc-dev linux-headers

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install --without development test

COPY lib ./lib
COPY bin ./bin
COPY main.tf .

COPY --from=terraform bin/terraform /app/bin/terraform
