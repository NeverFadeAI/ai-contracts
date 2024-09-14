/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { ethers } from 'hardhat';
import {
  deployAndVerifyAndThen
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
  const [deployer] = await ethers.getSigners();
  
  const NeverFadeHubAddress = "0x3f7210986b68A16E1d4f0C8E58eBabf82f0f4363"
  const v3NonfungiblePositionManagerAddress = ""

  await deployAndVerifyAndThen({
    hre,
    name: "NeverFadePoints",
    contract: 'NeverFadePoints',
    args: ["NeverFadePoints", "NFP", NeverFadeHubAddress, v3NonfungiblePositionManagerAddress, deployer.address],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployDonation']

export default deployFn
