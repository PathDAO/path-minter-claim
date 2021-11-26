const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Path Token contract", function () {
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
    PathMinterClaimContract = await ethers.getContractFactory("PathMinterClaim");
    timeStart = Math.floor(Date.now() / 1000);

    [owner, addr1, addr2] = await ethers.getSigners();
    //deploy contract
    Path = await PathToken.deploy("1000000000000000000000000000");
    PathAddr = Path.address
    PathMinterClaim = await PathMinterClaimContract.deploy(PathAddr, timeStart, timeStart + 100, 15);
    await Path.transfer(PathMinterClaim.address, "100000000000000000000000000");

  });

  describe("Add allocations", function () {
    it("Should add allocations to contract", async function () {
      await PathMinterClaim.setAllocation([addr2.address], ["40000000000000000000000"])
    });
  });

  describe("Claim the correct amount", function () {
    it("Should allow the right claim amount to contract", async function () {
      await PathMinterClaim.setAllocation([addr1.address], ["100000000000000000000000"])
      await network.provider.send("evm_setNextBlockTimestamp", [timeStart + 9])
      await network.provider.send("evm_mine") 
      await PathMinterClaim.connect(addr1).claim()

      const balance = ethers.utils.formatEther(await Path.balanceOf(addr1.address))
      const expected = 100000 * 0.15 + ((100000 - (100000 * 0.15)) * (10 / 100))
      expect(parseFloat(balance)).to.equal(parseFloat(expected));
    });
  });

  describe("Claim the correct amount after initial allocation", function () {
    it("Should allow the right claim amount to contract after initial allocation is claimed", async function () {
      await PathMinterClaim.setAllocation([addr1.address], ["100000000000000000000000"])
      await PathMinterClaim.connect(addr1).claim()

      await network.provider.send("evm_increaseTime", [10])
      await network.provider.send("evm_mine")
      const blockNumAfter = await ethers.provider.getBlockNumber();
      const blockAfter = await ethers.provider.getBlock(blockNumAfter);
      const timestampAfter = blockAfter.timestamp;

      const timeElapsed = blockAfter.timestamp - timeStart
      await PathMinterClaim.connect(addr1).claim()

      const balance = ethers.utils.formatEther(await Path.balanceOf(addr1.address))
      const expected = 100000 * 0.15 + (((100000 - (100000 * 0.15)) * ((timeElapsed + 1) / 100)))
      expect(parseFloat(balance)).to.equal(parseFloat(expected));
    });
  });
});
