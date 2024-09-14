import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    userTwo,
    userTwoAddress,
    neverFadeHub,
    abiCoder,
    constCurveModule,
    bondCurveModule,
    linearCurveModule,
    governance,
    buyAmount,
    userThreeAddress,
    userThree,
    constCurveModuleAddress,
    linearCurveModuleAddress,
    bondCurveModuleAddress,
    feeProtocolAddress,
    sellAmount,
    governanceAddress,
} from '../__setup.spec';
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';
import { ZERO_ADDRESS } from '../helpers/constants';

makeSuiteCleanRoom('Sell Item', function () {
    context('Generic', function () {

        beforeEach(async function () {
            const square = ethers.parseEther("0.0001");
            const multipier = ethers.parseEther("1");
            const startPrice = ethers.parseEther("20");
            await expect(neverFadeHub.connect(governance).initializeItemByGov({
                curveModule:  constCurveModuleAddress,
                curveModuleInitData: abiCoder.encode(['uint256','uint256'], [startPrice, 1000]),
            })).to.be.not.reverted;

            await expect(neverFadeHub.connect(governance).initializeItemByGov({
                curveModule:  linearCurveModuleAddress,
                curveModuleInitData: abiCoder.encode(['uint256','uint256','uint256'], [startPrice,multipier,2000]), 
            })).to.be.not.reverted;

            await expect(neverFadeHub.connect(governance).initializeItemByGov({
                curveModule:  bondCurveModuleAddress,
                curveModuleInitData: abiCoder.encode(['uint256', 'uint256', 'uint256', 'uint256'], [startPrice, square, multipier, 3000]),
            })).to.be.not.reverted;

            const price = await constCurveModule.connect(governance).getBuyPrice(0, buyAmount);
            await expect(neverFadeHub.connect(userTwo).buyItem({
                itemIndex: 0,
                amount: buyAmount,
                maxAcceptedPrice: price,
                referralAddress: userThreeAddress
            },{value: price})).to.be.not.reverted;
            expect(await neverFadeHub.connect(governance).getSupply(0)).to.equal(buyAmount)

            const keyPrice = await linearCurveModule.connect(governance).getBuyPrice(1, buyAmount);
            const feeStr = await linearCurveModule.connect(userTwo).getFeePercent();
            const feePercentage = feeStr[0];
            const itemPercentage = feeStr[1];

            const price1 = keyPrice + (keyPrice * feePercentage / BigInt(10000)) + (keyPrice * itemPercentage / BigInt(10000));
            await expect(neverFadeHub.connect(userThree).buyItem({
                itemIndex: 1,
                amount: buyAmount,
                maxAcceptedPrice: price1,
                referralAddress: userAddress
            },{value: price1})).to.be.not.reverted;
            expect(await neverFadeHub.connect(governance).getSupply(1)).to.equal(buyAmount)

            const keyPrice2 = await bondCurveModule.connect(governance).getBuyPrice(2, buyAmount);
            const feeStr1 = await bondCurveModule.connect(userTwo).getFeePercent();
            const feePercentage1 = feeStr1[0];
            const itemPercentage1 = feeStr1[1];
            const price2 = keyPrice2 + (keyPrice2 * feePercentage1 / BigInt(10000)) + (keyPrice2 * itemPercentage1 / BigInt(10000));

            await expect(neverFadeHub.connect(user).buyItem({
                itemIndex: 2,
                amount: buyAmount,
                maxAcceptedPrice: price2,
                referralAddress: userTwoAddress
            },{value: price2})).to.be.not.reverted;
            expect(await neverFadeHub.connect(governance).getSupply(2)).to.equal(buyAmount)
        });

        context('Negatives', function () {
            it('User should fail to sell item if pause contract.',   async function () {
                await expect(neverFadeHub.connect(governance).adminPause()).to.not.be.reverted;

                await expect(neverFadeHub.connect(userThree).sellItem({
                    itemIndex: 1,
                    amount: buyAmount,
                    minAcceptedPrice: 100000000,
                    receiver: userThreeAddress,
                    referralAddress: userAddress
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.EnforcedPause);
            });

            it('User should fail to sell Item if subject not initialized.',   async function () {
                await expect(neverFadeHub.connect(userThree).sellItem({
                    itemIndex: 3,
                    amount: buyAmount,
                    minAcceptedPrice: 100000000,
                    receiver: userThreeAddress,
                    referralAddress: userAddress
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.ItemNotInitialized);
            });

            it('User should fail to sell Item if sell more than hold.',   async function () {
                await expect(neverFadeHub.connect(userThree).sellItem({
                    itemIndex:  1,
                    amount: buyAmount+1,
                    minAcceptedPrice: 100000000,
                    receiver: userThreeAddress,
                    referralAddress: userAddress
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.InsufficientItemAmount);
            });

            it('User should fail to sell Item if sell const curve.',   async function () {
                await expect(neverFadeHub.connect(userTwo).sellItem({
                    itemIndex:  0,
                    amount: buyAmount,
                    minAcceptedPrice: 100000000,
                    receiver: userThreeAddress,
                    referralAddress: userAddress
                })).to.be.revertedWithCustomError(constCurveModule, ERRORS.ConstCurveCannotSell);
            });

            it('User should fail to sell Item if sell price less than min accepted price.',   async function () {
                const price = await linearCurveModule.getSellPrice(1, buyAmount);
                await expect(neverFadeHub.connect(userThree).sellItem({
                    itemIndex:  1,
                    amount: buyAmount,
                    minAcceptedPrice: price + BigInt(1000),
                    receiver: userThreeAddress,
                    referralAddress: userAddress
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.LessThanMinAcceptedPrice);
            });

            it('User should fail to sell Item if received fund address is zero address',   async function () {
                const price = await linearCurveModule.getSellPrice(1, buyAmount);
                await expect(neverFadeHub.connect(userThree).sellItem({
                    itemIndex:  1,
                    amount: buyAmount,
                    minAcceptedPrice: price,
                    receiver: ZERO_ADDRESS,
                    referralAddress: userAddress
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.CanNotBeZeroAddress);
            });

            it('User should fail to sell Item if amount = 0',   async function () {
                const price = await linearCurveModule.getSellPrice(1, buyAmount);
                await expect(neverFadeHub.connect(userThree).sellItem({
                    itemIndex:  1,
                    amount: 0,
                    minAcceptedPrice: price,
                    receiver: userThreeAddress,
                    referralAddress: userAddress
                })).to.be.revertedWithCustomError(neverFadeHub, ERRORS.InvalidAmount);
            });
        })

        context('Scenarios', function () {

            it('Get correct variable if sell linear curve Item success.',   async function () {
                
                const creatorBeforeBalance = await ethers.provider.getBalance(governanceAddress);
                const userTwoBeforeBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeBeforeBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressBeforeBalance = await ethers.provider.getBalance(feeProtocolAddress);

                const price = await linearCurveModule.connect(userThree).getSellPrice(1, sellAmount);
                const txResp = await neverFadeHub.connect(userThree).sellItem({
                    itemIndex:  1,
                    amount: sellAmount,
                    minAcceptedPrice: price,
                    receiver: userThreeAddress,
                    referralAddress: userTwoAddress
                })
                const txReceipt = await txResp.wait();
                const gasEth = txReceipt!.fee;

                const userTwoAfterBalance = await ethers.provider.getBalance(userTwoAddress);
                const userThreeAfterBalance = await ethers.provider.getBalance(userThreeAddress);
                const feeAddressAfterBalance = await ethers.provider.getBalance(feeProtocolAddress);
                const creatorAfterBalance = await ethers.provider.getBalance(governanceAddress);

                const feeStr = await linearCurveModule.connect(userThree).getFeePercent();
                const config = await linearCurveModule.connect(userThree).getItemConfig(1);
                const feePercentage = feeStr[0];
                const itemPercentage = feeStr[1];
                const referralPercentage = config[2];
                
                const protocolFee = price * feePercentage / BigInt(10000);
                const leftFee = price * itemPercentage / BigInt(10000);
                const referralFee = leftFee * referralPercentage / BigInt(10000);
                const subjectFee = leftFee - referralFee;
                const sellFee = price - protocolFee - leftFee;

                expect((creatorBeforeBalance + subjectFee)).to.equal(creatorAfterBalance);
                expect((userThreeBeforeBalance - gasEth + sellFee)).to.equal(userThreeAfterBalance);
                expect((userTwoBeforeBalance + referralFee)).to.equal(userTwoAfterBalance);
                expect((feeAddressBeforeBalance + protocolFee)).to.equal(feeAddressAfterBalance);

                expect(await neverFadeHub.connect(userThree).balanceOf(1, userThreeAddress)).to.equal(buyAmount - sellAmount)
            });

            it('Get correct variable if sell bonding curve Item success.',   async function () {
                
                const userTwoBeforeBalance = await ethers.provider.getBalance(userTwoAddress);
                const userBeforeBalance = await ethers.provider.getBalance(userAddress);
                const feeAddressBeforeBalance = await ethers.provider.getBalance(feeProtocolAddress);
                const creatorBeforeBalance = await ethers.provider.getBalance(governanceAddress);

                const price = await bondCurveModule.connect(user).getSellPrice(2, sellAmount);
                const txResp = await neverFadeHub.connect(user).sellItem({
                    itemIndex:  2,
                    amount: sellAmount,
                    minAcceptedPrice: price,
                    receiver: userAddress,
                    referralAddress: userTwoAddress
                })
                const txReceipt = await txResp.wait();
                const gasEth = txReceipt!.fee;

                const userTwoAfterBalance = await ethers.provider.getBalance(userTwoAddress);
                const userAfterBalance = await ethers.provider.getBalance(userAddress);
                const feeAddressAfterBalance = await ethers.provider.getBalance(feeProtocolAddress);
                const creatorAfterBalance = await ethers.provider.getBalance(governanceAddress);

                const feeStr = await bondCurveModule.connect(user).getFeePercent();
                const config = await bondCurveModule.connect(user).getItemConfig(2);
                const feePercentage = feeStr[0];
                const itemPercentage = feeStr[1];
                const referralPercentage = config[2];
                
                const protocolFee = price * feePercentage / BigInt(10000);
                const leftFee = price * itemPercentage / BigInt(10000);
                const referralFee = leftFee * referralPercentage / BigInt(10000);
                const subjectFee = leftFee - referralFee;
                const sellFee = price - protocolFee - leftFee;

                expect((creatorBeforeBalance + subjectFee)).to.equal(creatorAfterBalance);
                expect((userBeforeBalance - gasEth + sellFee)).to.equal(userAfterBalance);
                expect((userTwoBeforeBalance + referralFee)).to.equal(userTwoAfterBalance);
                expect((feeAddressBeforeBalance + protocolFee)).to.equal(feeAddressAfterBalance);

                expect(await neverFadeHub.connect(userThree).balanceOf(2, userAddress)).to.equal(buyAmount - sellAmount)
            });
        })
    })
})