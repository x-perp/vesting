// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract XperpVestingContract is ReentrancyGuard {
    address public owner;
    IERC20 public xperpToken;
    uint256 public contractStartTime;
    uint256 public constant VESTING_DURATION = 30 days;
    uint256 public totalVestedAmount;

    mapping(address => uint256) public tokensAllocated;

    mapping(address => uint256) public tokensClaimed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address _xperpTokenAddress, address[] memory investors, uint256[] memory tokenAmounts) {
        require(investors.length == tokenAmounts.length, "Investors and tokenAmounts length mismatch");

        owner = msg.sender;
        xperpToken = IERC20(_xperpTokenAddress);
        contractStartTime = block.timestamp;

        for (uint256 i = 0; i < investors.length; i++) {
            tokensAllocated[investors[i]] = tokenAmounts[i];
            totalVestedAmount += tokenAmounts[i];
        }
    }

    function claim() external nonReentrant {
        require(block.timestamp >= contractStartTime, "Vesting hasn't started yet");
        require(tokensAllocated[msg.sender] > 0, "No tokens allocated for this address");

        uint256 elapsed = block.timestamp - contractStartTime;
        uint256 timeIntoVesting = elapsed > VESTING_DURATION ? VESTING_DURATION : elapsed;

        uint256 totalToBeClaimedTillNow = (tokensAllocated[msg.sender] * timeIntoVesting) / VESTING_DURATION;
        uint256 yetToBeClaimed = totalToBeClaimedTillNow - tokensClaimed[msg.sender];

        require(yetToBeClaimed > 0, "No tokens left to be claimed");

        tokensClaimed[msg.sender] += yetToBeClaimed;
        require(xperpToken.transfer(msg.sender, yetToBeClaimed), "Token transfer failed");
    }

    function recoverAnyERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(owner, _amount);
    }
}
