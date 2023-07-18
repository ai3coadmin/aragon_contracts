# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

# Deployment
```shell
npx hardhat run --network mumbai scripts/deploy-tax.ts
```
Copy and replace the `taxManager` in other scripts
for mumbai it is "0x52bd813177a90afe18f330d849B1F427483b785F"

Change `maintainer` & `gDAO` address.
gDAO should be aragon multiple address DAO
change the subdomain if required currently is 'veto-v3' & 'veto-multisig-v2', if you change it then frontend has to be updated as well

```shell
npx hardhat run --network mumbai scripts/deploy.ts
npx hardhat run --network mumbai scripts/deploy-multisig.ts
```
