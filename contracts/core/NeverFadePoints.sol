// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";

contract NeverFadePoints is ERC20 {
    error NotNeverFadeHub();
    error NoMsgValue();
    error SendETHFailed();
    error TransferNotAllowed();
    error CreatePairFailed();
    error InvalidAddress();

    address immutable NEVER_FADE_HUB;
    address immutable _v3NonfungiblePositionManager;

    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant MAX_SUPPLY = 100_000_000_000_000 * 10 ** 18;
    uint256 public constant TEAM_RESERVE = 10_000_000_000_000 * 10 ** 18; //10%
    uint256 public constant LP_RESERVE = 45_000_000_000_000 * 10 ** 18; //45%
    uint256 public _tokenLeftForNeverFade = 45_000_000_000_000 * 10 ** 18; //45% for NeverFadeHub, 45% for LP and raise for 450 eth
    bool public _canTransfer = false;
    bool public _soldOut = false;
    address public _poolAddress;
    address public _teamAddress;

    event AddLiquidity(
        address tokenAddress,
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    modifier onlyNeverFadeHub() {
        if (msg.sender != NEVER_FADE_HUB) revert NotNeverFadeHub();
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address neverFadeHub,
        address v3NonfungiblePositionManager,
        address teamAddress
    ) ERC20(name, symbol) {
        if (
            neverFadeHub == address(0) ||
            v3NonfungiblePositionManager == address(0) ||
            teamAddress == address(0)
        ) {
            revert InvalidAddress();
        }
        NEVER_FADE_HUB = neverFadeHub;
        _mint(address(this), LP_RESERVE); //mint 45% token into this contract for LP

        _v3NonfungiblePositionManager = v3NonfungiblePositionManager;
        _teamAddress = teamAddress;
        _poolAddress = _createUniswapV3Pool(
            792281625142643375935,
            7922816251426433759354395033600000000
        ); //initial uniswap pool for price 1eth = 10_000_000_000_000_000 * 10 ** 18 points token
    }

    function mint(address to) external payable onlyNeverFadeHub returns (bool) {
        if (msg.value == 0) revert NoMsgValue();
        if (_soldOut) return false;

        uint256 amount = msg.value * 10_000_000_000_000_000;
        if (amount > _tokenLeftForNeverFade) {
            amount = _tokenLeftForNeverFade;
        }
        _tokenLeftForNeverFade -= amount;
        _mint(to, amount);
        if (_tokenLeftForNeverFade == 0) {
            _addLiquidity();
        }
        return true;
    }

    function withdrawETH() external onlyNeverFadeHub {
        (bool suc, ) = payable(_teamAddress).call{value: address(this).balance}(
            ""
        );
        if (!suc) {
            revert SendETHFailed();
        }
    }

    function enforceAddLiquidity() external onlyNeverFadeHub {
        _addLiquidity();
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        if (!_canTransfer) {
            if (from != address(0)) {
                revert TransferNotAllowed();
            }
        }
        super._update(from, to, value);
    }

    function _createUniswapV3Pool(
        uint160 sqrtPriceX96,
        uint160 sqrtPriceB96
    ) private returns (address) {
        address weth_ = INonfungiblePositionManager(
            _v3NonfungiblePositionManager
        ).WETH9();

        (address token0, address token1, bool zeroForOne) = address(this) <
            weth_
            ? (address(this), weth_, true)
            : (weth_, address(this), false);

        address pool = INonfungiblePositionManager(
            _v3NonfungiblePositionManager
        ).createAndInitializePoolIfNecessary(
                token0,
                token1,
                uint24(10_000),
                zeroForOne ? sqrtPriceX96 : sqrtPriceB96
            );
        if (pool == address(0)) {
            revert CreatePairFailed();
        }
        return pool;
    }

    function _addLiquidity() private {
        address _weth = INonfungiblePositionManager(
            _v3NonfungiblePositionManager
        ).WETH9();

        (address token0, address token1, bool zeroForOne) = address(this) <
            _weth
            ? (address(this), _weth, true)
            : (_weth, address(this), false);

        uint256 ethValue = address(this).balance;
        {
            (
                uint256 tokenId,
                uint128 liquidity,
                uint256 amount0,
                uint256 amount1
            ) = INonfungiblePositionManager(_v3NonfungiblePositionManager).mint{
                    value: ethValue
                }(
                    INonfungiblePositionManager.MintParams({
                        token0: token0,
                        token1: token1,
                        fee: uint24(10_000),
                        tickLower: int24(-887200),
                        tickUpper: int24(887200),
                        amount0Desired: zeroForOne ? LP_RESERVE : ethValue,
                        amount1Desired: zeroForOne ? ethValue : LP_RESERVE,
                        amount0Min: 0,
                        amount1Min: 0,
                        recipient: _teamAddress,
                        deadline: block.timestamp
                    })
                ); //add liquidity to uniswap v3 pool, and burn LP token, receipient is ZeroAddress

            emit AddLiquidity(
                address(this),
                tokenId,
                liquidity,
                amount0,
                amount1
            );
        }

        uint256 leftToken = balanceOf(address(this));
        if (leftToken > 0) {
            transfer(DEAD_ADDRESS, leftToken);
        }
        INonfungiblePositionManager(_v3NonfungiblePositionManager).refundETH();
        if (address(this).balance > 0) {
            (bool success, ) = payable(_teamAddress).call{
                value: address(this).balance
            }("");
            if (!success) {
                revert SendETHFailed();
            }
        }
        _canTransfer = true; // allow transfer token
        _soldOut = true;
        _mint(_teamAddress, TEAM_RESERVE); // mint 10% token for team
    }
}
