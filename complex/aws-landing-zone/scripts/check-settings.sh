#!/bin/sh
# Prints the settings object of a deployment: ./check-settings.sh <bucket>
set -eu
aws s3 cp "s3://$1/configs/settings.json" - | python3 -m json.tool
