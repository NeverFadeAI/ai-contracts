/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'

import { ethers, upgrades } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {

  const NeverFadeHub = await ethers.getContractFactory("NeverFadeHub");

  const proxyAddr = "0x27E93060CC304Ed56Ed49aE1f776382B62f94E95"
  const proxy = await upgrades.upgradeProxy(proxyAddr, NeverFadeHub);
  await proxy.waitForDeployment()

  const proxyAddress = await proxy.getAddress()
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['UpgradeNeverFadeHub']

export default deployFn