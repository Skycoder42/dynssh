#!/bin/bash
set -eo pipefail

with_docker=$1

echo ::group::Setup SSH
# sudo service ssh start

mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519

ssh-keyscan localhost > ~/.ssh/known_hosts
ssh-keyscan aur.archlinux.org >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

cat ~/.ssh/id_ed25519.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

cat << EOF > ~/.ssh/config.template
Host test.dynssh.skycoder42.de
    HostName localhost
    User $USER
    IdentityFile ~/.ssh/id_ed25519

Host forbidden.test.dynssh.skycoder42.de
    HostName aur.archlinux.org
EOF
chmod 600 ~/.ssh/config.template
echo ::endgroup::

if [ "$with_docker" == 'true' ]; then
    echo ::group::Build docker image
    docker build -t local/dynssh --build-arg TARGETPLATFORM=linux/amd64 .
    echo ::endgroup::
fi
