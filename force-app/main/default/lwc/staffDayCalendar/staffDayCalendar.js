import { LightningElement, track } from 'lwc';
import getDailyCruises from '@salesforce/apex/StaffPortalController.getDailyCruises';
import getActiveBoats from '@salesforce/apex/StaffPortalController.getActiveBoats';

const HEBREW_DAYS = ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'];
const HEBREW_MONTHS = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];

const TYPE_COLORS = {
    'Club': 'type-club', 'Course': 'type-course',
    'General': 'type-general', 'Friends': 'type-friends', 'Enriching': 'type-enriching',
    'Renting': 'type-renting', 'Certification': 'type-certification',
    'Introduction': 'type-intro', 'Maintenance': 'type-maintenance',
    'Abroad': 'type-general', 'Draft': 'type-default', 'Renewal': 'type-default'
};

const RECORD_TYPE_HEBREW_MAP = {
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

export default class StaffDayCalendar extends LightningElement {
    @track selectedDate;
    @track boats = [];
    @track cruises = [];
    @track isLoading = false;
    @track selectedBoatId = 'all';
    hours = [];

    constructor() {
        super();
        this.selectedDate = new Date();
        // Build hours from 6:00 to 20:00
        for (let h = 6; h <= 20; h++) {
            this.hours.push(h);
        }
    }

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            // Format date as YYYY-MM-DD for Apex Date parameter
            const y = this.selectedDate.getFullYear();
            const m = String(this.selectedDate.getMonth() + 1).padStart(2, '0');
            const d = String(this.selectedDate.getDate()).padStart(2, '0');
            const dateStr = `${y}-${m}-${d}`;

            const [boatsResult, cruisesResult] = await Promise.all([
                getActiveBoats(),
                getDailyCruises({ selectedDate: dateStr })
            ]);
            this.boats = boatsResult || [];
            this.cruises = (cruisesResult || []).map(c => this._enrichCruise(c));
        } catch (e) {
            console.error('Error loading data:', e);
        } finally {
            this.isLoading = false;
        }
    }

    _enrichCruise(c) {
        // Extract hours from Start_Date__c and End_Date__c (DateTime fields)
        const startDt = c.Start_Date__c ? new Date(c.Start_Date__c) : null;
        const endDt = c.End_Date__c ? new Date(c.End_Date__c) : null;
        const startHour = startDt ? startDt.getHours() : 0;
        const startMin = startDt ? startDt.getMinutes() : 0;
        const endHour = endDt ? endDt.getHours() : startHour + 1;
        const endMin = endDt ? endDt.getMinutes() : 0;
        const durationHours = endDt && startDt ? (endDt - startDt) / (1000 * 60 * 60) : 1;

        const startTimeStr = `${String(startHour).padStart(2, '0')}:${String(startMin).padStart(2, '0')}`;
        const endTimeStr = `${String(endHour).padStart(2, '0')}:${String(endMin).padStart(2, '0')}`;

        // Determine type and color
        const recTypeName = c.RecordType ? c.RecordType.DeveloperName : 'default';
        const typeColorClass = TYPE_COLORS[recTypeName] || 'type-default';
        const typeDisplayName = c.RecordType 
            ? (RECORD_TYPE_HEBREW_MAP[c.RecordType.DeveloperName] || RECORD_TYPE_HEBREW_MAP[c.RecordType.Name] || c.RecordType.Name) 
            : '';

        // Guide info
        const guideName = c.Guide__r ? c.Guide__r.Name : '';
        const guidePhone = c.Employee_Phone__c || '';

        // Customer info
        const customerName = c.CUSTOMER_NAME__c || (c.AccountName__r ? c.AccountName__r.Name : '');
        const customerPhone = c.CUSTOMER_PHONE__c || '';

        return {
            Id: c.Id,
            Name: c.Name,
            boatId: c.Boat__c,
            boatName: c.Boat__r ? c.Boat__r.Name : '',
            startHour,
            startMin,
            endHour,
            durationHours: Math.max(0.5, durationHours),
            startTime: startTimeStr,
            endTime: endTimeStr,
            timeRange: `${endTimeStr} - ${startTimeStr}`,
            typeName: typeDisplayName,
            typeClass: `cruise-block ${typeColorClass}`,
            guideName,
            guidePhone,
            customerName,
            customerPhone,
            additionalInfo: c.Additional_Info__c || '',
            status: c.Status__c,
            courseType: c.Course_Type__c || '',
            telLink: guidePhone ? `tel:${guidePhone}` : ''
        };
    }

    get formattedDate() {
        const d = this.selectedDate;
        const dayName = HEBREW_DAYS[d.getDay()];
        const monthName = HEBREW_MONTHS[d.getMonth()];
        return `${dayName}, ${String(d.getDate()).padStart(2, '0')} ב${monthName}' ${d.getFullYear()}`;
    }

    get dateInputValue() {
        const y = this.selectedDate.getFullYear();
        const m = String(this.selectedDate.getMonth() + 1).padStart(2, '0');
        const d = String(this.selectedDate.getDate()).padStart(2, '0');
        return `${y}-${m}-${d}`;
    }

    handlePreviousDay() {
        const d = new Date(this.selectedDate);
        d.setDate(d.getDate() - 1);
        this.selectedDate = d;
        this.loadData();
    }

    handleNextDay() {
        const d = new Date(this.selectedDate);
        d.setDate(d.getDate() + 1);
        this.selectedDate = d;
        this.loadData();
    }

    handleToday() {
        this.selectedDate = new Date();
        this.loadData();
    }

    handleDateChange(e) {
        if (e.target.value) {
            const parts = e.target.value.split('-');
            this.selectedDate = new Date(parts[0], parts[1] - 1, parts[2]);
            this.loadData();
        }
    }

    handleBoatFilter(event) {
        this.selectedBoatId = event.target.value;
    }

    handleGoToCruises() {
        this.dispatchEvent(new CustomEvent('navigate', {
            detail: 'cruises',
            bubbles: true,
            composed: true
        }));
    }

    get boatOptions() {
        return [
            { label: 'כל הסירות', value: 'all' },
            ...this.boats.map(b => ({ label: b.Name, value: b.Id }))
        ];
    }

    get filteredBoats() {
        if (this.selectedBoatId === 'all') return this.boats;
        return this.boats.filter(b => b.Id === this.selectedBoatId);
    }

    get calendarGrid() {
        const grid = [];
        const boats = this.filteredBoats;
        const hourHeight = 50; // pixels per hour

        for (let i = 0; i < this.hours.length; i++) {
            const hour = this.hours[i];
            const rowBoats = [];

            for (let j = 0; j < boats.length; j++) {
                const boat = boats[j];
                // Find cruises that START in this hour for this boat
                const startingCruises = this.cruises.filter(c => {
                    return c.boatId === boat.Id && c.startHour === hour;
                });

                rowBoats.push({
                    boatId: boat.Id,
                    key: `${hour}-${boat.Id}`,
                    hasCruises: startingCruises.length > 0,
                    cruises: startingCruises.map(c => {
                        const blockHeight = Math.round(c.durationHours * hourHeight);
                        const topOffset = Math.round((c.startMin / 60) * hourHeight);
                        return {
                            ...c,
                            blockStyle: `height: ${blockHeight}px; top: ${topOffset}px;`
                        };
                    })
                });
            }

            grid.push({
                hour: String(hour).padStart(2, '0') + ':00',
                hourKey: `hour-${hour}`,
                boats: rowBoats
            });
        }
        return grid;
    }

    get hasBoats() {
        return this.filteredBoats.length > 0;
    }
}
