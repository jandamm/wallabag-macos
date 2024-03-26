#!/bin/zsh

echo "extension API.Telemetry {
	// This is set by the CI pipeline.
	// Use your own if you fork this project
	static let appID = \"$1\"
}" > Wallabag/Telemetry+AppID.swift
