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
        require(_startTime <= _endVesting, "start time should be larger than endtime");
        token = IERC20(_tokenAddress);
        startTime = _startTime;
        endVesting = _endVesting;
        initialPercentage = _initialPercentage;
    }



    function getClaimTotal(address _recipient) public view returns (uint amount) {
        return  calculateClaimAmount(_recipient) - allocations[_recipient].amountClaimed;
    }

    // view function to calculate claimable tokens
    function calculateClaimAmount(address _recipient) internal view returns (uint amount) {
         uint newClaimAmount;

        if (block.timestamp >= endVesting) {
            newClaimAmount = allocations[_recipient].totalAllocated;
        }
        else {
            newClaimAmount = allocations[_recipient].initialAllocation;
            newClaimAmount += ((allocations[_recipient].totalAllocated - allocations[_recipient].initialAllocation) / (endVesting - startTime)) * (block.timestamp - startTime);
        }
        return newClaimAmount;
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
    * @dev Allows msg.sender to claim their allocated tokens
     */

    function claim() external {
        require(allocations[msg.sender].amountClaimed < allocations[msg.sender].totalAllocated, "Address should have some allocated tokens");
        require(startTime <= block.timestamp, "Start time of claim should be later than current time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(msg.sender);
        uint tokensToClaim = getClaimTotal(msg.sender);
        allocations[msg.sender].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        require(token.transfer(msg.sender, tokensToClaim));
        emit claimedToken(msg.sender, tokensToClaim, allocations[msg.sender].amountClaimed);
    }
}