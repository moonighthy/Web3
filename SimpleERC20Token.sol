// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleERC20Token is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("SimpleToken", "STKN") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract LiquidityMining is Ownable {
    IERC20Metadata public token;
    uint256 public rewardRate;
    uint256 public constant scaleFactor = 10**18;

    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userRewards;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 reward);

    constructor(IERC20Metadata _token, uint256 _rewardRate) {
        token = _token;
        rewardRate = _rewardRate;
    }
    event Debug(string message, address sender, uint256 amount);

    function deposit(uint256 amount) external {
        emit Debug("Deposit called", msg.sender, amount);
        require(amount > 0, "Amount must be greater than 0");
        emit Debug("Before transferFrom", msg.sender, amount);
        token.transferFrom(msg.sender, address(this), amount);
        userDeposits[msg.sender] += amount;
        _updateRewards(msg.sender);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(userDeposits[msg.sender] >= amount, "Insufficient balance");
        token.transfer(msg.sender, amount);
        userDeposits[msg.sender] -= amount;
        _updateRewards(msg.sender);
        emit Withdraw(msg.sender, amount);
    }

    function claimRewards() external {
        uint256 reward = _calculateReward(msg.sender);
        require(reward > 0, "No rewards available");
        token.transfer(msg.sender, reward);
        userRewards[msg.sender] = 0;
        emit Claim(msg.sender, reward);
    }

    function _updateRewards(address user) internal {
        userRewards[user] += _calculateReward(user);
    }

    function _calculateReward(address user) internal view returns (uint256) {
        return (userDeposits[user] * rewardRate * scaleFactor) / token.totalSupply();
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }
}
