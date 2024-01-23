// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

error CapExceeded(uint256 cap, uint256 attemptedMintAmount);
error InvalidAddress();
error InvalidFeeRate();
error OwnershipLimitExceeded(uint256 limit);
error InsufficientAllowance(uint256 available, uint256 required);

contract BEP20Token is ERC20, ReentrancyGuard, AccessControl {
    uint256 private _cap;
    uint256 private _feeRate;
    address private _feeRecipient;

    constructor(
        string memory name,
        string memory symbol,
        uint256 cap,
        uint256 feeRate,
        address feeRecipient
    ) ERC20(name, symbol) {
        require(cap > 0, "Cap is 0");
        require(feeRecipient != address(0), "Fee recipient is zero address");
        require(feeRate <= 10000, "Invalid fee rate");

        _cap = cap;
        _feeRate = feeRate;
        _feeRecipient = feeRecipient;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public {
        if (to == address(0)) revert InvalidAddress();
        uint256 newSupply = totalSupply() + amount;
        if (newSupply > cap()) revert CapExceeded({cap: _cap, attemptedMintAmount: amount});
        if (balanceOf(to) + amount > cap() * 5 / 100) revert OwnershipLimitExceeded(cap() * 5 / 100);

        _mint(to, amount);
    }

    function setFeeRate(uint256 newFeeRate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newFeeRate > 10000) revert InvalidFeeRate();
        _feeRate = newFeeRate;
    }

    function setFeeRecipient(address newFeeRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newFeeRecipient == address(0)) revert InvalidAddress();
        _feeRecipient = newFeeRecipient;
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        uint256 fee = (amount * _feeRate) / 10000;
        uint256 amountAfterFee = amount - fee;

        super.transfer(_feeRecipient, fee);
        return super.transfer(recipient, amountAfterFee);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        if (currentAllowance < amount) revert InsufficientAllowance({available: currentAllowance, required: amount});

        uint256 fee = (amount * _feeRate) / 10000;
        uint256 amountAfterFee = amount - fee;

        super.transferFrom(sender, _feeRecipient, fee);
        return super.transferFrom(sender, recipient, amountAfterFee);
    }

    function cap() public view returns (uint256) {
        return _cap;
    }
}