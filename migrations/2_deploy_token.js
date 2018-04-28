var MVLToken = artifacts.require("MVLToken.sol");
var MVLPresale = artifacts.require('MVLPresale.sol');

module.exports = function(deployer) {
  deployer.deploy(MVLToken, 'Mass Vehicle Ledger Token', 'MVL', 18, 3*(1e10)*(1e18)).then(function() {
    return deployer.deploy(MVLPresale, [
      web3.eth.accounts[0], web3.eth.accounts[1]
    ], parseInt(Date.now()/1000)+30, 1535760000, 100000000000000000, 100000000000000000000,
    360000, web3.eth.accounts[0], MVLToken.address);
  });
};