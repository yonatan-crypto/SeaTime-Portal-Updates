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
    showSearchSection
    nextReservationLabel
    showRecentReservations = true
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
    @api isDesktop
    @api accountId
    @api clubCruisesArray = [];
    

    get mainSectionSelector() {
        return !this.showSearchSection && this.isDesktop && 'main-section-desktop'
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
        this.searchData = { date: today, boatTypes: [this.yacht, this.catamaran], boatDuration: this.x3_Hours }
        this.daysArray = utility.updateSelectedDayArray(today, this.daysArray);
    }

    handleAddOneWeekToSearchDate() {
        if(this.lang == 'en-US'){
        service.updateSearchDateWithOneWeek(true)
        }else{
            service.updateSearchDateWithOneWeek()
        }
    }

    handleSubtractOneWeekToSearchDate() {
        if(this.lang == 'en-US'){
            service.updateSearchDateWithOneWeek()
        }else{
            service.updateSearchDateWithOneWeek(true)
        }    
    }

    handleNavigateToPrivateReservation() {
        this.showSearchSection = !this.showSearchSection
    }

    handleSearchDateChange(event) {
        const selectedDate = event.target.value
        console.log('selectedDate==>',selectedDate);
        
        service.validateSelectedDate(selectedDate)
        const dayIndex = utility.getDayIndexFromDate(selectedDate)
        service.updateDaysArray(dayIndex, 'index')
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
    console.log('handleShowBookModal'+this.showBookBoatModal);
        if (!this.showBookBoatModal) {
            const dataset = event.currentTarget.dataset
            console.log('dataset'+JSON.stringify(dataset));
             let transDetails =  await getTransactionFromAccount({ accountId: this.accountId});
             console.log('transDetails',JSON.stringify(transDetails));
            this.transactionId = transDetails?.Id;
            console.log('handleShowBookModal inside if',this.showBookBoatModal);
            
            this.selectedBoat = {}
            let selectedBoat = await this.populateSelectedBoat(dataset);
            
            console.log('selectedBoat'+JSON.stringify(selectedBoat));
            selectedBoat.formattedDate = service.formatDate(selectedBoat.date);
            console.log('formattedDate'+JSON.stringify(selectedBoat.formattedDate));
        try{
           
            if(transDetails && transDetails.Points_Balance__c >= selectedBoat.price && transDetails.Active__c && transDetails.Club_Contract__c){
                
                this.showBookBoatModal = true
                this.boatReserved = undefined;
                this.selectedBoat = selectedBoat;
            }else{
                this.showBookBoatModal = true
                this.boatReserved = this.Subscription_Check 
            }
            
        } catch (error) {
            console.log('transDetails error', JSON.stringify(error))
        }  
        }else {
            this.showBookBoatModal = false
        }
    }
async populateSelectedBoat(dataset) {
        console.log('populateSelectedBoat1111'+JSON.stringify(dataset));
        const { boatId, name, startTime, endTime, boatType, isdisable } = dataset
        const { date } = this.searchData
        const israelTimeZoneOffset = '+02:00'; // Israel is UTC+2 in standard time
        const startDate = new Date(`${this.searchData.date}T${startTime}:00${israelTimeZoneOffset}`);
        const endDate = new Date(`${this.searchData.date}T${endTime}:00${israelTimeZoneOffset}`);

        console.log('searchData'+JSON.stringify(this.searchData));
       // const startDate = new Date(`${this.searchData.date}T${startTime}:00.000Z`);
      //  const endDate = new Date(`${this.searchData.date}T${endTime}:00.000Z`);

        let indexDay = utility.getDayIndexFromDate(this.searchData.date);
        let isHoliday =  this.boatWeekendIndices.length && this.boatWeekendIndices.includes(indexDay);
        var cruiseRec=
        {
            Boat__c:boatId,
            End_Date__c:endDate.toISOString(),
            Start_Date__c:startDate.toISOString(),
            Holiday__c:isHoliday,
            Transaction__c:this.transactionId
        };
        console.log('cruiseRec==>',JSON.stringify(cruiseRec));
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
            }


        } catch (error) {
            console.log('There is an error', JSON.stringify(error))
        }
    }

    async handleSubmit() {

        try {
            this.showSpinner = true
            let searchDataTrans = this.lang != 'en-US' ? this.translateBoatTypesToEnglish() :this.searchData;
            console.log('handleSubmit'+JSON.stringify(searchDataTrans));
            const boatsApexData = await getPrivateReservationBoats({ searchData: searchDataTrans });
            console.log('boatsApexData'+JSON.stringify(boatsApexData));
            this.boatsArrayRaw = boatsApexData.boatsArray;
            this.boatWeekendIndices = boatsApexData.boatWeekendIndexes;
            wrapper.wrapBoatsArray()
            this.showRecentReservations = false
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