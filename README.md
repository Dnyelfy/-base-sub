# BaseSub 🔁

**Subscriptions that collect themselves — non-custodial USDC subscriptions on Base.**

Live app → https://base-sub.vercel.app

## What it does

Crypto has no native standing payment order: every payment needs a human signature at the moment of payment. BaseSub fixes that for Base.

- **Non-custodial, allowance-pull model** — funds never leave the subscriber's wallet. One USDC approve, then each period is pulled only when due. Cancel anytime, by either party, in one click.
- **Autonomous billing agent** — a keeper with its own burner wallet lives in the page. While online it scans BaseSub every 15s and charges every due subscription by itself: no wallet popup, no clicks, no human.
- **Subscribe-links** — merchants generate a shareable link with a prefilled plan (amount, period, label). Netflix-style checkout, on Base. One-tap share to Farcaster.
- **Basenames everywhere** — enter `name.base.eth` instead of 0x addresses; lists and headers resolve reverse records.
- **ERC-8021 attributed** — every transaction (approve, subscribe, charge, cancel, keeper charges) carries a Builder Code suffix for onchain attribution via base.dev.
- **Base mini app** — signed `/.well-known/farcaster.json` manifest; opens inside Farcaster / Base App.

## Contract

| | |
|---|---|
| BaseSub | [`0x959e55D41fA78747f69C3444b1d653068535083B`](https://basescan.org/address/0x959e55D41fA78747f69C3444b1d653068535083B) (verified) |
| USDC (Base) | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Network | Base mainnet (8453) |

Core functions: `subscribe(merchant, amount, interval, label)` charges the first period immediately and schedules the next; `charge(id)` is permissionless — anyone (including the billing agent) can collect a due payment; `chargeMany(ids)` batches; `cancel(id)` by subscriber or merchant.

## Stack

Single-file dApp (HTML + ethers.js v6, no build step) · Solidity 0.8 · Vercel.

Same protocol also live on Arc Testnet as part of [ArcPay](https://arc-pay-black.vercel.app).

## Author

Built by [@Dnyelfy](https://x.com/Dnyelfy) · dnyelf.base.eth
