// Copyright (c) Cetus Technology Limited

#[allow(unused_field)]
/// The global config module is used for manage the `protocol_fee`, acl roles, fee_tiers and package version of the cetus clmmpool protocol.
/// The `protocol_fee` is the protocol fee rate, it will be charged when user swap token.
/// The `fee_tiers` is a map, the key is the tick spacing, the value is the fee rate. the fee_rate can be same for
/// different tick_spacing and can be updated.
/// For different types of pair, we can use different tick spacing. Basically, for stable pair we can use small tick
/// spacing, for volatile pair we can use large tick spacing.
/// the fee generated of a swap is calculated by the following formula:
/// total_fee = fee_rate * swap_in_amount.
/// protocol_fee = total_fee * protocol_fee_rate / 1000000
/// lp_fee = total_fee - protocol_fee
/// Also, the acl roles is managed by this module, the roles is used for control the access of the cetus clmmpool
/// protocol.
/// Currently, we have 5 roles:
/// 1. PoolManager: The pool manager can update pool fee rate, pause and unpause the pool.
/// 2. FeeTierManager: The fee tier manager can add/remove fee tier, update fee tier fee rate.
/// 3. ClaimProtocolFee: The claim protocol fee can claim the protocol fee.
/// 4. PartnerManager: The partner manager can add/remove partner, update partner fee rate.
/// 5. RewarderManager: The rewarder manager can add/remove rewarder, update rewarder fee rate.
/// The package version is used for upgrade the package, when upgrade the package, we need increase the package version.
module cetus_clmm::config {
    public struct GlobalConfig has key, store {
        id: UID
    }

    #[test_only]
    public fun new_global_config_for_test(ctx: &mut TxContext): GlobalConfig {
        GlobalConfig { id: object::new(ctx) }
    }
}