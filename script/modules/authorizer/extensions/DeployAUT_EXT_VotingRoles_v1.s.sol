pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {AUT_EXT_VotingRoles_v1} from
    "src/modules/authorizer/role/AUT_EXT_VotingRoles_v1.sol";

/**
 * @title AUT_EXT_VotingRoles_v1 Deployment Script
 *
 * @dev Script to deploy a new AUT_EXT_VotingRoles_v1.
 *
 *
 * @author Inverter Network
 */
contract DeployAUT_EXT_VotingRoles_v1 is Script {
    // ------------------------------------------------------------------------
    // Fetch Environment Variables
    uint deployerPrivateKey = vm.envUint("ORCHESTRATOR_ADMIN_PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    AUT_EXT_VotingRoles_v1 votingRoles;

    function run() external returns (address) {
        vm.startBroadcast(deployerPrivateKey);
        {
            // Deploy the VotingRoles module.

            votingRoles = new AUT_EXT_VotingRoles_v1();
        }

        vm.stopBroadcast();

        // Log the deployed AUT_EXT_VotingRoles_v1 contract address.
        console2.log(
            "Deployment of AUT_EXT_VotingRoles_v1 Implementation at address",
            address(votingRoles)
        );

        return address(votingRoles);
    }
}
