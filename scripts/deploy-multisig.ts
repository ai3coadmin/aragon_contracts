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

const gDAO = "0xe9a758dfb55201a1c7287a8a0670a54e6c4f6ade"
const taxManager = "0x52bd813177a90afe18f330d849B1F427483b785F"
const maintainer = "0x57F700b3f48458756f8B955172485161eC7407A8"
async function main() {
  const VetoMultisigPluginSetup = await ethers.getContractFactory("VetoMultisigPluginSetup");
  const vetoMultisigPluginSetup = await VetoMultisigPluginSetup.deploy(
      gDAO,
      taxManager
  );
  await vetoMultisigPluginSetup.deployed();
  // const vetoMultisigPluginSetup = await VetoMultisigPluginSetup.attach("0x868248ecF7BBA2E9cF8E618F1527F0fad97E8b8a");
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
    "veto-multisig-v2",
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
