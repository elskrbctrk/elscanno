// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721TL} from "tl-creator-contracts-4.0.0-rc.1/erc-721/ERC721TL.sol";

/// @title DeathAndTaxesCitizens.sol
/// @notice A custom version of ERC721TL that adds a privileged burn function to make the game work.
/// @author Transient Labs
contract DeathAndTaxesCitizens is ERC721TL {
    /////////////////////////////////////////////////////////////////////
    // Storage
    /////////////////////////////////////////////////////////////////////

    address public deathAndTaxes;
    bool public deathAndTaxesLocked;

    /////////////////////////////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////////////////////////////

    error DeathAndTaxesLocked();
    error NotDeathAndTaxes();

    /////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////

    event DeathAndTaxesAddressUpdated(
        address indexed sender, address indexed previousAddress, address indexed newAddress
    );
    event DeathAndTaxesConfigLocked(address indexed sender);

    /////////////////////////////////////////////////////////////////////
    // Constructor
    /////////////////////////////////////////////////////////////////////

    /// @notice Deploys the citizens token contract.
    /// @param disable Forwarded to ERC721TL initialization guard behavior.
    constructor(bool disable) ERC721TL(disable) {}

    /////////////////////////////////////////////////////////////////////
    // Admin
    /////////////////////////////////////////////////////////////////////

    /// @notice Function to set the death and taxes address
    /// @dev Can be set until it is locked
    /// @param newDeathAndTaxes Authorized game contract allowed to call `kill`.
    function setDeathAndTaxesAddress(address newDeathAndTaxes) external onlyRoleOrOwner(ADMIN_ROLE) {
        if (deathAndTaxesLocked) revert DeathAndTaxesLocked();

        address oldDeathAndTaxes = deathAndTaxes;
        deathAndTaxes = newDeathAndTaxes;
        emit DeathAndTaxesAddressUpdated(msg.sender, oldDeathAndTaxes, newDeathAndTaxes);
    }

    /// @notice Function to lock the death and taxes game contract
    /// @dev This is a one-way switch
    function lockDeathAndTaxes() external onlyRoleOrOwner(ADMIN_ROLE) {
        if (deathAndTaxesLocked) revert DeathAndTaxesLocked();
        deathAndTaxesLocked = true;
        emit DeathAndTaxesConfigLocked(msg.sender);
    }

    /////////////////////////////////////////////////////////////////////
    // Burn
    /////////////////////////////////////////////////////////////////////

    /// @notice Function that can only be called by the death and taxes contract
    /// @dev Burns the token without approval from the owner in the spirit of the game.
    ///      The game will mint another token from another contract as part of this burn.
    /// @param tokenId Citizen token id to burn.
    function kill(uint256 tokenId) external {
        if (msg.sender != deathAndTaxes) revert NotDeathAndTaxes();

        _burnWithTracking(tokenId);
    }
}
