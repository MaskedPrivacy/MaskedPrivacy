import 'Safemath.sol';
import 'SafeERC20.sol';

pragma solidity =0.6.6;

contract TokenVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable beneficiary;

    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;

    mapping (address => uint256) public released;

    event Released(uint256 amount);

    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration
    )
    public
    {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);

        beneficiary = _beneficiary;
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;
    }

    function release(IERC20 _token) external {
        uint256 unreleased = releasableAmount(_token);

        require(unreleased > 0);

        released[address(_token)] = released[address(_token)].add(unreleased);

        _token.safeTransfer(beneficiary, unreleased);

    }

    function releasableAmount(IERC20 _token) public view returns (uint256) {
        return vestedAmount(_token).sub(released[address(_token)]);
    }

    function vestedAmount(IERC20 _token) public view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released[address(_token)]);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
}