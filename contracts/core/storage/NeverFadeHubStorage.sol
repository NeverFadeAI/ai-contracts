// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {DataTypes} from "../../libraries/DataTypes.sol";

/**
 * @title NeverFadeHubStorage
 *
 * @notice This is an abstract contract that *only* contains storage for the NeverFadeHub contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the NeverFadeHub storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract NeverFadeHubStorage {
    // ItemItem => ItemInfo
    mapping(uint256 => DataTypes.ItemInfo) public _keyItemInfo;

    //whitelist curve address
    mapping(address => bool) public _curveModuleWhitelisted;

    uint256 public _globalItemIndex;
    uint256 public _tradeIndex;

    //protocol fee address
    address public _protocolFeeAddress;
    //governance address
    address public _governance;

    address public _neverFadeAstraAddress;
    bool public _pointsSoldOut;
}
