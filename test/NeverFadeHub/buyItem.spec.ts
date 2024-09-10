import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    userTwo,
    userTwoAddress,
    neverFadeHub,
    abiCoder,
    constCurveModule,
    bondCurveModule,
    linearCurveModule,
    governance,
    userThreeAddress,
    userThree,
    constCurveModuleAddress,
    linearCurveModuleAddress,
    bondCurveModuleAddress,
    buyAmount,
    feeProtocolAddress,
    governanceAddress,
} from '../__setup.spec';
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';

makeSuiteCleanRoom('Buy Item', function () {
    context('Generic', function () {

        beforeEach(async function () {
            const multipier = ethers.parseEther("0.1");
            const startPrice = ethers.parseEther("1");
            await expect(neverFadeHub.connect(governance).initializeItemByGov({
                curveModule:  constCurveModuleAddress,
                curveModuleInitData: abiCoder.encode(['uint256','uint256'], [startPrice, 1000]),
            })).to.be.not.reverted;
            expect(await neverFadeHub.connect(governance).getCurveModuleAddress(0)).to.equal(constCurveModuleAddress)
            expect(await neverFadeHub.connect(governance).getSupply(0)).to.equal(0)
            
            const config = await constCurveModule.connect(governance).getItemConfig(0);
            expect(config[0]).to.equal(startPrice)
            expect(config[1]).to.equal(1)
            expect(config[2]).to.equal(1000)

            await expect(neverFadeHub.connect(governance).initializeItemByGov({
                curveModule:  linearCurveModuleAddress,
                curveModuleInitData: abiCoder.encode(['uint256','uint256','uint256'], [startPrice,multipier,2000]), 
            })).to.be.not.reverted;
            expect(await neverFadeHub.connect(governance).getCurveModuleAddress(1)).to.equal(linearCurveModuleAddress)
            expect(await neverFadeHub.connect(governance).getSupply(1)).to.equal(0)

            await expect(neverFadeHub.connect(governance).initializeItemByGov({
                curveModule:  bondCurveModuleAddress,
                curveModuleInitData: abiCoder.encode(['uint256', 'uint256', 'uint256'], [startPrice, multipier, 3000]),
            })).to.be.not.reverted;
            expect(await neverFadeHub.connect(governance).getCurveModuleAddress(2)).to.equal(bondCurveModuleAddress)
            expect(await neverFadeHub.connect(governance).getSupply(2)).to.equal(0)
        });

        context('Negatives', function () {
            it('User should fail to buy item if pause contract.', async function () {
                console.log('neverFadeHub');
                await expect(neverFadeHub.connect(governance).adminPause()).to.not.be.reverted;
                expect(await neverFadeHub.connect(governance).paused()).to.be.true;

                await expect(neverFadeHub.connect(userTwo).buyItem({
                    itemIndex: 0,
                    amount: buyAmount,
                    maxAcceptedPrice: 100000000,
                    referralAddress: userThreeAddress,
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.EnforcedPause);
            });

            it('User should fail to buy item if item not initialized.', async function () {
                await expect(neverFadeHub.connect(userTwo).buyItem({
                    itemIndex:  3,
                    amount: buyAmount,
                    maxAcceptedPrice: 100000000,
                    referralAddress: userThreeAddress,
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.ItemNotInitialized);
            });

            it('User should fail to buy item if msg.value not enough.',   async function () {
                const price = await constCurveModule.getBuyPrice(0, buyAmount);
                await expect(neverFadeHub.connect(userTwo).buyItem({
                    itemIndex:  0,
                    amount: buyAmount,
                    maxAcceptedPrice: price,
                    referralAddress: userThreeAddress,
                },{value: price - BigInt(100000)})).to.be.revertedWithCustomError(neverFadeHub, ERRORS.MsgValueNotEnough);
            });

            it('User should fail to buy item if price exceed the max accepted price.',   async function () {
                const price = await constCurveModule.getBuyPrice(0, buyAmount);
                await expect(neverFadeHub.connect(userTwo).buyItem({
                    itemIndex:  0,
                    amount: buyAmount,
                    maxAcceptedPrice: price - BigInt(100000),
                    referralAddress: userThreeAddress,
                },{value: price})).to.be.revertedWithCustomError(neverFadeHub, ERRORS.ExceedMaxAcceptedPrice);
            });

            it('User should fail to buy item by buyStandardKey if amount = 0.',   async function () {
                await expect(neverFadeHub.connect(userTwo).buyItem({
                    itemIndex:  0,
                    amount: 0,
                    maxAcceptedPrice: ethers.parseEther("1"),
                    referralAddress: userThreeAddress,
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.InvalidAmount);
            });
        })

        context('Scenarios', function () {
            it('Get correct variable if buy const curve item success.',   async function () {
                const price = await constCurveModule.connect(userTwo).getBuyPrice(0, buyAmount);
                const feeStr = await constCurveModule.connect(userTwo).getFeePercent();
                const config = await constCurveModule.connect(userTwo).getItemConfig(0);
                const feePercentage = feeStr[0];
                const itemPercentage = feeStr[1];
                const referralPercentage = config[2];

                const creatorBeforeBalance = await ethers.provider.getBalance(governanceAddress);
                const userTwoBeforeBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeBeforeBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressBeforeBalance = await ethers.provider.getBalance(feeProtocolAddress);
                
                const txResp = await neverFadeHub.connect(userTwo).buyItem({
                    itemIndex:  0,
                    amount: buyAmount,
                    maxAcceptedPrice: price,
                    referralAddress: userThreeAddress,
                },{value: price});
                const txReceipt = await txResp.wait();
                const gasEth = txReceipt!.fee;

                const creatorAfterBalance = await ethers.provider.getBalance(governanceAddress);
                const userTwoAfterBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeAfterBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressAfterBalance = await ethers.provider.getBalance(feeProtocolAddress);
                
                const protocolFee = price * feePercentage / BigInt(10000);
                const leftFee = price * itemPercentage / BigInt(10000);
                const referralFee = leftFee * referralPercentage / BigInt(10000);
                const subjectFee = leftFee - referralFee;

                expect((userTwoBeforeBalance - gasEth - price)).to.equal(userTwoAfterBalance);
                expect((creatorBeforeBalance + subjectFee)).to.equal(creatorAfterBalance);
                expect((userThreeBeforeBalance + referralFee)).to.equal(userThreeAfterBalance);
                expect((feeAddressBeforeBalance + protocolFee)).to.equal(feeAddressAfterBalance);

                expect(await neverFadeHub.connect(userTwo).getSupply(0)).to.equal(buyAmount)
                expect(await neverFadeHub.connect(userTwo).balanceOf(0, userTwoAddress)).to.equal(buyAmount)
            });

            it('Get correct variable if buy linear curve item success.',   async function () {
                const keyPrice = await linearCurveModule.connect(userTwo).getBuyPrice(1, buyAmount);
                const feeStr = await linearCurveModule.connect(userTwo).getFeePercent();
                const config = await linearCurveModule.connect(userTwo).getItemConfig(1);
                const feePercentage = feeStr[0];
                const itemPercentage = feeStr[1];
                const referralPercentage = config[2];

                const price = keyPrice + (keyPrice * feePercentage / BigInt(10000)) + (keyPrice * itemPercentage / BigInt(10000));

                const creatorBeforeBalance = await ethers.provider.getBalance(governanceAddress);
                const userTwoBeforeBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeBeforeBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressBeforeBalance = await ethers.provider.getBalance(feeProtocolAddress);

                const txResp = await neverFadeHub.connect(userThree).buyItem({
                    itemIndex:  1,
                    amount: buyAmount,
                    maxAcceptedPrice: price,
                    referralAddress: userTwoAddress
                },{value: price});

                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt!.fee;
                const creatorAfterBalance = await ethers.provider.getBalance(governanceAddress);
                const userTwoAfterBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeAfterBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressAfterBalance = await ethers.provider.getBalance(feeProtocolAddress);

                const protocolFee = keyPrice * feePercentage / BigInt(10000);
                const leftFee = keyPrice * itemPercentage / BigInt(10000);
                const referralFee = leftFee * referralPercentage / BigInt(10000);
                const subjectFee = leftFee - referralFee;

                expect((userThreeBeforeBalance - gasEth - price)).to.equal(userThreeAfterBalance);
                expect((creatorBeforeBalance + subjectFee)).to.equal(creatorAfterBalance);
                expect((userTwoBeforeBalance + referralFee)).to.equal(userTwoAfterBalance);
                expect((feeAddressBeforeBalance + protocolFee)).to.equal(feeAddressAfterBalance);
                
                expect(await neverFadeHub.connect(userTwo).getSupply(1)).to.equal(buyAmount)
                expect(await neverFadeHub.connect(userTwo).balanceOf(1, userThreeAddress)).to.equal(buyAmount)
            });

            it('Get correct variable if buy bond curve item success.',   async function () {
                const keyPrice = await bondCurveModule.connect(userTwo).getBuyPrice(2, buyAmount);
                const feeStr = await bondCurveModule.connect(userTwo).getFeePercent();
                const config = await bondCurveModule.connect(userTwo).getItemConfig(2);
                const feePercentage = feeStr[0];
                const itemPercentage = feeStr[1];
                const referralPercentage = config[2];

                const price = keyPrice + (keyPrice * feePercentage / BigInt(10000)) + (keyPrice * itemPercentage / BigInt(10000));

                const creatorBeforeBalance = await ethers.provider.getBalance(governanceAddress);
                const userTwoBeforeBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeBeforeBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressBeforeBalance = await ethers.provider.getBalance(feeProtocolAddress);

                const txResp = await neverFadeHub.connect(userThree).buyItem({
                    itemIndex:  2,
                    amount: buyAmount,
                    maxAcceptedPrice: price,
                    referralAddress: userTwoAddress,
                },{value: price});

                const txReceipt = await txResp.wait();
                const gasEth =  txReceipt!.fee;

                const creatorAfterBalance = await ethers.provider.getBalance(governanceAddress);
                const userTwoAfterBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeAfterBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressAfterBalance = await ethers.provider.getBalance(feeProtocolAddress);

                const protocolFee = keyPrice * feePercentage / BigInt(10000);
                const leftFee = keyPrice * itemPercentage / BigInt(10000);
                const referralFee = leftFee * referralPercentage / BigInt(10000);
                const subjectFee = leftFee - referralFee;

                expect((userThreeBeforeBalance - gasEth - price)).to.equal(userThreeAfterBalance);
                expect((creatorBeforeBalance + subjectFee)).to.equal(creatorAfterBalance);
                expect((userTwoBeforeBalance + referralFee)).to.equal(userTwoAfterBalance);
                expect((feeAddressBeforeBalance + protocolFee)).to.equal(feeAddressAfterBalance);

                expect(await neverFadeHub.connect(userTwo).getSupply(2)).to.equal(buyAmount)
                expect(await neverFadeHub.connect(userTwo).balanceOf(2, userThreeAddress)).to.equal(buyAmount)
            });
        })
    })
})