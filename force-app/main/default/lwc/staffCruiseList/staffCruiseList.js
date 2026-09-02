import { LightningElement, api, track } from 'lwc';
import getGuideCruises from '@salesforce/apex/StaffPortalController.getGuideCruises';
import getCruiseParticipants from '@salesforce/apex/StaffPortalController.getCruiseParticipants';

const HEBREW_DAYS = ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'];

const RECORD_TYPE_MAP = {
    'Enriching': 'מודרכת',
    'Course': 'קורס',
    'Renting': 'השכרה',
    'Certification': 'הסמכה',
    'General': 'כללי',
    'Club': 'מועדון',
    'Friends': 'חברים',
    'Abroad': 'חו״ל',
    'Maintenance': 'תחזוקה',
    'Introduction': 'היכרות',
    'Renewal': 'חידוש',
    'Draft': 'טיוטה'
};

function formatHebrewCruiseType(recordType) {
    if (!recordType) return '';
    const key = recordType.DeveloperName || recordType.Name || '';
    return RECORD_TYPE_MAP[key] || RECORD_TYPE_MAP[recordType.Name] || recordType.Name || '';
}

export default class StaffCruiseList extends LightningElement {
    _employeeId;
    @track cruises = [];
    @track isLoading = false;
    @track errorMsg = '';

    @api 
    get employeeId() {
        return this._employeeId;
    }
    set employeeId(value) {
        this._employeeId = value;
        if (value) {
            this.loadCruises();
        }
    }

    connectedCallback() {
        if (!this._employeeId) {
            try {
                const savedId = sessionStorage.getItem('staffEmployeeId');
                if (savedId) {
                    this._employeeId = savedId;
                }
            } catch (e) {
                console.warn('Could not read sessionStorage', e);
            }
        }
        if (this._employeeId) {
            this.loadCruises();
        }
    }

    async loadCruises() {
        if (!this._employeeId) {
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        this.errorMsg = '';
        try {
            const data = await getGuideCruises({ employeeId: this._employeeId });
            
            // Filter out any canceled and sort strictly ascending by Start_Date__c (closest first)
            const validCruises = (data || []).filter(c => c.Status__c !== 'Canceled');
            validCruises.sort((a, b) => {
                const tA = a.Start_Date__c ? new Date(a.Start_Date__c).getTime() : 0;
                const tB = b.Start_Date__c ? new Date(b.Start_Date__c).getTime() : 0;
                return tA - tB;
            });

            this.cruises = validCruises.map((c, idx) => {
                const startDt = c.Start_Date__c ? new Date(c.Start_Date__c) : null;
                const endDt = c.End_Date__c ? new Date(c.End_Date__c) : null;

                const dayName = startDt ? HEBREW_DAYS[startDt.getDay()] : '';
                const dateStr = startDt 
                    ? `${String(startDt.getDate()).padStart(2, '0')}/${String(startDt.getMonth() + 1).padStart(2, '0')}/${startDt.getFullYear()}` 
                    : '';
                const startTime = startDt 
                    ? `${String(startDt.getHours()).padStart(2, '0')}:${String(startDt.getMinutes()).padStart(2, '0')}` 
                    : '';
                const endTime = endDt 
                    ? `${String(endDt.getHours()).padStart(2, '0')}:${String(endDt.getMinutes()).padStart(2, '0')}` 
                    : '';

                const boatName = (c.Boat__r && c.Boat__r.Name) ? c.Boat__r.Name : '';
                const typeName = formatHebrewCruiseType(c.RecordType);

                return {
                    Id: c.Id,
                    Name: c.Name,
                    index: idx,
                    dayName,
                    dateStr,
                    startTime,
                    endTime,
                    boatName,
                    typeName,
                    additionalInfo: c.Additional_Info__c || '',
                    customerName: c.CUSTOMER_NAME__c || '',
                    customerPhone: c.CUSTOMER_PHONE__c || '',
                    status: c.Status__c,
                    expanded: false,
                    participants: [],
                    participantsLoaded: false,
                    hasParticipants: false,
                    hasAdditionalInfo: !!c.Additional_Info__c,
                    expandIcon: '▼'
                };
            });
        } catch (e) {
            console.error('Error loading cruises:', e);
            this.errorMsg = 'שגיאה בטעינת ההפלגות.';
        } finally {
            this.isLoading = false;
        }
    }

    async handleToggleCruise(event) {
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        if (isNaN(idx) || idx < 0 || idx >= this.cruises.length) {
            return;
        }

        const updated = [...this.cruises];
        const cruise = { ...updated[idx] };
        cruise.expanded = !cruise.expanded;
        cruise.expandIcon = cruise.expanded ? '▲' : '▼';

        if (cruise.expanded && !cruise.participantsLoaded) {
            try {
                const parts = await getCruiseParticipants({ cruiseId: cruise.Id });
                cruise.participants = (parts || []).map(p => ({
                    Id: p.Id,
                    participantName: (p.Account_Co__r && p.Account_Co__r.Name) ? p.Account_Co__r.Name : 'לא ידוע',
                    participantPhone: p.Phone__c || '',
                    telLink: p.Phone__c ? `tel:${p.Phone__c}` : '',
                    hasPhone: !!p.Phone__c
                }));
                cruise.participantsLoaded = true;
                cruise.hasParticipants = cruise.participants.length > 0;
            } catch (e) {
                console.error('Error loading participants:', e);
                cruise.participants = [];
                cruise.participantsLoaded = true;
                cruise.hasParticipants = false;
            }
        }

        updated[idx] = cruise;
        this.cruises = updated;
    }

    handlePhoneClick(event) {
        if (event) {
            event.stopPropagation();
        }
    }

    handleGoToCalendar() {
        this.dispatchEvent(new CustomEvent('navigate', {
            detail: 'calendar',
            bubbles: true,
            composed: true
        }));
    }

    get hasCruises() {
        return !this.isLoading && this.cruises.length > 0;
    }

    get noCruises() {
        return !this.isLoading && this.cruises.length === 0 && !this.errorMsg;
    }
}
