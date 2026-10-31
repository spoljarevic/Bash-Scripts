#!/bin/bash

_libraries=(
	lib/libQt5*.so.5
	/usr/lib/libwavpack.so.1
	"$STEAM_RUNTIME"/amd64/lib/x86_64-linux-gnu/libdbus-1.so.3
    "$STEAM_RUNTIME"/usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.4
    "$STEAM_RUNTIME"/usr/lib/x86_64-linux-gnu/libidn.so.11
    "$STEAM_RUNTIME"/lib/x86_64-linux-gnu/libgcrypt.so.11
    "$STEAM_RUNTIME"/usr/lib/x86_64-linux-gnu/librtmp.so.0
)

export LD_PRELOAD="${_libraries[*]}"

exec "$@" > ~/worms-stdout.log 2> ~/worms-stderr.log
