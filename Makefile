-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

help:
	@echo "Usage:"
	@echo "To deploy to sepolia network: make deploy-sepolia"
	@echo "To deploy to anvil network: First run: 'make anvil', then 'make deploy-anvil'"
	@echo "To run tests: make test"
	@echo "To clean the repo: make clean"
	@echo "To remove modules: make remove"
	@echo "To install modules: make install"

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

# Update Dependencies
update:; forge update

anvil:; anvil --block-time 1

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

deploy-sepolia :
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url ${SEPOLIA_RPC_URL} --account sepolia_wallet_1 --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-anvil :
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url ${ANVIL_RPC_URL} --account anvil_wallet_1 --broadcast -vvvv

