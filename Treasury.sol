// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {DeathAndTaxesCitizens} from "./DeathAndTaxesCitizens.sol";
import {GameParams} from "./GameParams.sol";
import {Ownable} from "@openzeppelin-contracts-5.0.2/access/Ownable.sol";
import {IERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/utils/SafeERC20.sol";

/// @title Treasury
/// @notice Holds game proceeds and distributes equal shares to surviving citizens at settlement.
contract Treasury is Ownable, GameParams {
    using SafeERC20 for IERC20;

    /////////////////////////////////////////////////////////////////////
    // Storage
    /////////////////////////////////////////////////////////////////////

    bool public treasuryUnlocked;
    DeathAndTaxesCitizens public immutable citizens;
    uint256 public payoutPerCitizen;
    mapping(uint256 => bool) private _hasClaimedShare;

    /////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////

    event EthReceived();
    event ShareClaimed(uint256 indexed tokenId);
    event TreasuryUnlocked(uint256 indexed finalSupply, uint256 indexed weiPerShare);
    event EmergencyEthWithdrawn(address indexed to, uint256 amount);

    /////////////////////////////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////////////////////////////

    error ClaimFailed();
    error GameNotFinished();
    error ShareAlreadyClaimed();
    error TreasuryIsUnlocked();
    error InvalidAddress();
    error WinnersRemain();

    /////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////

    /// @notice Deploys the treasury linked to the citizens collection.
    /// @param citizensAddress Address of the citizen NFT contract.
    constructor(address citizensAddress) Ownable(msg.sender) {
        if (citizensAddress == address(0)) revert InvalidAddress();
        if (citizensAddress.code.length == 0) revert InvalidAddress();
        citizens = DeathAndTaxesCitizens(citizensAddress);
    }

    /////////////////////////////////////////////////////////////////////
    // Receive
    /////////////////////////////////////////////////////////////////////

    /// @notice Accepts ETH while settlement is still locked.
    receive() external payable {
        if (treasuryUnlocked) revert TreasuryIsUnlocked();
        emit EthReceived();
    }

    /////////////////////////////////////////////////////////////////////
    // Treasury Functions
    /////////////////////////////////////////////////////////////////////

    /// @notice Unlocks treasury claims once survivor count reaches settlement conditions.
    function unlockTreasury() external {
        if (treasuryUnlocked) revert TreasuryIsUnlocked();
        uint256 supply = citizens.totalSupply();
        if (supply > WINNERS) revert GameNotFinished();

        payoutPerCitizen = address(this).balance / supply;
        treasuryUnlocked = true;

        emit TreasuryUnlocked(supply, payoutPerCitizen);
    }

    /// @notice Claims a token's share and pays the token owner.
    /// @param tokenId Citizen token id claiming one settlement share.
    function claimShare(uint256 tokenId) external {
        if (!treasuryUnlocked) revert GameNotFinished();
        if (_hasClaimedShare[tokenId]) revert ShareAlreadyClaimed();
        address owner = citizens.ownerOf(tokenId);

        _hasClaimedShare[tokenId] = true;

        (bool success,) = owner.call{value: payoutPerCitizen}(""); // griefing attack not an issue here
        if (!success) revert ClaimFailed();

        emit ShareClaimed(tokenId);
    }

    /// @notice Emergency escape hatch for the edge case where all citizens are gone.
    /// @param to Recipient of the treasury ETH balance.
    function emergencyWithdrawEth(address to) external onlyOwner {
        if (to == address(0)) revert InvalidAddress();
        if (citizens.totalSupply() != 0) revert WinnersRemain();

        uint256 amount = address(this).balance;
        (bool success,) = to.call{value: amount}("");
        if (!success) revert ClaimFailed();

        emit EmergencyEthWithdrawn(to, amount);
    }

    /////////////////////////////////////////////////////////////////////
    // Admin Functions
    /////////////////////////////////////////////////////////////////////

    /// @notice Recovers ERC20 tokens accidentally sent to this contract.
    /// @param token ERC20 token address.
    /// @param to Recipient address.
    /// @param amount Amount to transfer.
    function rescueERC20(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

}
