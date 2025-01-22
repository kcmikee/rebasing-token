pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RebasingERC20 is IERC20, Ownable {
  string public constant name = "Rebasing Token";
  string public constant symbol = "$RBT";
  uint8 public constant decimals = 18;

  uint256 private _totalSup;
  uint256 private _initialSup;
  mapping(address => uint256) private _bals;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _rebaseFactor = 1e18;

  event Rebase(uint256 totalSupply);

  constructor(
    uint256 initialSupply
  ) Ownable(msg.sender) {
    _totalSup = initialSupply;
    _initialSup = initialSupply;
    _bals[msg.sender] = initialSupply;
    emit Transfer(address(0), msg.sender, initialSupply);
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSup;
  }

  function balanceOf(
    address account
  ) public view override returns (uint256) {
    return (_bals[account] * _rebaseFactor) / 1e18;
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    address owner = msg.sender;
    uint256 internalAmount = (amount * 1e18) / _rebaseFactor;
    require(
      _bals[owner] >= internalAmount,
      " transfer amount is greater than balance "
    );

    _bals[owner] -= internalAmount;
    _bals[to] += internalAmount;

    emit Transfer(owner, to, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public override returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    uint256 curAllowance = _allowances[from][msg.sender];
    require(curAllowance >= amount, " insufficient allowance ");

    uint256 internalAmount = (amount * 1e18) / _rebaseFactor;
    require(
      _bals[from] >= internalAmount, " transfer amount is greater than balance "
    );

    _bals[from] -= internalAmount;
    _bals[to] += internalAmount;
    _allowances[from][msg.sender] = curAllowance - amount;

    emit Transfer(from, to, amount);
    return true;
  }

  function rebase(
    int256 rebaseAmount
  ) external onlyOwner {
    if (rebaseAmount > 0) {
      _totalSup += uint256(rebaseAmount);
    } else {
      _totalSup -= uint256(-rebaseAmount);
    }

    _rebaseFactor = (_totalSup * 1e18) / _initialSup;
    emit Rebase(_totalSup);
  }
}
