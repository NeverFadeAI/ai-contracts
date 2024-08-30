// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ICurveModule} from "../../interfaces/ICurveModule.sol";
import {ModuleBase} from "../base/ModuleBase.sol";
import {Errors} from "../../libraries/Errors.sol";

struct LinearCurveData {
    uint256 startPrice;
    uint256 multiplier;
    uint256 supply;
    uint256 referralRatio;
}

/**
 * @title LinearCurveModule  The key price is according to the linear curve,
 * Item price = a(x-1) + b
 *
 * @notice This is a linear curve contract, the key price increase model according lineae curve.
 */

contract LinearCurveModule is ModuleBase, ICurveModule {
    mapping(uint256 => LinearCurveData) internal _dataLinearCurveByItemAddress;

    uint256 _protocolFeePercent;
    uint256 _subjectFeePercent;

    constructor(address neverFadeHub) ModuleBase(neverFadeHub) {
        _protocolFeePercent = 500; //5%
        _subjectFeePercent = 500; //5%
    }

    /// @inheritdoc ICurveModule
    function initializeCurveModule(
        uint256 itemIndex,
        bytes calldata data
    ) external override onlyNeverFadeHub returns (uint256) {
        (uint256 startPrice, uint256 multiplier, uint256 referralRatio) = abi
            .decode(data, (uint256, uint256, uint256));

        if (referralRatio > 10000) revert Errors.ReferralRatioTooHigh();

        _dataLinearCurveByItemAddress[itemIndex] = LinearCurveData(
            startPrice,
            multiplier,
            0,
            referralRatio
        );
        return 0;
    }

    /// @inheritdoc ICurveModule
    function processBuy(
        uint256 itemIndex,
        uint256 amount
    )
        external
        override
        onlyNeverFadeHub
        returns (uint256, uint256, uint256, uint256, bool)
    {
        uint256 price = _getPrice(
            _dataLinearCurveByItemAddress[itemIndex].startPrice,
            _dataLinearCurveByItemAddress[itemIndex].multiplier,
            _dataLinearCurveByItemAddress[itemIndex].supply,
            amount
        );
        _dataLinearCurveByItemAddress[itemIndex].supply += amount;

        //check if have customized fee percent
        uint256 retProtoFeePercent = _protocolFeePercent;
        uint256 retItemFeePercent = _subjectFeePercent;

        return (
            price,
            _dataLinearCurveByItemAddress[itemIndex].referralRatio,
            retProtoFeePercent,
            retItemFeePercent,
            false
        );
    }

    /// @inheritdoc ICurveModule
    function processSell(
        uint256 itemIndex,
        uint256 amount
    ) external override onlyNeverFadeHub returns (uint256, uint256, uint256) {
        uint256 price = _getPrice(
            _dataLinearCurveByItemAddress[itemIndex].startPrice,
            _dataLinearCurveByItemAddress[itemIndex].multiplier,
            _dataLinearCurveByItemAddress[itemIndex].supply - amount,
            amount
        );
        _dataLinearCurveByItemAddress[itemIndex].supply -= amount;

        uint256 retProtoFeePercent = _protocolFeePercent;
        uint256 retItemFeePercent = _subjectFeePercent;

        return (price, retProtoFeePercent, retItemFeePercent);
    }

    /// @inheritdoc ICurveModule
    function setReferralRatio(
        uint256 itemIndex,
        uint256 newReferralRatio
    ) external override onlyNeverFadeHub {
        _dataLinearCurveByItemAddress[itemIndex]
            .referralRatio = newReferralRatio;
    }

    /// @inheritdoc ICurveModule
    function setItemPrice(
        uint256,
        uint256
    ) external view override onlyNeverFadeHub {
        revert Errors.NotSupportedFunction();
    }

    /// @inheritdoc ICurveModule
    function setFeePercent(
        uint256 newProtocolFeePercent,
        uint256 newItemFeePercent
    ) external override onlyNeverFadeHub {
        _protocolFeePercent = newProtocolFeePercent;
        _subjectFeePercent = newItemFeePercent;
    }

    /// @inheritdoc ICurveModule
    function getFeePercent() external view override returns (uint256, uint256) {
        return (_protocolFeePercent, _subjectFeePercent);
    }

    /// @inheritdoc ICurveModule
    function getBuyPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view override returns (uint256) {
        return
            _getPrice(
                _dataLinearCurveByItemAddress[itemIndex].startPrice,
                _dataLinearCurveByItemAddress[itemIndex].multiplier,
                _dataLinearCurveByItemAddress[itemIndex].supply,
                amount
            );
    }

    /// @inheritdoc ICurveModule
    function getBuyPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view override returns (uint256) {
        uint256 price = _getPrice(
            _dataLinearCurveByItemAddress[itemIndex].startPrice,
            _dataLinearCurveByItemAddress[itemIndex].multiplier,
            _dataLinearCurveByItemAddress[itemIndex].supply,
            amount
        );

        uint256 retProtoFeePercent = _protocolFeePercent;
        uint256 retItemFeePercent = _subjectFeePercent;

        return
            price +
            ((price * retProtoFeePercent) / 10000) +
            ((price * retItemFeePercent) / 10000);
    }

    /// @inheritdoc ICurveModule
    function getSellPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view override returns (uint256) {
        if (amount == 0) return 0;
        else
            return
                _getPrice(
                    _dataLinearCurveByItemAddress[itemIndex].startPrice,
                    _dataLinearCurveByItemAddress[itemIndex].multiplier,
                    _dataLinearCurveByItemAddress[itemIndex].supply - amount,
                    amount
                );
    }

    /// @inheritdoc ICurveModule
    function getSellPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view override returns (uint256) {
        if (amount == 0) return 0;
        uint256 price = _getPrice(
            _dataLinearCurveByItemAddress[itemIndex].startPrice,
            _dataLinearCurveByItemAddress[itemIndex].multiplier,
            _dataLinearCurveByItemAddress[itemIndex].supply - amount,
            amount
        );

        uint256 retProtoFeePercent = _protocolFeePercent;
        uint256 retItemFeePercent = _subjectFeePercent;

        return
            price -
            ((price * retProtoFeePercent) / 10000) -
            ((price * retItemFeePercent) / 10000);
    }

    /// @inheritdoc ICurveModule
    function getItemConfig(
        uint256 itemIndex
    ) external view override returns (uint256, uint256, uint256) {
        return (
            _dataLinearCurveByItemAddress[itemIndex].startPrice,
            _dataLinearCurveByItemAddress[itemIndex].multiplier,
            _dataLinearCurveByItemAddress[itemIndex].referralRatio
        );
    }

    /// @inheritdoc ICurveModule
    function getCurveType() external pure returns (uint256) {
        return 4; // 4 for linear curve
    }

    function _getPrice(
        uint256 startPrice,
        uint256 multiplier,
        uint256 supply,
        uint256 amount
    ) private pure returns (uint256) {
        uint256 ret = 0;
        if (amount > 0) {
            ret =
                (startPrice * amount) +
                (amount * multiplier * supply) +
                ((amount - 1) * amount * multiplier) /
                2;
        }
        return ret;
    }
}
