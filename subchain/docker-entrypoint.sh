#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for navajoanonsubchaind"

  set -- navajoanonsubchaind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "navajoanonsubchaind" ]; then
  mkdir -p "$SUBCHAIN_DATA"
  chmod 700 "$SUBCHAIN_DATA"
  chown -R subchain "$SUBCHAIN_DATA"

  echo "$0: setting data directory to $SUBCHAIN_DATA"

  set -- "$@" -datadir="$SUBCHAIN_DATA"
fi

if [ "$1" = "navajoanonsubchaind" ]; then
  echo
  exec su-exec subchain "$@"
fi

echo
exec "$@"
