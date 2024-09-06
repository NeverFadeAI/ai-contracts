/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
  getContractFromArtifact
} from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {
    
  const NeverFadeHubAddress = "0xcD6f5Bf3894fe063DC3a2eC30269469B40d789Ef"
  
  await deployAndVerifyAndThen({
      hre,
      name: "LinearCurveModule",
      contract: 'LinearCurveModule',
      args: [NeverFadeHubAddress],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployLinearCurveModule']

export default deployFn
