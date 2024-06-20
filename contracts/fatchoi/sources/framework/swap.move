module fatchoi::swap {
    use cetus_clmm::config::GlobalConfig;
    use cetus_clmm::pool::{Self, Pool};
    use sui::clock::Clock;
    use sui::balance::{Self, Balance};

    public(package) fun swap<CoinTypeA, CoinTypeB>(
        config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        mut balance_a: Balance<CoinTypeA>,
        mut balance_b: Balance<CoinTypeB>,
        a2b: bool,
        clock: &Clock
    ): (Balance<CoinTypeA>, Balance<CoinTypeB>) {        
        let amount = if (a2b) balance::value(&balance_a) else balance::value(&balance_b);
        if (amount == 0) {
            return (balance_a, balance_b)
        };

        // Reference: https://cetus-1.gitbook.io/cetus-developer-docs/developer/via-contract/features-available/swap-and-preswap
        let (mut receive_a, mut receive_b, flash_receipt) = pool::flash_swap<CoinTypeA, CoinTypeB>(
            config,
            pool,
            a2b,
            true, // by amount in
            amount,
            if (a2b) 4295048016 else 79226673515401279992447579055, // sqrt_price_limit
            clock
        );
        let fee_amount = pool::swap_pay_amount(&flash_receipt);
        
        // pay for flash swap
        let (pay_coin_a, pay_coin_b) = if (a2b) {
            (balance::split(&mut balance_a, fee_amount), balance::zero<CoinTypeB>())
        } else {
            (balance::zero<CoinTypeA>(), balance::split(&mut balance_b, fee_amount))
        };

        balance::join(&mut receive_a, balance_a);
        balance::join(&mut receive_b, balance_b);

        pool::repay_flash_swap<CoinTypeA, CoinTypeB>(
            config,
            pool,
            pay_coin_a,
            pay_coin_b,
            flash_receipt
        );

        (receive_a, receive_b)
    }

    #[test]
    fun test_swap() {
        use sui::test_scenario;
        use sui::test_utils;

        let initial_owner = @0xA;

        let mut scenario = test_scenario::begin(initial_owner);
        let config = cetus_clmm::config::new_global_config_for_test(scenario.ctx());
        let mut pool = cetus_clmm::pool::new_for_test<sui::sui::SUI, fatchoi::coin_bucket_v1::COIN_BUCKET_V1>(scenario.ctx());
        let clock = sui::clock::create_for_testing(scenario.ctx());
        
        {
            let (balance_a, balance_b) = swap(&config, &mut pool, balance::create_for_testing(100), balance::zero(), true, &clock);
            assert!(balance::value(&balance_a) == 0, 0);
            assert!(balance::value(&balance_b) == 1000, 0);
            balance::destroy_for_testing(balance_a);
            balance::destroy_for_testing(balance_b);
        };
        
        {
            let (balance_a, balance_b) = swap(&config, &mut pool, balance::zero(), balance::create_for_testing(100), false, &clock);
            assert!(balance::value(&balance_a) == 1000, 0);
            assert!(balance::value(&balance_b) == 0, 0);
            balance::destroy_for_testing(balance_a);
            balance::destroy_for_testing(balance_b);
        };

        test_utils::destroy(config);
        test_utils::destroy(pool);
        test_utils::destroy(clock);

        scenario.end();
    }    
}