/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { ethers } from 'hardhat';
import {
  deployAndVerifyAndThen
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
  const [deployer] = await ethers.getSigners();
  
  await deployAndVerifyAndThen({
    hre,
    name: "Donation",
    contract: 'Donation',
    args: [deployer.address],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployDonation']

export default deployFn
