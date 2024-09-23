/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
    NeverFadeHub__factory,
} from '../typechain-types';
import { ethers } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
    const [deployer] = await ethers.getSigners();
    const NeverFadeHubAddress = "0x27E93060CC304Ed56Ed49aE1f776382B62f94E95"
    const ConstCurveModuleAddress = "0xf8361c3408D8D2A3823F1fC6Dc5168F4AB10a7bF"
    const LinearCurveModuleAddress = "0x550C539ad4c0653300Dc4a979BAbe6A102660d18"
    const QuadraticCurveModuleAddress= "0xC20B3E81f613b4461f71D47eF7746dfAcccdb3A9"

    const nerverFadeHub = NeverFadeHub__factory.connect(NeverFadeHubAddress)
    const tx = await nerverFadeHub.connect(deployer).whitelistCurveModule([ConstCurveModuleAddress, LinearCurveModuleAddress, QuadraticCurveModuleAddress], true)
    await tx.wait()
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['PreEnv']

export default deployFn