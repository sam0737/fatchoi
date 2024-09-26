import { useSuiClientQuery } from "@mysten/dapp-kit";

const c = {
  coin: {
    token: "0x8227925a95d62bffa724e2ce9d00a5ead3516a3cb2618a93ba9a4ee5ebd554c1::coin_bucket_v1::COIN_BUCKET_V1",
    BUCK: "0xce7ff77a83ea0cb6fd39bd8748e2ec89a3f41e8efdc3f4eb123e0ca37b184db2::buck::BUCK",
    USDC: "0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN"
  },
  package: "0xaf3ec272be57a3a76a4fdd41d3e9947fa40ae85dd6ce7811dab5144ac9d85898",
  module: "bucket_v1",
  vault: "0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef",
  flask: "0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8",
  fountain: "0xbdf91f558c2b61662e5839db600198eda66d502e4c10c4fc5c683f9caca13359",
}

export default c
export function GetData() {
  let pairs: Record<string, string> = {
    [c.vault]: "fcBUCKv1_SBUCK",
    "0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8": "SBUCK_BUCK",
    "0xbb7f0d0974628c11fe1f33696247a9ffebf1f6ed67f78921633f9e2816141aa8": "USDC_BUCK",
    "0x1c400c096e8b52a22c43c080fea4aa22661c9a35b469493dfac5332aecb4789c": "USDC_USD",
  }

  let rates: Record<string, number> = {}

  let { data, error } = useSuiClientQuery(
    "multiGetObjects",
    {
      ids: Object.keys(pairs),
      options:
      {
        showContent: true,
        showType: true,
      }
    },
    {
      refetchInterval: 60000
    }
  )

  if (error || !data) {
    return {rates: null, tvl: null};
  }

  data.map((v, _) => {
    let f = (v.data?.content as { fields: any })?.fields;
    let id = v.data?.objectId as string
    if (!f || !(id in pairs)) return;
    let rate = f?.sbuck_supply ? Number(f.reserves) / Number(f.sbuck_supply.fields.value) :
      f?.value?.fields.value ? Number(f.value.fields.value) / Math.pow(10, f.value.fields.decimal) :
        Number(f.total_holding) / Number(f.token_supply.fields.value)
    rates[pairs[id]] = rate
  })

  let vault = (data[0].data?.content as { fields: any })?.fields
  let tvl = vault.total_holding / Math.pow(10, 9) * rates["fcBUCKv1_SBUCK"] * rates["SBUCK_BUCK"] / rates["USDC_BUCK"] * rates["USDC_USD"]
  return {rates, tvl}
}