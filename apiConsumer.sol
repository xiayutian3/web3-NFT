// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./Dogs.sol";


contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    int256 public temp; //温度
    bytes32 private jobId;
    uint256 private fee;
    uint public cityCode = 440300;
    Dogs public dogs;

    constructor( address dogAddr) ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
        dogs = Dogs(dogAddr);
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestTempData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        // https://restapi.amap.com/v3/weather/weatherInfo?city=440300&key=8ea4bbbd0efed89f75ac1dafb54baf6e
        string memory api =string(
            abi.encodePacked("https://restapi.amap.com/v3/weather/weatherInfo?city=",cityCode,"&key=8ea4bbbd0efed89f75ac1dafb54baf6e")
            ); 
        req.add(
            "get",
            api
        );


        req.add("path", "lives, 0, temperature"); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10 ** 18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        int256 _temp
    ) public recordChainlinkFulfillment(_requestId) {
        temp = _temp;
        dogs.updateLatestTmp(_temp); //更新温度
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
