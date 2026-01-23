#!/bin/bash

TARGET_PATH=/usr/share/containers/systemd/

echo "Creating a directory $TARGET_PATH"
mkdir -p $TARGET_PATH

echo "Copying *.container files"
cp *.container $TARGET_PATH
echo "Files copied"

echo "Listing files:"
ls -la $TARGET_PATH

echo "Reloading systemd daemon"
systemctl --user daemon-reload
