/**
 * @description Renders Private Reservation page.
 * @author Ceptes
 * @date Sunday-June-30-2024
 **/

import { LightningElement, api, track } from 'lwc'
import LANG from '@salesforce/i18n/lang';
import DIR from "@salesforce/i18n/dir";
import Verbiages from 'c/seaTimeAppVerbiages'
import Service from './privateReservationService'
import Utility from 'c/seaTimeAppUtilities'
import Wrapper from './privateReservationWrapper'
import DEFAULT_BOAT_IMAGE from '@salesforce/resourceUrl/DefaultBoatImage'
import getPrivateReservationBoats from '@salesforce/apex/PrivateReservationPageController.getPrivateReservationData'
import createPrivateReservation from '@salesforce/apex/PrivateReservationPageController.createPrivateReservation'
import getTransactionFromAccount from '@salesforce/apex/PrivateReservationPageController.getTransactionFromAccount'
import calculateCruisePrice from '@salesforce/apex/SeaTimeController.calculateCruisePrice'
import DEFAULT_BOAT_IMAGES from '@salesforce/resourceUrl/DefaultBoatImages'
import FORM_FACTOR from '@salesforce/client/formFactor'


let verbiage,
    service,
    utility,
    today,
    day,
    wrapper

export default class PrivateReservationPage extends LightningElement {
    showSpinner
    showSearchSection = true // Show search by default (Internal property)
    nextReservationLabel
    showRecentReservations = false // Hide by default
    showInvalidDateVerbiage
    invalidDateVerbiage
    boatTypeRequired
    defaultBoatImage = DEFAULT_BOAT_IMAGE
    boatIdToPriceLines = {}
    showBookBoatModal  
    boatDuration
    selectedBoat
    show12HourTime = false
    boatIdToCertificates = {}
    addNewReservation
    defaultBoatImages = DEFAULT_BOAT_IMAGES
    privateReservation
    nextReservation
    boatType
    duration
    boatReserved;
    Subscription_Check;
    showSubscriptionError;
    sailingDetailsFlag;
    submit;
    renderWire;
    yacht
    catamaran
    x3_Hours 
    lang = LANG
    dir = DIR;
    boatTileDir = DIR =='rtl' ? 'ltr' :'rtl';
    boatDateDir = this.lang =='en-US' ? 'ltr' :'rtl';

    //boatTileDir = lang == 'en-US'? 'rtl' : 'ltr';
    boatWeekendIndices = [];
    transactionId;
    @track recentClubCruises = [];

    @track daysArray = []
    @track boatTypesArray = []
    @track boatDurationArray = []
    @track boatsArrayRaw = []
    @track boatsArray = []
    @track searchData = {}
    @track currentTime;

    @api privateReservationArray
    @api accountId
    @api clubCruisesArray = []
    @api initialShowSearchSection = false
    

    get mainSectionSelector() {
        return this.isDesktop ? 'main-section main-section-desktop' : 'main-section'
    }

    get showAddNewReservationButton() {
        return !this.showSearchSection
    }

    get pageHeader() {
        return this.showSearchSection ? this.privateReservation : this.nextReservation
    }

    get disableSearchButton() {
        return this.showInvalidDateVerbiage
    }

    get isDesktop() {
        return FORM_FACTOR == 'Large'
    }

    get fixedSearchSectionSelector() {
        return this.isDesktop ? 'fixed-search-section' : 'box-padding'
    }

    get headerSelector() {
        return this.isDesktop && this.showSearchSection && 'fixed-sub-header'
    }

    constructor() {
        super()
        verbiage = new Verbiages(this)
        verbiage.loadPrivateReservationLabels()

        service = new Service(this)
        utility = new Utility(this)
        today = utility.getTodaysDate()
        day = utility.getDayIndexFromDate(today)
        service.updateDaysArray(day, 'index')
        wrapper = new Wrapper(this)
        this.searchData = { date: today, boatTypes: [this.yacht], boatDuration: this.x2_Hours }
        this.daysArray = utility.updateSelectedDayArray(today, this.daysArray);
    }

    connectedCallback() {
        if (this.initialShowSearchSection) {
            this.showSearchSection = true;
        } else {
            // Force true internally if not specified, 
            // since the user wants search shown before recent cruises
            this.showSearchSection = true;
        }
    }

    handleNextDay() {
        const d = new Date(this.searchData.date);
        d.setDate(d.getDate() + 1);
        this.searchData.date = d.toISOString().slice(0, 10);
        service.validateSelectedDate(this.searchData.date);
    }

    handlePrevDay() {
        const d = new Date(this.searchData.date);
        d.setDate(d.getDate() - 1);
        this.searchData.date = d.toISOString().slice(0, 10);
        service.validateSelectedDate(this.searchData.date);
    }

    handleScrollLeft(event) {
        const startTime = event.currentTarget.dataset.time;
        const container = this.template.querySelector(`[data-container-time="${startTime}"]`);
        if (container) {
            container.scrollBy({ left: -350, behavior: 'smooth' });
        }
    }

    handleScrollRight(event) {
        const startTime = event.currentTarget.dataset.time;
        const container = this.template.querySelector(`[data-container-time="${startTime}"]`);
        if (container) {
            container.scrollBy({ left: 350, behavior: 'smooth' });
        }
    }

    handleNavigateToPrivateReservation() {
        this.showSearchSection = !this.showSearchSection
    }

    handleNewSearch() {
        this.boatsArray = [];
        this.boatsArrayRaw = [];
        this.showSearchSection = true;
    }

    handleSearchDateChange(event) {
        const selectedDate = event.target.value
        console.log('selectedDate==>',selectedDate);
        
        service.validateSelectedDate(selectedDate)
        const dayIndex = utility.getDayIndexFromDate(selectedDate)
        service.updateDaysArray(dayIndex, 'index')
    }

    handleDateClick(event) {
        if (event.target.showPicker) {
            event.target.showPicker();
        }
    }

    async handleSelectedDay(event) {
        const dataId = event.currentTarget.dataset.id
        const dayIndex = event.currentTarget.dataset.index
        this.searchData.selectedDay = dataId
        await service.updateDaysArray(dataId, 'value')
        await service.updateTheDateOnDaySelect(dayIndex)
        await service.validateSelectedDate(this.searchData.date)
    }

    handleBoatTypeSelected(event) {
        const target = event.target
        service.updateSelectedTypeButtonSelector(target)

        if (this.searchData.boatTypes.length == 0) {
            this.showInvalidDateVerbiage = true;
            this.invalidDateVerbiage = this.boatTypeRequired;
        } else {
            //Checking selectedTime 
            service.validateSelectedDate(this.searchData.date)
        }
    }

    handleBoatDurationSelected(event) {
        const dataId = event.target.dataset.id;
        this.searchData.boatDuration = dataId;
        service.updateSearchButtonsArray(this.boatDurationArray, dataId)
    }

    async handleShowBookModal(event) {
        if (!this.showBookBoatModal) {
            const dataset = event.currentTarget.dataset
            let currentAccountId = this.accountId || sessionStorage.getItem('accountId');
            let transDetails =  await getTransactionFromAccount({ accountId: currentAccountId});
            this.transactionId = transDetails?.Id;
            
            this.selectedBoat = {}
            let selectedBoat = await this.populateSelectedBoat(dataset);
            selectedBoat.formattedDate = service.formatDate(selectedBoat.date);
            
            this.showBookBoatModal = true;
            this.boatReserved = undefined;
            this.selectedBoat = selectedBoat;
        } else {
            this.showBookBoatModal = false;
        }
    }

    async populateSelectedBoat(dataset) {
        const { boatId, name, startTime, endTime, boatType, isdisable } = dataset
        const { date } = this.searchData
        const israelTimeZoneOffset = '+02:00'; // Israel is UTC+2 in standard time
        const startDate = new Date(`${this.searchData.date}T${startTime}:00${israelTimeZoneOffset}`);
        const endDate = new Date(`${this.searchData.date}T${endTime}:00${israelTimeZoneOffset}`);

        let indexDay = utility.getDayIndexFromDate(this.searchData.date);
        let isHoliday =  this.boatWeekendIndices.length > 0 && this.boatWeekendIndices.includes(indexDay);
        var cruiseRec=
        {
            Boat__c:boatId,
            End_Date__c:endDate.toISOString(),
            Start_Date__c:startDate.toISOString(),
            Holiday__c:isHoliday,
            Transaction__c:this.transactionId
        };
        
        let price = await calculateCruisePrice({cruiseRec:cruiseRec});
        return {
            boatId,
            date,
            name,
            boatType,
            startTime,
            endTime,
            price,
            isdisable,
            accountId: this.accountId
        }
      
    }

    async handleApprovePrivateReservation(event) {
        let inputText = event.detail.additionalInput;
        this.selectedBoat.additionalInput = inputText;
        try {
            const reservedData = await createPrivateReservation({ selectedBoat: this.selectedBoat });
            this.boatReserved = reservedData.startsWith('a04') ? undefined : reservedData;
            if (!this.boatReserved) {
                this.renderWire = true;
                this.showBookBoatModal = false
                this.showRecentReservations = true
                this.showSearchSection = false

                this.dispatchEvent(new CustomEvent('refresh'))
                this.dispatchEvent(new CustomEvent('success'))
            }


        } catch (error) {
            console.log('There is an error', JSON.stringify(error))
        }
    }

    async handleSubmit() {

        try {
            this.showSpinner = true
            let searchDataTrans = this.lang != 'en-US' ? this.translateBoatTypesToEnglish() :this.searchData;
            const boatsApexData = await getPrivateReservationBoats({ searchData: searchDataTrans });
            this.boatsArrayRaw = boatsApexData.boatsArray;
            this.boatWeekendIndices = boatsApexData.boatWeekendIndexes;
            wrapper.wrapBoatsArray()
            this.showRecentReservations = false
            
            // Hide search section after successful search if boats are found
            if (this.boatsArray.length > 0) {
                this.showSearchSection = false;
            }
        } catch (error) {
            console.log('handleSubmit  error', JSON.stringify(error))
        } finally {
            this.showSpinner = false
        }
    }

    translateBoatTypesToEnglish(){
        let searchDataEng = {'date':this.searchData.date,'boatTypes':[]} ;
        this.searchData.boatTypes.forEach(element => {
            this.boatTypesArray.forEach(ele=>{
                if(searchDataEng.boatTypes.length && searchDataEng.boatTypes.includes(ele.value)) {return}
                if(element == ele.label){
                    searchDataEng.boatTypes.push(ele.value);
                }
            })
            
        });
        return searchDataEng;
    }
}