#!/bin/bash
set -eo pipefail

echo ::group::Setup SSH
sudo service ssh start

mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519

touch ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

cat ~/.ssh/id_ed25519.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "Host integration_test_local
    HostName x.x.x.x
    User $USER
    IdentityFile ~/.ssh/id_ed25519
" > ~/.ssh/config
chmod 600 ~/.ssh/config
echo ::endgroup::

echo ::group::Compile dynssh
sudo dart compile exe bin/dynssh.dart -o /usr/local/bin/dynssh
echo ::endgroup::
