// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LabMonster is ERC721URIStorage, VRFConsumerBaseV2 {
    using Strings for uint256;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId = 1305;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 s_keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    address s_owner;
    address public owner;

    string public baseTokenURI = "QmRaJabTWUT9orFKC98HfpudKdBj9VkKFJydSj3HFkYoXm";
    address public tokenAddress;
    uint256 constant DECIMALS = 10**18;
    uint256 price = 15;

    mapping(uint256 => address) public s_rollers;
    mapping(address => uint256) public s_results;

    uint256 private constant ROLL_IN_PROGRESS = 42;

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);
    event output(uint256 output);

    constructor() ERC721("Lab Monstaer", "LAVMONSTER") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "!owner");
      _;
    }

    function updateSlabs(address _address) public onlyOwner{
        tokenAddress = _address;
    }

    function mint(uint256 mintID) public {
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) > (price * DECIMALS),
            "Not enough SLABS to mint"
        );
        require(
            IERC20(tokenAddress).allowance(msg.sender, address(this)) > (price * DECIMALS),
            "Not enough SLABS to mint"
        );
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), price * DECIMALS);
        _safeMint(msg.sender, mintID);
    }

    function rollDice(address player) external returns (uint256 requestId) {
        // require(s_results[roller] == 0, 'Already rolled');
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_rollers[requestId] = player;
        s_results[player] = ROLL_IN_PROGRESS;
        
        emit DiceRolled(requestId, _msgSender());
        return requestId;   
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 d20Value = (randomWords[0] % 100) + 1;
        s_results[s_rollers[requestId]] = d20Value;
        emit DiceLanded(requestId, d20Value);
    }

    function house(address player) public view returns (uint256) {
        require(s_results[player] != 0, "Dice not rolled");
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");
        return s_results[player];
        // s_results[player]=0;
        // emit output(_output);
        // return getTokenURI(_output);
    }

    function resettherandomvalue(address player) public {
        s_results[player] = 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
}
