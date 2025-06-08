#!/bin/bash
set -e

# Clé GitHub stockée dans un fichier temporaire
mkdir -p ~/.ssh_tmp
ssh-keyscan github.com > ~/.ssh_tmp/known_hosts

# Git utilisera ce fichier temporaire
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/root/.ssh_tmp/known_hosts"

# Clone si pas déjà fait
[ ! -d ~/famine ] && git clone git@github.com:Zerrino/famine ~/famine || true

exec bash

