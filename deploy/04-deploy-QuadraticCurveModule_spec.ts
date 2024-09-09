/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
} from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {
    
  const NeverFadeHubAddress = "0xcD6f5Bf3894fe063DC3a2eC30269469B40d789Ef"
  
  await deployAndVerifyAndThen({
      hre,
      name: "QuadraticCurveModule",
      contract: 'QuadraticCurveModule',
      args: [NeverFadeHubAddress],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployQuadraticCurveModule']

export default deployFn
