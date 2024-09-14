/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { ethers } from 'hardhat';
import {
  deployAndVerifyAndThen
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
  const [deployer] = await ethers.getSigners();
  
  const NeverFadeHubAddress = "0x74483Cbff8De256ecBF958B12C560af081651fBD"
  const v3NonfungiblePositionManagerAddress = "0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2"

  await deployAndVerifyAndThen({
    hre,
    name: "NeverFadePoints",
    contract: 'NeverFadePoints',
    args: ["NeverFadePoints", "NFP", NeverFadeHubAddress, v3NonfungiblePositionManagerAddress, deployer.address],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployNeverFadePoints']

export default deployFn
