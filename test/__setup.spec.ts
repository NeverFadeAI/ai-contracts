import { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers, upgrades } from 'hardhat';
import {
  LinearCurveModule,
  LinearCurveModule__factory,
  ConstCurveModule,
  ConstCurveModule__factory,
  QuadraticCurveModule,
  QuadraticCurveModule__factory,
  Donation__factory,
  Donation,
} from '../typechain-types';
import {
  revertToSnapshot,
  takeSnapshot,
} from './helpers/utils';
import { ERRORS } from './helpers/errors';
import { NeverFadeHub } from '../typechain-types/contracts/core/NeverFadeHub.sol';
import { NeverFadeHub__factory } from '../typechain-types/factories/contracts/core/NeverFadeHub.sol';

export let accounts: Signer[];
export let deployer: Signer;
export let governance: Signer;
export let user: Signer;
export let userTwo: Signer;
export let userThree: Signer;
export let feeProtocol: Signer;
export let deployerAddress: string;
export let governanceAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let userThreeAddress: string;
export let feeProtocolAddress: string;
export let constCurveModule: ConstCurveModule;
export let linearCurveModule: LinearCurveModule;
export let bondCurveModule: QuadraticCurveModule;
export let donation: Donation;
export let neverFadeHub: NeverFadeHub;

export function makeSuiteCleanRoom(name: string, tests: () => void) {
  describe(name, () => {
    beforeEach(async function () {
      await takeSnapshot();
    });
    tests();
    afterEach(async function () {
      await revertToSnapshot();
    });
  });
}

before(async function () {
  accounts = await ethers.getSigners();
  deployer = accounts[0];
  governance = accounts[1];
  user = accounts[2];
  userTwo = accounts[3];
  userThree = accounts[4];
  feeProtocol = accounts[5];

  deployerAddress = await deployer.getAddress();
  governanceAddress = await governance.getAddress();
  userAddress = await user.getAddress();
  userTwoAddress = await userTwo.getAddress();
  userThreeAddress = await userThree.getAddress();
  feeProtocolAddress = await feeProtocol.getAddress();

  donation = await new Donation__factory(deployer).deploy(deployerAddress);
  expect(donation).to.not.be.undefined;

  const NeverFadeHub = await ethers.getContractFactory("NeverFadeHub");
  const neverFadeHubProxy = await upgrades.deployProxy(NeverFadeHub, [governanceAddress, feeProtocolAddress]);
  const proxyAddress = await neverFadeHubProxy.getAddress()
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))

  constCurveModule = await new ConstCurveModule__factory(deployer).deploy(proxyAddress);
  linearCurveModule = await new LinearCurveModule__factory(deployer).deploy(proxyAddress);
  bondCurveModule = await new QuadraticCurveModule__factory(deployer).deploy(proxyAddress);

  neverFadeHub = NeverFadeHub__factory.connect(proxyAddress)

  await expect(neverFadeHub.connect(governance).setGovernance(userAddress)).to.not.be.reverted;
  await expect(neverFadeHub.connect(user).setGovernance(governanceAddress)).to.not.be.reverted;

  const constCurveModuleAddress = await constCurveModule.getAddress();
  const linearCurveModuleAddress = await linearCurveModule.getAddress();
  const bondCurveModuleAddress = await bondCurveModule.getAddress();

  await expect(neverFadeHub.connect(governance).whitelistCurveModule(constCurveModuleAddress,true)).to.not.be.reverted;
  await expect(neverFadeHub.connect(governance).whitelistCurveModule(linearCurveModuleAddress,true)).to.not.be.reverted;
  await expect(neverFadeHub.connect(governance).whitelistCurveModule(bondCurveModuleAddress,true)).to.not.be.reverted;
  await expect(neverFadeHub.connect(governance).setCurveFeePercent(constCurveModuleAddress, 2000, 8000)).to.not.be.reverted;
  await expect(neverFadeHub.connect(governance).setCurveFeePercent(bondCurveModuleAddress, 200, 800)).to.not.be.reverted;

  await expect(neverFadeHub.connect(governance).setCurveFeePercent(deployerAddress, 11000, 9000)).to.be.revertedWithCustomError(neverFadeHub, ERRORS.CURVEMODULE_NOT_WHITELISTED);
  await expect(neverFadeHub.connect(governance).setCurveFeePercent(constCurveModuleAddress, 1000, 8500)).to.be.revertedWithCustomError(neverFadeHub, ERRORS.INVALID_FEE_PERCENT);
  await expect(neverFadeHub.connect(governance).setCurveFeePercent(bondCurveModuleAddress, 900, 101)).to.be.revertedWithCustomError(neverFadeHub, ERRORS.INVALID_FEE_PERCENT);
  //change back to 5% 5%
  await expect(neverFadeHub.connect(governance).setCurveFeePercent(bondCurveModuleAddress, 500, 500)).to.not.be.reverted;

  await expect(neverFadeHub.connect(user).setGovernance(userAddress)).to.be.revertedWithCustomError(neverFadeHub, ERRORS.NOT_GOVERNANCE);
  await expect(neverFadeHub.connect(user).whitelistCurveModule(bondCurveModuleAddress,true)).to.be.revertedWithCustomError(neverFadeHub, ERRORS.NOT_GOVERNANCE);
  await expect(neverFadeHub.connect(user).setCurveFeePercent(constCurveModuleAddress, 1000, 9000)).to.be.revertedWithCustomError(neverFadeHub, ERRORS.NOT_GOVERNANCE);

  expect(neverFadeHub).to.not.be.undefined;
});