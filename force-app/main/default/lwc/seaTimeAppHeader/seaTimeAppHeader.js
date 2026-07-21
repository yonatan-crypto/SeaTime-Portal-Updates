import { LightningElement } from 'lwc'
import LOGO from '@salesforce/resourceUrl/seaTimeLogo'
import FORM_FACTOR from '@salesforce/client/formFactor'

export default class SeaTimeAppHeader extends LightningElement {

    companyLogo = LOGO

    get logoSelector() {
        return FORM_FACTOR == 'Large' ? 'logo-desktop' : 'logo-mobile'
    }
}