import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    donation,
    deployer,
    deployerAddress
} from '../__setup.spec';
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';

makeSuiteCleanRoom('Donation ', function () {
    context('Generic', function () {

        context('Negatives', function () {
            it('User should fail to withdraw if not owner.',   async function () {
                await expect(donation.connect(user).withdraw()).to.be.revertedWithCustomError(donation, ERRORS.OwnableUnauthorizedAccount);
            });
        })

        context('Scenarios', function () {
            it('Get correct variable if received eth', async function () {
                const donationAddress = await donation.getAddress();
                const balance = await ethers.provider.getBalance(donationAddress);
                expect(balance).to.equal(0);

                const beforeBalance = await ethers.provider.getBalance(deployerAddress);

                //send eth to donation contract
                await user.sendTransaction({
                    to: donationAddress,
                    value: ethers.parseEther('100')
                });
                const balance1 = await ethers.provider.getBalance(donationAddress);
                expect(balance1).to.equal(ethers.parseEther('100'));

                await expect(donation.connect(deployer).withdraw()).to.be.not.reverted;
                const afterBalance = await ethers.provider.getBalance(deployerAddress);

                expect(afterBalance - beforeBalance).to.lessThan(ethers.parseEther('100'));
                expect(afterBalance - beforeBalance).to.greaterThan(ethers.parseEther('99.9'));
            });
        })
    })
})