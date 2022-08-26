// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ILabMonster {
    function rollDice(address _address) external; 
}

contract SLABS is ERC20 {

    ILabMonster LabMonster;

    uint8 _decimals;
    uint256 _totalSupply = 1000 ether;
    address public owner;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    constructor() ERC20("Starter Labs", "SLABS") {
      _decimals = 18;
      balances[msg.sender] = _totalSupply;
      owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "!owner");
      _;
    }

    function updateMonster(address _address) public onlyOwner {
        LabMonster = ILabMonster(_address);
    }

    function _rollDice(address _address) internal {
      LabMonster.rollDice(_address);
    }

    function decimals() public view virtual override returns (uint8) {
        if (_decimals > 0) return _decimals;
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
      return _totalSupply;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _rollDice(_owner);
        _approve(_owner, spender, amount);
        return true;
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

}