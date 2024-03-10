//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IERC20.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/SafeERC20.sol";
import "hardhat/console.sol";

contract FlashLoan {
    using SafeERC20 for IERC20;
    // Factory and Routing Addresses
    address private constant PANCAKE_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Token Addresses
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant CROX = 0x2c094F5A7D1146BB93850f629501eB749f6Ed491;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    uint256 private deadline = block.timestamp + 1 days;
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    function initiateArbitrage(address busdAddress, uint amount) external {
        IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(CROX).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(BUSD).safeApprove(address(PANCAKE_ROUTER), MAX_INT);

        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
            busdAddress,
            WBNB
        );

        require(pair != address(0), "InitiateArbitrage: Pool not found");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint amount0ToBorrow = busdAddress == token0 ? amount : 0;
        uint amount1ToBorrow = busdAddress == token1 ? amount : 0;

        bytes memory data = abi.encode(busdAddress, amount, msg.sender);
        IUniswapV2Pair(pair).swap(
            amount0ToBorrow,
            amount1ToBorrow,
            address(this),
            data
        );
    }

    function pancakeCall(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
            token0,
            token1
        );

        require(pair == msg.sender, "PancakeCall: Invalid caller");
        require(sender == address(this), "PancakeCall: Invalid sender");

        (address busdAddress, uint amount, address userAddress) = abi.decode(
            data,
            (address, uint, address)
        );

        uint fee = ((amount * 3) / 997) + 1;
        uint repayAmount = amount + fee;
        uint loanAmount = amount0 > 0 ? amount0 : amount1;

        uint trade1Token = placeTrade(BUSD, CROX, loanAmount);
        uint trade2Token = placeTrade(CROX, CAKE, trade1Token);
        uint trade3Token = placeTrade(CAKE, BUSD, trade2Token);

        console.log("Trading BUSD => CROX :", loanAmount/(10**18), "=>", trade1Token/(10**18));
        console.log("Trading CROX => CAKE :", trade1Token/(10**18), "=>", trade2Token/(10**18));
        console.log("Trading CAKE => BUSD :", trade2Token/(10**18), "=>", trade3Token/(10**18));

        bool profit = checkProfit(repayAmount, trade3Token);
        require(profit, "PancakeCall: Arbitrage is not profitable");

        IERC20(BUSD).transfer(userAddress, trade3Token - repayAmount);
        IERC20(busdAddress).transfer(pair, repayAmount);
    }

    function placeTrade(
        address fromToken,
        address toToken,
        uint amountToTrade
    ) private  returns (uint) {
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(
            fromToken,
            toToken
        );
        require(pair != address(0), "PlaceTrade: Pair not fount");
        address[] memory path = new address[](2);
        (path[0], path[1]) = (fromToken, toToken);

        uint estimatedResultToken = IUniswapV2Router01(PANCAKE_ROUTER)
            .getAmountsOut(amountToTrade, path)[1];

        uint amountReceived = IUniswapV2Router01(PANCAKE_ROUTER)
            .swapExactTokensForTokens(
                amountToTrade,
                estimatedResultToken,
                path,
                address(this),
                deadline
            )[1];

        require(amountReceived > 0, "PlaceTrade: Transactoin aborted");
        return amountReceived;
    }

    function checkProfit(
        uint repayAmount,
        uint earnedToken
    ) private pure returns (bool) {
        return earnedToken > repayAmount;
    }

    function getBalanceOfToken(address tokenAddress) public view returns(uint){
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
