# Solv Vault Guardian

### Description

Solv Vault Guardian functions as the guardian within the [Guard mechanism](https://docs.safe.global/safe-smart-account/guards) of the [Safe Wallet](https://safe.global/wallet). It exclusively permits Safe Wallet with multiple signatures to execute operations within a defined range.

### Test

1. Install Foundry CLI

2. Create Safe Wallet On Arbitrum One

https://app.safe.global/

1. Set Environment Variables

```bash
export SAFE_ACCOUNT= # Safe Wallet Address
export GOVERNOR= # Governor Address
export OWNER_OF_SAFE= # Owner Address for Safe Account
export PERMISSIONLESS_ACCOUNT= # Other EOA Address not same as OWNER_OF_SAFE and GOVERNOR
export PRIVATE_KEY_FOR_OWNER_OF_SAFE= # Private Key for OWNER_OF_SAFE
export ARB_RPC_URL= # Arbitrum One archive node RPC URL
```

4. Run Test

```
forge test --fork-url $ARB_RPC_URL
```