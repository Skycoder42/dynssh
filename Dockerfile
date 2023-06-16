FROM docker.io/debian:stable AS dart-sdk
ARG TARGETPLATFORM

COPY tool/docker /tmp
RUN /tmp/dart.install.sh
ENV PUB_CACHE=/var/cache/pub
ENV PATH="$PATH:/opt/dart-sdk/bin:$PUB_CACHE/bin"

FROM dart-sdk AS build
WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart run build_runner build
RUN mkdir -p build/bin
RUN dart compile exe bin/dynssh.dart -o build/bin/dynssh

FROM docker.io/debian:stable-slim

RUN apt-get update && apt-get install -y openssh-client
COPY --from=build /app/build /app

ENTRYPOINT [ "/app/bin/dynssh" ]

