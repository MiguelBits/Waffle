// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@pancakeswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "./pool-cl/CLBaseHook.sol";
import "../lib/Options-Margin/src/libraries/IVXPricer.sol";
import {WaffleLendingManager} from "./WaffleLendingManager.sol";

contract WaffleHook is CLBaseHook {
    using PoolIdLibrary for PoolKey;

    uint256 public epochEnd;
    PoolKey public key;
    WaffleLendingManager public manager;

    constructor(ICLPoolManager _poolManager, WaffleLendingManager _manager) CLBaseHook(_poolManager) {
        manager = _manager;
    }

    function setKey(PoolKey memory _key) external {
        key = _key;
    }

    function setNewEpoch(uint256 epoch) external {
        epochEnd = epoch + 24 hours;
    }
    
    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterAddLiquidityReturnsDelta: false,
                afterRemoveLiquidityReturnsDelta: false
            })
        );
    }

    /*
    function test_calculateBSPrices() public {
        // Set the test parameters
        uint256 timeToExp = 2 days;
        uint256 vol = 6500000000000000000;
        uint256 spot = 1500000000000000000000;
        uint256 strike = 2000000000000000000000;
        int256 rate = 50000000000000000;

        IVXPricer.PricingInputs memory inputs =
            IVXPricer.PricingInputs(IVXPricer.FetchedInputs(vol, spot, strike), timeToExp, rate, 0);
        (uint256 call, uint256 put) = IVXPricer.calculateBSPrices(inputs);
        console.log("call", call); //buy option
        console.log("put ", put); //sell option
    }*/

    function beforeAddLiquidity(
        address,
        PoolKey calldata _key,
        ICLPoolManager.ModifyLiquidityParams calldata _liqParams,
        bytes calldata _data
    ) external override returns (bytes4) {
        if(msg.sender == address(manager)) {
            return this.beforeAddLiquidity.selector;
        }

        (bool isLong, uint256 _amountCollateral) = abi.decode(_data, (bool, uint256));
        
        if(_amountCollateral == 0) {
            return this.beforeAddLiquidity.selector;
        }     

        manager.lendLong(key, _amountCollateral, 2);
        
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata _key,
        ICLPoolManager.ModifyLiquidityParams calldata _liqParams,
        BalanceDelta _delta,
        bytes calldata _data
    ) external override returns (bytes4, BalanceDelta) {
        if(msg.sender == address(manager)) {
            return (this.beforeAddLiquidity.selector, toBalanceDelta(0,0));
        }

        PoolId poolId = key.toId();
        
        (bool isLong, uint256 _amountCollateral) = abi.decode(_data, (bool, uint256));
        
        if(_amountCollateral == 0) {
            return (this.beforeAddLiquidity.selector, toBalanceDelta(0,0));
        }

        uint256 timeToExp = epochEnd - block.timestamp;
        uint256 vol = 6500000000000000000;
        (uint256 spot, ) = manager.getCurrentPrice(poolId); 
        int24 tickUpper = _liqParams.tickUpper;
        int24 tickLower = _liqParams.tickLower;
        
        uint256 strike;
        //convert int24 to uint256
        if(isLong) {
            strike = uint256(int256(tickUpper)) * 1e12;
        } 
        else {
            strike = uint256(int256(tickLower)) * 1e12;
        }

        int256 rate = 50000000000000000;

        IVXPricer.PricingInputs memory inputs =
            IVXPricer.PricingInputs(IVXPricer.FetchedInputs(vol, spot, strike), timeToExp, rate, 0);
        (uint256 call, uint256 put) = IVXPricer.calculateBSPrices(inputs);

        BalanceDelta delta;

        //call *= amountOfContracts
        //put *= amountOfContracts

        if(isLong){
            delta = toBalanceDelta(int128(int256(call)), 0);
        }
        else {
            delta = toBalanceDelta(0, int128(int256(put)));
        }

        return (this.beforeAddLiquidity.selector, delta);
    }

    function toBalanceDelta(int128 _amount0, int128 _amount1) internal pure returns (BalanceDelta balanceDelta) {
        assembly ("memory-safe") {
            balanceDelta := or(shl(128, _amount0), and(sub(shl(128, 1), 1), _amount1))
        }
    }
}
