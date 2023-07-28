// @ts-nocheck
import { ethers } from "hardhat";
import hre from "hardhat";
import { PluginRepoFactory__factory } from "@aragon/osx-ethers";
import { uploadToIpfs } from "../ipfsHelper";

import * as addresses from "../address.json";
import * as releaseMetaDataUri from "../releaseMetadata.json";
import * as buildMetadataUri from "../metadata.json";

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

export function toHex(input: string): BytesLike {
  return ethers.utils.hexlify(ethers.utils.toUtf8Bytes(input));
}

const gDAO = "0x7d8b38b139cb4a222085b39faaacf960d62453b1"
const taxManager = "0x7e5e585dec84e2618ea5aea1d5c0a18ddd0ade23"
const maintainer = "0x57F700b3f48458756f8B955172485161eC7407A8"
async function main() {
  // const TestVotingToken = await ethers.getContractFactory("TestVotingToken");
  // const testVotingToken = await TestVotingToken.deploy(10000000);
  // await testVotingToken.deployed();

  // console.log(testVotingToken.address);

  // console.log(
  //   `TestVotingToken contract deployed to ${testVotingToken.address}`
  // );
  console.log(
      `VetoPluginSetup Deploying...`
  );

  const VetoPluginSetup = await ethers.getContractFactory("VetoPluginSetup");
  console.log(
      `VetoPluginSetup getContractFactory`
  );
  const vetoPluginSetup = await VetoPluginSetup.deploy(
      gDAO, taxManager
  );
  console.log(
      `VetoPluginSetup vetoPluginSetup ${vetoPluginSetup.address}`
  );
  await vetoPluginSetup.deployed();

  console.log(
    `VetoPluginSetup contract deployed to ${vetoPluginSetup.address}\n`
  );

  // // Upload to IPFS
  const releaseMetadata = await uploadToIpfs(
    JSON.stringify(releaseMetaDataUri)
  );
  console.log("Release metadata uploaded to ", releaseMetadata);
  const buildMetadata = await uploadToIpfs(JSON.stringify(buildMetadataUri));
  console.log("Build metadata uploaded to ", buildMetadata);
  // PluginSetup Deploy
  const [deployer] = await ethers.getSigners();
  console.log('USING FACTORY: ', addresses[hre.network.name].PluginRepoFactory, hre.network.name)
  const pluginRepoFactory = PluginRepoFactory__factory.connect(
      addresses[hre.network.name].PluginRepoFactory,
      deployer
  );
  console.log("deploying plugin repo factory", vetoPluginSetup.address);
  console.log("deploying plugin repo factory ipfs hex", toHex(releaseMetadata),
      toHex(buildMetadata));

  const tx = await pluginRepoFactory.createPluginRepoWithFirstVersion(
      "veto-token",
      vetoPluginSetup.address,
      maintainer,
      toHex(releaseMetadata),
      toHex(buildMetadata)
  );

  console.log(tx.hash);

  const receipt = await tx.wait();

  console.log(receipt.transactionHash);

  // await verifyContract(testVotingToken.address, [10000000]);
  await verifyContract(vetoPluginSetup.address, [gDAO, taxManager]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
