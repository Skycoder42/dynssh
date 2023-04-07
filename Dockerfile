FROM docker.io/library/dart:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart run build_runner build
RUN mkdir -p build/bin
RUN dart compile exe bin/dynssh.dart -o build/bin/dynssh

FROM scratch

COPY --from=build /runtime/ /
COPY --from=build /app/build /app
VOLUME /etc/dynssh

ENTRYPOINT [ "/app/bin/dynssh" ]

