// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

library Errors {
    error NotItemOwner();
    error NotGovernance(); //b56f932c
    error CurveModuleNotWhitelisted(); //161b556c
    error NotNeverFadeHub(); //1e70a69a
    error InitParamsInvalid(); //48be0eb3
    error ItemNotInitialized(); //5685edd8
    error InsufficientItemAmount(); //324bf1cb
    error MsgValueNotEnough(); //1be2f2a2
    error ReferralRatioTooHigh(); //94ca060c
    error NotSupportedFunction(); //3e784e83
    error ExceedMaxAcceptedPrice(); //B018E8A5
    error ConstCurveCannotSell(); //9696d3e3
    error LessThanMinAcceptedPrice(); //a2361c2b
    error CanNotBeZeroAddress(); //45281e4c
    error InvalidAmount(); //2c5211c6
    error InvalidToAddress(); //8aa3a72f
    error InvalidFeePercent(); //8a81d3b3
    error SendETHFailed(); //56761812
    error InitializeItemForUserNotOpen(); //b1b3b1b3
}
