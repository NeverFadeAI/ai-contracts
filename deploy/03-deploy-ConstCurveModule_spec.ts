/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
} from '../scripts/deploy-utils';

const deployFn: DeployFunction = async (hre) => {

  const NeverFadeHubAddress = "0x74483Cbff8De256ecBF958B12C560af081651fBD"
  
  await deployAndVerifyAndThen({
      hre,
      name: "ConstCurveModule",
      contract: 'ConstCurveModule',
      args: [NeverFadeHubAddress],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DeployConstCurveModule']

export default deployFn
