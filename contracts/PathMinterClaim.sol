pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PathMinterClaim is Ownable{

    IERC20 private token;

    uint256 public initialPercentage;
    uint256 public grandTotalClaimed = 0;
    uint256 public startTime;
    uint256 public endVesting;

    struct Allocation {
        uint256 initialAllocation; //Initial token allocated
        uint256 totalAllocated; // Total tokens allocated
        uint256 amountClaimed;  // Total tokens claimed
    }

    mapping (address => Allocation) public allocations;

    event claimedToken(address indexed minter, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress, uint256 _startTime, uint256 _endVesting, uint256 _initialPercentage) {
        require(_startTime >= block.timestamp);
        token = IERC20(_tokenAddress);
        startTime = _startTime;
        endVesting = _endVesting;
        initialPercentage = _initialPercentage;
    }

    /**
    * @dev Set the minters and their corresponding allocations. Each mint gets 40000 Path Tokens with a vesting schedule
    * @param _addresses The recipient of the allocation
    * @param _totalAllocated The total number of minted NFT
    */
    function setAllocation (address[] memory _addresses, uint[] memory _totalAllocated) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length);
        for (uint i = 0; i < _addresses.length; i++ ) {
            uint initialAllocation =  _totalAllocated[i] * initialPercentage / 100;
            allocations[_addresses[i]] = Allocation(initialAllocation, _totalAllocated[i], 0);
        }
    }

    /**
    * @dev Check current claimable amount
    * @param _recipient recipient of allocation
     */
    function getRemainingAmount (address _recipient) public view returns (uint amount) {
        return allocations[_recipient].totalAllocated - allocations[msg.sender].amountClaimed;
    }

    /**
    * @dev Allows msg.sender to claim their allocated tokens. Able to claim monthly
     */

    function claim() external {
        require(allocations[msg.sender].amountClaimed < allocations[msg.sender].totalAllocated);
        require(startTime >= block.timestamp);
        uint newClaimAmount;

        if (block.timestamp >= endVesting) {
            newClaimAmount = allocations[msg.sender].totalAllocated;
        }
        else {
            //check to make sure that number of months does not go beyond vesting duration
            newClaimAmount = allocations[msg.sender].initialAllocation;
            newClaimAmount += ((allocations[msg.sender].totalAllocated - allocations[msg.sender].initialAllocation) / (endVesting - startTime)) * (block.timestamp - startTime);
        }
        //transfer tokens after subtracting tokens claimed
        uint tokensToClaim = newClaimAmount - allocations[msg.sender].amountClaimed;
        allocations[msg.sender].amountClaimed = newClaimAmount;
        require(token.transfer(msg.sender, tokensToClaim));
        grandTotalClaimed += tokensToClaim;
        emit claimedToken(msg.sender, tokensToClaim, allocations[msg.sender].amountClaimed);
    }
}