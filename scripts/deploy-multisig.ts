// @ts-nocheck
import { ethers } from "hardhat";
import hre from "hardhat";
import { PluginRepoFactory__factory } from "@aragon/osx-ethers";
import { uploadToIpfs } from "../ipfsHelper";

import * as addresses from "../address.json";
import * as releaseMetaDataUri from "../veto-multisig-release-metadata.json";
import * as buildMetadataUri from "../veto-multisig-metadata.json";

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
  const VetoMultisigPluginSetup = await ethers.getContractFactory("VetoMultisigPluginSetup");
  // const vetoMultisigPluginSetup = await VetoMultisigPluginSetup.deploy(
  //     gDAO,
  //     taxManager
  // );
  // await vetoMultisigPluginSetup.deployed();
  const vetoMultisigPluginSetup = await VetoMultisigPluginSetup.attach("0x4D92efdB9EFCA73CAe4076d8331ef46830b680a9");
  // await verifyContract(vetoMultisigPluginSetup.address, [gDAO, taxManager]);
  // return;
  console.log(
    `VetoMultisigPluginSetup contract deployed to ${vetoMultisigPluginSetup.address}\n`
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
  console.log("deploying plugin repo factory", vetoMultisigPluginSetup.address);
  console.log("deploying plugin repo factory ipfs hex", toHex(releaseMetadata),
      toHex(buildMetadata));
  const tx = await pluginRepoFactory.createPluginRepoWithFirstVersion(
    "veto-multisig",
      vetoMultisigPluginSetup.address,
    maintainer,
    toHex(releaseMetadata),
    toHex(buildMetadata)
  );

  console.log(tx.hash);

  const receipt = await tx.wait();

  console.log(receipt.transactionHash);

  // await verifyContract(vetoPluginSetup.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
