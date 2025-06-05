pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {ProxyAdmin} from "contracts/universal/ProxyAdmin.sol";
import {OptimismPortal} from "../contracts/L1/OptimismPortal.sol";

contract UpgradeScript is Script {

    function run() external {
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));
        address optimismPortalProxy = vm.envAddress("OPTIMISM_PORTAL_PROXY");
        OptimismPortal PortalProxy = OptimismPortal(payable(optimismPortalProxy));
        vm.startBroadcast(ownerPrivateKey);

        console.log("===========");
        console.log(PortalProxy.GUARDIAN());
        console.log(PortalProxy.paused());
        console.log("===========");

        OptimismPortal portal = new OptimismPortal({
            _l2Oracle: PortalProxy.L2_ORACLE(),
            _guardian: PortalProxy.GUARDIAN(),
            _paused: PortalProxy.paused(),
            _config: PortalProxy.SYSTEM_CONFIG()
        });

        console.log("address===========");
        console.log(address(portal));
        console.log("address===========");

        proxyAdmin.upgrade({
            _proxy: payable(optimismPortalProxy),
            _implementation: address(portal)
        });

        vm.stopBroadcast();

    }

}
