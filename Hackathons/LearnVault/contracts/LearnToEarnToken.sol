// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IDeFiProtocol {
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getYield(uint256 amount, uint256 duration) external view returns (uint256);
}

contract LearnToEarnToken is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Events
    event TaskCompleted(address indexed user, uint256 taskId, uint256 rewardAmount);
    event TokensStaked(address indexed user, uint256 amount, uint256 startTime);
    event YieldDistributed(address indexed user, uint256 yieldAmount);
    event DeFiProtocolSet(address indexed protocol);

    // Struct for staking information
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        bool isStaking;
    }

    // Mapping to track user stakes and task completions
    mapping(address => StakeInfo) public stakes;
    mapping(address => mapping(uint256 => bool)) public completedTasks;
    
    // DeFi protocol for staking
    IDeFiProtocol public defiProtocol;
    IERC20 public rewardToken;

    // Track active users for yield distribution
    EnumerableSet.AddressSet private activeStakers;

    constructor(address _rewardToken) ERC20("LearnToEarnToken", "L2E") {
        rewardToken = IERC20(_rewardToken);
    }

    // Function to verify task completion and reward tokens
    function completeTask(uint256 taskId, uint256 difficulty) external nonReentrant {
        require(!completedTasks[msg.sender][taskId], "Task already completed");

        // Custom logic for task verification can be added here
        completedTasks[msg.sender][taskId] = true;

        // Mint tokens to user (example: reward is proportional to task difficulty)
        uint256 rewardAmount = difficulty * 10**decimals();
        _mint(msg.sender, rewardAmount);

        emit TaskCompleted(msg.sender, taskId, rewardAmount);
    }

    // Function to stake earned tokens
    function stakeTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Transfer tokens to the contract and burn them
        _burn(msg.sender, amount);

        // Update staking info
        StakeInfo storage stake = stakes[msg.sender];
        stake.amount += amount;
        stake.startTime = block.timestamp;
        stake.isStaking = true;

        activeStakers.add(msg.sender);

        // Stake tokens in DeFi protocol
        defiProtocol.stake(amount);

        emit TokensStaked(msg.sender, amount, block.timestamp);
    }

    // Function to distribute yield from staking
    function distributeYield() external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        require(stake.isStaking, "No tokens staked");

        uint256 stakingDuration = block.timestamp - stake.startTime;
        uint256 yieldAmount = defiProtocol.getYield(stake.amount, stakingDuration);

        // Distribute yield
        rewardToken.safeTransfer(msg.sender, yieldAmount);

        emit YieldDistributed(msg.sender, yieldAmount);
    }

    // Function to withdraw staked tokens and yield
    function withdrawStake() external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        require(stake.isStaking, "No tokens staked");

        uint256 stakingDuration = block.timestamp - stake.startTime;
        uint256 yieldAmount = defiProtocol.getYield(stake.amount, stakingDuration);

        // Withdraw tokens from DeFi protocol
        defiProtocol.withdraw(stake.amount);

        // Transfer staked tokens and yield to user
        rewardToken.safeTransfer(msg.sender, yieldAmount);
        _mint(msg.sender, stake.amount);

        // Reset staking info
        stake.amount = 0;
        stake.startTime = 0;
        stake.isStaking = false;

        activeStakers.remove(msg.sender);

        emit YieldDistributed(msg.sender, yieldAmount);
    }

    // Owner can set the DeFi protocol address (for integration)
    function setDeFiProtocol(address _defiProtocol) external onlyOwner {
        defiProtocol = IDeFiProtocol(_defiProtocol);
        emit DeFiProtocolSet(_defiProtocol);
    }

    // Function to retrieve staking information
    function getStakingInfo(address user) external view returns (uint256, uint256, bool) {
        StakeInfo storage stake = stakes[user];
        return (
            stake.amount,
            stake.startTime,
            stake.isStaking
        );
    }
}
