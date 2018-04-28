pragma solidity ^0.4.19;

import './SafeMath.sol';
import './CappedTokenSale.sol';
import "./LimitedTokenSale.sol";
import "./RefundableTokenSale.sol";
import "./PostDeliveryTokenSale.sol";

contract MVLPresale is PostDeliveryTokenSale, LimitedTokenSale, RefundableTokenSale, CappedTokenSale {
  function MVLPresale(address[] walletAddresses, uint256 _openingTime, uint256 _closingTime, uint256 min, uint256 max, uint256 _cap, uint256 _rate, address _wallet, DetailedERC20 _token)
    TimedTokenSale(_openingTime, _closingTime)
    CappedTokenSale(_cap)
    LimitedTokenSale(min, max)
    RefundableTokenSale(walletAddresses)
    PostDeliveryTokenSale(msg.sender)
    TokenSale(_rate, _wallet, _token) public {
  }
}