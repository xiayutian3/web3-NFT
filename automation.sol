// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./Dogs.sol";


// 自动化更新元数据metadada

contract Counter is AutomationCompatibleInterface {

    Dogs public dogs;


    constructor(address addr) {
        dogs = Dogs(addr);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
       upkeepNeeded = (dogs.currentTmp() != dogs.latestTmp());//判断温度是否相等
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        dogs.updateMetadata(); //更新元数据
    }
}
