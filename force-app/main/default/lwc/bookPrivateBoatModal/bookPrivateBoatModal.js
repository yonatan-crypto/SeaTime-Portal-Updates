/**
 * @description
 * @author Ceptes
 * @date Sunday-July-21-2024
 **/

import { LightningElement, api } from 'lwc';
import Verbiages from 'c/seaTimeAppVerbiages';
import DIR from "@salesforce/i18n/dir";

let verbiages

export default class BookPrivateBoatModal extends LightningElement {

    @api selectedBoat = {}
    _boatReserved;
    showSpinner
    sailingDetails
    date
    nameOfTheBoat
    typeOfTheBoat
    startTime
    endTime
    cruiseValue
    confirm
    cancel
    certificate
    additionalInput
    boatRequiresCertificate
    additionalInfo
    aiPlaceHolder
    dir = DIR;
    
    constructor() {
        super()
        verbiages = new Verbiages(this)
        verbiages.loadBookPrivateBoatVerbiages()
    }

  @api
    get boatReserved() {
        return this._boatReserved;
    }
    set boatReserved(value) {
        if (value) {
            this.showSpinner = false;
        }
      this._boatReserved = value;
    }

    handleInput(event) {
        this.additionalInput = event.target.value;
    }
    handleCloseModal() {
        this.dispatchEvent(new CustomEvent('close'))
    }

    handleApprove() {
        this.showSpinner = true
        this.dispatchEvent(new CustomEvent('approve', { detail: { additionalInput: this.additionalInput } }));
    }

    handleNavigateToCertificates() {
        this.dispatchEvent(new CustomEvent('navigatetocertificate', {
            bubbles: true,
            composed: true
        }))
    }

}