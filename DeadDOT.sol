// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title DeadDOT — On-chain Dead Man's Switch
/// @notice Owner must ping periodically or beneficiary can claim all funds.
///         "Crypto inheritance in 100 lines." Built for Polkadot Hub / PVM.
/// @dev    Deployed and compiled with resolc (Revive) targeting PVM.
///         Native DOT is transferred directly — no ERC-20, no wrapping.
contract DeadDOT {

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------

    address public owner;
    address public beneficiary;

    /// @notice How often the owner must ping (in seconds)
    uint256 public interval;

    /// @notice Timestamp of the last ping (or contract creation)
    uint256 public lastPing;

    /// @notice Whether the switch has been triggered (beneficiary claimed)
    bool public triggered;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event Deposited(address indexed from, uint256 amount);
    event Pinged(address indexed owner, uint256 at);
    event Claimed(address indexed beneficiary, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "DeadDOT: not owner");
        _;
    }

    modifier notTriggered() {
        require(!triggered, "DeadDOT: already triggered");
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _beneficiary Who inherits if the owner goes silent
    /// @param _interval    Seconds between required pings (e.g. 30 days = 2592000)
    constructor(address _beneficiary, uint256 _interval) payable {
        require(_beneficiary != address(0), "DeadDOT: zero beneficiary");
        require(_beneficiary != msg.sender,  "DeadDOT: owner can't be beneficiary");
        require(_interval >= 1 hours,        "DeadDOT: interval too short");

        owner       = msg.sender;
        beneficiary = _beneficiary;
        interval    = _interval;
        lastPing    = block.timestamp;

        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    // -------------------------------------------------------------------------
    // Owner actions
    // -------------------------------------------------------------------------

    /// @notice Prove you're alive. Resets the countdown.
    function ping() external onlyOwner notTriggered {
        lastPing = block.timestamp;
        emit Pinged(msg.sender, block.timestamp);
    }

    /// @notice Deposit more DOT into the switch
    function deposit() external payable onlyOwner notTriggered {
        require(msg.value > 0, "DeadDOT: zero deposit");
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Cancel the switch and withdraw all funds
    function withdraw() external onlyOwner notTriggered {
        uint256 balance = address(this).balance;
        require(balance > 0, "DeadDOT: nothing to withdraw");

        triggered = true; // Prevent re-entrancy; treat as cancelled
        (bool ok, ) = owner.call{value: balance}("");
        require(ok, "DeadDOT: transfer failed");

        emit Withdrawn(owner, balance);
    }

    /// @notice Update the beneficiary address (owner signs)
    function updateBeneficiary(address _newBeneficiary) external onlyOwner notTriggered {
        require(_newBeneficiary != address(0), "DeadDOT: zero address");
        require(_newBeneficiary != owner,      "DeadDOT: owner can't be beneficiary");

        address old = beneficiary;
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(old, _newBeneficiary);
    }

    // -------------------------------------------------------------------------
    // Beneficiary action
    // -------------------------------------------------------------------------

    /// @notice Claim all funds if the owner has been silent for too long.
    ///         Anyone can call this — the funds always go to `beneficiary`.
    function claim() external notTriggered {
        require(block.timestamp >= lastPing + interval, "DeadDOT: owner still alive");

        uint256 balance = address(this).balance;
        require(balance > 0, "DeadDOT: nothing to claim");

        triggered = true;
        (bool ok, ) = beneficiary.call{value: balance}("");
        require(ok, "DeadDOT: transfer failed");

        emit Claimed(beneficiary, balance);
    }

    // -------------------------------------------------------------------------
    // View helpers
    // -------------------------------------------------------------------------

    /// @notice Seconds until the beneficiary can claim (0 if already claimable)
    function timeRemaining() external view returns (uint256) {
        uint256 deadline = lastPing + interval;
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    /// @notice Whether the beneficiary can claim right now
    function isClaimable() external view returns (bool) {
        return !triggered && block.timestamp >= lastPing + interval;
    }

    /// @notice Current DOT balance held by the switch
    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    // -------------------------------------------------------------------------
    // Receive
    // -------------------------------------------------------------------------

    /// @notice Accept direct DOT sends
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }
}
