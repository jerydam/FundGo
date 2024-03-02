// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Contribute.sol";

contract ContributionSystemFactory {
    address[] public deployedSystems;

    event ContributionSystemCreated(address indexed newSystem);

    function createContributionSystem(uint dayRange, uint expectedNumber, uint contributionAmount) external {
        address newSystem = address(new ContributionSystem(dayRange, expectedNumber, contributionAmount));
        deployedSystems.push(newSystem);
        emit ContributionSystemCreated(newSystem);
    }

    function getDeployedSystems() external view returns (address[] memory) {
        return deployedSystems;
    }
}
