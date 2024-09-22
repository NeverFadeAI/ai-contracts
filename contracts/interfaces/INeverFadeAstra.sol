// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface INeverFadeAstra {
    function mint(address to) external payable returns (bool);

    function _soldOut() external view returns (bool);

    function enforceAddLiquidity() external;

    function withdrawETH() external;
}
