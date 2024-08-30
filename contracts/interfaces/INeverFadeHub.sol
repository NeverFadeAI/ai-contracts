// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title INeverFadeHub
 *
 * @notice This is the entrypoint contract for the NeverFadeHub contract, the main entry point for Create/Buy/Sell Item.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface INeverFadeHub {
    /**
     * @notice initialize smart contract.
     * @param governanceContractAddress The governance address to set.
     * @param protocolFeeAddress The protocol fee address to set.
     */
    function initialize(
        address governanceContractAddress,
        address protocolFeeAddress
    ) external;

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    /**
     * @notice set new governance address
     *
     * @param newGovernance new address
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice set new protocol fee address
     *
     * @param newProtocolFeeAddress new fee address
     */
    function setProtocolFeeAddress(address newProtocolFeeAddress) external;

    /**
     * @notice set whitelist curve module address
     *
     * @param curveModule address of curve contract
     * @param whitelist whitelist or not
     */
    function whitelistCurveModule(address curveModule, bool whitelist) external;

    /**
     * @notice change fee percentage of curve contract
     *
     * @param curveModuleAddress address of curve contract
     * @param newProtocolFeePercent new percentage of protocol
     * @param newItemFeePercent new percentage of item
     */
    function setCurveFeePercent(
        address curveModuleAddress,
        uint256 newProtocolFeePercent,
        uint256 newItemFeePercent
    ) external;

    /**
     * @notice help user to initialize item, sometime kol not have gas, just not initialized user
     * and the supply == 0
     *
     * @param vars A InitialItemDataByGov struct containing the following params:
     *      keyItem: The address of item
     *      curveModule: The address of curve module contract.
     *      item: The address pf item
     *      curveModuleInitData: The curve module initialization data, if any.
     */
    function initializeItemByGov(
        DataTypes.InitialItemData calldata vars
    ) external;

    function initializeItemByUser(
        DataTypes.InitialItemData calldata vars
    ) external;

    /// ***********************
    /// *****EXTERNAL FUNCTIONS*****
    /// ***********************

    /**
     * @notice buy some amount of item
     *
     * @param vars A BuyItemDataBeforeOpenCurve struct containing the following params:
     *      keyItem: The address of item
     *      referralAddress: The address of referral user, if any
     *      amount: buy amount
     *      maxAcceptedPrice: The max price user can accept
     */
    function buyItem(DataTypes.BuyItemData calldata vars) external payable;

    /**
     * @notice sell some amount of item
     *
     * @param vars A SellItemData struct containing the following params:
     *      keyItem: The address of item
     *      amount: sell amount
     *      minAcceptedPrice: The min price user can accept
     */
    function sellItem(DataTypes.SellItemData calldata vars) external;

    /**
     * @notice transfer some amount to other user
     *
     * @param vars A TransferItemData struct containing the following params:
     *      keyItem: The address of item
     *      to: The address who receive key
     *      amount: The transfer amount
     */
    function transferItem(DataTypes.TransferItemData calldata vars) external;

    /**
     * @notice change referral ratio.
     *
     * @param itemIndex The index of item
     * @param newReferralRatio The new referra ratio
     */
    function setReferralRatio(
        uint256 itemIndex,
        uint256 newReferralRatio
    ) external;

    /**
     * @notice change subscribe price for item,
     * Just Const Curve Module, and the owner of item
     * call this function
     *
     * @param itemIndex The index of item
     * @param newPrice The new price
     */
    function setItemPrice(uint256 itemIndex, uint256 newPrice) external;

    /// ***********************
    /// *****VIEW FUNCTIONS*****
    /// ***********************

    /**
     * @notice get item supply
     */
    function getSupply(uint256 itemIndex) external view returns (uint256);

    /**
     * @notice get balance of item the holder hold
     *
     * @param itemIndex the index of item
     * @param holder the holder address
     */
    function balanceOf(
        uint256 itemIndex,
        address holder
    ) external view returns (uint256);

    /**
     * @notice get curve module address of the item
     *
     * @param itemIndex the index of item
     */
    function getCurveModuleAddress(
        uint256 itemIndex
    ) external view returns (address);

    /**
     * @notice get buy price of the item
     *
     * @param itemIndex the index of item
     * @param amount buy amount
     */
    function getBuyPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get buy price of the item, add fee
     *
     * @param itemIndex the index of item
     * @param amount buy amount
     */
    function getBuyPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get sell price of the item
     *
     * @param itemIndex the index of item
     * @param amount sell amount
     */
    function getSellPrice(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get sell price with fee of the item
     *
     * @param itemIndex the index of item
     * @param amount sell amount
     */
    function getSellPriceAfterFee(
        uint256 itemIndex,
        uint256 amount
    ) external view returns (uint256);
}
