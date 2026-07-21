/**
 * @description It renders as a modal popup to confirm the booking under the club cruise page.
 * @author Ceptes
 * @date Sunday-August-04-2024
 **/

import { LightningElement, api } from 'lwc'
import Verbiages from 'c/seaTimeAppVerbiages'

let verbiage

export default class BookClubCruiseModal extends LightningElement {


    @api selectedCruise = {}
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
}