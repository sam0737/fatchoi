#!/bin/bash
PATH=$PATH:/home/linuxbrew/.linuxbrew/bin

cd "$(dirname "$0")"
script_name=$(basename "$0" .sh)

# Check if the stop file exists
# if [ -f "${script_name}.stop" ]; then
#   echo "last run failed" >&2
#   exit 1
# fi

sui client call \
    --package 0xaf3ec272be57a3a76a4fdd41d3e9947fa40ae85dd6ce7811dab5144ac9d85898 \
    --module bucket_v1 --function restake_protocol \
    --type-args 0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1::coin_bucket_v1::COIN_BUCKET_V1 0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN --args 0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef 0x93d1ebacfeef764a8d1f01bacf01339bdba083ca1bdc839e05c1ce060a3cb121 0x6 0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f 0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630 0x81fe26939ed676dd766358a60445341a06cea407ca6f3671ef30f162c84126d5 0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8 0xbdf91f558c2b61662e5839db600198eda66d502e4c10c4fc5c683f9caca13359 \
    2>&1 >${script_name}.out || { echo "sui call failed, stopping future runs." >&2; touch ${script_name}.stop; exit 1; }
