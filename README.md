# Symbiotic Bonding Curves

This project combines Bonding-Curve-based fundraising with Liquid Staking Derivatives into an Aragon Plugin with increasingly wonkier options for managing the yield.

Hackathon project page: [LINK](https://ethglobal.com/showcase/undefined-q11gf)

You can read the slides here: [LINK](https://docs.google.com/presentation/d/1K1wKiX8oEGINubxe64s2J__osIcG2R68DdSttxkCGDw/edit#slide=id.p)

## Characteristics
- Functional Aragon Dao Plugin, signed up at the registry ([link](https://mumbai.polygonscan.com/tx/0x144dab540594e66be2ecde2b5ac701d4ce5c49ca167d3ddc99ec49125df0c856))
- Original Foundry scripts in Solidity for plugin deployment and registration
- Deployed Contracts on Polygon Mumbai Testnet (see addresses below)
- The SymbioticBondingCurvePlugin contract implements the BaseRelayRecipient contract, and is therefore compatible with gas-less transactions.
- Management and testing automated with Chainlink automation. ([Rebase](https://automation.chain.link/mumbai/27856060908643686677321196615300647332707232863806945074647748540463835847677), [YieldDistribution](https://automation.chain.link/mumbai/112530855485555977933439502299040451398443904724924978027178076855937771955502))
https

### Commands for deployment

For a local deployment you can uncomment the setup() function in script/DeployPlugin.s.sol and run 
```
forge script script/DeployPlugin.s.sol:PluginScript --broadcast --chain 80001 --legacy -vvvv
```

For test on-chain deployments, it's more comfortable to run script/DeployDemoTokens.s.sol first:
```
forge script script/DeployDemoTokens.s.sol:TokenDeployerScript --rpc-url https://polygon-mumbai.g.alchemy.com/v2/[MUMBAY_API_KEY] --broadcast --verify --etherscan-api-key [ETHERSCAN_POLYGON_API_KEY] --chain 80001 --legacy -vvvv
```

Then copy the deployment addresses into the .env file and run:

```
forge script script/DeployPlugin.s.sol:PluginScript --rpc-url https://polygon-mumbai.g.alchemy.com/v2/[MUMBAY_API_KEY] --broadcast --verify --etherscan-api-key [ETHERSCAN_POLYGON_API_KEY] --chain 80001 --legacy -vvvv
```

Afterwards, you can copy the PluginRepo address into the .env and run (as of end of hackathon, this script is not yet functional)
```
forge script script/DeployDaoWithPlugin.s.sol:DaoPluginScript --rpc-url https://polygon-mumbai.g.alchemy.com/v2/[MUMBAY_API_KEY] --broadcast --verify --etherscan-api-key [ETHERSCAN_POLYGON_API_KEY] --chain 80001 --legacy -vvvv
```

## Deployment Addresses (Polygon Mumbai)
| Contract | Address |
|----------|---------|
| SymbioticBondingCurvePlugin | [0x6272E0238378796783C4fe1A839E187D3910973c](https://mumbai.polygonscan.com/address/0x6272E0238378796783C4fe1A839E187D3910973c) |
| SymbioticBondingCurvePluginSetup | [0x11CaBEBDF05AB6817919733e21D126A4920C095b](https://mumbai.polygonscan.com/address/0x11CaBEBDF05AB6817919733e21D126A4920C095b)| 
| Test DAO | [0x454034f4f8873140dd3e37596a7fa4a221a6964a](https://app.aragon.org/#/daos/mumbai/0x454034f4f8873140dd3e37596a7fa4a221a6964a/finance) |
| Mock Protocol Token | [0x979D92F7ecb126F520Df61EAd1D48E16f25Be49f](https://mumbai.polygonscan.com/address/0x979D92F7ecb126F520Df61EAd1D48E16f25Be49f) |
| Mock Liquid Staking Token | [0x6326781165914A33F2034a8E1dC66859dAc6b5dA](https://mumbai.polygonscan.com/address/0x6326781165914A33F2034a8E1dC66859dAc6b5dA) |

#### Note
This repo started as a fork of safe-core. The idea to implement changed during the hackathon, but it now looks like it has a long commit list. The first commit for the final project is ee818486e6ab81d524ec2690c0ad2305072f04b2

### Final Words

Math-head nouns approve of weird bonding curves.<br>
![nounsy](noun_mid.jpg)
