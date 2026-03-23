#!/usr/bin/env sh
set -eu

mkdir -p /paperclip/instances/default
chown -R node:node /paperclip

if command -v su >/dev/null 2>&1; then
  exec su node -s /bin/sh -c 'exec node --import ./server/node_modules/tsx/dist/loader.mjs server/dist/index.js'
fi

if command -v runuser >/dev/null 2>&1; then
  exec runuser -u node -- node --import ./server/node_modules/tsx/dist/loader.mjs server/dist/index.js
fi

echo "Neither su nor runuser is available in the container" >&2
exit 1
