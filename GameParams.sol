// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice Shared game parameters used across contracts.
abstract contract GameParams {
    /// @notice Duration of one game epoch.
    uint256 public constant EPOCH_DURATION = 24 hours;
    /// @notice Nominal settlement survivor target.
    uint256 public constant WINNERS = 69;
    /// @notice Base tax unit multiplied by current epoch number.
    uint256 public constant BASE_TAX_RATE = 0.00069 ether;
    /// @notice Flat ETH cost to initiate a player audit.
    uint256 public constant AUDIT_COST = 0.00069 ether;
    /// @notice Flat ETH cost to buy life insurance.
    uint256 public constant LIFE_INSURANCE_COST = 0.00969 ether;
    /// @notice Basis points denominator.
    uint256 public constant BASIS = 10_000;
    /// @notice Protocol fee charged on qualifying payments.
    uint256 public constant FEE_BPS = 690;
    /// @notice Default audits allowed per token per epoch.
    uint256 public constant DAILY_AUDIT_LIMIT = 1;
    /// @notice Maximum audit limit that IRS can grant.
    uint256 public constant AUDITOR_DAILY_AUDIT_LIMIT = 3;
    /// @notice Maximum number of epochs that can be prepaid in one call.
    uint256 public constant EPOCHS_CAN_PAY_AT_ONE_TIME = 7;
    /// @notice Maximum number of bribes that can be held by one token.
    uint256 public constant MAX_BRIBE_BALANCE = 3;
    /// @notice Role hash for IRS-authorized operations.
    bytes32 public constant IRS_ROLE = keccak256("IRS_ROLE");
}
