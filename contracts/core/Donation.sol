// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Donation is Ownable {
    error ZeroValue();
    error SendETHFailed();
    event Receive(address indexed user, uint256 donation_amount);

    constructor(address owner) Ownable(owner) {}

    receive() external payable {
        if (msg.value == 0) {
            revert ZeroValue();
        }
        emit Receive(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        address owner = owner();
        uint256 bal = address(this).balance;
        (bool success, ) = payable(owner).call{value: bal}("");
        if (!success) {
            revert SendETHFailed();
        }
    }
}
