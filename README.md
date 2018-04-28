# contracts


### compile

- Truffle v4.1.3 (core: 4.1.3)
- Solidity v0.4.19 (solc-js)

```
#!/bin/bash

echo "var tokenOutput=`solc  --optimize --combined-json abi,bin,interface --allow-paths .,.. ./token/HPCToken.sol`" > HPCtoken.js
echo "var icoOutput=`solc  --optimize --combined-json abi,bin,interface --allow-paths .,.. ./HPCico/HPCPresale.sol`" > build/HPCpresale.js
```

### deploy example

```javascript
loadScript('./HPCpresale.js');
icoContractAbi = icoOutput.contracts['./HPCico/HPCPresale.sol:HPCPresale'].abi;
icoBincode = "0x" + icoOutput.contracts['./HPCico/HPCPresale.sol:HPCPresale'].bin;
icoContract = eth.contract(JSON.parse(icoContractAbi));
deployTransactionObject = {from: eth.accounts[0], gas: 3000000, data: icoBincode, gasPrice: 2};
icoContract.new(
  ['0xd30f1e144ffe859ef6b26a0f950f0135ce53dc13', '0x456b5150cd59aaa68a472a2286ad1275d97e63f9'],
  parseInt(Date.now()/1000)+300, 1535760000,
  100000000000000000, 100000000000000000000,
  360000,
  '0xd30f1e144ffe859ef6b26a0f950f0135ce53dc13',
  HPCToken.address,
  deployTransactionObject);


tokenContractAbi = tokenOutput.contracts['HPCcoin.sol:HPCToken'].abi;
tokenBincode = "0x" + tokenOutput.contracts['HPCcoin.sol:HPCToken'].bin;
tokenContract = eth.contract(JSON.parse(tokenContractAbi));
deployTransactionObject = {from: eth.accounts[0], gas: 2000000, data: tokenBincode, gasPrice: 2};
tokenContract.new('Mass Vehicle Ledger Token', 'HPC', 18, 3e28,
  deployTransactionObject);


coinAddress = '0x38b0c5ee777ac914a603d634e3227cf5a2c2349d';


icoAddress = '0x4e862509b12ce3f93661f50cdda0b6b6991a4b89';
ico = icoContract.at(icoAddress);
vaultContractAbi = icoOutput.contracts['./HPCico/RefundVault.sol:RefundVault'].abi;
vaultContract = eth.contract(JSON.parse(vaultContractAbi));
vault1Address = '0x3443541746d2dc235e6772bf48eeefd15aca6822';
vault2Address = '0x20a4d055ac25ade5da151db09e765407baa08433';

vault1 = vaultContract.at(vault1Address);
vault2 = vaultContract.at(vault2Address);


// ico participate
eth.sendTransaction({from: eth.accounts[0], to: icoAddress, value: web3.toWei(1, 'ether') , gas: 2000000, gasPrice: 2})
```

### truffle test script

```javascript
migrate --reset
HPCToken.deployed().then(i=>token=i)
HPCPresale.deployed().then(i=>ico=i)
token.unlockAllTokens()
web3.eth.sendTransaction({from: web3.eth.accounts[3], to: ico.address, gas: 6000000, value: web3.toWei(1, 'ether')})

ico.updateKYCStatus(web3.eth.accounts[3], true)
ico.setState(true)

token.approve.sendTransaction(ico.address, 3e28, {gas: 6000000, gasPrice: 1})

ico.withdrawTokensTo(web3.eth.accounts[3], {gas: 6000000})

web3.eth.getBlock(web3.eth.blockNumber)
```