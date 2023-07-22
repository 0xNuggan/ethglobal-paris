# Symbiotic Bonding Curves

This project combines Boniding-Curve-based fundraising with Liquid Staking Derivatives into an Aragon Plugin with increasingly wonkier options for managing the yield.

You can watch the presentation and slides here:

## Characteristics
- Functional Aragon Dao Plugin, signed up at the registry (link)
- Foundry Solidity scripting 
- Deployed on Polygon Mumbai Testnet
- The SymbioticBondingCurvePlugin contract implements the BaseRelayRecipient contract, and can therefore work with gas-less transactions.
- Management and testing automated with chainlink automation.

### Todo:


done Bonding curve reserve ratio update
done test "rebase"
done missing yield use functions

**basic functionlity in module ready. to do:**
done Aragon setup script
done Gasless transactions enabled
Deploy on Polygon
Register in Aragon registry

Presentation with focus on convicing people that don't know about bonding curves

optional missing tax on yield use functions



### Commands for deployment

For a local deployment you can uncomment the setup function in script/DeployPlugin.s.sol and run 
'''
forge script script/DeployPlugin.s.sol:PluginScript --broadcast --chain 80001 --legacy -vvvv
'''

For test on-chain deployments, it's more comfortable to run script/DeployDemoTokens.s.sol first:
'''
forge script script/DeployDemoTokens.s.sol:TokenDeployerScript --rpc-url https://polygon-mumbai.g.alchemy.com/v2/[MUMBAY_API_KEY] --broadcast --verify --etherscan-api-key [ETHERSCAN_POLYGON_API_KEY] --chain 80001 --legacy -vvvv
'''

Then copy the deployment addresses into the .env file and run:

'''
forge script script/DeployPlugin.s.sol:PluginScript --rpc-url https://polygon-mumbai.g.alchemy.com/v2/[MUMBAY_API_KEY] --broadcast --verify --etherscan-api-key [ETHERSCAN_POLYGON_API_KEY] --chain 80001 --legacy -vvvv
'''

and then copying the addresses into the .env before running DeployPlugin.

'''
forge create --rpc-url https://polygon-mumbai.g.alchemy.com/v2/YOUR_MUMBAI_API_KEY \
    --constructor-args "IF_NECESSARY" \
    --private-key PRIVATE_KEY \
    --legacy \
    src/your/path/YourContract.sol:YourContract

'''

### Command for verification
'''
forge verify-contract THE_DEPLOYMENT_ADDRES \
src/your/path/YourContract.sol:YourContract \
--chain 80001 \
--num-of-optimizations 10000 \
--etherscan-api-key POLYGON_API_KEY
'''


[write some ords about the commit history / change of Idea]


Math-head nouns approve of wonky bonding curves.
![nounsy](mathHeadNoun.jpg)

#### Note
This repo started as a fork of safe-core. The idea to implement changed during the hackathon, but it now looks like it has a long commit list. The first commit for the final project is ee818486e6ab81d524ec2690c0ad2305072f04b2