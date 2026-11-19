# Builder images: https://hub.docker.com/r/hexpm/elixir/tags?name=alpine
# Runner images: https://hub.docker.com/_/alpine?tab=tags
ARG ELIXIR_VERSION=1.20.5
ARG OTP_VERSION=29.1.2
ARG ALPINE_VERSION=3.22.8

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

ARG APP_VERSION=0.0.42

# install build dependencies
RUN apk add --no-cache build-base openssl ncurses-libs nodejs npm git

# https://stackoverflow.com/questions/52894632/cannot-install-pycosat-on-alpine-during-dockerizing
RUN echo "#include <unistd.h>" > /usr/include/sys/unistd.h

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"
ENV MIX_OS_DEPS_COMPILE_PARTITION_COUNT=4

# set app version
ENV APP_VERSION=${APP_VERSION}

RUN echo "APP_VERSION=${APP_VERSION}"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# install asset dependencies
COPY assets/package.json assets/package-lock.json assets/
RUN mix assets.setup

COPY priv priv
COPY lib lib
COPY assets assets
COPY docs docs
COPY README.md README.md

# Compile the release
RUN mix compile

# Compile assets
RUN mix assets.deploy

RUN mix sentry.package_source_code

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apk add --no-cache libstdc++ openssl ncurses-libs ca-certificates

# Set the locale
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/data_aggregator ./

USER nobody

CMD ["/app/bin/server"]
