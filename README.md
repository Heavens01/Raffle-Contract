## Raffle Contract

### Overview
This repository contains a Solidity smart contract implementing a decentralized raffle, built with Foundry. The contract integrates Chainlink VRF for random winner selection and Chainlink Automation for time-based upkeep, enabling automated raffle draws on Ethereum-compatible blockchains.

### Features
* **Chainlink VRF**: Uses Chainlink VRF v2.5 for provably fair random winner selection.
* **Chainlink Automation**: Time-based upkeep triggers raffle draws automatically.
* **Customizable**: Configurable entry fee, raffle duration, and maximum participants.
* **Event Emission**: Emits events for entry, winner selection, and raffle completion.

### Installation
1. **Prerequisites**:
   * Foundry installed (forge and cast)

2. **Clone Repository**:
    ```bash
    git clone https://github.com/Heavens01/Raffle-Contract
    cd Raffle-Contract
    ```

3. **Install Dependencies**:
    ```bash
    forge install
    ```

### Usage

1. **Contract Deployment**:
    * Update script/DeployRaffle.s.sol with desired raffle parameters (entry fee, duration, VRF coordinator, subscription ID).
    * Deploy using Foundry:
    Edit the commented parameter in script/HelperConfig correctly and save.
    Then:
    ```bash
    forge script script/DeployRaffle.s.sol --rpc-url <rpc-url> --account <keystore-name> --broadcast
    ```

2. **Interacting with the Contract**:
    * Use cast or ethers.js/web3.js to interact with the deployed contract.
    * Example (cast for Basic NFT):
    ```bash
    cast call <contract-address> "getRecentWinner()(address)"
    ```

3. **Testing**
    * Run unit tests using Foundry:
    ```bash
    forge test
    ```


### Security

1. **Audits**: Ensure the contract is audited before deployment to mainnet.
2. **Best Practices**: This contract follows OpenZeppelin's ERC721 implementation guidelines.

### License

MIT License.