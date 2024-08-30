// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

library Errors {
    error NotItemOwner();
    error Paused(); //9e87fac8
    error NotGovernance(); //b56f932c
    error CannotInitImplementation(); //971d0414
    error Initialized(); //5daa87a0
    error SignatureInvalid(); //37e8456b
    error CurveModuleNotWhitelisted(); //161b556c
    error ItemAlreadyInitialized(); //b64662c5
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
    error TransferNotSupport(); //d2dcfd2c
    error NotAllowBotTrade(); //b11ba392
    error CanNotBeZeroAddress(); //45281e4c
    error OnlySupportDefaultCurve(); //8421be29
    error InitializeItemPaused(); //1b1d90d7
    error InvalidAmount(); //2c5211c6
    error InvalidToAddress(); //8aa3a72f
    error InvalidFeePercent(); //8a81d3b3
    error SendETHFailed(); //56761812
}
