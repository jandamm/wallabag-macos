#!/usr/bin/env bash

if [[ $SWIFT_ACTIVE_COMPILATION_CONDITIONS =~ DEBUG ]]; then
	exit 0 # It's okay for DEBUG builds
fi

file='Wallabag/Telemetry+AppID.swift'
if grep -E '^\s*static let appID = ""' $file ; then
	echo "error: No App ID for Telemetry Deck set. See $file."
	exit 42
fi
