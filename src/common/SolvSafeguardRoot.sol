// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { GnosisSafeL2, Enum } from "safe-contracts/GnosisSafeL2.sol";
import { Guard } from "safe-contracts/base/GuardManager.sol";
import { BaseGuard } from "./BaseGuard.sol";
import { GuardManagerGuard } from "./GuardManagerGuard.sol";
import "forge-std/console.sol";

abstract contract SolvSafeguardRoot is Guard, Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    event SolvGuardsAdded(bytes32 indexed cluster, address guard);
    event SolvGuardsRemoved(bytes32 indexed cluster, address guard);
    event SolvGuardsSetForbidden();

    EnumerableSet.Bytes32Set internal _clusters;

    // `Cluster` => `Guard Address Set`
    mapping(bytes32 => EnumerableSet.AddressSet) internal _guards;

    bool public allowSetSolvGuards;

    address public immutable safeAccount;
    
	fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    constructor(address safeAccount_) Ownable() {
        safeAccount = safeAccount_;
        allowSetSolvGuards = true;

        // GuardManagerGuard: allow updating safeguard address by default
		bytes32 guardManagerCluster = bytes32(keccak256("GuardManagerGuards"));
		GuardManagerGuard guardManagerGuard = new GuardManagerGuard(safeAccount_);
		address[] memory guardManagerGuards = new address[](1);
		guardManagerGuards[0] = address(guardManagerGuard);
		_addSolvGuards(guardManagerCluster, guardManagerGuards);
    }

    function addSolvGuards(bytes32 cluster_, address[] calldata guards_) external onlyOwner {
        _addSolvGuards(cluster_, guards_);
    }

    function _addSolvGuards(bytes32 cluster_, address[] memory guards_) internal {
        require(allowSetSolvGuards, "not allowed");
        require(guards_.length > 0, "empty guards");

        for (uint256 index = 0; index < guards_.length; index++) {
            if (_guards[cluster_].add(guards_[index])) {
                emit SolvGuardsAdded(cluster_, guards_[index]);
            }
        }

        _clusters.add(cluster_);
    }

    function removeSolvGuards(bytes32 cluster_, address[] calldata guards_) external onlyOwner {
        _removeSolvGuards(cluster_, guards_);
    }

    function _removeSolvGuards(bytes32 cluster_, address[] memory guards_) internal {
        require(allowSetSolvGuards, "not allowed");
        require(guards_.length > 0, "empty guards");

        for (uint256 index = 0; index < guards_.length; index++) {
            if (_guards[cluster_].remove(guards_[index])) {
                emit SolvGuardsRemoved(cluster_, guards_[index]);
            }
        }

        if (_guards[cluster_].length() == 0) {
            _clusters.remove(cluster_);
        }
    }

    function getAllClusters() public view returns (bytes32[] memory) {
        return _clusters.values();
    }

    function getAllGuards(bytes32 cluster_) public view returns (address[] memory) {
        return _guards[cluster_].values();
    }

    function forbidSetSolvGuards() external onlyOwner {
        // Remove GuardManagerGuard: disallow updating safeguard address
		bytes32 guardManagerCluster = bytes32(keccak256("GuardManagerGuards"));
        address[] memory guards = getAllGuards(guardManagerCluster);
        _removeSolvGuards(guardManagerCluster, guards);        

        allowSetSolvGuards = false;
        emit SolvGuardsSetForbidden();
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation /*operation*/,
        uint256 /*safeTxGas*/,
        uint256 /*baseGas*/,
        uint256 /*gasPrice*/,
        address /*gasToken*/,
        address payable /*refundReceiver*/,
        bytes memory /*signatures*/,
        address msgSender
    ) external override {
        if (to == safeAccount && data.length == 0) {
            console.logString("SolvSafeguard: checkTransaction: safeWallet");
            return;
        }
        BaseGuard.TxData memory txData = BaseGuard.TxData({
            from: msgSender,
            to: to,
            value: value,
            data: data
        });

        bool globalCheckResult = false;

        uint256 clusterLength = _clusters.length();
        for (uint256 i = 0; i < clusterLength; i++ ) {
            EnumerableSet.AddressSet storage guardSet = _guards[_clusters.at(i)];
            uint256 guardLength = guardSet.length();
            
            bool clusterCheckResult = true;
            for (uint256 j = 0; j < guardLength; j++) {
                BaseGuard.CheckResult memory guardResult = BaseGuard(guardSet.at(j)).checkTransaction(txData);
                if (!guardResult.success) {
                    clusterCheckResult = false;
                    break;
                }
            }

            if (clusterCheckResult) {
                globalCheckResult = true;
                break;
            }
        }

        require(globalCheckResult, "SolvSafeguard: all guards failed");
	}

    function checkAfterExecution(
        bytes32 txHash,
        bool success
    ) external override {}

}