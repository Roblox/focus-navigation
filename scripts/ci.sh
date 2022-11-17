#!/bin/bash

set -x

echo "Install dependencies"
rotrieve install

echo "Run linting and formatting"
roblox-cli analyze --project tests.project.json
selene src
stylua -c src

echo "Run tests"
roblox-cli run --load.model tests.project.json --run scripts/run-tests.lua --fastFlags.overrides EnableLoadModule=true
