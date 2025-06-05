pragma solidity ^0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {ProxyAdmin} from "contracts/universal/ProxyAdmin.sol";
import {L2OutputOracle} from "../contracts/L1/L2OutputOracle.sol";

contract UpgradeScript is Script {

    function run() external {
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        ProxyAdmin proxyAdmin = ProxyAdmin(vm.envAddress("PROXY_ADMIN_ADDRESS"));
        address l2OutputOracleProxy = vm.envAddress("L2_OUTPUT_ORACLE_PROXY");
        L2OutputOracle OracleProxy = L2OutputOracle(l2OutputOracleProxy);
        vm.startBroadcast(ownerPrivateKey);

        console.log("===========");
        console.log(OracleProxy.SUBMISSION_INTERVAL());
        console.log(OracleProxy.L2_BLOCK_TIME());
        console.log(OracleProxy.startingBlockNumber());
        console.log(OracleProxy.startingTimestamp());
        console.log(OracleProxy.PROPOSER());
        console.log(OracleProxy.CHALLENGER());
        console.log(OracleProxy.FINALIZATION_PERIOD_SECONDS());
        console.log("===========");

        L2OutputOracle oracle1 = new L2OutputOracle({
            _submissionInterval: OracleProxy.SUBMISSION_INTERVAL(),
            _l2BlockTime: OracleProxy.L2_BLOCK_TIME(),
            _startingBlockNumber: OracleProxy.startingBlockNumber(),
            _startingTimestamp: OracleProxy.startingTimestamp(),
            _proposer: OracleProxy.PROPOSER(),
            _challenger: OracleProxy.CHALLENGER(),
            _finalizationPeriodSeconds: OracleProxy.FINALIZATION_PERIOD_SECONDS()
        });

        console.log("address===========");
        console.log(address(oracle1));
        console.log("address===========");

        proxyAdmin.upgrade({
            _proxy: payable(l2OutputOracleProxy),
            _implementation: address(oracle1)
        });

        vm.stopBroadcast();

    }

}
