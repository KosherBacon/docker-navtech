#!/bin/sh
set -ex

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for navcoind"

  set -- navcoind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "navcoind" ]; then
  mkdir -p "$NAVCOIN_DATA"
  chmod 700 "$NAVCOIN_DATA"
  chown -R navcoin "$NAVCOIN_DATA"

  echo "$0: setting data directory to $NAVCOIN_DATA"

  set -- "$@" -datadir="$NAVCOIN_DATA"
fi

if [ "$1" = "navcoind" ] || [ "$1" = "navcoin-cli" ] || [ "$1" = "navcoin-tx" ]; then
  echo
  exec su-exec navcoin "$@"
fi

echo
exec "$@"
