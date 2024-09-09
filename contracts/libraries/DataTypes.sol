// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/**
 * @title DataTypes
 * @author Tomo Protocol
 *
 * @notice A standard library of data types used throughout the NeverFadeHub.
 */
library DataTypes {
    enum CurveType {
        None,
        BondingCurve,
        LinearCurve,
        ConstCurve
    }

    struct InitialItemData {
        address curveModule;
        bytes curveModuleInitData;
    }

    struct ItemInfo {
        uint256 supply; //total supply
        address creator; //creator address
        address curveModule; //curveModule address
        mapping(address => uint256) balanceOf; //holder -> balance
    }

    struct BuyItemData {
        uint256 itemIndex;
        uint256 amount;
        uint256 maxAcceptedPrice;
        address referralAddress;
    }

    struct SellItemData {
        uint256 itemIndex;
        uint256 amount;
        uint256 minAcceptedPrice;
        address referralAddress;
        address receiver;
    }

    struct TransferItemData {
        uint256 itemIndex;
        address to;
        uint256 amount;
    }
}
