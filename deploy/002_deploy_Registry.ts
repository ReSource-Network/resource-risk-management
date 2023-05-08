import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { deployProxyAndSave } from "../utils/utils"

const func: DeployFunction = async function (hardhat: HardhatRuntimeEnvironment) {
  let registryAddress = (await hardhat.deployments.getOrNull("StableCreditRegistry"))?.address
  if (!registryAddress) {
    // deploy registry
    const registryAbi = (await hardhat.artifacts.readArtifact("StableCreditRegistry")).abi
    const registryArgs = []
    registryAddress = await deployProxyAndSave(
      "StableCreditRegistry",
      registryArgs,
      hardhat,
      registryAbi
    )
  }
}
export default func
func.tags = ["REGISTRY"]
