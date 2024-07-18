pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {FeeManager_v1} from "@ex/fees/FeeManager_v1.sol";

import {IInverterBeacon_v1} from "src/proxies/interfaces/IInverterBeacon_v1.sol";

import {DeployAndSetUpInverterBeacon_v1} from
    "script/proxies/DeployAndSetUpInverterBeacon_v1.s.sol";

/**
 * @title FeeManager Deployment Script
 *
 * @dev Script to deploy a new FeeManager and link it to a beacon.
 *
 * @author Inverter Network
 */
contract DeployFeeManager_v1 is Script {
    // ------------------------------------------------------------------------
    // Fetch Environment Variables
    uint deployerPrivateKey = vm.envUint("ORCHESTRATOR_ADMIN_PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    DeployAndSetUpInverterBeacon_v1 deployAndSetUpInverterBeacon_v1 =
        new DeployAndSetUpInverterBeacon_v1();

    function run() external returns (address) {
        // Read deployment settings from environment variables.

        address reverter = vm.envAddress("REVERTER_ADDRESS");
        address governor = vm.envAddress("GOVERNOR_ADDRESS");
        address defaultProtocolTreasury =
            vm.envAddress("COMMUNITY_MULTISIG_ADDRESS"); // Community Multisig as default treasury
        uint defaultCollateralFee = 100; // Should be 1%
        uint defaultIssuanceFee = 100; // Should be 1%
            // Check settings.
        require(
            reverter != address(0),
            "DeployOrchestratorFactory_v1: Missing env variable: reverter contract"
        );
        require(
            governor != address(0),
            "DeployFeeManager: Missing env variable: governor"
        );

        require(
            defaultProtocolTreasury != address(0),
            "DeployFeeManager: Missing env variable: defaultProtocolTreasury"
        );

        // Deploy the Governor.
        return run(
            reverter,
            governor,
            defaultProtocolTreasury,
            defaultCollateralFee,
            defaultIssuanceFee
        );
    }

    /// @notice Creates the implementation of the FeeManager
    /// @return implementation The implementation of the FeeManager
    function run(
        address reverter,
        address owner,
        address defaultProtocolTreasury,
        uint defaultCollateralFee,
        uint defaultIssuanceFee
    ) public returns (address implementation) {
        address feeManagerImplementation;
        vm.startBroadcast(deployerPrivateKey);
        {
            // Deploy the feeManager.
            feeManagerImplementation = address(new FeeManager_v1());
        }
        vm.stopBroadcast();

        address feeManagerBeacon;
        address feeManagerProxy;

        (feeManagerBeacon, feeManagerProxy) = deployAndSetUpInverterBeacon_v1
            .deployBeaconAndSetupProxy(
            reverter, owner, feeManagerImplementation, 1, 0, 0
        );

        FeeManager_v1 feeManager = FeeManager_v1(feeManagerProxy);

        vm.startBroadcast(deployerPrivateKey);
        {
            feeManager.init(
                owner,
                defaultProtocolTreasury,
                defaultCollateralFee,
                defaultIssuanceFee
            );
        }
        vm.stopBroadcast();

        implementation = address(feeManager);

        // Log
        console2.log(
            "Deployment of Fee Manager implementation at address ",
            implementation
        );
    }

    function createProxy(address reverter, address owner)
        external
        returns (address implementation)
    {
        address feeManagerImplementation;
        vm.startBroadcast(deployerPrivateKey);
        {
            // Deploy the feeManager.
            feeManagerImplementation = address(new FeeManager_v1());
        }
        vm.stopBroadcast();

        address feeManagerBeacon;
        address feeManagerProxy;

        (feeManagerBeacon, feeManagerProxy) = deployAndSetUpInverterBeacon_v1
            .deployBeaconAndSetupProxy(
            reverter, owner, feeManagerImplementation, 1, 0, 0
        );

        implementation = address(FeeManager_v1(feeManagerProxy));
        // Log
        console2.log(
            "Deployment of Fee Manager implementation at address ",
            implementation
        );
    }

    function init(
        address feeManager,
        address owner,
        address defaultProtocolTreasury,
        uint defaultCollateralFee,
        uint defaultIssuanceFee
    ) external {
        vm.startBroadcast(deployerPrivateKey);
        {
            FeeManager_v1(feeManager).init(
                owner,
                defaultProtocolTreasury,
                defaultCollateralFee,
                defaultIssuanceFee
            );
        }
        vm.stopBroadcast();

        // Log
        console2.log("Initialization of Fee Manager at address ", feeManager);
    }
}
