/**
 * @description It renders as a modal popup to confirm the booking under the club cruise page.
 * @author Ceptes
 * @date Sunday-August-04-2024
 **/

import { LightningElement, api } from 'lwc'
import Verbiages from 'c/seaTimeAppVerbiages'
import generateAndSendClubContract from '@salesforce/apex/PrivateReservationPageController.generateAndSendClubContract';

let verbiage

export default class BookClubCruiseModal extends LightningElement {

    @api selectedCruise = {}
    contractSent = false;
    contractError = null;
    reachOutToClub
    clubCruiseBookingLabel
    cancel
    confirm
    showSpinner
    noSlotLeft

    get showConfirmButton() {
        return !this.selectedCruise.isBookingNotAvailable && !this.noSeatLeft
    }

    get noSeatLeft() {
        return this.selectedCruise.noSeatLeft
    }

    constructor() {
        super()
        verbiage = new Verbiages(this)
        verbiage.loadBookClubCruiseLabels()
    }

    renderedCallback() {
        if (this.noSeatLeft) {
            this.showSpinner = false
        }
    }

    handleCloseModal() {
        this.dispatchEvent(new CustomEvent('close'))
    }

    handleConfirm() {
        this.showSpinner = true
        this.dispatchEvent(new CustomEvent('confirm'))
    }

    async handleGenerateContract() {
        this.showSpinner = true;
        this.contractError = null;
        try {
            const transId = this.selectedCruise?.transactionId;
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