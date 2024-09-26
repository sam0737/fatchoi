module fatchoi::bucket_v1 {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use cetus_clmm::config::GlobalConfig;
    use cetus_clmm::pool::Pool;
    use sui::clock::Clock;
    use fatchoi::math;
    use sui::balance::{Self, Balance, Supply};
    use flask::sbuck::{Flask, SBUCK};
    use bucket_protocol::buck::{BUCK, BucketProtocol};
    use fountain::fountain_core::{Fountain, StakeProof};
    
    const ERR_FUNCTION_DEPRECATED: u64 = 99;
    const ERR_WRONG_VERSION: u64 = 1001;
    const ERR_INVALID_ADMIN_CAP: u64 = 1002;
    const ERR_INSUFFICIENT_BALANCE: u64 = 1003;
    const ERR_UNSTAKE_SANITY_CHECK: u64 = 1004;
    const ERR_SWAP_CLEAR_INTERMEDIATE: u64 = 1005;
    const ERR_SWAP_CLEAR_SOURCE: u64 = 1006;

    const VERSION: u64 = 5;
    const PROFIT_TARGET: u64 = 1000000000;

    public struct Vault<phantom T> has key {
        id: UID,
        version: u64,
        token_supply: Supply<T>,

        total_holding: u64,
        holding: vector<StakeProof<SBUCK, SUI>>,

        profit_target: u64,
        profit: Balance<SUI>,
    }

    // deprecated event
    #[allow(unused_field)]
    public struct DepositEvent<phantom T> has copy, drop {
        vault_id: ID,
        amount: u64,
        minted: u64,
        before: u64,
        after: u64,
    }

    // deprecated event
    #[allow(unused_field)]
    public struct WithdrawEvent<phantom T> has copy, drop {
        vault_id: ID,
        burnt: u64,
        amount: u64,
        before: u64,
        after: u64,
    }

    // deprecated event
    #[allow(unused_field)]
    public struct RestakeEvent<phantom T> has copy, drop {
        vault_id: ID,
        before: u64,
        after: u64,
    }

    public struct Deposit has copy, drop {
        vault_id: ID,
        amount: u64,
        minted: u64,
        before: u64,
        after: u64,
    }

    public struct Withdraw has copy, drop {
        vault_id: ID,
        burnt: u64,
        amount: u64,
        before: u64,
        after: u64,
    }

    public struct Restake has copy, drop {
        vault_id: ID,
        before: u64,
        after: u64,
    }

    public struct AdminCap has key, store {
        id: UID,
        vault_id: ID,
    }

    public fun create<T>(token_treasury: coin::TreasuryCap<T>, ctx: &mut TxContext): (Vault<T>, AdminCap) {
        let vault = Vault<T> {
            id: object::new(ctx),
            version: VERSION,
            token_supply: coin::treasury_into_supply(token_treasury),
            holding: vector::empty(),
            total_holding: 0,
            profit_target: PROFIT_TARGET,
            profit: balance::zero(),
        };
        let admin_cap = AdminCap { id: object::new(ctx), vault_id: object::id(&vault) };
        (vault, admin_cap)
    }

    #[allow(lint(share_owned))]
    entry fun create_entry<T>(token_treasury: coin::TreasuryCap<T>, ctx: &mut TxContext) {
        let (vault, admin_cap) = create(token_treasury, ctx);
        transfer::share_object(vault);
        transfer::transfer(admin_cap, ctx.sender());
    }

    public fun collect_profit<T>(
        vault: &mut Vault<T>,
        admin_cap: &AdminCap
        ): Balance<SUI> {
        assert_pacakge_version(vault);
        assert_admin_cap(vault, admin_cap);
        vault.profit.withdraw_all()
    }

    entry fun collect_profit_entry<T>(vault: &mut Vault<T>, admin_cap: &AdminCap, ctx: &mut TxContext) {
        let profit = collect_profit(vault, admin_cap);
        transfer::public_transfer(coin::from_balance(profit, ctx), ctx.sender());
    }

    #[deprecated]
    #[allow(unused_variable)]
    public fun deposit<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        deposit: Balance<BUCK>,
        ctx: &mut TxContext
        ): Balance<T> {
        abort ERR_FUNCTION_DEPRECATED
    }

    fun deposit_v2<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        bucket_protocol: &mut BucketProtocol,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        deposit: Balance<BUCK>,
        ctx: &mut TxContext
        ): Balance<T> {
        assert_pacakge_version(vault);

        let deposit_amount = deposit.value();
        let sbucks = bucket_protocol.buck_to_sbuck(flask, clock, deposit);
        let amount = if (vault.total_holding > 0) {
            math::mul_factor(sbucks.value(), vault.token_supply.supply_value(), vault.total_holding)
        } else {
            sbucks.value()
        };

        let before = vault.total_holding;
        vault.total_holding = vault.total_holding + sbucks.value();
        vault.stake_protocol(clock, fountain, sbucks, ctx);

        event::emit(Deposit {
            vault_id: object::id(vault),
            amount: deposit_amount,
            minted: amount,
            before: before,
            after: vault.total_holding,
        });
        vault.token_supply.increase_supply(amount)
    }

    entry fun deposit_entry<T>(vault: &mut Vault<T>, clock: &Clock, bucket_protocol: &mut BucketProtocol, flask: &mut Flask<BUCK>, fountain: &mut Fountain<SBUCK, SUI>, deposit: Coin<BUCK>, ctx: &mut TxContext) {
        let balance = deposit_v2(vault, clock, bucket_protocol, flask, fountain, deposit.into_balance(), ctx);
        transfer::public_transfer(coin::from_balance(balance, ctx), ctx.sender());
    }
    
    #[deprecated]
    #[allow(unused_variable)]
    public fun withdraw<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        withdraw: Balance<T>,
        ctx: &mut TxContext
        ): Balance<BUCK> {
        abort ERR_FUNCTION_DEPRECATED
    }

    
    fun withdraw_v2<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        bucket_protocol: &mut BucketProtocol,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        withdraw: Balance<T>,
        ctx: &mut TxContext
        ): Balance<BUCK> {
        assert_pacakge_version(vault);
        assert!(withdraw.value() <= vault.token_supply.supply_value(), ERR_INSUFFICIENT_BALANCE);

        let (mut sbucks, suis) = vault.unstake_protocol(clock, fountain);
        vault.profit.join(suis);

        let mut amount = math::mul_factor(withdraw.value(), sbucks.value(), vault.token_supply.supply_value());
        if (amount > sbucks.value()) {
            amount = sbucks.value()
        };
        let withdraw_balance = sbucks.split(amount);
        let before = vault.total_holding;
        vault.total_holding = sbucks.value();

        vault.stake_protocol(clock, fountain, sbucks, ctx);
        let burnt_amount = withdraw.value();
        vault.token_supply.decrease_supply(withdraw);
        let bucks = bucket_protocol.sbuck_to_buck(flask, clock, withdraw_balance);

        event::emit(Withdraw {
            vault_id: object::id(vault),
            burnt: burnt_amount,
            amount: bucks.value(),
            before: before,
            after: vault.total_holding,
        });
        bucks
    }

    entry fun withdraw_entry<T>(vault: &mut Vault<T>, clock: &Clock, bucket_protocol: &mut BucketProtocol, flask: &mut Flask<BUCK>, fountain: &mut Fountain<SBUCK, SUI>, withdraw: Coin<T>, ctx: &mut TxContext) {
        let balance = withdraw_v2(vault, clock, bucket_protocol, flask, fountain, withdraw.into_balance(), ctx);
        transfer::public_transfer(coin::from_balance(balance, ctx), ctx.sender());
    }

    fun stake_protocol<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        fountain: &mut Fountain<SBUCK, SUI>,
        input: Balance<SBUCK>,
        ctx: &mut TxContext
        ) {
        if (input.value() > 0) {
            let stake_proof = fountain::fountain_core::stake(clock, fountain, input, 4838400000, ctx);
            vault.holding.push_back(stake_proof);
        } else {
            input.destroy_zero()
        }
    }

    fun unstake_protocol<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        fountain: &mut Fountain<SBUCK, SUI>
        ): (Balance<SBUCK>, Balance<SUI>) {

        let mut sbucks = balance::zero<SBUCK>();
        let mut suis = balance::zero<SUI>();

        // Unstake from fountain
        while (vault.holding.is_empty() == false) {
            let stake_proof = vault.holding.pop_back();
            let (sbuck, sui) = fountain::fountain_core::force_unstake(clock, fountain, stake_proof);
            sbucks.join(sbuck);
            suis.join(sui);
        };

        assert!(vault.total_holding == sbucks.value(), ERR_UNSTAKE_SANITY_CHECK);
        (sbucks, suis)
    }

    

    #[deprecated]
    #[allow(unused_variable)]
    public entry fun restake_protocol<T, X>(
        vault: &mut Vault<T>,
        admin_cap: &AdminCap,
        clock: &Clock,
        config: &GlobalConfig,
        pool_a: &mut Pool<X, SUI>,
        pool_b: &mut Pool<BUCK, X>,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        ctx: &mut TxContext
        ) {
        abort ERR_FUNCTION_DEPRECATED
    }

    public entry fun restake_protocol_v2<T, X>(
        vault: &mut Vault<T>,
        admin_cap: &AdminCap,
        clock: &Clock,
        config: &GlobalConfig,
        pool_a: &mut Pool<X, SUI>,
        pool_b: &mut Pool<BUCK, X>,
        bucket_protocol: &mut BucketProtocol,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        ctx: &mut TxContext
        ) {
        assert_pacakge_version(vault);
        assert_admin_cap(vault, admin_cap);

        let (mut sbucks, suis) = vault.unstake_protocol(clock, fountain);
        vault.profit.join(suis);
    
        // profit is reserved for admin, then the remaining is converted to SBUCKS and restaked
        if (vault.profit.value() > vault.profit_target) {
            let delta = vault.profit.value() - vault.profit_target;
            let suis = vault.profit.split(delta);

            // swap SUIs to BUCKs
            let (xs, suis) = fatchoi::swap::swap(config, pool_a, balance::zero(), suis, false, clock);
            let (bucks, xs) = fatchoi::swap::swap(config, pool_b, balance::zero(), xs, false, clock);
            assert!(xs.value() == 0, ERR_SWAP_CLEAR_INTERMEDIATE);
            xs.destroy_zero();
            assert!(suis.value() == 0, ERR_SWAP_CLEAR_SOURCE);
            suis.destroy_zero();

            if (bucks.value() > 0) {
                sbucks.join(bucket_protocol.buck_to_sbuck(flask, clock, bucks));
            } else {
                bucks.destroy_zero();
            };
        };

        let before = vault.total_holding;
        vault.total_holding = sbucks.value();
        event::emit(Restake {
            vault_id: object::id(vault),
            before: before,
            after: vault.total_holding,
        });
        vault.stake_protocol(clock, fountain, sbucks, ctx);
    }

    public entry fun upgrade_protocol<T>(
        vault: &mut Vault<T>,
        admin_cap: &AdminCap)
    {
        assert_admin_cap(vault, admin_cap);
        assert!(vault.version < VERSION, ERR_WRONG_VERSION);
        vault.version = VERSION
    }

    fun assert_admin_cap<T>(
        vault: &Vault<T>,
        admin_cap: &AdminCap
        ) {
        assert!(object::id(vault) == admin_cap.vault_id, ERR_INVALID_ADMIN_CAP);
    }

    fun assert_pacakge_version<T>(vault: &Vault<T>) {
        assert!(vault.version == VERSION, ERR_WRONG_VERSION);
    }

    #[test]
    fun test_flask() {
        use sui::test_scenario;
        let alice = @0xA1CE;
        let bob = @0xB0B;

        let mut scenario = test_scenario::begin(alice);
        let (mut vault, admin_cap, mut flask, mut fountain, fountain_admin_cap, clock) = test_init(&mut scenario);
        {
            scenario.next_tx(alice);
            let a_bal = vault.deposit(&clock, &mut flask, &mut fountain, balance::create_for_testing(1000), scenario.ctx());
            assert!(a_bal.value() == 1000, 404);
            flask.collect_rewards(balance::create_for_testing(100));

            scenario.next_tx(bob);
            let b_bal = vault.deposit(&clock, &mut flask, &mut fountain, balance::create_for_testing(2000), scenario.ctx());
            assert!(b_bal.value() == 1818, 404);

            scenario.next_tx(alice);
            let a_rbal = vault.withdraw(&clock, &mut flask, &mut fountain, a_bal, scenario.ctx());
            assert!(a_rbal.value() == 1100, 404);
            a_rbal.destroy_for_testing();

            scenario.next_tx(bob);
            let b_rbal = vault.withdraw(&clock, &mut flask, &mut fountain, b_bal, scenario.ctx());
            assert!(b_rbal.value() == 2000, 404);
            b_rbal.destroy_for_testing()
        };
        test_destroy(vault, admin_cap, flask, fountain, fountain_admin_cap, clock);
        scenario.end();
    }

    #[test]
    fun test_fountain() {
        use sui::test_scenario;
        use sui::test_utils;
        let alice = @0xA1CE;
        let bob = @0xB0B;

        let mut scenario = test_scenario::begin(alice);
        let (mut vault, admin_cap, mut flask, mut fountain, fountain_admin_cap, mut clock) = test_init(&mut scenario);
        {
            scenario.next_tx(alice);
            let mut a_bal = vault.deposit(&clock, &mut flask, &mut fountain, balance::create_for_testing(1000), scenario.ctx());
            assert!(a_bal.value() == 1000, 404);

            scenario.next_tx(bob);
            let b_bal = vault.deposit(&clock, &mut flask, &mut fountain, balance::create_for_testing(2000), scenario.ctx());
            assert!(b_bal.value() == 2000, 404);

            fountain::fountain_core::supply(&clock, &mut fountain, balance::create_for_testing(301 * PROFIT_TARGET));
            clock.increment_for_testing(100000 * PROFIT_TARGET / 1000);

            scenario.next_tx(alice);
            let a_rbal_1 = vault.withdraw(&clock, &mut flask, &mut fountain, a_bal.split(250), scenario.ctx());
            assert!(a_rbal_1.value() == 250, 404);
            a_rbal_1.destroy_for_testing();
            assert!(vault.profit.value() == 301 * PROFIT_TARGET, 404);

            let config = cetus_clmm::config::new_global_config_for_test(scenario.ctx());
            let mut pool_a = cetus_clmm::pool::new_for_test<fatchoi::coin_bucket_v1::COIN_BUCKET_V1, sui::sui::SUI>(1, 1, scenario.ctx());
            let mut pool_b = cetus_clmm::pool::new_for_test<BUCK, fatchoi::coin_bucket_v1::COIN_BUCKET_V1>(11, 10 * PROFIT_TARGET, scenario.ctx());
            vault.restake_protocol(&admin_cap, &clock, &config, &mut pool_a, &mut pool_b, &mut flask, &mut fountain, scenario.ctx());
            assert!(vault.profit.value() == 1 * PROFIT_TARGET, 404);

            let a_rbal_2 = vault.withdraw(&clock, &mut flask, &mut fountain, a_bal, scenario.ctx());
            assert!(a_rbal_2.value() == 750+90, 404);
            a_rbal_2.destroy_for_testing();

            scenario.next_tx(bob);
            let b_rbal = vault.withdraw(&clock, &mut flask, &mut fountain, b_bal, scenario.ctx());
            assert!(b_rbal.value() == 2000+240, 404);
            b_rbal.destroy_for_testing();

            test_utils::destroy(config);
            test_utils::destroy(pool_a);
            test_utils::destroy(pool_b)
        };
        test_destroy(vault, admin_cap, flask, fountain, fountain_admin_cap, clock);
        scenario.end();
    }

    #[test_only]
    fun test_init(scenario: &mut sui::test_scenario::Scenario):
        (Vault<fatchoi::coin_bucket_v1::COIN_BUCKET_V1>, AdminCap, Flask<BUCK>, Fountain<SBUCK, SUI>, fountain::fountain_core::AdminCap, Clock) {
        use flask::sbuck;
        use sui::test_scenario;
        use fatchoi::coin_bucket_v1::{Self, COIN_BUCKET_V1};

        let dummy = @0xD1E;

        scenario.next_tx(dummy);
        {
            coin_bucket_v1::test_init(scenario.ctx());
            sbuck::init_for_testing(scenario.ctx())
        };

        scenario.next_tx(dummy);
        {
            let cap = test_scenario::take_from_sender<coin::TreasuryCap<SBUCK>>(scenario);
            sbuck::initialize<BUCK>(cap, scenario.ctx())
        };

        scenario.next_tx(dummy);
        let treasurycap = test_scenario::take_from_sender<coin::TreasuryCap<COIN_BUCKET_V1>>(scenario);
        let flask = test_scenario::take_shared<Flask<BUCK>>(scenario);
        let clock = sui::clock::create_for_testing(scenario.ctx());
        let (mut fountain, fountain_admin_cap) = fountain::fountain_core::new_fountain_with_admin_cap<SBUCK, SUI>(1000000000, 1000, 100000, 4838400000, clock.timestamp_ms(), scenario.ctx());
        fountain::fountain_core::new_penalty_vault(&fountain_admin_cap, &mut fountain, 0);
        let (vault, admin_cap) = create(treasurycap, scenario.ctx());

        (vault, admin_cap, flask, fountain, fountain_admin_cap, clock)
    }

    #[test_only]
    fun test_destroy(
        vault: Vault<fatchoi::coin_bucket_v1::COIN_BUCKET_V1>,
        admin_cap: AdminCap,
        flask: Flask<BUCK>,
        fountain: Fountain<SBUCK, SUI>,
        fountain_admin_cap: fountain::fountain_core::AdminCap,
        clock: Clock
        ) {
        use sui::test_utils;

        test_utils::destroy(admin_cap);
        test_utils::destroy(fountain_admin_cap);
        test_utils::destroy(flask);
        test_utils::destroy(vault);
        clock.destroy_for_testing();
        fountain.destroy_fountain_for_testing();
    }
}
