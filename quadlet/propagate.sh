#!/bin/bash

TARGET_PATH=/usr/share/containers/systemd/

mkdir -p $TARGET_PATH
cp *.container $TARGET_PATH
