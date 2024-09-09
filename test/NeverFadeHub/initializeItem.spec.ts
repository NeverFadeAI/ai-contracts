import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    deployerAddress,
    constCurveModule,
    bondCurveModule,
    linearCurveModule,
    userTwoAddress,
    userTwo,
    governance,
    userThreeAddress,
    neverFadeHub,
    abiCoder,
    constCurveModuleAddress,
    linearCurveModuleAddress,
    bondCurveModuleAddress
} from '../__setup.spec';
import { ERRORS } from '../helpers/errors';

makeSuiteCleanRoom('Initialize Item', function () {
    context('Generic', function () {
        context('Negatives', function () {
            it('User should fail to initialize item if paused.',   async function () {
                await expect(neverFadeHub.connect(governance).adminPause()).to.not.be.reverted;
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  constCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256'], [1000]), 
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.EnforcedPause);
            });

            it('Gover should fail to initialize item if use not whitelist curve address.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  deployerAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256'], [1000, 5000]), 
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.CurveModuleNotWhitelisted);
            });

            it('User should fail to initialize constant item if use invalid initial data format.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  constCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'bool'], [1000, true]), 
                })).to.be.revertedWithoutReason;
            });

            it('User should fail to initialize item if not gover.',   async function () {
                await expect(neverFadeHub.connect(user).initializeItemByGov({
                    curveModule:  constCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256'], [1000, 5000]), 
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.NotGovernance);
            });

            it('User should fail to initialize item if referralRatio too high when choice Const Curve.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  constCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256'], [1000, 10001]), 
                })).to.be.revertedWithCustomError(constCurveModule, ERRORS.ReferralRatioTooHigh);
            });

            it('User should fail to initialize item if referralRatio too high when choice Linear Curve.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  linearCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256', 'uint256'], [1000, 1000, 10001]), 
                })).to.be.revertedWithCustomError(linearCurveModule, ERRORS.ReferralRatioTooHigh);
            });

            it('User should fail to initialize item if referralRatio too high when choice Bonding Curve.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  bondCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256', 'uint256'], [1000, 1000, 10001]), 
                })).to.be.revertedWithCustomError(bondCurveModule, ERRORS.ReferralRatioTooHigh);
            });

            it('User should fail to linear item if use invalid initial data format.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  linearCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256', 'bool'], [1000, 1000, true]), 
                })).to.be.revertedWithoutReason;
            });

            it('User should fail to bondCurve item if use invalid initial data format.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  bondCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256', 'bool'], [1000, 1000, true]), 
                })).to.be.revertedWithoutReason;
            });

            it('User should fail to initialize item if remove const curve from whitelist.',   async function () {
                await expect(neverFadeHub.connect(governance).whitelistCurveModule(constCurveModuleAddress,false)).to.not.be.reverted;
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  constCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256','uint256'], [100000, 2000]),
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.CurveModuleNotWhitelisted);
            });

        })

        context('Scenarios', function () {
            it('Get correct variable if initialize item with const curve success.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  constCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256','uint256'], [100000, 2000]),
                })).to.be.not.reverted;
                expect(await neverFadeHub.connect(governance).getCurveModuleAddress(0)).to.equal(constCurveModuleAddress)
                expect(await neverFadeHub.connect(governance).getSupply(0)).to.equal(0)
            });

            it('Get correct variable if initialize item with linear curve success.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  linearCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256','uint256','uint256'], [1000,100000,3000]), 
                })).to.be.not.reverted;
                expect(await neverFadeHub.connect(governance).getCurveModuleAddress(0)).to.equal(linearCurveModuleAddress)
                expect(await neverFadeHub.connect(governance).getSupply(0)).to.equal(0)
            });

            it('Get correct variable if initialize item with bonding curve success.',   async function () {
                await expect(neverFadeHub.connect(governance).initializeItemByGov({
                    curveModule:  bondCurveModuleAddress,
                    curveModuleInitData: abiCoder.encode(['uint256', 'uint256', 'uint256'], [1000, 1000, 5000]),
                })).to.be.not.reverted;
                expect(await neverFadeHub.connect(governance).getCurveModuleAddress(0)).to.equal(bondCurveModuleAddress)
                expect(await neverFadeHub.connect(governance).getSupply(0)).to.equal(0)
            });
        })
    })
})