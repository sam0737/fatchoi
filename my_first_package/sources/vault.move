module my_first_package::vault {
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    public struct Vault<phantom COIN> has key {
        id: UID,
        treasury: TreasuryCap<COIN>,
        vault: Balance<SUI>
    }

    public fun create<COIN>(treasury: TreasuryCap<COIN>, ctx: &mut TxContext) {
        transfer::share_object(Vault<COIN> { 
            id: object::new(ctx),
            treasury: treasury,
            vault: balance::zero<SUI>()
        });
    }

    public fun stake<COIN>(vault: &mut Vault<COIN>, amount: Coin<SUI>, ctx: &mut tx_context::TxContext): Coin<COIN> {
        let value = coin::value(&amount);
        coin::put(&mut vault.vault, amount);
        coin::mint(&mut vault.treasury, value, ctx)
    }

    public fun unstake<COIN>(vault: &mut Vault<COIN>, amount: Coin<COIN>, ctx: &mut tx_context::TxContext): Coin<SUI> {
        let value = coin::value(&amount);
        coin::burn(&mut vault.treasury, amount);
        coin::take(&mut vault.vault, value, ctx)
    }
}