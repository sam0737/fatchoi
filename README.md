# Deployment Information

## Upgrade

sui client upgrade --upgrade-capability 0xcc3ded817c7573c2bc3f90451680f4579b2d2ac73e4db3d0403e3fcb47cbde7a --skip-dependency-verification --dry-run

### Update

* ./contracts/fatchoi/Move.toml:published-at = "0x4d57d8b3e3450ec5d4c2fa5e5994b95512ab373538c8e59ea635c7ddaa3fbadf"
* ./README.md:Latest: 0x4d57d8b3e3450ec5d4c2fa5e5994b95512ab373538c8e59ea635c7ddaa3fbadf
* ./scripts/bucket_v1_restake.sh:    --package 0x4d57d8b3e3450ec5d4c2fa5e5994b95512ab373538c8e59ea635c7ddaa3fbadf \
* ./frontend/src/strategies/BucketV1.ts:  package: "0x4d57d8b3e3450ec5d4c2fa5e5994b95512ab373538c8e59ea635c7ddaa3fbadf",

## fatchoi contract

Base: 0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1
Latest: 0x4d57d8b3e3450ec5d4c2fa5e5994b95512ab373538c8e59ea635c7ddaa3fbadf

## Deposit

Type: 0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1::coin_bucket_v1::COIN_BUCKET_V1
Vault: 0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef
Clock: 0x6
BucketProtocol: 0x9e3dab13212b27f5434416939db5dec6a319d15b89a84fd074d03ece6350d3df
Flask: 0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8
Fountain: 0xbdf91f558c2b61662e5839db600198eda66d502e4c10c4fc5c683f9caca13359

## Collect Profit

Type: 0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1::coin_bucket_v1::COIN_BUCKET_V1
Vault: 0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef
Admin Cap: 0x93d1ebacfeef764a8d1f01bacf01339bdba083ca1bdc839e05c1ce060a3cb121

## Restake

Type 1: 0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1::coin_bucket_v1::COIN_BUCKET_V1
Type 2: 0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN

Vault: 0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef
Admin Cap: 0x93d1ebacfeef764a8d1f01bacf01339bdba083ca1bdc839e05c1ce060a3cb121
Clock: 0x6
Config: 0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f
Pool A: 0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630
Pool B: 0x81fe26939ed676dd766358a60445341a06cea407ca6f3671ef30f162c84126d5
BucketProtocol: 0x9e3dab13212b27f5434416939db5dec6a319d15b89a84fd074d03ece6350d3df
Flask: 0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8
Fountain: 0xbdf91f558c2b61662e5839db600198eda66d502e4c10c4fc5c683f9caca13359

sui client call --package 0x39e6a5b3d2d08bf81fa5973bd9e93c5155aac9327715585c422dd86bf950a978 \
--module bucket_v1 \
--function restake_protocol \
--type-args 0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1::coin_bucket_v1::COIN_BUCKET_V1 0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN \
--args 0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef 0x93d1ebacfeef764a8d1f01bacf01339bdba083ca1bdc839e05c1ce060a3cb121 0x6 0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f 0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630 0x81fe26939ed676dd766358a60445341a06cea407ca6f3671ef30f162c84126d5 0x9e3dab13212b27f5434416939db5dec6a319d15b89a84fd074d03ece6350d3df 0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8 0xbdf91f558c2b61662e5839db600198eda66d502e4c10c4fc5c683f9caca13359

# Strategy

## Navi

Supply: https://suiscan.xyz/mainnet/tx/9PNPeFYkNDW9MxVkYQwc74pGQuETUddKST3nm9VWDw5s
Claim Reward: https://suiscan.xyz/mainnet/tx/LSgfQZdCSABeDH1XrEYYEFL1aSzjYUdLSMpAcdaJJSx

## Bucket

sBUCK Flask Object: 0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8

Supply: 6zRujjakjpyGNijiXb7e1DqZ3ySA9YBGL8tDDpd6PYA1 (USDT to sBuck)
   Staking BUCK to sBUCK: 0x1798f84ee72176114ddbf5525a6d964c5f8ea1b3738d08d50d0d3de4cf584884::sbuck::deposit
   https://github.com/Sparkling-Finance/contract/blob/sbuck/flask/sources/sbuck.move

Fountain Object: 0xbdf91f558c2b61662e5839db600198eda66d502e4c10c4fc5c683f9caca13359

Staking ~1300 sBUCK for Sui Reward: 3EyWcue8AbtLwU7XQ6Bh5K34DAQHfZdGQ4fbUMMbH71M
    Stakeproof 1: 0xce5d18e52d0b1037ff1745f2112e0ce910e11c5c835bda0060cfec40384e1699
    https://github.com/Fountain-Fi/contract/blob/main/fountain/sources/fountain_core.move
    0x75b23bde4de9aca930d8c1f1780aa65ee777d8b33c3045b053a178b452222e82::fountain_core::stake

Unstaking ~300 sBUCK: ZP4ZZxio9BGuaSWuf4G8LxX5cirLJTTzfL275pcqcVE (unstake all/restake 1000)
    SP1 deleted
    Stakeproof 2: 0x0aa1042da9ec61f18cbb367d91911958ef6923c7ede9f2f46d69e9a1661d54db
Staking ~300 sBUCK: JDpA7LQcVakLSg17Uh5wrBitrgp8ST64jnxrve1tVoi5
    Stakeproof 3: 0xb0f1e97ddc431dd76c265244b298b39d44639465e3eb170b7cdc0b44ad9b1b4f
Unstake 1100 sBUCK: CNBQes5qcSLLFJWFfdGZbu1kxf1f9DLTz1hoXAoyGWex
    SP2, SP3 deleted
    Stakeproof 4: 0xd61034e05bfa497a45969d95013f1ba7df584456c59f5d6226b7fadd19e85c82


Claiming Sui Reward: FNCdFmqTDcuLG7T4ntF4pswrnKzUctv4Mr32vnX32SwF

Swapping Cetus SUI to USDC: 6GguybYWPv5bP64dZgvGFhT27ABBE5XGWVNBE9GvfcUE
Pool A: 0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630
Pool B: 0x81fe26939ed676dd766358a60445341a06cea407ca6f3671ef30f162c84126d5

Global Config: 0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f

https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-contract/features-available/swap-and-preswap

# Contract Design

## Buy
1. $T = $Fund / $Token_rate
2. mint $T, transfer to sender
3. $InvestingVault += $Fund

## Claim
1. User send $T to Contract, burnt.
2. ClaimWaitinglist[User] += $T

## Withdraw
1. Transfer ClaimableList[Sender] to Sender

## Execution
1. Claim all Rewards $R
2. Assert $R more than gas
3. Convert all Rewards to $Protocol_Base ($R_Base)
4. Reserve performance fee. $R_Net_Base = post performance fee of $R_Base
5. Unstake $U = Sum(ClaimWaitinglist)*$Token_rate/$Protocol_rate-$R_Net_Base-$InvestingVault
6. Merge $R_Net_Base, $InvestingVault into $U
7. ClaimableList[*] += ClaimWaitingList[*]*$Token_rate, clear ClaimWaitingList[*]
8. $Token_rate += $TVL + $R_Net_Base / $TVL
9. Stake $U to Protocol
10. $TVL += $U
