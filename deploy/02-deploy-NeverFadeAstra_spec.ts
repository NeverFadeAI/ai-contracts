/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { ethers } from 'hardhat';
import {
  deployAndVerifyAndThen
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
  const [deployer] = await ethers.getSigners();
  
  const NeverFadeHubAddress = "0x27E93060CC304Ed56Ed49aE1f776382B62f94E95"
  const v3NonfungiblePositionManagerAddress = "0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2"

  await deployAndVerifyAndThen({
    hre,
    name: "NeverFadeAstra",
    contract: 'NeverFadeAstra',
    args: ["NeverFade Astra Token", "NFAT", NeverFadeHubAddress, v3NonfungiblePositionManagerAddress, deployer.address],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployNeverFadeAstra']

export default deployFn
