// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Constants} from "@pancakeswap/v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {CLCounterHook} from "../src/pool-cl/CLCounterHook.sol";
//import "..src/pool-cl/utils/CLTestUtils.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLSwapRouterBase} from "@pancakeswap/v4-periphery/src/pool-cl/interfaces/ICLSwapRouterBase.sol";
import {CLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/CLPoolManager.sol";
import {SortTokens} from "@pancakeswap/v4-core/test/helpers/SortTokens.sol";
import {NonfungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-cl/NonfungiblePositionManager.sol";
import {INonfungiblePositionManager} from
    "@pancakeswap/v4-periphery/src/pool-cl/interfaces/INonfungiblePositionManager.sol";

import {WaffleHook} from "../src/WaffleHook.sol";


contract AddLiquidityScript is Script {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    address eth = 0xA2bFA4Cd0171f124Df6ed94a41D79A81B5Ffb42d;
    address usdc = 0x60Be8D6884fF778db96968635F6089029Ecf0799;
    address btc = 0x1e45F105146d7499fE056d646E55F93dc0DC751F;
    address nft = 0x14E33Aec2C60cFB73b6E2dff2c788bB5E8BF8dce;

    uint256 amount0 = 1 ether;
    uint256 amount1 = 1000 * 10**6; // 1000 usdc

    WaffleHook hook = WaffleHook(0x212De9edC27d871Cf974cC27B02CC64E17efF441); //TODO
    MockERC20 token0 = MockERC20(eth); //TODO
    MockERC20 token1 = MockERC20(usdc); //TODO
    NonfungiblePositionManager pancake_periphery = NonfungiblePositionManager(payable(0xf8d44CC59B87b7649F7BC37a8F1C86B2f3a92876));
    
    function setUp() public {}

    function run() public {
        CLPoolManager poolManager = CLPoolManager(0x97e09cD0E079CeeECBb799834959e3dC8e4ec31A); //sepolia
        //set currency0 and currency1
        (Currency currency0, Currency currency1) = SortTokens.sort(token0, token1);

        vm.startBroadcast();

        token0.approve(address(pancake_periphery), amount0);
        token1.approve(address(pancake_periphery), amount1);

        _addLiquidity(
            PoolKey({
                currency0: currency0,
                currency1: currency1,
                hooks: hook,
                poolManager: poolManager,
                fee: uint24(3000), // 0.3% fee
                // tickSpacing: 10
                parameters: bytes32(uint256(hook.getHooksRegistrationBitmap())).setTickSpacing(10)
            }),
            amount0,
            amount1,
            int24(195877-107), //TODO
            int24(195877+103)   //TODO
        );

        vm.stopBroadcast();
    }

    function _addLiquidity(PoolKey memory _key, uint256 _amount0, uint256 _amount1, int24 tickLower, int24 tickUpper)
        internal
    {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            poolKey: _key,
            tickLower: tickLower,
            tickUpper: tickUpper,
            salt: bytes32(0),
            amount0Desired: _amount0,
            amount1Desired: _amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: 0x10704c7c238CAaCB6e2bC41CF1dbACAAD5E5AEf7, //TODO me
            deadline: block.timestamp + 1 days
        });

        pancake_periphery.mint(mintParams);
    }
}
