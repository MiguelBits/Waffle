// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "@pancakeswap/v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import "./pool-cl/utils/CLTestUtils.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLSwapRouterBase} from "@pancakeswap/v4-periphery/src/pool-cl/interfaces/ICLSwapRouterBase.sol";
import {PoolId} from "@pancakeswap/v4-core/src/types/PoolId.sol";

import {WaffleHook} from "../src/WaffleHook.sol";
import {WaffleLendingManager} from "../src/WaffleLendingManager.sol";

contract WaffleHookTest is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    address eth;
    address usdc;
    address btc;

    address user = address(1);

    WaffleHook hook;

    MockERC20 token0;
    MockERC20 token1;

    PoolKey key;
    NonfungiblePositionManager pancake_periphery;

    Currency currency0;
    Currency currency1;

    WaffleLendingManager lendingManager;
    WaffleHook waffleHook;

    function setUp() public {
        token0 = new MockERC20("eth","eth",18);
        eth = address(token0);
        token1 = new MockERC20("usd","usd",6);
        usdc = address(token1);

        
        // create the lending manager
        lendingManager = new WaffleLendingManager(address(poolManager), address(pancake_periphery));
        lendingManager.setHook(address(waffleHook));

        poolManager = CLPoolManager(0x97e09cD0E079CeeECBb799834959e3dC8e4ec31A); //sepolia
        pancake_periphery = NonfungiblePositionManager(payable(0xf8d44CC59B87b7649F7BC37a8F1C86B2f3a92876)); //sepolia
        waffleHook = new WaffleHook(poolManager, lendingManager);

        //set currency0 and currency1
        currency0 = Currency.wrap(eth);
        currency1 = Currency.wrap(usdc);

        (currency0, currency1) = SortTokens.sort(token0, token1);
        console.log("currency0 ", MockERC20(Currency.unwrap(currency0)).name());
        console.log("currency1 ", MockERC20(Currency.unwrap(currency1)).name());
        
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: waffleHook,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            // tickSpacing: 10
            parameters: bytes32(uint256(waffleHook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        waffleHook.setKey(key);
        waffleHook.setNewEpoch(block.timestamp);

        // Create the pool
        // initialize pool for eth/usdc
        poolManager.initialize(key, 1419367377903407086326843728793702, new bytes(0));

        MockERC20(Currency.unwrap(currency0)).mint(address(lendingManager), 10000e6);
        MockERC20(Currency.unwrap(currency1)).mint(address(lendingManager), 2e18);

        MockERC20(Currency.unwrap(currency0)).mint(user, 3100e6);
        MockERC20(Currency.unwrap(currency1)).mint(user, 1e18);

        MockERC20(Currency.unwrap(currency0)).mint(address(waffleHook), 3100e6);
        MockERC20(Currency.unwrap(currency1)).mint(address(waffleHook), 1e18);
    }

    function test_swapBorrow() public {
        // approve token

        // deposit liquidity

        // check that the hook minted stablecoin
    }

    function test_getPrice() public view returns (uint256) {
        uint256 tokenId = 5;
        (
            ,
            ,
            PoolId poolId,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            
        ) = pancake_periphery.positions(tokenId);
        
        (uint256 price, ) = lendingManager.getCurrentPrice(poolId);
        console.log("price", price);
        price = price * 1e12;
        console.log("weth amount", price * 2e18 / 1e18);
        return price;
    }

    function test_lendLong() public {
        uint256 amount = 1e18;

        console.log("lendLong1");

        vm.startBroadcast(address(waffleHook));

        lendingManager.depositLiquidityForLending(key, 1e18, 1e6, true);

        console.log("lendLong2");

        MockERC20(Currency.unwrap(currency1)).approve(address(lendingManager), type(uint256).max);
        lendingManager.lendLong(key, amount, 2);

        uint256 debt = lendingManager.debtAccrued(address(waffleHook));
        console.log("debt", debt);

        vm.stopBroadcast();

        uint256 price = test_getPrice();
        console.log("price", price);
    }

    function test_addLiquidityLong() public {
        
        

    }
}
