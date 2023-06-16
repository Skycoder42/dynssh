#!/bin/bash
set -eo pipefail

case "$TARGETPLATFORM" in
  linux/amd64 | linux/amd64/*)
    dart_platform=x64
  ;;
  linux/arm64 | linux/arm64/*)
    dart_platform=arm64
  ;;
  linux/arm | linux/arm/*)
    dart_platform=arm
  ;;
  linux/386 | linux/386/*)
    dart_platform=ia32
  ;;
  *)
    echo "UNSUPPORTED DOCKER PLATFORM: $TARGETPLATFORM"
    exit 1
  ;;
esac

echo "Detected dart platform for $TARGETPLATFORM as: $dart_platform"

apt-get update
apt-get install -y wget unzip

archive_name="dartsdk-linux-$dart_platform-release.zip"
download_url="https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/$archive_name"

cd /tmp
wget "$download_url"
wget "$download_url.sha256sum"
sha256sum -c "$archive_name.sha256sum"

unzip "$archive_name" -d /opt

mkdir -p /var/cache/pub
