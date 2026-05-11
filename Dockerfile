# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=28
ARG DEBIAN_VERSION=bookworm-20241016-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ---------- Build stage ----------
FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y \
 && apt-get install -y build-essential git curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.setup
RUN mix assets.deploy
RUN mix compile

COPY config/runtime.exs config/

RUN mix release

# ---------- Runtime stage ----------
FROM ${RUNNER_IMAGE}

RUN apt-get update -y \
 && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

WORKDIR /app
ENV MIX_ENV="prod" PHX_SERVER="true"

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/soiree_plateau ./

USER nobody

EXPOSE 4000

CMD ["/app/bin/soiree_plateau", "start"]
