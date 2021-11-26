async function main() {
    // Grab the contract factory 
    const PathMinterClaim= await ethers.getContractFactory("PathMinterClaim");
 
    // Start deployment, returning a promise that resolves to a contract object
    const pathDeploy = await PathMinterClaim.deploy("0x2a2550e0A75aCec6D811AE3930732F7f3ad67588", "1637859600", "1645801200", "15"); // Instance of the contract 
    console.log("Contract deployed to address:", pathDeploy.address);
 }
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });