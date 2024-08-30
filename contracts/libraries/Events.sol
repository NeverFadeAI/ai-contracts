// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {DataTypes} from "./DataTypes.sol";

library Events {
    /**
     * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    event ProtocolFeeAddressSet(
        address indexed caller,
        address indexed prevProcotolFeeAddress,
        address indexed newProcotolFeeAddress,
        uint256 timestamp
    );

    event CurveModuleWhitelisted(
        address indexed curveModule,
        bool whitelist,
        uint256 timestamp
    );

    event ModuleBaseConstructed(
        address indexed neverFadeHub,
        uint256 timestamp
    );

    event TradeItemSuccess(
        uint256 tradeIndex,
        uint256 amount,
        uint256 price,
        uint256 timestamp,
        uint256 balance,
        uint256 supply,
        address trader,
        address receiver,
        uint256 itemIndex,
        address referrer,
        bool isBuy
    );

    event TransferItemSuccess(
        uint256 tradeIndex,
        address from,
        address to,
        uint256 itemIndex,
        uint256 amount,
        uint256 balanceOfFrom,
        uint256 balanceOfTo,
        uint256 supply,
        uint256 timestamp
    );
}
