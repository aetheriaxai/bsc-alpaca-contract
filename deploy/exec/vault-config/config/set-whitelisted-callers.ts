import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { TimelockEntity } from "../../../entities";
import { fileService, TimelockService } from "../../../services";
import { getConfig } from "../../../entities/config";
import { Multicall2Service } from "../../../services/multicall/multicall2";
import { ConfigurableInterestVaultConfig, ConfigurableInterestVaultConfig__factory } from "../../../../typechain";
import { getDeployer, isFork } from "../../../../utils/deployer-helper";

interface IInput {
  VAULT_SYMBOL: string;
  WHITELISTED_CALLERS: string[];
  IS_ENABLE: boolean;
}

interface IDerivedInput {
  vaultConfig: ConfigurableInterestVaultConfig;
  whitelistedCallers: string[];
  isEnable: boolean;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
  ░██╗░░░░░░░██╗░█████╗░██████╗░███╗░░██╗██╗███╗░░██╗░██████╗░
  ░██║░░██╗░░██║██╔══██╗██╔══██╗████╗░██║██║████╗░██║██╔════╝░
  ░╚██╗████╗██╔╝███████║██████╔╝██╔██╗██║██║██╔██╗██║██║░░██╗░
  ░░████╔═████║░██╔══██║██╔══██╗██║╚████║██║██║╚████║██║░░╚██╗
  ░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║██║░╚███║██║██║░╚███║╚██████╔╝
  ░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝╚═╝░░╚══╝░╚═════╝░
  Check all variables below before execute the deployment script
  */
  const TITLE = "mainnet_whitelist_multisig";
  const TARGETED_VAULT_CONFIG: Array<IInput> = [
    {
      VAULT_SYMBOL: "ibWBNB",
      WHITELISTED_CALLERS: ["0x954b53Bba4DA95537738c6bb7F6FC17E24aa0F54"],
      IS_ENABLE: true,
    },
    {
      VAULT_SYMBOL: "ibBUSD",
      WHITELISTED_CALLERS: ["0x954b53Bba4DA95537738c6bb7F6FC17E24aa0F54"],
      IS_ENABLE: true,
    },
    {
      VAULT_SYMBOL: "ibTUSD",
      WHITELISTED_CALLERS: ["0x954b53Bba4DA95537738c6bb7F6FC17E24aa0F54"],
      IS_ENABLE: true,
    },
    {
      VAULT_SYMBOL: "ibUSDC",
      WHITELISTED_CALLERS: ["0x954b53Bba4DA95537738c6bb7F6FC17E24aa0F54"],
      IS_ENABLE: true,
    },
    {
      VAULT_SYMBOL: "ibETH",
      WHITELISTED_CALLERS: ["0x954b53Bba4DA95537738c6bb7F6FC17E24aa0F54"],
      IS_ENABLE: true,
    },
    {
      VAULT_SYMBOL: "ibCAKE",
      WHITELISTED_CALLERS: ["0x954b53Bba4DA95537738c6bb7F6FC17E24aa0F54"],
      IS_ENABLE: true,
    },
    {
      VAULT_SYMBOL: "ibBTCB",
      WHITELISTED_CALLERS: ["0x954b53Bba4DA95537738c6bb7F6FC17E24aa0F54"],
      IS_ENABLE: true,
    },
  ];
  const EXACT_ETA = "1663156800";

  const config = getConfig();
  const timelockTransactions: Array<TimelockEntity.Transaction> = [];
  const deployer = await getDeployer();
  const multiCall2Service = new Multicall2Service(config.MultiCall, deployer);
  let nonce = await deployer.getTransactionCount();
  const ops = isFork() ? { gasLimit: 2000000 } : {};

  const inputs: Array<IDerivedInput> = TARGETED_VAULT_CONFIG.map((tv) => {
    const vault = config.Vaults.find((v) => tv.VAULT_SYMBOL == v.symbol);
    if (vault === undefined) {
      throw `error: not found vault with ${tv.VAULT_SYMBOL} symbol`;
    }
    if (vault.config === "") {
      throw `error: not found config address`;
    }

    return {
      vaultConfig: ConfigurableInterestVaultConfig__factory.connect(vault.config, deployer),
      whitelistedCallers: tv.WHITELISTED_CALLERS,
      isEnable: tv.IS_ENABLE,
    };
  });

  const owners = await multiCall2Service.multiContractCall<Array<string>>(
    inputs.map((i) => {
      return {
        contract: i.vaultConfig,
        functionName: "owner",
      };
    })
  );
  let isTimeLockExecuted: boolean = false;
  for (let index = 0; index < inputs.length; index++) {
    const i = inputs[index];
    const owner = owners[index];

    if (owner.toLowerCase() === config.Timelock.toLowerCase()) {
      isTimeLockExecuted = true;
      timelockTransactions.push(
        await TimelockService.queueTransaction(
          `>> Queue tx on Timelock to setWhitelistedCallers for ${i.vaultConfig.address}`,
          i.vaultConfig.address,
          "0",
          "setWhitelistedCallers(address[],bool)",
          ["address[]", "bool"],
          [i.whitelistedCallers, i.isEnable],
          EXACT_ETA,
          { gasPrice: ethers.utils.parseUnits("15", "gwei"), ...ops, nonce: nonce++ }
        )
      );
      continue;
    } else {
      console.log(`>> setWhitelistedCaller for ${i.vaultConfig.address}`);
      await i.vaultConfig.setWhitelistedCallers(i.whitelistedCallers, i.isEnable, {
        ...ops,
        nonce: nonce++,
      });
      console.log(`>> ✅ Done`);
    }
  }

  if (isTimeLockExecuted) {
    const ts = Math.floor(Date.now() / 1000);
    fileService.writeJson(`${ts}_${TITLE}`, timelockTransactions);
  }
};

export default func;
func.tags = ["SetWhitelistedCallers"];
