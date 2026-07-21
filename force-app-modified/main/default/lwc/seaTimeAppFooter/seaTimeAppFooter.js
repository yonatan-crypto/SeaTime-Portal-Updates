/**
 * @description Renders fotter for all the pages of sea time app.
 * @author Ceptes
 * @date Friday-July-05-2024
 **/

import { LightningElement } from 'lwc'
import LOGO from '@salesforce/resourceUrl/seaTimeLogo'
import FORM_FACTOR from '@salesforce/client/formFactor'
import Verbiage from 'c/seaTimeAppVerbiages'

let verbiage

export default class SeaTimeAppFooter extends LightningElement {

    companyLogo = LOGO

    footerLabel
    footerLabel2

    constructor() {
        super()
        verbiage = new Verbiage(this)
        verbiage.loadFooterVerbiages()
    }

    get isDesktop() {
        return FORM_FACTOR == 'Large'
    }



}