/**
 * @description
 * @author Ceptes
 * @date Sunday-July-21-2024
 **/

import { LightningElement, api } from 'lwc';
import Verbiages from 'c/seaTimeAppVerbiages';
import DIR from "@salesforce/i18n/dir";
import generateAndSendClubContract from '@salesforce/apex/PrivateReservationPageController.generateAndSendClubContract';

let verbiages

export default class BookPrivateBoatModal extends LightningElement {

    @api selectedBoat = {}
    contractSent = false;
    contractError = null;
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
    needSkipperLabel
    needSkipper = false
    dir = DIR;
    
    constructor() {
        super()
        verbiages = new Verbiages(this)
        verbiages.loadBookPrivateBoatVerbiages()
    }

    connectedCallback() {
        if (this.selectedBoat && this.selectedBoat.isdisable) {
            this.needSkipper = true;
        }
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
    
    handleNeedSkipperChange(event) {
        this.needSkipper = event.target.checked;
    }
    handleCloseModal() {
        this.dispatchEvent(new CustomEvent('close'))
    }

    handleApprove() {
        this.showSpinner = true
        this.dispatchEvent(new CustomEvent('approve', { detail: { additionalInput: this.additionalInput, needSkipper: this.needSkipper } }));
    }

    handleNavigateToCertificates() {
        this.dispatchEvent(new CustomEvent('navigatetocertificate', {
            bubbles: true,
            composed: true
        }))
    }

    async handleGenerateContract() {
        this.showSpinner = true;
        this.contractError = null;
        try {
            const transId = this.selectedBoat?.transactionId;
            await generateAndSendClubContract({ transactionId: transId });
            this.contractSent = true;
        } catch (error) {
            console.error('Error generating contract:', error);
            this.contractError = error?.body?.message || error?.message || 'אירעה שגיאה בשליחת התקנון למייל.';
        } finally {
            this.showSpinner = false;
        }
    }

}