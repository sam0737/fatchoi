#!/bin/bash
cd "$(dirname "$0")"
script_name=$(basename "$0" .sh)

bin/bucket_v1 >> "${script_name}.$(date +%Y-%m).value"