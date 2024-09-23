/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
} from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {
    
  const NeverFadeHubAddress = "0x27E93060CC304Ed56Ed49aE1f776382B62f94E95"
  
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
