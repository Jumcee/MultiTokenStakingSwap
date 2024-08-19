async function main() {
  // Get the deployer's account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Get the balance of the deployer's account
  const balance = await deployer.getBalance();
  console.log("Account balance:", hre.ethers.utils.formatEther(balance), "ETH");

  // Replace with your actual reward token address
  const rewardTokenAddress = "0xYourRewardTokenAddressHere";

  // Deploy the LearnToEarnToken contract
  const LearnToEarnToken = await hre.ethers.getContractFactory("LearnToEarnToken");
  const learnToEarnToken = await LearnToEarnToken.deploy(rewardTokenAddress);

  await learnToEarnToken.deployed();
  console.log("LearnToEarnToken deployed to:", learnToEarnToken.address);

  // Optionally set a DeFi protocol (replace with the actual address)
  const defiProtocolAddress = "0xYourDeFiProtocolAddressHere";
  await learnToEarnToken.setDeFiProtocol(defiProtocolAddress);
  console.log("DeFi Protocol set to:", defiProtocolAddress);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
      console.error(error);
      process.exit(1);
  });
