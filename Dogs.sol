// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "hardhat/console.sol";


//部署到了goerli 测试网上  地址： 0xfeA78f34d0cb3A7aFB960A347488704C8bE9D044

contract Dogs is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public MAX_AMOUNT = 3; //铸造nft 最大数
    // string uri = ""; //metadata地址 元数据地址（JSON文件）
    mapping(address => bool) public whiteList; //添加福利白名单
    bool public preMintWindow = false; // 控制开启或关闭 preMint窗口期（时间）
    bool public mintWindow = false; // 控制开启或关闭 mint窗口期（时间）
    mapping(uint256 => uint256) public reqIdToTokenId; //随机数请求 与 tokenid相对应

    // 动态变化（metadata）需要的温度条件
    int256 public currentTmp;
    int256 public latestTmp;


    // ipfs上文文件（4张狗图） metadata
    // const Dog1JSON = "https://ipfs.filebase.io/ipfs/QmPP1ExZKzFNQpqoLJ2UBWNzYGSYWCgxDyrdfa9NeNNHY7";
    // string constant Dog1JSON = "ipfs://QmPP1ExZKzFNQpqoLJ2UBWNzYGSYWCgxDyrdfa9NeNNHY7";

    // 热天气的nft，冷天气的nft，不冷不热的nft，（这里都是一样的元数据，就没有分开写了）
    string constant Dog1JSON = "ipfs://QmaCViT5Kzs41MSJWgk4bpcL9gHBQNGAQKQm3MsEKGGcen";
    string constant Dog2JSON = "ipfs://QmPowr6B6WmGtxjwFJeT7U3gCoQ2aLUa2hj7EsW74gLdvW";
    string constant Dog3JSON = "ipfs://QmbzqATki4gfV8N6vWFUDmrNjZbJPL5KgeEADLS5TVhdMD";
    string constant Dog4JSON = "ipfs://QmXYBUeeEc5wAtTSopW3vWNNNHMuKmwZGkCcJKsninjrUL";
    string[] DogTypes = [Dog1JSON,Dog2JSON,Dog3JSON,Dog4JSON];
    // // METADATA of NFT
    // string constant METADATA_SHIBAINU = "ipfs://QmXw7TEAJWKjKifvLE25Z9yjvowWk2NWY3WgnZPUto9XoA";
    // string constant METADATA_HUSKY = "ipfs://QmTFXZBmmnSANGRGhRVoahTTVPJyGaWum8D3YicJQmG97m";
    // string constant METADATA_BULLDOG = "ipfs://QmSM5h4WseQWATNhFWeCbqCTAGJCZc11Sa1P5gaXk38ybT";
    // string constant METADATA_SHEPHERD = "ipfs://QmRGryH7a1SLyTccZdnatjFpKeaydJcpvQKeQTzQgEp9eK";    

    // chainlink 生成随机数需要
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;


    constructor(uint64 subscriptionId) ERC721("Dogs", "DGS") VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        s_subscriptionId = subscriptionId;
    }

    // 根据温度更新nft的元数据
    function updateLatestTmp(int256 temp) public {
        latestTmp = temp;
        // updateMetadata();
    }
    function updateMetadata() public {
        if(latestTmp != currentTmp){
            if(latestTmp < 10*10**18){ //小于10度，冷
                for(uint i=0;i<totalSupply();i++ ){
                    _setTokenURI(i, DogTypes[i]);
                }
            }else if(latestTmp > 18*10**18){//大于18度，热
                for(uint i=0;i<totalSupply();i++ ){
                    _setTokenURI(i, DogTypes[i]);
                }
            }else{ //不冷不热
                for(uint i=0;i<totalSupply();i++ ){
                    _setTokenURI(i, DogTypes[i]);
                }
            }
           currentTmp = latestTmp;
        }
    }

    // 给追随者优惠的价格铸造NFT 
    function preMint( ) public payable {
        require(preMintWindow, "PreMint is not open yet!");
        require(msg.value == 0.001 ether, "the price of dog nft is 0.001 ether");
        require(whiteList[msg.sender],"You are not in white list");//判断是否在白名单中
        require(balanceOf(msg.sender) < 1, "max amount of NFT minted by an address is 1"); //只能铸造一个
        require(totalSupply() < MAX_AMOUNT,"Dog NFT is sold out"); //totalSupply在某个继承的合约中已经实现了

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        // _setTokenURI(tokenId, uri);
        requestRandomWords(tokenId);
    }

    // 给正常的用户的价格
    function mint( ) public payable {
        require(mintWindow, "mint is not open yet!");
        require(msg.value == 0.005 ether, "the price of dog nft is 0.005 ether");
        require(totalSupply() < MAX_AMOUNT,"Dog NFT is sold out"); //totalSupply在某个继承的合约中已经实现了

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        // _setTokenURI(tokenId, uri);
        requestRandomWords(tokenId);
    }

    // 提现功能
    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    // 随机性需要预言机提供随机数
    // 请求预言机函数生成随机性
    function requestRandomWords(uint _tokenId)
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        reqIdToTokenId[requestId] = _tokenId;
        return requestId;
    }
    // 预言机调用函数，返回随机性的结果
        function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 randomNumber = _randomWords[0] % 4;
        if (randomNumber == 0) {
            _setTokenURI(reqIdToTokenId[_requestId], Dog1JSON);
        } else if (randomNumber == 1) {
            _setTokenURI(reqIdToTokenId[_requestId], Dog2JSON);
        } else if (randomNumber == 2) {
            _setTokenURI(reqIdToTokenId[_requestId], Dog3JSON);
        } else {
            _setTokenURI(reqIdToTokenId[_requestId], Dog4JSON);
        }
    }
    // function fulfillRandomWords(
    //     uint256 _requestId,
    //     uint256[] memory _randomWords
    // ) internal override {
    //     uint256 randomNumber = _randomWords[0] % 4;
    //     if (randomNumber == 0) {
    //         _setTokenURI(reqIdToTokenId[_requestId], METADATA_SHIBAINU);
    //     } else if (randomNumber == 1) {
    //         _setTokenURI(reqIdToTokenId[_requestId], METADATA_HUSKY);
    //     } else if (randomNumber == 2) {
    //         _setTokenURI(reqIdToTokenId[_requestId], METADATA_SHEPHERD);
    //     } else {
    //         _setTokenURI(reqIdToTokenId[_requestId], METADATA_BULLDOG);
    //     }
    // }




    // 添加白名单
    function addToWhiteList(address[] calldata addrs) public onlyOwner {
        for(uint i=0; i<addrs.length; i++){
            whiteList[addrs[i]] = true;
        }
    }

    //开启或关闭 窗口时间
    function setWindow(bool _premint, bool _mint) public onlyOwner {
        preMintWindow = _premint;
        mintWindow = _mint;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}