#!/bin/bash
set -e

if [[ $TARGET_VERSION -eq 21 ]]; then
    if [[ $BUILD_IOS ]]; then
        git clone --branch jdk-21.0.8+7 --depth 1 https://github.com/openjdk/jdk21u openjdk-21
    else
        # The latest jdk21u release, with its security updates; the Android patch set is rebased on it.
        git clone --branch jdk-21.0.13.1-ga --depth 1 https://github.com/openjdk/jdk21u openjdk-21
    fi
else
    git clone --depth 1 https://github.com/openjdk/jdk17u openjdk-17
fi
