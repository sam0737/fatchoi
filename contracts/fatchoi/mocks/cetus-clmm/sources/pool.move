// Copyright (c) Cetus Technology Limited

#[allow(unused_type_parameter, unused_field)]
/// Concentrated Liquidity Market Maker (CLMM) is a new generation of automated market maker (AMM) aiming to improve
/// decentralized exchanges' capital efficiency and provide attractive yield opportunities for liquidity providers.
/// Different from the constant product market maker that only allows liquidity to be distributed uniformly across the
/// full price curve (0, `positive infinity`), CLMM allows liquidity providers to add their liquidity into specified price ranges.
/// The price in a CLMM pool is discrete, rather than continuous. The liquidity allocated into a specific price range
/// by a user is called a liquidity position.
///
/// "Pool" is the core module of Clmm protocol, which defines the trading pairs of "clmmpool".
/// All operations related to trading and liquidity are completed by this module.
module cetus_clmm::pool {
    use sui::clock::{Clock};
    use sui::balance::{Self, Balance};
    use cetus_clmm::config::GlobalConfig;

    // === Struct ===
    
    /// The clmmpool
    public struct Pool<phantom CoinTypeA, phantom CoinTypeB> has key, store {
        id: UID,
        numerator: u64,
        denominator: u64,
        pool_a: Balance<CoinTypeA>,
        pool_b: Balance<CoinTypeB>,
    }
    
    /// Flash loan resource for swap.
    /// There is no way in Move to pass calldata and make dynamic calls, but a resource can be used for this purpose.
    /// To make the execution into a single transaction, the flash loan function must return a resource
    /// that cannot be copied, cannot be saved, cannot be dropped, or cloned.
    public struct FlashSwapReceipt<phantom CoinTypeA, phantom CoinTypeB> {
        pay_amount: u64
    }

    /// Flash swap
    /// Params
    ///     - `config` The global config of clmm package.
    ///     - `pool` The clmm pool object.
    ///     - `a2b` One flag, if true, indicates that coin of `CoinTypeA` is exchanged with the coin of `CoinTypeB`,
    /// otherwise it indicates that the coin of `CoinTypeB` is exchanged with the coin of `CoinTypeA`.
    ///     - `by_amount_in` A flag, if set to true, indicates that the next `amount` parameter specifies
    /// the input amount, otherwise it specifies the output amount.
    ///     - `amount` The amount that indicates input or output.
    ///     - `sqrt_price_limit` Price limit, if the swap causes the price to it value, the swap will stop here and return
    ///     - `clock`
    public fun flash_swap<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        a2b: bool,
        _by_amount_in: bool,
        amount: u64,
        _sqrt_price_limit: u128,
        _clock: &Clock,
    ): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>) {
        if (a2b) {
            (balance::zero(), balance::split(&mut pool.pool_b, amount * pool.numerator / pool.denominator), FlashSwapReceipt{ pay_amount: amount })
        } else {
            (balance::split(&mut pool.pool_a, amount * pool.numerator / pool.denominator), balance::zero(), FlashSwapReceipt{ pay_amount: amount })
        }
    }

    /// Repay for flash swap
    /// Params
    ///     - `config` The global config of clmm package.
    ///     - `pool` The clmm pool object.
    ///     - `coin_a` The object of `CoinTypeA` will pay for flash_swap,
    /// if `a2b` is true the value need equal `receipt.pay_amount` else it need with zero value.
    ///     - `coin_b` The object of `CoinTypeB` will pay for flash_swap,
    /// if `a2b` is false the value need equal `receipt.pay_amount` else it need with zero value.
    ///     - `receipt` The receipt which will be destory.
    /// Returns
    ///     Null
    public fun repay_flash_swap<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        coin_a: Balance<CoinTypeA>,
        coin_b: Balance<CoinTypeB>,
        _receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>
    ) {
        balance::join(&mut pool.pool_a, coin_a);
        balance::join(&mut pool.pool_b, coin_b);
        let FlashSwapReceipt{ pay_amount: _ } = _receipt;
    }

    /// Get the swap pay amount
    public fun swap_pay_amount<CoinTypeA, CoinTypeB>(_receipt: &FlashSwapReceipt<CoinTypeA, CoinTypeB>): u64 {
        _receipt.pay_amount
    }

    #[test_only]
    public fun new_for_test<CoinTypeA, CoinTypeB>(numerator: u64, denominator: u64, ctx: &mut TxContext): Pool<CoinTypeA, CoinTypeB> {
        Pool<CoinTypeA, CoinTypeB>{ 
            id: object::new(ctx),
            numerator: numerator,
            denominator: denominator,
            pool_a: balance::create_for_testing(9223372036854775808),
            pool_b: balance::create_for_testing(9223372036854775808),
        }
    }
}