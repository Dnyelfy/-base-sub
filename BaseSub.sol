// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BaseSub — non-custodial USDC subscriptions on Base
/// @notice Allowance-pull model: funds never leave the subscriber's wallet.
///         First period is charged on subscribe; each next period is pulled
///         only when due, by anyone (permissionless keeper).
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract BaseSub {
    // USDC on Base mainnet (6 decimals)
    IERC20 public constant USDC = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

    struct Sub {
        address subscriber;
        address merchant;
        uint96  amount;        // USDC, 6 decimals
        uint32  interval;      // seconds
        uint40  nextChargeAt;  // unix
        bool    active;
        string  label;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Sub) private subs;
    mapping(address => uint256[]) private bySubscriber;
    mapping(address => uint256[]) private byMerchant;

    event Subscribed(uint256 indexed id, address indexed subscriber, address indexed merchant, uint96 amount, uint32 interval, string label);
    event Charged(uint256 indexed id, address indexed merchant, uint96 amount, uint40 nextCharge);
    event Cancelled(uint256 indexed id, address by);

    /// @notice Create a subscription. First period is charged immediately.
    function subscribe(address merchant, uint96 amount, uint32 interval, string calldata label) external returns (uint256 id) {
        require(merchant != address(0), "merchant=0");
        require(amount > 0, "amount=0");
        require(interval >= 60, "interval too short");
        require(bytes(label).length <= 64, "label too long");

        id = nextId++;
        uint40 next = uint40(block.timestamp + interval);
        subs[id] = Sub(msg.sender, merchant, amount, interval, next, true, label);
        bySubscriber[msg.sender].push(id);
        byMerchant[merchant].push(id);

        require(USDC.transferFrom(msg.sender, merchant, amount), "USDC pull failed");
        emit Subscribed(id, msg.sender, merchant, amount, interval, label);
        emit Charged(id, merchant, amount, next);
    }

    /// @notice Permissionless: anyone can collect a due payment.
    function charge(uint256 id) public {
        Sub storage s = subs[id];
        require(s.active, "inactive");
        require(block.timestamp >= s.nextChargeAt, "not due");

        s.nextChargeAt = uint40(block.timestamp + s.interval);
        require(USDC.transferFrom(s.subscriber, s.merchant, s.amount), "USDC pull failed");
        emit Charged(id, s.merchant, s.amount, s.nextChargeAt);
    }

    function chargeMany(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) charge(ids[i]);
    }

    /// @notice Either party can cancel.
    function cancel(uint256 id) external {
        Sub storage s = subs[id];
        require(s.active, "inactive");
        require(msg.sender == s.subscriber || msg.sender == s.merchant, "not party");
        s.active = false;
        emit Cancelled(id, msg.sender);
    }

    function listBySubscriber(address a) external view returns (uint256[] memory) { return bySubscriber[a]; }
    function listByMerchant(address a) external view returns (uint256[] memory) { return byMerchant[a]; }

    function getSub(uint256 id) external view returns (
        address subscriber, address merchant, uint96 amount, uint32 interval,
        uint40 nextChargeAt, bool active, string memory label
    ) {
        Sub storage s = subs[id];
        return (s.subscriber, s.merchant, s.amount, s.interval, s.nextChargeAt, s.active, s.label);
    }
}
