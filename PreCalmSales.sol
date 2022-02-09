// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "hardhat/console.sol";

interface IERC20 {
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(x == 0 || (z = x * y) / x == y);
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x + y) >= x == (y >= 0));
  }

  /// @notice Returns x - y, reverts if overflows or underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x - y) <= x == (y >= 0));
  }

  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y > 0);
    z = x / y;
  }
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;

  function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
  address internal _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual override onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner_)
    public
    virtual
    override
    onlyOwner
  {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner_);
    _owner = newOwner_;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(
      data
    );
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

library SafeERC20 {
  using LowGasSafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

contract PreCalmSales is Ownable {
  using LowGasSafeMath for uint256;
  using SafeERC20 for IERC20;

  event SaleStarted(address indexed activator, uint256 timestamp);
  event SaleEnded(address indexed activator, uint256 timestamp);
  event SellerApproval(
    address indexed approver,
    address indexed seller,
    string indexed message
  );

  IERC20 public immutable Calm; // token given as payment for bond
  IERC20 public dai;
  IERC20 public pCalm;

  address private saleProceedsAddress;

  uint256 public pCalmPrice; // pCalmPrice in DAI digits (18-digit)

  uint256 public pCalmPurchaseLimit;

  bool public initialized;

  mapping(address => bool) public approvedBuyers;

  constructor(address _Calm) {
    require(_Calm != address(0));
    Calm = IERC20(_Calm);
  }

  function initialize(
    address pCalm_,
    address dai_,
    uint256 pCalmPrice_,
    uint256 pCalmPurchaseLimit_,
    address saleProceedsAddress_
  ) external onlyOwner {
    require(!initialized);
    require(pCalmPrice_ > 0, "Price should be greater than zero");

    pCalm = IERC20(pCalm_);
    dai = IERC20(dai_);
    pCalmPrice = pCalmPrice_;
    pCalmPurchaseLimit = pCalmPurchaseLimit_;
    saleProceedsAddress = saleProceedsAddress_;
    initialized = true;
  }

  function setPCalmPrice(uint256 newPCalmPrice_)
    external
    onlyOwner
    returns (uint256)
  {
    pCalmPrice = newPCalmPrice_;

    return pCalmPrice;
  }

  function setPCalmPurchaseLimit(uint256 newPCalmPurchaseLimit)
    external
    onlyOwner
    returns (uint256)
  {
    pCalmPurchaseLimit = newPCalmPurchaseLimit;

    return pCalmPurchaseLimit;
  }

  function _approveBuyer(address newBuyer_) internal onlyOwner returns (bool) {
    approvedBuyers[newBuyer_] = true;

    return approvedBuyers[newBuyer_];
  }

  function approveBuyer(address newBuyer_) external onlyOwner returns (bool) {
    return _approveBuyer(newBuyer_);
  }

  function approveBuyers(address[] calldata newBuyers_)
    external
    onlyOwner
    returns (uint256)
  {
    for (uint256 iteration_ = 0; newBuyers_.length > iteration_; iteration_++) {
      _approveBuyer(newBuyers_[iteration_]);
    }

    return newBuyers_.length;
  }

  function _calculateAmountPurchased(uint256 amountPaid_)
    internal
    returns (uint256)
  {
    return amountPaid_.div(pCalmPrice);
  }

  function buyPcalm(uint256 amountPaid_) external returns (bool) {
    require(approvedBuyers[msg.sender], "Buyer not approved.");

    // the number of pCalm tokens being purchased
    uint256 pCalmAmountPurchased_ = _calculateAmountPurchased(amountPaid_);

    require(
      pCalmAmountPurchased_ < pCalmPurchaseLimit,
      "Can't buy more than purchase limit"
    );

    dai.approve(saleProceedsAddress, amountPaid_);
    dai.safeTransferFrom(msg.sender, saleProceedsAddress, amountPaid_);

    uint256 _pCalmAmountPurchased = pCalmAmountPurchased_.mul(
      10**pCalm.decimals()
    );

    pCalm.safeTransferFrom(
      saleProceedsAddress,
      msg.sender,
      _pCalmAmountPurchased
    );

    return true;
  }

  // function changepCalmtoCalm(address user_) external onlyOwner returns (bool) {
  //   uint256 pCalmAmountPurchased_ = pCalm.balanceOf(user_);

  //   require(pCalmAmountPurchased_ > 0, "Not enough pCalm");

  //   Calm.safeTransfer(msg.sender, pCalmAmountPurchased_);

  //   pCalm.safeTransfer(address(0), pCalmAmountPurchased_);

  //   return true;
  // }

  function withdrawTokens(address tokenToWithdraw_)
    external
    onlyOwner
    returns (bool)
  {
    IERC20(tokenToWithdraw_).safeTransfer(
      msg.sender,
      IERC20(tokenToWithdraw_).balanceOf(address(this))
    );

    return true;
  }
}
