// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SolvSafeguardRoot } from "./common/SolvSafeguardRoot.sol";

contract GuardManagerSafeguard is SolvSafeguardRoot {
	
	string public constant NAME = "GuardManageSafeguard";
    uint256 public constant VERSION = 1;

	constructor(address safeAccount_, address governor_) SolvSafeguardRoot(safeAccount_, governor_) {}

}