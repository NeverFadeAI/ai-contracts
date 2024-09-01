// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ICurveModule} from "../interfaces/ICurveModule.sol";
import {INeverFadeHub} from "../interfaces/INeverFadeHub.sol";
import {NeverFadeHubStorage} from "./storage/NeverFadeHubStorage.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";

contract NeverFadeHub is
    PausableUpgradeable,
    INeverFadeHub,
    NeverFadeHubStorage
{
    uint256 internal constant BPS_MAX = 10000;

    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /// @inheritdoc INeverFadeHub
    function initialize(
        address governanceContractAddress,
        address protocolFeeAddress
    ) external override initializer {
        _setGovernance(governanceContractAddress);
        _setProtocolFeeAddress(protocolFeeAddress);
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    /// @inheritdoc INeverFadeHub
    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    /// @inheritdoc INeverFadeHub
    function setProtocolFeeAddress(
        address newProtocolFeeAddress
    ) external override onlyGov {
        _setProtocolFeeAddress(newProtocolFeeAddress);
    }

    /// @inheritdoc INeverFadeHub
    function whitelistCurveModule(
        address curveModule,
        bool whitelist
    ) external override onlyGov {
        _whitelistCurveModule(curveModule, whitelist);
    }

    /// @inheritdoc INeverFadeHub
    function setCurveFeePercent(
        address curveModuleAddress,
        uint256 newProtocolFeePercent,
        uint256 newItemFeePercent
    ) external override onlyGov {
        if (!_curveModuleWhitelisted[curveModuleAddress])
            revert Errors.CurveModuleNotWhitelisted();

        //if change const curve fee percentage. The sum must be 10000
        if (ICurveModule(curveModuleAddress).getCurveType() == 8) {
            if (newProtocolFeePercent + newItemFeePercent != BPS_MAX)
                revert Errors.InvalidFeePercent();
        } else {
            //revert if the sum more than 10% when not const curve
            if (newProtocolFeePercent + newItemFeePercent > 1000)
                revert Errors.InvalidFeePercent();
        }

        ICurveModule(curveModuleAddress).setFeePercent(
            newProtocolFeePercent,
            newItemFeePercent
        );
    }

    /// @inheritdoc INeverFadeHub
    function initializeItemByGov(
        DataTypes.InitialItemData calldata vars
    ) external override onlyGov {
        if (!_curveModuleWhitelisted[vars.curveModule])
            revert Errors.CurveModuleNotWhitelisted();

        uint256 currentItemIndex = _globalItemIndex++;
        _keyItemInfo[currentItemIndex].curveModule = vars.curveModule;
        ICurveModule(vars.curveModule).initializeCurveModule(
            currentItemIndex,
            vars.curveModuleInitData
        );
    }

    function adminPause() external onlyGov {
        _pause();
    }

    function adminUnpause() external onlyGov {
        _unpause();
    }

    /// @inheritdoc INeverFadeHub
    function buyItem(
        DataTypes.BuyItemData calldata vars
    ) external payable override whenNotPaused {
        if (vars.amount == 0) revert Errors.InvalidAmount();
        if (_keyItemInfo[vars.itemIndex].curveModule == address(0))
            revert Errors.ItemNotInitialized();

        _buyItem(
            vars.itemIndex,
            vars.referralAddress,
            vars.amount,
            vars.maxAcceptedPrice
        );
    }

    /// @inheritdoc INeverFadeHub
    function sellItem(
        DataTypes.SellItemData calldata vars
    ) external override whenNotPaused {
        if (vars.amount == 0) revert Errors.InvalidAmount();
        if (vars.receiver == address(0)) revert Errors.CanNotBeZeroAddress();
        if (_keyItemInfo[vars.itemIndex].curveModule == address(0))
            revert Errors.ItemNotInitialized();
        if (_keyItemInfo[vars.itemIndex].balanceOf[msg.sender] < vars.amount)
            revert Errors.InsufficientItemAmount();

        //check if can sell from corresponding curve module contract
        (
            uint256 price,
            uint256 protocolFeePercent,
            uint256 subjectFeePercent
        ) = ICurveModule(_keyItemInfo[vars.itemIndex].curveModule).processSell(
                vars.itemIndex,
                vars.amount
            );

        if (price < vars.minAcceptedPrice)
            revert Errors.LessThanMinAcceptedPrice();

        _keyItemInfo[vars.itemIndex].supply -= vars.amount;
        _keyItemInfo[vars.itemIndex].balanceOf[msg.sender] -= vars.amount;

        uint256 protocolFee = (price * protocolFeePercent) / BPS_MAX;
        (bool success, ) = _protocolFeeAddress.call{value: protocolFee}("");
        if (!success) {
            revert Errors.SendETHFailed();
        }

        uint256 subjectFee = (price * subjectFeePercent) / BPS_MAX;
        (bool success1, ) = _keyItemInfo[vars.itemIndex].creator.call{
            value: subjectFee
        }("");
        if (!success1) {
            revert Errors.SendETHFailed();
        }

        uint256 sellValue = price - protocolFee - subjectFee;
        (bool success2, ) = vars.receiver.call{value: sellValue}("");
        if (!success2) {
            revert Errors.SendETHFailed();
        }
        _emitTradeItemEvent(
            msg.sender,
            vars.receiver,
            vars.itemIndex,
            address(0),
            vars.amount,
            price,
            false
        );
    }

    /// @inheritdoc INeverFadeHub
    function transferItem(
        DataTypes.TransferItemData calldata vars
    ) external override whenNotPaused {
        if (vars.amount == 0) revert Errors.InvalidAmount();
        if (vars.to == address(0) || vars.to == msg.sender)
            revert Errors.InvalidToAddress();
        if (_keyItemInfo[vars.itemIndex].curveModule == address(0))
            revert Errors.ItemNotInitialized();
        if (_keyItemInfo[vars.itemIndex].balanceOf[msg.sender] < vars.amount)
            revert Errors.InsufficientItemAmount();

        _keyItemInfo[vars.itemIndex].balanceOf[msg.sender] -= vars.amount;
        _keyItemInfo[vars.itemIndex].balanceOf[vars.to] += vars.amount;
        emit Events.TransferItemSuccess(
            _tradeIndex++,
            msg.sender,
            vars.to,
            vars.itemIndex,
            vars.amount,
            _keyItemInfo[vars.itemIndex].balanceOf[msg.sender],
            _keyItemInfo[vars.itemIndex].balanceOf[vars.to],
            _keyItemInfo[vars.itemIndex].supply,
            block.timestamp
        );
    }

    /// @inheritdoc INeverFadeHub
    function setReferralRatio(
        uint256 itemIndex,
        uint256 newReferralRatio
    ) external override {
        if (_keyItemInfo[itemIndex].curveModule == address(0))
            revert Errors.ItemNotInitialized();
        if (_keyItemInfo[itemIndex].creator == msg.sender)
            revert Errors.NotItemOwner();

        if (newReferralRatio > BPS_MAX) revert Errors.ReferralRatioTooHigh();
        ICurveModule(_keyItemInfo[itemIndex].curveModule).setReferralRatio(
            itemIndex,
            newReferralRatio
        );
    }

    /// @inheritdoc INeverFadeHub
    function setItemPrice(
        uint256 itemIndex,
        uint256 newPrice
    ) external override {
        if (_keyItemInfo[itemIndex].curveModule == address(0))
            revert Errors.ItemNotInitialized();
        if (_keyItemInfo[itemIndex].creator == msg.sender)
            revert Errors.NotItemOwner();

        ICurveModule(_keyItemInfo[itemIndex].curveModule).setItemPrice(
            itemIndex,
            newPrice
        );
    }

    /// ****************************
    /// *****QUERY VIEW FUNCTIONS***
    /// ****************************

    /// @inheritdoc INeverFadeHub
    function getSupply(
        uint256 itemIndex
    ) external view override returns (uint256) {
        return _keyItemInfo[itemIndex].supply;
    }

    /// @inheritdoc INeverFadeHub
    function balanceOf(
        uint256 itemIndex,
        address holder
    ) external view override returns (uint256) {
        return _keyItemInfo[itemIndex].balanceOf[holder];
    }

    /// @inheritdoc INeverFadeHub
    function getCurveModuleAddress(
        uint256 itemIndex
    ) external view override returns (address) {
        return _keyItemInfo[itemIndex].curveModule;
    }

    /// @inheritdoc INeverFadeHub
    function getBuyPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256) {
        address curve = _keyItemInfo[itemIndex].curveModule;
        if (curve == address(0)) {
            revert Errors.ItemNotInitialized();
        }

        return ICurveModule(curve).getBuyPrice(itemIndex, amount);
    }

    /// @inheritdoc INeverFadeHub
    function getBuyPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256) {
        address curve = _keyItemInfo[itemIndex].curveModule;
        if (curve == address(0)) {
            revert Errors.ItemNotInitialized();
        }

        return ICurveModule(curve).getBuyPriceAfterFee(itemIndex, amount);
    }

    /// @inheritdoc INeverFadeHub
    function getSellPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256) {
        address curve = _keyItemInfo[itemIndex].curveModule;
        if (curve == address(0)) {
            revert Errors.ItemNotInitialized();
        }
        return ICurveModule(curve).getSellPrice(itemIndex, amount);
    }

    /// @inheritdoc INeverFadeHub
    function getSellPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256) {
        address curve = _keyItemInfo[itemIndex].curveModule;
        if (curve == address(0)) {
            revert Errors.ItemNotInitialized();
        }
        return ICurveModule(curve).getSellPriceAfterFee(itemIndex, amount);
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _buyItem(
        uint256 itemIndex,
        address referralAddress,
        uint256 amount,
        uint256 maxAcceptedPrice
    ) internal {
        //check if can buy from corresponding curve module contract
        (
            uint256 price,
            uint256 referralRatio,
            uint256 protocolFeePercent,
            uint256 subjectFeePercent,
            bool bConstCurve
        ) = ICurveModule(_keyItemInfo[itemIndex].curveModule).processBuy(
                itemIndex,
                amount
            );

        if (price > maxAcceptedPrice) revert Errors.ExceedMaxAcceptedPrice();
        uint256 protocolFee = (price * protocolFeePercent) / BPS_MAX;
        uint256 subjectFee = (price * subjectFeePercent) / BPS_MAX;

        //avoid stack too deep
        {
            //if Const Curve, deduct fee from the price
            //if linea or bonding curve, deduct fee from msg.value, msg.value > price + protocolFee + subjectFee
            uint256 finalPrice = price;
            if (bConstCurve) {
                if (msg.value < price) revert Errors.MsgValueNotEnough();
            } else {
                if (msg.value < price + protocolFee + subjectFee)
                    revert Errors.MsgValueNotEnough();
                finalPrice = price + protocolFee + subjectFee;
            }

            _keyItemInfo[itemIndex].supply += amount;
            _keyItemInfo[itemIndex].balanceOf[msg.sender] += amount;

            if (msg.value > finalPrice) {
                (bool success, ) = msg.sender.call{
                    value: msg.value - finalPrice
                }("");
                if (!success) {
                    revert Errors.SendETHFailed();
                }
            }
        }
        {
            (bool success1, ) = _protocolFeeAddress.call{value: protocolFee}(
                ""
            );
            if (!success1) {
                revert Errors.SendETHFailed();
            }
            uint256 referralFee = 0;
            if (referralAddress != address(0) && referralRatio != 0) {
                referralFee = (subjectFee * referralRatio) / BPS_MAX;
                (bool success2, ) = referralAddress.call{value: referralFee}(
                    ""
                );
                if (!success2) {
                    revert Errors.SendETHFailed();
                }
            }
            (bool success3, ) = _keyItemInfo[itemIndex].creator.call{
                value: subjectFee - referralFee
            }("");
            if (!success3) {
                revert Errors.SendETHFailed();
            }
        }

        _emitTradeItemEvent(
            msg.sender,
            _keyItemInfo[itemIndex].creator,
            itemIndex,
            referralAddress,
            amount,
            price,
            true
        );
    }

    function _emitTradeItemEvent(
        address trader,
        address receiver,
        uint256 itemIndex,
        address referrer,
        uint256 amount,
        uint256 price,
        bool isBuy
    ) private {
        emit Events.TradeItemSuccess(
            _tradeIndex++,
            amount,
            price,
            block.timestamp,
            _keyItemInfo[itemIndex].balanceOf[trader],
            _keyItemInfo[itemIndex].supply,
            trader,
            receiver,
            itemIndex,
            referrer,
            isBuy
        );
    }

    function _setGovernance(address newGovernance) internal {
        if (newGovernance == address(0)) revert Errors.CanNotBeZeroAddress();
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(
            msg.sender,
            prevGovernance,
            newGovernance,
            block.timestamp
        );
    }

    function _setProtocolFeeAddress(address newProtocolFeeAddress) internal {
        if (newProtocolFeeAddress == address(0))
            revert Errors.CanNotBeZeroAddress();
        address preProtocolFeeAddress = _protocolFeeAddress;
        _protocolFeeAddress = newProtocolFeeAddress;
        emit Events.ProtocolFeeAddressSet(
            msg.sender,
            preProtocolFeeAddress,
            newProtocolFeeAddress,
            block.timestamp
        );
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function _whitelistCurveModule(
        address curveModule,
        bool whitelist
    ) internal {
        _curveModuleWhitelisted[curveModule] = whitelist;
        emit Events.CurveModuleWhitelisted(
            curveModule,
            whitelist,
            block.timestamp
        );
    }
}
