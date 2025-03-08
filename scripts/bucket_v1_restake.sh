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
    --package 0x4d57d8b3e3450ec5d4c2fa5e5994b95512ab373538c8e59ea635c7ddaa3fbadf \
    --module bucket_v1 --function restake_protocol_v3 \
    --type-args 0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1::coin_bucket_v1::COIN_BUCKET_V1 0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC \
    --args 0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef 0x93d1ebacfeef764a8d1f01bacf01339bdba083ca1bdc839e05c1ce060a3cb121 0x6 0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f \
    0xb8d7d9e66a60c239e7a60110efcf8de6c705580ed924d0dde141f4a0e2c90105 0x4c50ba9d1e60d229800293a4222851c9c3f797aa5ba8a8d32cc67ec7e79fec60 \
    0x9e3dab13212b27f5434416939db5dec6a319d15b89a84fd074d03ece6350d3df 0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8 0xbdf91f558c2b61662e5839db600198eda66d502e4c10c4fc5c683f9caca13359 \
    2>&1 >${script_name}.out || { echo "sui call failed, stopping future runs." >&2; touch ${script_name}.stop; exit 1; }