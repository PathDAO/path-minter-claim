const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Path Vesting contract", function () {
  let PathToken;
  let Path;
  let PathAddr;
  let owner;
  let addr1;
  let addr2;
  let timeStart;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    PathToken = await ethers.getContractFactory("PathToken");
    PathVestingContract = await ethers.getContractFactory("PathVesting");
    timeStart = 1638896400;
    [owner, addr1, addr2] = await ethers.getSigners();
    //deploy contract
    Path = await PathToken.deploy("1000000000000000000000000000");
    PathAddr = Path.address
    PathVesting = await PathVestingContract.deploy(PathAddr, timeStart);
    await Path.transfer(PathVesting.address, "100000000000000000000000000");

  });

  describe("Add allocations", function () {
    it("Should add allocations to contract", async function () {
      await PathVesting.setAllocation([addr2.address], ["100000000000000000000000"],["10000000000000000000000"],
        [timeStart], [timeStart + 10], [timeStart + 100], [0]);
    
      const allocation = ethers.utils.formatEther((await PathVesting.allocations(addr2.address)).totalAllocated);
      const expectedTotal = 100000
      expect(parseFloat(allocation)).to.equal(parseFloat(expectedTotal));

      const initialAllocation = ethers.utils.formatEther((await PathVesting.allocations(addr2.address)).initialAllocation);
      const expectedInitial = 10000
      expect(parseFloat(initialAllocation)).to.equal(parseFloat(expectedInitial));
    });
  });

  describe("Claim the correct amount", function () {
    it("Should allow the right claim amount to contract", async function () {
      await PathVesting.setAllocation([addr1.address], ["100000000000000000000000"],["10000000000000000000000"],
        [timeStart], [timeStart + 10], [timeStart + 100], [0]);
      await network.provider.send("evm_setNextBlockTimestamp", [timeStart])
      await network.provider.send("evm_mine") 
      await PathVesting.connect(addr1).transferTokens(addr1.address)

      const balance = ethers.utils.formatEther(await Path.balanceOf(addr1.address))
      const expected = 10000
      expect(parseFloat(balance)).to.equal(parseFloat(expected));
    });
  });

  describe("Not allow claim before cliff", function () {
    it("Should not allow to claim before initial cliff is completed", async function () {

      const blockNumAfter = await ethers.provider.getBlockNumber();
      const blockAfter = await ethers.provider.getBlock(blockNumAfter);
      const timeStampNow = blockAfter.timestamp;

      await PathVesting.setAllocation([addr1.address], ["100000000000000000000000"],["10000000000000000000000"],
        [timeStampNow], [timeStampNow + 10], [timeStampNow + 100], [0]);
      await PathVesting.connect(addr1).transferTokens(addr1.address)
    
      const balance = ethers.utils.formatEther(await Path.balanceOf(addr1.address))
      const expected = 10000
      expect(parseFloat(balance)).to.equal(parseFloat(expected));
      
      //second claim should have 0 tokens due to cliff not ending
      await expect(PathVesting.connect(addr1).transferTokens(addr1.address)).to.be.revertedWith('Recipient should have more than 0 tokens to claim');
    });
  });

  describe("Calculate the correct claim amount", function () {
    it("Should allow the right claim amount to contract after initial allocation is claimed for transfer function", async function () {

      const blockNumAfter = await ethers.provider.getBlockNumber();
      const blockAfter = await ethers.provider.getBlock(blockNumAfter);
      const timeStampNow = blockAfter.timestamp;
      await PathVesting.setAllocation([addr1.address], ["100000000000000000000000"],["10000000000000000000000"],
        [timeStampNow], [timeStampNow + 10], [timeStampNow + 110], [0]);

      await network.provider.send("evm_increaseTime", [14])
      await network.provider.send("evm_mine")
      const blockNumAfter1 = await ethers.provider.getBlockNumber();
      const blockAfter1 = await ethers.provider.getBlock(blockNumAfter1);
      const timestampAfter = blockAfter1.timestamp + 1;

      await PathVesting.connect(addr1).transferTokens(addr1.address)

      const balance = ethers.utils.formatEther(await Path.balanceOf(addr1.address))
      const initial = 10000
      const vested = 100000 - initial
      const vestedPerSecond = vested / (timeStampNow + 110 - (timeStampNow + 10))
      const expected = initial + (vestedPerSecond * (timestampAfter - (timeStampNow + 10)))

      expect(parseFloat(balance)).to.equal(parseFloat(expected));
    });
  });
});
