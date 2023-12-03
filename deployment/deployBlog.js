const { bytecode } = require("../artifacts/contracts/Blog.sol/Blog.json");
const { create2Address } = require("../utils/utils.js")

const main = async () => {
  const factoryAddr = "0xc0534198714f7FCBB6833Bc4ed4AaE8f52558e4E";
  const saltHex = ethers.utils.id("blockchain_top");

  const create2Addr = create2Address(factoryAddr, saltHex, bytecode);
  console.log("precomputed address:", create2Addr);

  const Factory = await ethers.getContractFactory("DeterministicDeployFactory");
  const factory = await Factory.attach(factoryAddr);

  const lockDeploy = await factory.deploy(bytecode, saltHex);
  const txReceipt = await lockDeploy.wait();
  console.log("Deployed to:", txReceipt.events[0].args[0]);  
};
  
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });