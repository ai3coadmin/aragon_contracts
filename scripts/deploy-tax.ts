// @ts-nocheck
import hre, { ethers } from "hardhat";

const verifyContract = async (_address, _args) => {
  if (_args)
    await hre.run("verify:verify", {
      address: _address,
      constructorArguments: [..._args],
    });
  else
    await hre.run("verify:verify", {
      address: _address,
    });
};

async function main() {
  const TaxManager = await ethers.getContractFactory("TaxManager");
  const taxManager = await TaxManager.deploy();
  await taxManager.deployed();
  // const taxManager = await TaxManager.attach("0x52bd813177a90afe18f330d849B1F427483b785F");
  await verifyContract(taxManager.address, []);
  // return;
  console.log(taxManager.address);

  console.log(
    `TestVotingToken contract deployed to ${taxManager.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
