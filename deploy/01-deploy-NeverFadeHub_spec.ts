/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { ethers, upgrades } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  const [ deployer ] = await ethers.getSigners();

  const NeverFadeHub = await ethers.getContractFactory("NeverFadeHub");
  const proxy = await upgrades.deployProxy(NeverFadeHub, [deployer.address, deployer.address]);
  await proxy.waitForDeployment()
  
  const proxyAddress = await proxy.getAddress()
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployNeverFadeHub']

export default deployFn
