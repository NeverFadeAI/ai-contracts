/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
    NeverFadeHub__factory,
} from '../typechain-types';
import { ethers } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
    const [deployer] = await ethers.getSigners();
    const NeverFadeHubAddress = "0xcD6f5Bf3894fe063DC3a2eC30269469B40d789Ef"
    const ConstCurveModuleAddress = "0x474b74a25354C9e11Ff16Af5c9432FC0Bbebe56D"
    const LinearCurveModuleAddress = "0x789af8C6844bBB1522662C4942ACE98aeB74C20D"
    const QuadraticCurveModuleAddress= "0x3dcfdFD53A965E12EF2BfA15aeF1bfC690060561"

    const nerverFadeHub = NeverFadeHub__factory.connect(NeverFadeHubAddress)
    const tx = await nerverFadeHub.connect(deployer).whitelistCurveModule(ConstCurveModuleAddress, true)
    await tx.wait()

    const tx1 = await nerverFadeHub.connect(deployer).whitelistCurveModule(QuadraticCurveModuleAddress, true)
    await tx1.wait()

    const tx2 = await nerverFadeHub.connect(deployer).whitelistCurveModule(LinearCurveModuleAddress, true)
    await tx2.wait()
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['PreEnv']

export default deployFn