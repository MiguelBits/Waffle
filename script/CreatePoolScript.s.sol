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

import {WaffleHook} from "../src/WaffleHook.sol";

contract CreatePoolScript is Script {
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
    //NonfungiblePositionManager pancake_periphery;

    function setUp() public {}

    function run() public {
        CLPoolManager poolManager = CLPoolManager(0x97e09cD0E079CeeECBb799834959e3dC8e4ec31A); //sepolia
        //pancake_periphery = NonfungiblePositionManager(0xf8d44CC59B87b7649F7BC37a8F1C86B2f3a92876); //sepolia

        //set currency0 and currency1
        Currency currency0 = Currency.wrap(eth);
        Currency currency1 = Currency.wrap(usdc);

        vm.startBroadcast();

        //& create the hook
        hook = new WaffleHook(poolManager);

        // create the pool key
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            // tickSpacing: 10
            parameters: bytes32(uint256(hook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        // Create the pool
        // initialize pool for eth/usdc
        poolManager.initialize(key, 1419367377903407086326843728793701, new bytes(0));

        vm.stopBroadcast();
    }
}
