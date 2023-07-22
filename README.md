# Symbiotic bonding curves

project for the ethglobal hackathon.

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



### Command for deployment

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