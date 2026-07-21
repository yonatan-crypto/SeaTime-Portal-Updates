import { LightningElement, api, wire } from 'lwc';
import getSubscriptionDetails from '@salesforce/apex/SeaTimeController.getSubscriptionDetails';
import updateCruiseStatus from '@salesforce/apex/SeaTimeController.updateCruiseStatus';
import cancelCoCruiseMember from '@salesforce/apex/SeaTimeController.cancelCoCruiseMember';
import { refreshApex } from '@salesforce/apex';
import DIR from '@salesforce/i18n/dir';

// Existing Labels
import My_Subscriptions from '@salesforce/label/c.My_Subscriptions';
import sailingDetails from '@salesforce/label/c.sailingDetails';
import date from '@salesforce/label/c.date';
import privateReservation from '@salesforce/label/c.privateReservation';
import clubCruise from '@salesforce/label/c.clubCruise';
import noCruiseAvailable from '@salesforce/label/c.noCruiseAvailable';
import recentCruises from '@salesforce/label/c.recentCruises';
import points from '@salesforce/label/c.points';
import Confirm from '@salesforce/label/c.Confirm';
import CancelLabel from '@salesforce/label/c.CancelLabel';
import wantToCancelLabel from '@salesforce/label/c.wantToCancel';

const STATUS_MAP = {
  'Approved': 'מאושר',
  'For Payment': 'לתשלום',
  'No Qualification': 'חסר הסמכה',
  'Canceled': 'מבוטל',
  'Pending': 'ממתין'
};

export default class SeaTimeSubscriptions extends LightningElement {

  labels = {
    subscriptionHeader: My_Subscriptions,
    subscriptionDetails: 'פרטי המנוי',
    totalPointsPurchased: 'סה"כ נקודות שנרכשו',
    pointsRemained: 'נקודות שנותרו',
    pointsUsed: 'נקודות שנוצלו',
    startDate: 'תאריך התחלה',
    endDate: 'תאריך סיום',
    privateOrders: privateReservation,
    guidedOrders: 'הפלגות מועדון',
    noRecordsFound: noCruiseAvailable,
    showOrderHistory: recentCruises,
    points: points,
    extraSubscriptionDetails: 'מידע נוסף למנוי',
    confirm: Confirm,
    cancelLabel: CancelLabel,
    hours: 'שעות'
  };

  @api accountId;
  @api displaySubscription = false;
  @api isClub = false;
  @api renderWire;
  @api isDesktop;

  subscriptionsData = [];
  subscriptionMore = [];
  isLoading = true;
  isPrivateOrder = true;
  showTabs = true;
  showPrivateTab = true;
  showModal = false;
  selectedBoat = { "isCertificateRequired": true };
  cruiseId;
  dir = DIR;
  wantToCancel = wantToCancelLabel;
  privateOrderPoints = 0;
  guidedOrderPoints = 0;
  isClubOrders = false;
  isCoMemberCancel = false;
  refreshsubDetails;
  isHideMore = false;

  @wire(getSubscriptionDetails, { accId: '$accountId' })
  wiredsubDeatails(result) {
    this.refreshsubDetails = result;
    if (result.data) {
        try {
            const parsedData = JSON.parse(result.data);
            this.processData(parsedData);
        } catch (e) {
            console.error('Error parsing data:', e);
            this.isLoading = false;
        }
    } else if (result.error) {
        console.error('Error in getSubscriptionDetails:', result.error);
        this.isLoading = false;
    }
  }

  processData(data) {
    try {
        const item = data;
        if (!item || (!item.id && !item.Id)) {
            this.subscriptionsData = [];
            this.isLoading = false;
            return;
        }

        const isStudent = item.StudentMeshit30__c === true;
        const transList = item.Account__r || [];
        const activeSub = transList.length > 0 ? transList[0] : null;
        const activeSubId = activeSub ? activeSub.Id : null;

        // Filter cruises and co-cruises by active subscription ID if possible and exclude Canceled status
        const cruises = (item.Cruises__r || [])
            .filter(c => (!activeSubId || c.Transaction__c === activeSubId) && c.Status__c !== 'Canceled')
            .map(c => ({
            ...c,
            startDate: this.formatDate(c.Start_Date__c),
            startTime: this.getFormattedTimeFromDateTime(c.Start_Date__c),
            endTime: this.getFormattedTimeFromDateTime(c.End_Date__c),
            boatName: c.Boat__r ? c.Boat__r.Name : '',
            StatusCss: 'status ' + this.getStatusClass(c.Status__c)
        }));

        const coCruises = (item.Co_Cruise_Sailres__r || [])
            .filter(c => (!activeSubId || c.Transaction__c === activeSubId) && c.Status__c !== 'Canceled' && (!c.Cruise__r || c.Cruise__r.Status__c !== 'Canceled'))
            .map(c => ({
            ...c,
            cruiseDate: this.formatDate(c.Date__c),
            sailTypeVal: c.Cruise__r && c.Cruise__r.RecordType ? c.Cruise__r.RecordType.Name : '',
            extraInfo: c.Cruise__r ? c.Cruise__r.Additional_Info__c : '',
            StatusCss: 'status ' + this.getStatusClass(c.Status__c)
        }));

        const subObj = {
            id: item.id || item.Id,
            name: item.name || item.Name,
            isStudent: isStudent && activeSub == null, // Only show student header if NO active sub
            showSubscriptionDetails: activeSub != null,
            subscription: activeSub ? {
                ...activeSub,
                startDate: this.formatDate(activeSub.Start_Date__c),
                endDate: this.formatDate(activeSub.End_Date__c)
            } : {},
            cruise: cruises,
            coCruiseSailres: coCruises
        };

        this.subscriptionsData = [subObj];
        this.subscriptionMore = [subObj];
        
        if (isStudent && activeSub == null) {
            this.isPrivateOrder = false;
        } else {
            this.isPrivateOrder = true;
        }

        this.privateOrderPoints = this.calculateCruisePoints(cruises);
        this.guidedOrderPoints = this.calculateCruisePoints(coCruises);
        this.isClubOrders = coCruises.length > 0;
        
    } catch (e) {
        console.error('Error processing data:', e);
    }
    this.isLoading = false;
  }

  getStatusClass(status) {
    if (status === 'Approved') return 'buttonGreen';
    if (status === 'Pending' || status === 'For Payment') return 'buttonOrrange';
    if (status === 'Canceled') return 'buttonRed';
    return 'buttonBlack';
  }

  calculateCruisePoints(cruiseList) {
    if (!cruiseList || !Array.isArray(cruiseList)) return 0;
    return cruiseList.reduce((acc, curr) => acc + (curr.Cruise_Points__c || 0), 0);
  }

  formatDate(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleDateString('he-IL', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  getFormattedTimeFromDateTime(dateTimeStr) {
    if (!dateTimeStr) return '';
    const d = new Date(dateTimeStr);
    return d.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit', hour12: false });
  }

  handleClick(event) {
    const title = event.target.title;
    if (title === this.labels.privateOrders) {
      this.isPrivateOrder = true;
    } else if (title === this.labels.guidedOrders) {
      this.isPrivateOrder = false;
    }
  }

  handleMore() {
    this.isHideMore = true;
    // Potentially load more data if needed
  }

  get displayCruiseOrder() {
    return this.isPrivateOrder;
  }

  get tabPrivateClass() {
    return this.isPrivateOrder ? 'tab-item tab-active' : 'tab-item';
  }

  get tabGuidedClass() {
    return !this.isPrivateOrder ? 'tab-item tab-active' : 'tab-item';
  }

  get mainSectionSelector() {
    return this.displaySubscription ? 'mini-view' : 'premium-section';
  }

  get mainCard() {
    return this.displaySubscription ? 'mini-card' : 'premium-card';
  }

  get displaySubsciptionData() {
    return this.subscriptionsData && this.subscriptionsData.length > 0;
  }
}