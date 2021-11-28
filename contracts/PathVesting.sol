pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PathVesting is Ownable{

    IERC20 private token;
    enum AllocationType { TEAM, BONUS, ADVISOR, PRIVATE, OTHER }


    uint public grandTotalClaimed = 0;
    uint public startTime;

    uint private totalAllocated;

    struct Allocation {
        uint allocationType; //type of Allocation
        uint initialAllocation; //Initial token allocated
        uint endIntitial; // Initial token claim locked until 
        uint endCliff; // Vested Tokens are locked until
        uint endVesting; // End vesting 
        uint totalAllocated; // Total tokens allocated
        uint amountClaimed;  // Total tokens claimed
    }

    struct TypeAllocated {
        uint totalAllocated; // Total tokens allocated
        uint amountClaimed;  // Total tokens claimed
    }

    mapping (address => Allocation) public allocations;
    mapping (AllocationType => TypeAllocated) public totalAllocatedTypes; // total allocated for each type

    event claimedToken(address indexed _recipient, uint tokensClaimed, uint totalClaimed);

    constructor (address _tokenAddress, uint _startTime) {
        require(_startTime >= 1638896400, "start time should be larger or equal to TGE");
        token = IERC20(_tokenAddress);
        startTime = _startTime;
    }

    function getClaimTotal(address _recipient) public view returns (uint amount) {
        return  calculateClaimAmount(_recipient) - allocations[_recipient].amountClaimed;
    }

    // view function to calculate claimable tokens
    function calculateClaimAmount(address _recipient) internal view returns (uint amount) {
         uint newClaimAmount;

        if (block.timestamp >= allocations[_recipient].endVesting) {
            newClaimAmount = allocations[_recipient].totalAllocated;
        }
        else {
            newClaimAmount = allocations[_recipient].initialAllocation;
            if (block.timestamp >= allocations[_recipient].endCliff) {
                newClaimAmount += ((allocations[_recipient].totalAllocated - allocations[_recipient].initialAllocation)
                    / (allocations[_recipient].endVesting - allocations[_recipient].endCliff))
                    * (block.timestamp - allocations[_recipient].endCliff);
            }
        }
        return newClaimAmount;
    }

    /**
    * @dev Set the minters and their corresponding allocations. Each mint gets 40000 Path Tokens with a vesting schedule
    * @param _addresses The recipient of the allocation
    * @param _totalAllocated The total number of minted NFT
    */
    function setAllocation(
        address[] memory _addresses,
        uint[] memory _totalAllocated,
        uint[] memory _initialAllocation,
        uint[] memory _endInitial,
        uint[] memory _endCliff,
        uint[] memory _endVesting,
        uint[] memory _allocationType) onlyOwner external {
        //make sure that the length of address and total minted is the same
        require(_addresses.length == _totalAllocated.length);
        for (uint i = 0; i < _addresses.length; i++ ) {
            require(_endInitial[i] <= _endCliff[i], "Initial claim should be earlier than end cliff time");
            allocations[_addresses[i]] = Allocation(
                _allocationType[i],
                _initialAllocation[i],
                _endInitial[i],
                _endCliff[i],
                _endVesting[i],
                _totalAllocated[i],
                0);
            totalAllocatedTypes[AllocationType(_allocationType[i])].totalAllocated += _totalAllocated[i];
            totalAllocated += _totalAllocated[i];
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
     * @dev transfers allocated tokens to recipient to their address
     * @param _recipient the addresss to withdraw tokens for
      */
    function transferTokens(address _recipient) external {
        require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated, "Address should have some allocated tokens");
        require(startTime <= block.timestamp, "Start time of claim should be later than current time");
        require(startTime <= allocations[_recipient].endIntitial, "Initial claim should be later than current time");
        //transfer tokens after subtracting tokens claimed
        uint newClaimAmount = calculateClaimAmount(_recipient);
        uint tokensToClaim = getClaimTotal(_recipient);
        require(tokensToClaim > 0, "Recipient should have more than 0 tokens to claim");
        allocations[_recipient].amountClaimed = newClaimAmount;
        grandTotalClaimed += tokensToClaim;
        totalAllocatedTypes[AllocationType(allocations[_recipient].allocationType)].amountClaimed += tokensToClaim;
        require(token.transfer(_recipient, tokensToClaim));
        emit claimedToken(_recipient, tokensToClaim, allocations[_recipient].amountClaimed);
    }

    //owner restricted functions
    /**
     * @dev reclaim excess allocated tokens for claiming
     * @param _amount the amount to withdraw tokens for
      */
    function reclaimExcessTokens(uint _amount) public onlyOwner {
        require(_amount <= totalAllocated - grandTotalClaimed - token.balanceOf(address(this)));
        require(token.transfer(msg.sender, _amount));
    }
}
