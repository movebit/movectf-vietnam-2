module movectf::drop {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::event;
    use std::option;
    use movectf::counter::{Self, Counter};


    struct UCA has store {
        user: address,
    }

    struct Vault has key {
        id: UID,
        balance: Balance<DROP>,
        userlist: Table<address, UCA>,
    }

    struct DROP has drop {}

    struct Flag has copy, drop {
        user: address,
        flag: bool,
    }

    fun init (witness: DROP, ctx: &mut TxContext) {
        counter::create_counter(ctx);


        let initializer = tx_context::sender(ctx);
        let (coincap, coindata) = coin::create_currency(witness, 0, b"Drop", b"Drop Coins", b"create for Ctf", option::none(), ctx);
        let coins_minted = coin::mint<DROP>(&mut coincap, 10, ctx);
        transfer::public_freeze_object(coindata);
        transfer::public_transfer(coincap, initializer);
        transfer::share_object(
            Vault {
            id: object::new(ctx),
            balance: coin::into_balance<DROP>(coins_minted),
            userlist: table::new<address, UCA>(ctx),
            }
        );
    }

    public entry fun airdrop(vault: &mut Vault, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(!table::contains<address, UCA>(&vault.userlist, sender),1);
        let balance_drop = balance::split(&mut vault.balance, 1);
        let coin_drop = coin::take(&mut balance_drop, 1, ctx);
        transfer::public_transfer(coin_drop, sender);
        balance::destroy_zero(balance_drop);
        table::add<address, UCA>(&mut vault.userlist, sender, UCA {
            user: sender,
        });
    }

    public entry fun get_flag(user_counter: &mut Counter, coin_drop: &mut Coin<DROP>, ctx: &mut TxContext) {

        counter::increment(user_counter);
        counter::is_within_limit(user_counter);


        let sender = tx_context::sender(ctx);
        let limit = coin::value(coin_drop);
        assert!(limit == 5, 2);
        event::emit (Flag {
            user: sender,
            flag: true,
        });
    }
}