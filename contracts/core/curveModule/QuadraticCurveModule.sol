// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ICurveModule} from "../../interfaces/ICurveModule.sol";
import {ModuleBase} from "../base/ModuleBase.sol";
import {Errors} from "../../libraries/Errors.sol";

struct QuadraticCurveData {
    uint256 startPrice;
    uint256 square;
    uint256 multiplier;
    uint256 supply;
    uint256 referralRatio;
}

/**
 * @title QuadraticCurveData  The key price is according to the bonding curve,
 * key price = a(x-1)^2 + b
 *
 * @notice This is a bonding curve contract, the key price increase model according bond curve.
 */
contract QuadraticCurveModule is ModuleBase, ICurveModule {
    mapping(uint256 => QuadraticCurveData)
        internal _dataQuadraticCurveByItemAddress;

    uint256 _protocolFeePercent;
    uint256 _itemFeePercent;
    bool _canTransfer;

    constructor(address neverFadeHub) ModuleBase(neverFadeHub) {
        _protocolFeePercent = 200; // 2%
        _itemFeePercent = 300; // 3%
    }

    /// @inheritdoc ICurveModule
    function initializeCurveModule(
        uint256 itemIndex,
        bytes calldata data
    ) external override onlyNeverFadeHub returns (uint256) {
        (
            uint256 startPrice,
            uint256 square,
            uint256 multiplier,
            uint256 referralRatio
        ) = abi.decode(data, (uint256, uint256, uint256, uint256));

        if (referralRatio > 10000) revert Errors.ReferralRatioTooHigh();

        _dataQuadraticCurveByItemAddress[itemIndex] = QuadraticCurveData(
            startPrice,
            square,
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
            _dataQuadraticCurveByItemAddress[itemIndex].startPrice,
            _dataQuadraticCurveByItemAddress[itemIndex].square,
            _dataQuadraticCurveByItemAddress[itemIndex].multiplier,
            _dataQuadraticCurveByItemAddress[itemIndex].supply,
            amount
        );
        _dataQuadraticCurveByItemAddress[itemIndex].supply += amount;

        return (
            price,
            _dataQuadraticCurveByItemAddress[itemIndex].referralRatio,
            _protocolFeePercent,
            _itemFeePercent,
            false
        );
    }

    /// @inheritdoc ICurveModule
    function processSell(
        uint256 itemIndex,
        uint256 amount
    )
        external
        override
        onlyNeverFadeHub
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 price = _getPrice(
            _dataQuadraticCurveByItemAddress[itemIndex].startPrice,
            _dataQuadraticCurveByItemAddress[itemIndex].square,
            _dataQuadraticCurveByItemAddress[itemIndex].multiplier,
            _dataQuadraticCurveByItemAddress[itemIndex].supply - amount,
            amount
        );
        _dataQuadraticCurveByItemAddress[itemIndex].supply -= amount;

        return (
            price,
            _protocolFeePercent,
            _itemFeePercent,
            _dataQuadraticCurveByItemAddress[itemIndex].referralRatio
        );
    }

    /// @inheritdoc ICurveModule
    function processTransfer() external view override returns (bool) {
        return _canTransfer;
    }

    /// @inheritdoc ICurveModule
    function setTransferable(
        bool transferable_
    ) external override onlyNeverFadeHub {
        _canTransfer = transferable_;
    }

    /// @inheritdoc ICurveModule
    function setReferralRatio(
        uint256 itemIndex,
        uint256 newReferralRatio
    ) external override onlyNeverFadeHub {
        _dataQuadraticCurveByItemAddress[itemIndex]
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
        return
            _getPrice(
                _dataQuadraticCurveByItemAddress[itemIndex].startPrice,
                _dataQuadraticCurveByItemAddress[itemIndex].square,
                _dataQuadraticCurveByItemAddress[itemIndex].multiplier,
                _dataQuadraticCurveByItemAddress[itemIndex].supply,
                amount
            );
    }

    /// @inheritdoc ICurveModule
    function getBuyPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view override returns (uint256) {
        uint256 price = _getPrice(
            _dataQuadraticCurveByItemAddress[itemIndex].startPrice,
            _dataQuadraticCurveByItemAddress[itemIndex].square,
            _dataQuadraticCurveByItemAddress[itemIndex].multiplier,
            _dataQuadraticCurveByItemAddress[itemIndex].supply,
            amount
        );

        return
            price +
            ((price * _protocolFeePercent) / 10000) +
            ((price * _itemFeePercent) / 10000);
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
                    _dataQuadraticCurveByItemAddress[itemIndex].startPrice,
                    _dataQuadraticCurveByItemAddress[itemIndex].square,
                    _dataQuadraticCurveByItemAddress[itemIndex].multiplier,
                    _dataQuadraticCurveByItemAddress[itemIndex].supply - amount,
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
            _dataQuadraticCurveByItemAddress[itemIndex].startPrice,
            _dataQuadraticCurveByItemAddress[itemIndex].square,
            _dataQuadraticCurveByItemAddress[itemIndex].multiplier,
            _dataQuadraticCurveByItemAddress[itemIndex].supply - amount,
            amount
        );

        return
            price -
            ((price * _protocolFeePercent) / 10000) -
            ((price * _itemFeePercent) / 10000);
    }

    /// @inheritdoc ICurveModule
    function getItemConfig(
        uint256 itemIndex
    ) external view override returns (uint256, uint256, uint256) {
        return (
            _dataQuadraticCurveByItemAddress[itemIndex].startPrice,
            _dataQuadraticCurveByItemAddress[itemIndex].square,
            _dataQuadraticCurveByItemAddress[itemIndex].referralRatio
        );
    }

    /// @inheritdoc ICurveModule
    function getCurveType() external pure returns (uint256) {
        return 2; // 2 for quadratic curve
    }

    function _getPrice(
        uint256 startPrice,
        uint256 square,
        uint256 multiplier,
        uint256 supply,
        uint256 amount
    ) private pure returns (uint256) {
        if (amount == 0) return 0;

        uint256 sum1 = supply == 0
            ? 0
            : supply * (supply - 1) * (2 * supply - 1);

        uint256 sum2 = (supply + amount) *
            (supply + amount - 1) *
            (2 * (supply + amount) - 1);

        uint256 linearSum = (amount * (2 * supply + amount - 1)) / 2;

        return
            amount *
            startPrice +
            (square * (sum2 - sum1)) /
            6 +
            multiplier *
            linearSum;
    }
}
