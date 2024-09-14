/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { ethers, upgrades } from 'hardhat';
import { getCreateAddress } from "ethers"

const deployFn: DeployFunction = async (hre) => {
  const [ deployer ] = await ethers.getSigners();

  let deployerNonce = await ethers.provider.getTransactionCount(deployer);
  const neverFadePointsAddress = getCreateAddress({ from: deployer.address, nonce: deployerNonce + 2 })
  console.log("neverFadePointsAddress: ", neverFadePointsAddress)
  
  const NeverFadeHub = await ethers.getContractFactory("NeverFadeHub");
  const proxy = await upgrades.deployProxy(NeverFadeHub, [deployer.address, deployer.address, neverFadePointsAddress]);
  await proxy.waitForDeployment()
  
  const proxyAddress = await proxy.getAddress()
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployNeverFadeHub']

export default deployFn
