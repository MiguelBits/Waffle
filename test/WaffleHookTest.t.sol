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

    address eth = 0xA2bFA4Cd0171f124Df6ed94a41D79A81B5Ffb42d;
    address usdc = 0x60Be8D6884fF778db96968635F6089029Ecf0799;
    address btc = 0x1e45F105146d7499fE056d646E55F93dc0DC751F;
    address nft = 0x14E33Aec2C60cFB73b6E2dff2c788bB5E8BF8dce;

    WaffleHook hook;
    MockERC20 token0 = MockERC20(eth); //TODO
    MockERC20 token1 = MockERC20(usdc); //TODO
    PoolKey key;
    NonfungiblePositionManager pancake_periphery;

    Currency currency0;
    Currency currency1;

    WaffleLendingManager lendingManager;

    function setUp() public {
        poolManager = CLPoolManager(0x97e09cD0E079CeeECBb799834959e3dC8e4ec31A); //sepolia
        pancake_periphery = NonfungiblePositionManager(payable(0xf8d44CC59B87b7649F7BC37a8F1C86B2f3a92876)); //sepolia

        //set currency0 and currency1
        currency0 = Currency.wrap(eth);
        currency1 = Currency.wrap(usdc);

        // create the lending manager
        lendingManager = new WaffleLendingManager(address(poolManager), address(pancake_periphery));
    }

    function test_swapBorrow() public {
        // approve token

        // deposit liquidity

        // check that the hook minted stablecoin
    }

    function test_getPrice() public view{
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
    }

    function test_lendLong() public {
        lendingManager.depositLiquidityForLending(key, 1e18, 1);
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
        
        lendingManager.lendLong(poolId, 1e18, 2);
        uint256 debt = lendingManager.debtAccrued(msg.sender);
        console.log("debt", debt);

    }
}
