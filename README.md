# multisig_wallet

**(Addenda:**
- **30-6-2023 - An example of this deployed to the IC can be seen at https://bit.ly/ic_multisig**
- **1-7-2023 - A further example of the same deployed instance can be seen at https://vvy6jx.csb.app/, using a template developed by @krpeacock.)**


This is a multi-signature wallet designed for use with an EVM-based blockchain and built as part of the Internet Computer BUIDL Bitcoin Hackathon powered by Encode held in June 2023.

This project makes use of the **ic-web3** library developed by Rocklabs, available at https://github.com/rocklabs-io/ic-web3. The wallet uses two canisters, a Rust canister modified slight ly from https://github.com/rocklabs-io/ic-web3/blob/main/examples/example.rs, and a Motoko canister which provides functions for operating the multisig wallet. The Motoko canister is loosely based on the "Multi Sig Wallet" Solidity tutorial on https://www.smartcontract.engineer, which I converted from the original Solidity into Motoko.

As written, the wallet canister operates on the Goerli testnet. Note that in its current form the wallet is **not secure** as the private key can be easily replicated. This should be thought of as a work in progress, shared for demostation purposes.

For users new to the Internet Computer, a short tutorial on installing the necessary pre-requisites and deploying a canister (which is roughly equivalent to a smart contract on other blockchains) can be found at https://internetcomputer.org/docs/current/tutorials/deploy_sample_app.

To run the multisig wallet in this project, clone this repo, then from within the repo folder run `dfx start --background` and `dfx deploy`. Click or copy the link that appears immediately after `multisig_wallet_backend:`. (Don't use the frontend link as this is not yet complete.)

The following list of functions is able to be called. I've indicated the meaning of the input variables for each, as this is not necessarily apparent from the Candid UI that opens with the backend canister link.

- add_owner: (text) → Address of added owner
- approve: (nat) → TxId of transaction to approve
- call_batch_request: () → (result is displayed in CLI output)
- call_get_block: (nat64) → Block height
- call_get_canister_addr: () → (shows ETH address of the wallet)
- call_get_eth_balance: (text) → Wallet address
- call_get_eth_gas_price: () → (shows current gas price)
- call_get_tx_count: (text) → Wallet address
- call_token_balance: (text, text) → Wallet address; Token address
- execute: (nat) → TxId of transaction to execute
- init: (nat) → number of owners needed to approve a transaction (after all owners are added; shows transaction TxId)
- revoke: (nat) → TxId of transaction to revoke
- submit: (text, nat64) → Recipient wallet; amount of ETH to send
