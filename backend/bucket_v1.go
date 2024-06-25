package main

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/block-vision/sui-go-sdk/models"
	"github.com/block-vision/sui-go-sdk/sui"
)

func main() {
	pairs := map[string]string{
		"0x488f1928b7a8616a07b135da8734e143a7c9b9ab51ef3917adffe1b9f40c23ef": "fcBUCKv1_SBUCK",
		"0xc6ecc9731e15d182bc0a46ebe1754a779a4bfb165c201102ad51a36838a1a7b8": "SBUCK_BUCK",
		"0xbb7f0d0974628c11fe1f33696247a9ffebf1f6ed67f78921633f9e2816141aa8": "USDC_BUCK",
		"0x1c400c096e8b52a22c43c080fea4aa22661c9a35b469493dfac5332aecb4789c": "USDC_USD",
	}

	object_ids := make([]string, 0, len(pairs))
	rates := make(map[string]float64)
	for p := range pairs {
		object_ids = append(object_ids, p)
	}

	// configure your endpoint here or use BlockVision's free Sui RPC endpoint
	cli := sui.NewSuiClient("https://fullnode.mainnet.sui.io")
	r, _ := cli.SuiMultiGetObjects(context.TODO(), models.SuiMultiGetObjectsRequest{
		ObjectIds: object_ids,
		Options: models.SuiObjectDataOptions{
			ShowContent: true,
			ShowType:    true,
		},
	})

	var total_holding, token_supply int
	for _, v := range r {
		f := v.Data.Content.Fields
		key, ok := pairs[v.Data.ObjectId]
		if !ok {
			continue
		}

		if _, ok := f["sbuck_supply"]; ok {
			rate := MustFloat64(f["reserves"].(string)) /
				MustFloat64(f["sbuck_supply"].(map[string]interface{})["fields"].(map[string]interface{})["value"].(string))
			rates[key] = rate
		} else if _, ok := f["value"]; ok {
			f2 := f["value"].(map[string]interface{})["fields"].(map[string]interface{})
			rate := MustFloat64(f2["value"].(string)) / math.Pow10(int(f2["decimal"].(float64)))
			rates[key] = rate
		} else {
			total_holding = MustInt(f["total_holding"].(string))
			token_supply = MustInt(f["token_supply"].(map[string]interface{})["fields"].(map[string]interface{})["value"].(string))
			rate := float64(total_holding) / float64(token_supply)
			rates[key] = rate
		}
	}
	rates["fcBUCKv1_USD"] = rates["fcBUCKv1_SBUCK"] * rates["SBUCK_BUCK"] / rates["USDC_BUCK"] * rates["USDC_USD"]

	result := map[string]interface{}{
		"timestamp":     time.Now().UnixNano() / int64(time.Millisecond),
		"rates":         rates,
		"total_holding": total_holding,
		"token_supply":  token_supply,
	}

	if jsonData, err := json.Marshal(result); err != nil {
		fmt.Println("Error marshaling to JSON:", err)
		return
	} else {
		fmt.Println(string(jsonData))
	}
}

func MustInt(s string) int {
	if n, err := strconv.Atoi(s); err != nil {
		panic(err)
	} else {
		return n
	}
}

func MustFloat64(s string) float64 {
	return float64(MustInt(s))
}
