/**
 * @description It renders the club cruise page tab.
 * @author Ceptes
 * @date Monday-July-15-2024
 **/
import { LightningElement, api, track } from 'lwc'
import Verbiages from 'c/seaTimeAppVerbiages'
import Service from './clubCruisesPageService'
import getClubCruisePrices from '@salesforce/apex/ClubCruisesPageController.getClubCruisePrices'
import createCoCruiseMember from '@salesforce/apex/ClubCruisesPageController.createCoCruiseMember'
import Utility from 'c/seaTimeAppUtilities'
import FORM_FACTOR from '@salesforce/client/formFactor'

let verbiage, service

export default class ClubCruisesPage extends LightningElement {

    showSearchSection
    newClubCruises
    clubCruise
    recentCruises
    cruiseTypeLabel
    @track debugInfo;

    show12HourTime = false
    boatIdsArray = []
    priceLinesArray = []
    boatIdToPriceLines = {}
    utility
    showBookCruiseModal
    selectedCruise
    showBookNotAvailableModal
    noCruiseAvailable
    price
    selectedCruiseType = 'Enriching'
    slotsLeft
    renderWire;

    @track _clubCruisesArray
    @track selectedClubCruisesArray = []
    @track recentClubCruises = []

    // Filter states
    @track filterClub = true;
    @track filterSchool = true;
    @track filterTheory = true;
    @track filterCert = true;
    @track filterFriends = true;

    @api get clubCruisesArray() {
        return this._clubCruisesArray
    } set clubCruisesArray(cruiseArray) {
        if (!cruiseArray?.length) { return }
        this._clubCruisesArray = JSON.parse(JSON.stringify(cruiseArray))
        this.refreshData()
    }

    @api isDesktop
    @api account
    @api isStudentUser = false

    @api get transaction() {
        return this._transaction
    } set transaction(value) {
        this._transaction = value
        this.refreshData()
    }

    @api initialShowSearchSection = false;

    refreshData() {
        if (!this._clubCruisesArray || !this._clubCruisesArray.length) return;
        
        this.getClubCruisePrice()
        service.populateRecentClubCruises()
        service.updateSelectedClubCruisesArray()
    }

    @api
    get isNavigateToCertification() {
        return this._isNavigateToCertification
    }
    set isNavigateToCertification(value) {
        if (value) {
            this.selectedCruiseType = 'Certification'
            this.showSearchSection = true
            service.updateSelectedClubCruisesArray()
        }
    }

    get mainSectionSelector() {
        return !this.showSearchSection && this.isDesktop && 'main-section-desktop'
    }

    get pageHeader() {
        return this.showSearchSection ? this.clubCruise : this.recentCruises
    }

    get showAddNewReservationButton() {
        return !this.showSearchSection
    }

    get showRecentReservations() {
        return !this.showSearchSection
    }

    get showSelectedClubCruises() {
        return this.selectedClubCruisesArray.length
    }

    get showAdditionalInfo() {
        return this.selectedCruiseType == 'Certification'
            || this.selectedCruiseType == 'Enriching'
            || this.selectedCruiseType == 'Course'
    }

    get showSkipperName() {
        return this.selectedCruiseType == 'Friends'
    }

    get isDesktop() {
        return FORM_FACTOR == 'Large'
    }

    get fixedSearchSectionSelector() {
        return this.isDesktop ? 'fixed-club-cruise-search-section' : 'box-padding'
    }

    get headerSelector() {
        return this.isDesktop && !this.showRecentReservations && 'fixed-sub-header'
    }

    constructor() {
        super()
        verbiage = new Verbiages(this)
        verbiage.loadClubCruisesLabels()
        service = new Service(this)
        this.utility = new Utility(this)
    }

    connectedCallback() {
        if (this.initialShowSearchSection) {
            this.showSearchSection = true;
        }
    }

    async getClubCruisePrice() {

        if (!this.clubCruisesArray.length) { return }

        service.populateClubCruisesBoatIds()
        try {
            var clubCruisesArrayStr = JSON.stringify(this.clubCruisesArray);
            console.log('clubCruisesArrayStr'+clubCruisesArrayStr);
            this.priceLinesArray = await getClubCruisePrices({ boatIdsArray: clubCruisesArrayStr })
            console.log('priceLinesArray'+JSON.stringify(this.priceLinesArray));
            service.populateBoatIdToPriceLines()
            service.updateClubCruisePrices()
        } catch (error) {
            console.log('There is an error', JSON.stringify(error))
        }
    }

    handleFilterChange(event) {
        const filterId = event.target.dataset.id;
        const checked = event.target.checked;
        
        if (filterId === 'club') this.filterClub = checked;
        else if (filterId === 'school') this.filterSchool = checked;
        else if (filterId === 'theory') this.filterTheory = checked;
        else if (filterId === 'cert') this.filterCert = checked;
        else if (filterId === 'friends') this.filterFriends = checked;

        service.updateSelectedClubCruisesArray();
    }

    handleAddNewClubCruises() {
        this.showSearchSection = !this.showSearchSection
    }

    handleShowBookModal(event) {
        if (this.showBookCruiseModal) {
            this.showBookCruiseModal = false
        } else {
            this.showBookCruiseModal = true
            const selectedCruiseId = event.target.dataset.id
            this.selectedCruise = this.selectedClubCruisesArray
                .find(({ id }) => id == selectedCruiseId)

            this.selectedCruise.accountId = this.account.Id
        }
    }

    async handleConfirmBooking() {
         try {
        const isBooked = await createCoCruiseMember({ selectedCruise: this.selectedCruise })

        if (isBooked) {
            this.renderWire = true;
            this.showBookCruiseModal = false
            this.showSearchSection = true           
        } else {
            this.selectedCruise.noSeatLeft = true
        }

        this.dispatchEvent(new CustomEvent('refresh'))


        } catch (error) {
             console.error('There is an error', error)
         } 
    }
   
}