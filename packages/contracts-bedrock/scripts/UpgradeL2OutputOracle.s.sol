pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {ProxyAdmin} from "contracts/universal/ProxyAdmin.sol";
import {L2OutputOracle} from "../contracts/L1/L2OutputOracle.sol";

contract UpgradeScript is Script {

    function run() external {
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");

        ProxyAdmin proxyAdmin = ProxyAdmin(0xa2DCa85BB892De55D8B262d1806114733106e8D1);
        address oracleProxy = 0x30c789674ad3B458886BBC9abf42EEe19EA05C1D;

        // implementation
        address oracleImplementation = 0x0e874B9acD8d284B9bF6f6c6CC95BCE6F66E5441;
        vm.startBroadcast(ownerPrivateKey);


        bytes memory upgradeCalldata = abi.encodeWithSelector(
            ProxyAdmin.upgrade.selector,
            payable(oracleProxy),
            oracleImplementation
        );

        console.log("upgradeCalldata===========");
        console.logBytes(upgradeCalldata);
        console.log("upgradeCalldata===========");

        // proxyAdmin.upgrade({
        //     _proxy: payable(l2OutputOracleProxy),
        //     _implementation: address(oracle1)
        // });

        vm.stopBroadcast();

    }

}
