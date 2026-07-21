/**
 * @description it render the home page after user logged in successfully.
 * @author Ceptes
 * @date Wednesday-August-14-2024
 **/

import { LightningElement, wire, track } from 'lwc'
import { CurrentPageReference } from 'lightning/navigation'
import AppVerbiages from 'c/seaTimeAppVerbiages'
import HomePageBackground from '@salesforce/resourceUrl/HomePageBackground'
import HomePageBackgroundMobile from '@salesforce/resourceUrl/HomePageBackgroundMobile'
import FORM_FACTOR from '@salesforce/client/formFactor'
import HomePageIcons from '@salesforce/resourceUrl/HomePageIcons'
import Service from './homePageService'
import getHomePageTabsData from '@salesforce/apex/HomePageController.getHomePageTabsData'
import Wrapper from './homePageWrapper'
import CharterComingSoon from '@salesforce/resourceUrl/CharterComingSoon'
import cancelCoCruiseSailres from '@salesforce/apex/SeaTimeController.cancelCoCruiseSailres'
import updateCruiseStatus from '@salesforce/apex/SeaTimeController.updateCruiseStatus'

let verbiage,
    service,
    wrapper

export default class HomePage extends LightningElement {

    accountId
    account
    isLoggedIn = false
    renderedCallbackRunOnce = false
    showSpinner = false
    transaction
    cruiseRecordsArray = []
    isNavigateToCertification
    charterComingSoon = CharterComingSoon

    // Overlay
    showWelcomeOverlay = false
    overlayTimer

    show12HourTime = false
    hour
    fullyBooked
    booking
    alreadyBooked

    @track navigationItem = { renderDashboard: true }
    @track navigationItemsArray
    @track privateReservationArray = []
    @track clubCruisesArray = []
    
    @track isMobilePopupOpen = false
    @track selectedCruise = {}
    @track isPrivateSelected = false
    @track activeTab = 'private' // Default tab for mobile dashboard
    @track initialShowSearchSection = false;

    @track pastClubCruises = []
    @track isPastCruisesOpen = false

    get showSubscriptionButton() {
        // Show only if there's an active club membership transaction
        return this.transaction && this.transaction.Active__c === true;
    }

    get pastCruisesIcon() {
        return this.isPastCruisesOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    togglePastCruises() {
        this.isPastCruisesOpen = !this.isPastCruisesOpen;
    }

    get myClubCruisesDashboard() {
        return this.clubCruisesArray.filter(cruise => cruise.coCruiseRecords && cruise.coCruiseRecords.length > 0);
    }

    privateReservationLabel
    joinClubSailingLabel
    chartersLabel
    mySubscriptionLabel

    privateReservationIcon = `${HomePageIcons}/privateReservationIcon.png`
    joinClubSailingIcon = `${HomePageIcons}/joinClubSailingIcon.png`
    chartersIcon = `${HomePageIcons}/chartersIcon.png`
    mySubscriptionIcon = `${HomePageIcons}/mySubscriptionIcon.png`

    get privateTabClass() {
        return this.activeTab === 'private' ? 'tab-button active' : 'tab-button';
    }

    get clubTabClass() {
        return this.activeTab === 'club' ? 'tab-button active' : 'tab-button';
    }

    get isPrivateTabActive() {
        return this.activeTab === 'private';
    }

    get isClubTabActive() {
        return this.activeTab === 'club';
    }

    get privateBookingButtonClass() {
        return this.isPrivateBookingDisabled ? 'cta-button cta-button-disabled' : 'cta-button';
    }

    get isStudentUser() {
        return this.account?.StudentMeshit30__c === true;
    }

    get isPrivateBookingDisabled() {
        const isStudent = this.account?.StudentMeshit30__c === true;
        const membership = (this.transaction?.type_of_membership__c || '').trim();
        const isActive = this.transaction?.Active__c === true;
        
        // Full Club membership includes private cruises
        const isFullClub = membership.includes('חבר מועדון כולל פרטיות') || 
                          membership.includes('כולל פרטיות');

        // If the user is a student but ALSO has a Full Club membership, they CAN book private cruises
        if (isStudent && isFullClub && isActive) return false;

        // If they are just a student (or student with other membership), they are blocked
        if (isStudent) return true;

        // Standard logic for non-students
        if (isActive && isFullClub) return false;

        // If they have existing private cruises, allow them to see the page (to view/cancel)
        const hasExistingPrivateCruises = this.privateReservationArray && this.privateReservationArray.length > 0;
        if (hasExistingPrivateCruises) return false;

        return true;
    }

    get isDesktop() {
        return FORM_FACTOR === 'Large' && window.innerWidth >= 768;
    }


    get homePageBackgroundImage() {
        return this.isDesktop ? HomePageBackground : HomePageBackgroundMobile
    }

    get backgroundStyle() {
        return `
            width:100%;
            height: calc(100vh - calc(100vh - 100%)); 
            background-image:url(${this.homePageBackgroundImage}) !important;
            box-shadow: inset 0 0 0 1000px hsl(184, 78%, 38%, .4);
            background-repeat: repeat;
            position: fixed;
            top:0;
            left:0;
        `
    }

    constructor() {
        super()
        verbiage = new AppVerbiages(this)
        verbiage.loadHomePageLabels()

        service = new Service(this)
        service.loadNavigationItems()

        wrapper = new Wrapper(this)
    }

    @wire(CurrentPageReference)
    currentPageReference

    connectedCallback() {
        this.accountId = 
            this.currentPageReference?.state?.accountId || 
            sessionStorage.getItem('accountId');

        console.log('HomePage accountId context:', this.accountId);
        this.loadHomePageTabsData()
    }

    renderedCallback() {
        if (this.renderedCallbackRunOnce) return

        const loggedInData = sessionStorage.getItem('isLoggedIn')

        if (!loggedInData || !JSON.parse(loggedInData)) {
            this.navigateToLoginPage()
            return
        }

        this.isLoggedIn = true

        // OVERLAY SHOULD ALWAYS SHOW AFTER LOGIN
        this.showWelcomeOverlay = true

        // Auto hide after 20 seconds
        this.overlayTimer = setTimeout(() => {
            this.showWelcomeOverlay = false
        }, 20000)

        this.renderedCallbackRunOnce = true
    }

    disconnectedCallback() {
        if (this.overlayTimer) {
            clearTimeout(this.overlayTimer)
        }
    }

    // Data Load
    async loadHomePageTabsData() {
        try {
            this.showSpinner = true
            const result = await getHomePageTabsData({
                accountId: this.accountId
            })

            const { cruiseRecordsArray, account, transaction, pastClubCruises } = result

            this.account = JSON.parse(JSON.stringify(account))
            this.transaction = transaction
            this.cruiseRecordsArray = cruiseRecordsArray
            this.pastClubCruises = wrapper.wrapPastClubCruises(pastClubCruises)

            wrapper.wrapCruiseRecordsArray()
        } catch (error) {
            console.error('There is an error', error)
        } finally {
            this.showSpinner = false
        }
    }

    // Navigation
    navigateToLoginPage() {
        this.refs.navigation.navigateToAppPage('Home')
    }

    async handleNavigation(event, showSearch = false) {
        this.isNavigateToCertification = false
        this.navigationItem = {}
        this.initialShowSearchSection = showSearch;

        // Support both event objects and direct ID strings
        const selectedNavigationItem = event.target ? event.target.dataset.id : event

        await service.highlightSelectedTab('refresh')
        await service.highlightSelectedTab(selectedNavigationItem)
    }

    handleNavigateToDashboard() {
        this.handleNavigation('renderDashboard', false)
    }

    handleNavigateToSubscription() {
        this.handleNavigation('renderMySubscription', false)
    }

    handleNavigateToCertificates() {
        this.handleNavigation('renderJoinClubSailing', false)
        this.isNavigateToCertification = true
    }

    // Overlay Close
    handleCloseOverlay() {
        this.showWelcomeOverlay = false

        if (this.overlayTimer) {
            clearTimeout(this.overlayTimer)
        }
    }

    // Dashboard navigation
    handleDashboardBookPrivate() {
        this.handleNavigation('renderPrivateReservation', true);
    }

    handleDashboardJoinClub() {
        this.handleNavigation('renderJoinClubSailing', true);
    }

    // Cancel Private Cruise
    async cancelPrivateCruise(event) {
        const cruiseId = event.target.dataset.id;
        if (!confirm('האם אתה בטוח שברצונך לבטל הפלגה זו?')) return;
        
        try {
            this.showSpinner = true;
            await updateCruiseStatus({ cruiseId: cruiseId });
            alert('ההפלגה בוטלה בהצלחה.');
            this.handleCloseMobilePopup(); // Close popup if open
            await this.loadHomePageTabsData();
        } catch (error) {
            alert('שגיאה בביטול: ' + (error.body ? error.body.message : error.message));
        } finally {
            this.showSpinner = false;
        }
    }

    // Cancel Club Cruise (remove self)
    async cancelClubCruise(event) {
        const sailresId = event.target.dataset.id;
        if (!confirm('האם אתה בטוח שברצונך למחוק את עצמך מהפלגה זו?')) return;
        
        try {
            this.showSpinner = true;
            await cancelCoCruiseSailres({ sailresId: sailresId });
            alert('ההרשמה בוטלה בהצלחה.');
            this.handleCloseMobilePopup(); // Close popup if open
            await this.loadHomePageTabsData();
        } catch (error) {
            alert('שגיאה בביטול: ' + (error.body ? error.body.message : error.message));
        } finally {
            this.showSpinner = false;
        }
    }

    // Mobile Popup Handlers
    handleOpenMobilePopup(event) {
        const cruiseId = event.currentTarget.dataset.id;
        const type = event.currentTarget.dataset.type;
        
        if (type === 'private') {
            this.selectedCruise = this.privateReservationArray.find(c => c.id === cruiseId);
            this.isPrivateSelected = true;
        } else {
            this.selectedCruise = this.myClubCruisesDashboard.find(c => c.id === cruiseId);
            this.isPrivateSelected = false;
        }
        
        this.isMobilePopupOpen = true;
    }

    handleCloseMobilePopup() {
        this.isMobilePopupOpen = false;
        this.selectedCruise = {};
    }

    handleTabClick(event) {
        this.activeTab = event.target.dataset.tab;
    }

    handleLogout() {
        sessionStorage.clear();
        window.location.assign('https://sea-time.my.site.com/seaTimeApp/');
    }
}