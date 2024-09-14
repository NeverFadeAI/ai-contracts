/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
    NeverFadeHub__factory,
} from '../typechain-types';
import { ethers } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
    const [deployer] = await ethers.getSigners();
    const NeverFadeHubAddress = "0x74483Cbff8De256ecBF958B12C560af081651fBD"
    const ConstCurveModuleAddress = "0x0878595252ad939dF3451c13ee5BDb5bE5ee4298"
    const LinearCurveModuleAddress = "0x7F0BA00a7620A95B9cb9E6eC94722dba242AaCd6"
    const QuadraticCurveModuleAddress= "0x098fD682a7fC7716e4B8DF2dD89D5aEd7DD7d1e4"

    const nerverFadeHub = NeverFadeHub__factory.connect(NeverFadeHubAddress)
    const tx = await nerverFadeHub.connect(deployer).whitelistCurveModule([ConstCurveModuleAddress, LinearCurveModuleAddress, QuadraticCurveModuleAddress], true)
    await tx.wait()
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['PreEnv']

export default deployFn