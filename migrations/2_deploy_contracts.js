const CoinFlip = artifacts.require("CoinFlip");

module.exports = (deployer) => {
  deployer.deploy(CoinFlip, web3.utils.toWei("0.1", "ether"), web3.utils.toWei("1", "ether"), 90);
};
