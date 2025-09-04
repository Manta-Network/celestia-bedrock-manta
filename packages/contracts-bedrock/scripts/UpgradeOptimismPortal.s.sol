pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {ProxyAdmin} from "contracts/universal/ProxyAdmin.sol";
import {OptimismPortal} from "../contracts/L1/OptimismPortal.sol";

contract UpgradeScript is Script {

    function run() external {
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");

        ProxyAdmin proxyAdmin = ProxyAdmin(0xa2DCa85BB892De55D8B262d1806114733106e8D1);
        address portalProxy = 0x9168765EE952de7C6f8fC6FaD5Ec209B960b7622;

        // implementation
        address portalImplementation = 0x4fEee20712abF5724C2BC0476BD87CBf1F1eE388;
        vm.startBroadcast(ownerPrivateKey);

        bytes memory upgradeCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgrade.selector,
            payable(portalProxy),
            portalImplementation
        );


        console.log("upgradeCalldata===========");
        console.logBytes(upgradeCalldata);
        console.log("upgradeCalldata===========");

        // proxyAdmin.upgrade({
        //     _proxy: payable(optimismPortalProxy),
        //     _implementation: address(portal)
        // });

        vm.stopBroadcast();

    }

}
