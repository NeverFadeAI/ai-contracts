// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

abstract contract ModuleBase {
    address public immutable NEVER_FADE_HUB;

    modifier onlyNeverFadeHub() {
        if (msg.sender != NEVER_FADE_HUB) revert Errors.NotNeverFadeHub();
        _;
    }

    constructor(address neverFadeHub) {
        if (neverFadeHub == address(0)) revert Errors.InitParamsInvalid();
        NEVER_FADE_HUB = neverFadeHub;
        emit Events.ModuleBaseConstructed(neverFadeHub, block.timestamp);
    }
}
