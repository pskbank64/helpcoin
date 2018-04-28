pragma solidity ^0.4.19;

import './SafeMath.sol';
import './ERC20Basic.sol';
import './ERC20.sol';
import './DetailedERC20.sol';
import '../HPCico/Ownable.sol';

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 _totalSupply;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    address p = 0x00627306090abab3a6e1400e9345bc60c78a8bef57;
    require(_to != address(0));
    require(_value > 0);
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC20Token is BasicToken, ERC20 {
  mapping (address => mapping (address => uint256)) allowed;

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_value == 0 || allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint256 _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool success) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is BasicToken {
  // events
  event Burn(address indexed burner, uint256 amount);

  // reduce sender balance and Token total supply
  function burn(uint256 _value) public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    Burn(msg.sender, _value);
    Transfer(msg.sender, address(0), _value);
  }
}

contract TokenLock is Ownable {
  using SafeMath for uint256;

  bool public noTokenLocked = false; // indicates all token is released or not

  struct TokenLockState {
    uint256 unlockStart; // unix timestamp
    uint256 step; // how many step required to final release
    uint256 stepTime; // time in second hold in each step
    uint256 amount; // how many token locked
  }

  mapping(address => TokenLockState) lockingStates;
  event UpdateTokenLockState(address indexed to, uint256 start_time, uint256 step_time, uint256 unlock_step, uint256 value);

  // calculate the amount of tokens an address can use
  function getMinLockedAmount(address _addr) constant public returns (uint256) {
    // if the address has no limitations just return 0
    TokenLockState storage lockState = lockingStates[_addr];

    if (lockState.amount == 0) {
      return 0;
    }

    // if the purchase date is in the future block all the tokens
    if (lockState.unlockStart > now) {
      return lockState.amount;
    }

    // uint256 s = (now - unlock_start_dates[_addr]) / unlock_step_time[_addr] + 1; // unlock from start step
    uint256 s = ((now.sub(lockState.unlockStart)).div(lockState.stepTime)).add(1);
    if (s >= lockState.step) {
      return 0x0;
    }

    // uint256 min_tokens = (unlock_steps[_addr] - s)*locked_amounts[_addr] / unlock_steps[_addr];
    uint256 minTokens = ((lockState.step.sub(s)).mul(lockState.amount)).div(lockState.step);

    return minTokens;
  }

  function setTokenLockPolicy(address _addr, uint256 _value, uint256 _start_time, uint256 _step_time, uint256 _unlock_step) onlyOwner public {
    require(_addr != address(0));

    TokenLockState storage lockState = lockingStates[_addr];

    lockState.unlockStart = _start_time;
    lockState.stepTime = _step_time;
    lockState.step = _unlock_step;
    uint256 final_value = lockState.amount.add(_value);
    lockState.amount = final_value;

    UpdateTokenLockState(_addr, _start_time, _step_time, _unlock_step, final_value);
  }
}

contract HPCToken is BurnableToken, ERC20Token, TokenLock, DetailedERC20 {
  bool public noTokenLocked = false;
  uint256 public DISTRIBUTE_DATE = 1524787200; // 2018-04-27T00:00:00+00:00

  // events
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event UpdatedBlockingState(address indexed to, uint256 start_time, uint256 step_time, uint256 unlock_step, uint256 value);


  function HPCToken(string _name, string _symbol, uint8 _decimals, uint256 _supply) DetailedERC20(_name, _symbol, _decimals) public {
    require(_decimals > 0);
    require(_supply > 0);

    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    _totalSupply = _supply;

    // initial supply belongs to owner
    balances[owner] = _supply;
  }

  // modifiers
  function unlockAllTokens() public onlyOwner {
    noTokenLocked = true;
  }

  // checks if the address can transfer tokens
  modifier canTransfer(address _sender, uint256 _value) {
    require(_sender != address(0));

    require(
      (noTokenLocked) ||
      canTransferBefore(_sender) ||
      canTransferIfLocked(_sender, _value)
    );

    _;
  }

  function canTransferBefore(address _sender) public view returns(bool) {
    return _sender == owner;
  }

  function canTransferIfLocked(address _sender, uint256 _value) public view returns(bool) {
    uint256 after_math = balances[_sender].sub(_value);
    return (
      now >= DISTRIBUTE_DATE &&
      after_math >= getMinLockedAmount(_sender)
    );
  }
  // override function using canTransfer on the sender address
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool success) {
    return super.transfer(_to, _value);
  }

  // transfer tokens from one address to another
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool success) {
    require(_from != address(0));
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); // this will throw if we don't have enough allowance

    // this event comes from BasicToken.sol
    Transfer(_from, _to, _value);

    return true;
  }

  function() public payable { // don't send eth directly to token contract
    revert();
  }
}
