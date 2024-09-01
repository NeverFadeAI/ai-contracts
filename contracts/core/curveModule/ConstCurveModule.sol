// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ICurveModule} from "../../interfaces/ICurveModule.sol";
import {ModuleBase} from "../base/ModuleBase.sol";
import {Errors} from "../../libraries/Errors.sol";

struct ConstCurveData {
    uint256 price;
    uint256 supply;
    uint256 referralRatio;
}

/**
 * @title ConstCurveModule, Const curve, Subscribe Fee is fixed.
 * key price = b
 *
 * @notice This is a const curve contract, the key price is fixed.
 */
contract ConstCurveModule is ModuleBase, ICurveModule {
    mapping(uint256 => ConstCurveData) internal _dataConstCurveByItemAddress;

    uint256 _protocolFeePercent;
    uint256 _itemFeePercent;

    constructor(address neverFadeHub) ModuleBase(neverFadeHub) {
        _protocolFeePercent = 2000; //20%
        _itemFeePercent = 8000; //80%
    }

    /// @inheritdoc ICurveModule
    function initializeCurveModule(
        uint256 itemIndex,
        bytes calldata data
    ) external override onlyNeverFadeHub returns (uint256) {
        (uint256 price, uint256 referralRatio) = abi.decode(
            data,
            (uint256, uint256)
        );
        if (referralRatio > 10000) revert Errors.ReferralRatioTooHigh();

        _dataConstCurveByItemAddress[itemIndex] = ConstCurveData(
            price,
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
        _dataConstCurveByItemAddress[itemIndex].supply += amount;

        return (
            _dataConstCurveByItemAddress[itemIndex].price * amount,
            _dataConstCurveByItemAddress[itemIndex].referralRatio,
            _protocolFeePercent,
            _itemFeePercent,
            true
        );
    }

    /// @inheritdoc ICurveModule
    function processSell(
        uint256,
        uint256
    )
        external
        view
        override
        onlyNeverFadeHub
        returns (uint256, uint256, uint256)
    {
        revert Errors.ConstCurveCannotSell();
    }

    /// @inheritdoc ICurveModule
    function setReferralRatio(
        uint256 itemIndex,
        uint256 newReferralRatio
    ) external override onlyNeverFadeHub {
        _dataConstCurveByItemAddress[itemIndex]
            .referralRatio = newReferralRatio;
    }

    /// @inheritdoc ICurveModule
    function setItemPrice(
        uint256 itemIndex,
        uint256 newPrice
    ) external override onlyNeverFadeHub {
        _dataConstCurveByItemAddress[itemIndex].price = newPrice;
    }

    /// @inheritdoc ICurveModule
    function setFeePercent(
        uint256 newProtocolFeePercent,
        uint256 newItemFeePercent
    ) external override onlyNeverFadeHub {
        _protocolFeePercent = newProtocolFeePercent;
        _itemFeePercent = newItemFeePercent;
    }

    /// @inheritdoc ICurveModule
    function getFeePercent() external view override returns (uint256, uint256) {
        return (_protocolFeePercent, _itemFeePercent);
    }

    /// @inheritdoc ICurveModule
    function getBuyPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view override returns (uint256) {
        return _dataConstCurveByItemAddress[itemIndex].price * amount;
    }

    /// @inheritdoc ICurveModule
    function getBuyPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view override returns (uint256) {
        return _dataConstCurveByItemAddress[itemIndex].price * amount;
    }

    /// @inheritdoc ICurveModule
    function getItemConfig(
        uint256 itemIndex
    ) external view override returns (uint256, uint256, uint256) {
        return (
            _dataConstCurveByItemAddress[itemIndex].price,
            1,
            _dataConstCurveByItemAddress[itemIndex].referralRatio
        );
    }

    /// @inheritdoc ICurveModule
    function getCurveType() external pure returns (uint256) {
        return 8; // 8 for const curve
    }

    /// @inheritdoc ICurveModule
    function getSellPrice(
        uint256,
        uint256
    ) external pure override returns (uint256) {
        //can't sell
        return 0;
    }

    /// @inheritdoc ICurveModule
    function getSellPriceAfterFee(
        uint256,
        uint256
    ) external pure override returns (uint256) {
        //can't sell
        return 0;
    }
}
