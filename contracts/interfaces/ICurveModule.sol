// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ICurveModule
 * @author Tomo Protocol
 *
 * @notice This is base interface contract for all curve module contracts
 */
interface ICurveModule {
    /**
     * @notice Initial curve when initial item.
     *
     * @param itemIndex index of item
     * @param data the initial data for curve
     */
    function initializeCurveModule(
        uint256 itemIndex,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Check if can buy success from the rule of curve.
     *
     * @param itemIndex index of item
     * @param amount the buy amount
     */
    function processBuy(
        uint256 itemIndex,
        uint256 amount
    ) external returns (uint256, uint256, uint256, uint256, bool);

    /**
     * @notice Check if can sell success from the rule of curve.
     *
     * @param itemIndex index of item
     * @param amount the buy amount
     */
    function processSell(
        uint256 itemIndex,
        uint256 amount
    ) external returns (uint256, uint256, uint256);

    /**
     * @notice return if key can transfer or not.
     */
    function processTransfer() external pure returns (bool);

    /**
     * @notice change referral ratio.
     *
     * @param itemIndex index of item
     * @param newReferralRatio The new referra ratio
     */
    function setReferralRatio(
        uint256 itemIndex,
        uint256 newReferralRatio
    ) external;

    /**
     * @notice set a new subscribe price by item owner. only support const curve module
     *
     * @param itemIndex index of item
     * @param price the new price
     */
    function setItemPrice(uint256 itemIndex, uint256 price) external;

    /**
     * @notice set normal fee percent for users
     *
     * @param newProtocolFeePercent the new protocol fee percent
     * @param newItemFeePercent the new item fee percent
     */
    function setFeePercent(
        uint256 newProtocolFeePercent,
        uint256 newItemFeePercent
    ) external;

    /**
     * @notice get the price of buy amount key
     *
     * @param itemIndex index of item
     * @param amount buy amount
     */
    function getBuyPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get the price with fee of buy amount key
     *
     * @param itemIndex index of item
     * @param amount buy amount
     */
    function getBuyPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get item config
     *
     * @param itemIndex index of item
     */
    function getItemConfig(
        uint256 itemIndex
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice get timePeriod for const curve,
     * Const curve is subscription model, buy one key have timePeriod
     * Frontend can calculate the expiration time for each subscriber
     *
     * @param itemIndex index of item
     */
    function getTimePeriodFromCurve(
        uint256 itemIndex
    ) external view returns (uint256);

    /**
     * @notice get the price of sell amount key
     *
     * @param itemIndex index of item
     * @param amount sell amount
     */
    function getSellPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get the price with fee of buy amount key
     *
     * @param itemIndex index of item
     * @param amount buy amount
     */
    function getSellPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice protocolFeePercent and subjectFeePercent
     */
    function getFeePercent() external view returns (uint256, uint256);

    /**
     * @notice get curve type of curve
     */
    function getCurveType() external pure returns (uint256);
}
