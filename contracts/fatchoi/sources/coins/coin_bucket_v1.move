module fatchoi::coin_bucket_v1 {
    use sui::coin;

    public struct COIN_BUCKET_V1 has drop {}

    fun init(witness: COIN_BUCKET_V1, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(witness, 9, b"fcBUCKv1", b"fatchoi Bucket v1", b"fatchoi Bucket v1 strategy token", option::none(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender())
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(COIN_BUCKET_V1 {}, ctx)
    }
}