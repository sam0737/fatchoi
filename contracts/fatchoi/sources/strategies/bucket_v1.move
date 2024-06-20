module fatchoi::bucket_v1 {
    use sui::coin;
    use sui::sui::SUI;
    use cetus_clmm::config::GlobalConfig;
    use cetus_clmm::pool::Pool;
    use sui::clock::Clock;
    use fatchoi::math;
    use sui::balance::{Self, Balance, Supply};
    use flask::sbuck::{Self, Flask, SBUCK};
    use bucket_protocol::buck::{BUCK};
    use fountain::fountain_core::{Fountain, StakeProof};

    const ERR_WRONG_VERSION: u64 = 1;
    const ERR_INVALID_ADMIN_CAP: u64 = 2;
    const ERR_INSUFFICIENT_BALANCE: u64 = 3;
    
    const VERSION: u64 = 1;
    const PROFIT_TARGET: u64 = 1000000000;

    public struct Vault<phantom T> has key {
        id: UID,
        version: u64,
        token_supply: Supply<T>,
        
        total_holding: u64,
        holding: Option<StakeProof<SBUCK, SUI>>,

        profit_target: u64,
        profit: Balance<SUI>,
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
            holding: option::none(),
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
        assert!(object::id(vault) == admin_cap.vault_id, ERR_INVALID_ADMIN_CAP);
        balance::withdraw_all(&mut vault.profit)
    }

    entry fun collect_profit_entry<T>(vault: &mut Vault<T>, admin_cap: &AdminCap, ctx: &mut TxContext) {        
        let profit = collect_profit(vault, admin_cap);        
        transfer::public_transfer(coin::from_balance(profit, ctx), ctx.sender());
    }

    public fun deposit<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        config: &GlobalConfig,
        pool: &mut Pool<SUI, BUCK>,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        deposit: Balance<BUCK>,
        ctx: &mut TxContext
        ): Balance<T> {
        assert_pacakge_version(vault);

        let deposit_sbucks = sbuck::deposit(flask, coin::from_balance(deposit, ctx));
        let amount = if (vault.total_holding > 0) {
            math::mul_factor(balance::value(&deposit_sbucks), balance::supply_value(&vault.token_supply), vault.total_holding)
        } else {
            balance::value(&deposit_sbucks)
        };

        let mut sbucks = unstake_protocol(vault, clock, config, pool, flask, fountain, ctx);
        balance::join(&mut sbucks, deposit_sbucks);
        vault.total_holding = balance::value(&sbucks);

        stake_protocol(vault, clock, fountain, sbucks, ctx);
        balance::increase_supply(&mut vault.token_supply, amount)
    }

    public fun withdraw<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        config: &GlobalConfig,
        pool: &mut Pool<SUI, BUCK>,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        withdraw: Balance<T>,
        ctx: &mut TxContext
        ): Balance<BUCK> {
        assert_pacakge_version(vault);
        assert!(balance::value(&withdraw) <= balance::supply_value(&vault.token_supply), ERR_INSUFFICIENT_BALANCE);

        let mut sbucks = unstake_protocol(vault, clock, config, pool, flask, fountain, ctx);

        let amount = math::mul_factor(balance::value(&withdraw), balance::value(&sbucks), balance::supply_value(&vault.token_supply));
        let withdraw_balance = balance::split(&mut sbucks, amount);
        vault.total_holding = balance::value(&sbucks);
        
        stake_protocol(vault, clock, fountain, sbucks, ctx);

        balance::decrease_supply(&mut vault.token_supply, withdraw);
        sbuck::withdraw(flask, coin::from_balance(withdraw_balance, ctx))
    }

    fun stake_protocol<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        fountain: &mut Fountain<SBUCK, SUI>,
        input: Balance<SBUCK>,
        ctx: &mut TxContext
        ) {
        if (balance::value(&input) > 0) {
            let stake_proof = fountain::fountain_core::stake(clock, fountain, input, 4838400000, ctx);
            option::fill(&mut vault.holding, stake_proof)
        } else {
            balance::destroy_zero(input)
        }
    }

    fun unstake_protocol<T>(
        vault: &mut Vault<T>,
        clock: &Clock,
        config: &GlobalConfig,
        pool: &mut Pool<SUI, BUCK>,
        flask: &mut Flask<BUCK>,
        fountain: &mut Fountain<SBUCK, SUI>,
        ctx: &mut TxContext
        ): Balance<SBUCK> {
        
        if (vault.holding.is_none()) {
            return balance::zero()
        };

        // Unstake from fountain
        let (mut sbucks, mut suis) = fountain::fountain_core::unstake(clock, fountain, option::extract(&mut vault.holding));        
        
        // if the profit is not enough, we will take the profit from the vault
        if (balance::value(&sbucks) < vault.profit_target) {
            let delta = vault.profit_target - balance::value(&sbucks);
            let save_amount = if (delta > balance::value(&suis)) {
                balance::value(&suis)
            } else {
                delta
            };
            balance::join(&mut vault.profit, balance::split(&mut suis, save_amount));
        };

        // swap SUIs to BUCKs
        let (suis, bucks) = fatchoi::swap::swap<SUI, BUCK>(config, pool, suis, balance::zero(), true, clock);
        if (balance::value(&suis) > 0) {
            balance::join(&mut vault.profit, suis);
        } else {
            balance::destroy_zero(suis);
        };
        
        if (balance::value(&bucks) > 0) {
            balance::join(&mut sbucks, sbuck::deposit(flask, coin::from_balance(bucks, ctx)));
        } else {
            balance::destroy_zero(bucks);
        };
        sbucks
    }

    fun assert_pacakge_version<T>(vault: &Vault<T>) {
        assert!(vault.version == VERSION, ERR_WRONG_VERSION);
    }
}
