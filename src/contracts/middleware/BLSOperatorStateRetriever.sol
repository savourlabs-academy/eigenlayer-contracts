// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "./BLSRegistryCoordinatorWithIndices.sol";

import "../interfaces/IStakeRegistry.sol";
import "../interfaces/IBLSPubkeyRegistry.sol";
import "../interfaces/IIndexRegistry.sol";
import "../interfaces/IBLSRegistryCoordinatorWithIndices.sol";


contract BLSOperatorStateRetriever {
    struct Operator {
        bytes32 operatorId;
        uint96 stake;
    }

    IBLSRegistryCoordinatorWithIndices public registryCoordinator;
    IStakeRegistry public stakeRegistry;
    IBLSPubkeyRegistry public blsPubkeyRegistry;
    IIndexRegistry public indexRegistry;

    constructor(IBLSRegistryCoordinatorWithIndices _registryCoordinator) {
        registryCoordinator = _registryCoordinator;

        stakeRegistry = _registryCoordinator.stakeRegistry();
        blsPubkeyRegistry = _registryCoordinator.blsPubkeyRegistry();
        indexRegistry = _registryCoordinator.indexRegistry();
    }

    /**
     * @notice returns the ordered list of operators (id and stake) for each quorum
     * @param operatorId the id of the operator calling the function
     * @return 2d array of operators. For each quorum, a ordered list of operators
     */
    function getOperatorState(bytes32 operatorId) external view returns (Operator[][] memory) {
        bytes memory quorumNumbers = BytesArrayBitmaps.bitmapToBytesArray(registryCoordinator.getCurrentQuorumBitmapByOperatorId(operatorId));

        return getOperatorState(quorumNumbers);
    }

    function getOperatorState(bytes memory quorumNumbers) public view returns(Operator[][] memory) {
        Operator[][] memory operators = new Operator[][](quorumNumbers.length);
        for (uint256 i = 0; i < quorumNumbers.length; i++) {
            uint8 quorumNumber = uint8(quorumNumbers[i]);
            bytes32[] memory operatorIds = indexRegistry.getOperatorListForQuorum(quorumNumber);
            operators[i] = new Operator[](operatorIds.length);
            for (uint256 j = 0; j < operatorIds.length; j++) {
                bytes32 operatorId = bytes32(operatorIds[j]);
                operators[i][j] = Operator({
                    operatorId: operatorId,
                    stake: stakeRegistry.getMostRecentStakeUpdateByOperatorId(operatorId, quorumNumber).stake
                });
            }
        }
            
        return operators;
    }
}