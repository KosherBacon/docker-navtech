#!/bin/sh
set -e

exec su-exec navcoin navcoind -daemon
