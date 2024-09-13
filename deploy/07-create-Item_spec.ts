/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
    NeverFadeHub__factory,
} from '../typechain-types';
import { ethers } from 'hardhat';
import { abiCoder } from '../test/__setup.spec';

const deployFn: DeployFunction = async (hre) => {
    const [deployer] = await ethers.getSigners();
    const NeverFadeHubAddress = "0x3f7210986b68A16E1d4f0C8E58eBabf82f0f4363"

    const nerverFadeHub = NeverFadeHub__factory.connect(NeverFadeHubAddress)
    const ConstCurveModuleAddress = "0xe0441a9f317d73aeB99252cc5041D481Cd68c935"
    const LinearCurveModuleAddress = "0xFaE63D983d2a16F835be4fb067e0A9E0CBBEe9b7"
    const QuadraticCurveModuleAddress = "0xF05EEEdEB727fD732de1D1313443dA8aAfe41bD4"
    
    const multipier = ethers.parseEther("0.1");
    const startPrice = ethers.parseEther("1");
    const referralRatio = 1000;

    const tx = await nerverFadeHub.connect(deployer).initializeItemByGov({
        curveModule:  ConstCurveModuleAddress,
        curveModuleInitData: abiCoder.encode(['uint256','uint256'], [startPrice, referralRatio]),
    })
    // const tx = await nerverFadeHub.connect(deployer).initializeItemByGov({
    //     curveModule:  LinearCurveModuleAddress,
    //     curveModuleInitData: abiCoder.encode(['uint256','uint256','uint256'], [startPrice, multipier, referralRatio]),
    // })
    // const tx = await nerverFadeHub.connect(deployer).initializeItemByGov({
    //     curveModule:  QuadraticCurveModuleAddress,
    //     curveModuleInitData: abiCoder.encode(['uint256','uint256','uint256'], [startPrice, multipier, referralRatio]),
    // })
    await tx.wait()
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['PreEnv']

export default deployFn