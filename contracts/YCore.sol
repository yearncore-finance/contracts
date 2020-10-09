pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract YCore is ERC20 {

    struct LockedTokenInfo {
        uint amount;
        uint unlockTime;
    }

    address public governance;
    address public rewardPool;

    uint public constant feeMin = 1;
    uint public constant feeMax = 100;

    LockedTokenInfo[] public lockedTokens;

    constructor (address _rewardPool) public ERC20("YearnCORE.Finance", "YCORE") {
        governance = msg.sender;
        rewardPool = _rewardPool;

        _mint(msg.sender, 50000*(10 ** uint(decimals()))); // Circulation
    }

    /**
     * @dev ERC20 transfer with 1% transfer fee. Fee will be sent to reward pool
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint fee = amount * feeMin / feeMax;
        uint amountToSend = amount - fee;
        _transfer(_msgSender(), recipient, amountToSend);
        _transfer(_msgSender(), rewardPool, fee);
        return true;
    }

    /**
     * @dev ERC20 transferFrom with 1% transfer fee. Fee will be sent to reward pool
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint fee = amount * feeMin / feeMax;
        uint amountToSend = amount - fee;

        _transfer(sender, recipient, amountToSend);
        _transfer(sender, rewardPool, fee);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Set governance
     * @param _governance new governance address.
     */

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    /**
     * @dev Set reward pool
     * @param _rewardPool new reward pool address.
     */

    function setRewardPool(address _rewardPool) external {
        require(msg.sender == governance, "!governance");
        rewardPool = _rewardPool;
    }

    /**
     * @dev Lock token.
     * @param amount lock amount.
     * @param unlcokTime unlock time.
     */

    function lock(uint amount, uint unlcokTime) external {
        require(msg.sender == governance, "!governance");
        require(unlcokTime > block.timestamp, "!cannot lock");
        _transfer(_msgSender(), address(this), amount);
        lockedTokens.push(LockedTokenInfo({
            amount: amount,
            unlockTime: unlcokTime
        }));
    }

    /**
     * @dev Unlock token.
     * @param recipient recipient address for unlocked token.
     * @param id id of LockedTokenInfo.
     */

    function unlock(address recipient, uint id) external {
        require(msg.sender == governance, "!governance");
        require(lockedTokens.length > id, "!no locked token");
        require(lockedTokens[id].unlockTime <= block.timestamp, "!cannot unlock");
        _transfer(address(this), recipient, lockedTokens[id].amount);

        if (id < lockedTokens.length - 1) {
            lockedTokens[id] = lockedTokens[lockedTokens.length - 1];
        }
        lockedTokens.pop();
    }

    /**
     * @dev Number of unlocked token info size.
     */

    function unlockedSize() external view returns (uint) {
        return lockedTokens.length;
    }
}
