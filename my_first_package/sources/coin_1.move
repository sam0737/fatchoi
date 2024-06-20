module my_first_package::coin_1 {
    use sui::coin;

    public struct COIN_1 has drop {}

    fun init(witness: COIN_1, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(witness, 6, b"fcT1", b"fatchoi Test 1", b"fatchoi Test Coin 1", option::none(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender())
    }
}