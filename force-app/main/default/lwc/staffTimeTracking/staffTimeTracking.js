import { LightningElement, api, track } from 'lwc';
import getMonthlyReport from '@salesforce/apex/StaffTimeTrackingController.getMonthlyReport';
import saveTimeEntry from '@salesforce/apex/StaffTimeTrackingController.saveTimeEntry';
import deleteTimeEntry from '@salesforce/apex/StaffTimeTrackingController.deleteTimeEntry';

const HEBREW_MONTHS = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'
];

const HEBREW_DAYS = ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'];

export default class StaffTimeTracking extends LightningElement {
    _employeeId;

    @api
    get employeeId() {
        return this._employeeId || sessionStorage.getItem('staffEmployeeId');
    }
    set employeeId(val) {
        this._employeeId = val;
        if (val) {
            sessionStorage.setItem('staffEmployeeId', val);
            this.loadReport();
        }
    }

    @track selectedYear = new Date().getFullYear();
    @track selectedMonth = new Date().getMonth() + 1; // 1-12
    @track isLoading = true;
    @track summary = {
        totalHours: 0,
        regularHours: 0,
        overtime125Hours: 0,
        overtime150Hours: 0,
        estimatedSalary: 0,
        totalTravel: 0,
        totalBonuses: 0,
        totalExpenses: 0,
        workDaysCount: 0,
        entries: [],
        employeeSettings: null
    };

    // Modals
    @track isNewEntryModalOpen = false;
    @track isEditModalOpen = false;
    @track isSubmitting = false;
    @track modalError = '';

    // New entry form fields
    @track newEntryType = 'תורנות רציף';
    @track newEntryDate = new Date().toISOString().split('T')[0];
    @track newStartTime = '09:00';
    @track newEndTime = '14:00';
    @track newAmount = '';
    @track newDescription = '';

    // Editing entry form fields
    @track editingId = null;
    @track editingDate = '';
    @track editingStartTime = '';
    @track editingEndTime = '';
    @track editingDescription = '';
    @track editingEntryDesc = '';

    connectedCallback() {
        if (!this._employeeId) {
            this._employeeId = sessionStorage.getItem('staffEmployeeId');
        }
        this.loadReport();
    }

    async loadReport() {
        if (!this.employeeId) {
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        try {
            const data = await getMonthlyReport({
                employeeId: this.employeeId,
                year: this.selectedYear,
                month: this.selectedMonth
            });
            if (data) {
                this.summary = data;
            }
        } catch (e) {
            console.error('Error loading monthly report:', e);
        } finally {
            this.isLoading = false;
        }
    }

    // Month navigation
    handlePreviousMonth() {
        if (this.selectedMonth === 1) {
            this.selectedMonth = 12;
            this.selectedYear--;
        } else {
            this.selectedMonth--;
        }
        this.loadReport();
    }

    handleNextMonth() {
        if (this.selectedMonth === 12) {
            this.selectedMonth = 1;
            this.selectedYear++;
        } else {
            this.selectedMonth++;
        }
        this.loadReport();
    }

    handleCurrentMonth() {
        const now = new Date();
        this.selectedYear = now.getFullYear();
        this.selectedMonth = now.getMonth() + 1;
        this.loadReport();
    }

    // Getters
    get currentMonthHebrew() {
        return HEBREW_MONTHS[this.selectedMonth - 1] || '';
    }

    get hasOvertime125() {
        return this.summary.overtime125Hours && this.summary.overtime125Hours > 0;
    }

    get hasOvertime150() {
        return this.summary.overtime150Hours && this.summary.overtime150Hours > 0;
    }

    get totalBonusesAndExpenses() {
        return ((this.summary.totalBonuses || 0) + (this.summary.totalExpenses || 0)).toFixed(2);
    }

    get isMonthlyEmployee() {
        return this.summary.employeeSettings && this.summary.employeeSettings.Employee_Type__c === 'חודשי';
    }

    get formattedEntriesCount() {
        return (this.summary.entries && this.summary.entries.length) || 0;
    }

    get hasEntries() {
        return this.summary.entries && this.summary.entries.length > 0;
    }

    get formattedEntries() {
        if (!this.summary.entries) return [];

        return this.summary.entries.map(entry => {
            const dateObj = new Date(entry.Work_Date__c);
            const dayOfWeek = isNaN(dateObj.getDay()) ? 0 : dateObj.getDay();
            const dayName = HEBREW_DAYS[dayOfWeek] || '';

            // Format date DD/MM/YYYY
            const parts = entry.Work_Date__c ? entry.Work_Date__c.split('-') : [];
            const formattedDate = parts.length === 3 ? `${parts[2]}/${parts[1]}/${parts[0]}` : entry.Work_Date__c;

            // Type badge class
            let badgeClass = 'badge badge-default';
            if (entry.Entry_Type__c === 'הפלגה') badgeClass = 'badge badge-cruise';
            else if (entry.Entry_Type__c === 'תורנות רציף') badgeClass = 'badge badge-dock';
            else if (entry.Entry_Type__c === 'תחזוקה') badgeClass = 'badge badge-maint';
            else if (entry.Entry_Type__c === 'קורס') badgeClass = 'badge badge-course';
            else if (entry.Entry_Type__c === 'בונוס') badgeClass = 'badge badge-bonus';
            else if (entry.Entry_Type__c === 'החזר הוצאות') badgeClass = 'badge badge-expense';
            else if (entry.Entry_Type__c === 'חו״ל / יום מלא') badgeClass = 'badge badge-abroad';

            // Source badge
            const isAuto = entry.Is_Auto_Generated__c === true;
            const isManualEdit = entry.Is_Manual_Edit__c === true;
            let sourceLabel = isAuto ? (isManualEdit ? 'מערכת (נערך)' : 'מערכת') : 'ידני';
            let sourceBadgeClass = isAuto ? 'source-badge auto' : 'source-badge manual';

            // Multiplier display
            const mult = entry.Multiplier__c || 1.0;
            let multiplierText = mult === 1.0 ? '100%' : `${(mult * 100).toFixed(0)}%`;
            let multiplierBadgeClass = mult > 1.0 ? 'badge-multiplier highlight' : 'badge-multiplier';

            const timeRange = (entry.Start_Time__c && entry.End_Time__c)
                ? `${entry.Start_Time__c} - ${entry.End_Time__c}`
                : '-';

            return {
                id: entry.Id,
                raw: entry,
                formattedDate,
                dayName,
                typeLabel: entry.Entry_Type__c,
                typeBadgeClass: badgeClass,
                description: entry.Description__c || '-',
                timeRange,
                totalHours: entry.Total_Hours__c != null ? entry.Total_Hours__c : '-',
                baseRate: entry.Base_Rate__c || 0,
                multiplierText,
                multiplierBadgeClass,
                totalPayment: entry.Total_Payment__c != null ? entry.Total_Payment__c : 0,
                sourceLabel,
                sourceBadgeClass,
                canDelete: !isAuto, // Auto-generated cruises cannot be directly deleted, but can be edited
                rowClass: dayOfWeek === 6 ? 'saturday-row' : (dayOfWeek === 5 ? 'friday-row' : '')
            };
        });
    }

    // Form helpers
    get isHoursBasedType() {
        return ['הפלגה', 'תורנות רציף', 'תחזוקה'].includes(this.newEntryType);
    }

    get isAmountBasedType() {
        return ['בונוס', 'החזר הוצאות'].includes(this.newEntryType);
    }

    // Modal Handlers
    openNewEntryModal() {
        this.modalError = '';
        this.newEntryDate = new Date().toISOString().split('T')[0];
        this.newEntryType = 'תורנות רציף';
        this.newStartTime = '09:00';
        this.newEndTime = '14:00';
        this.newAmount = '';
        this.newDescription = '';
        this.isNewEntryModalOpen = true;
    }

    closeNewEntryModal() {
        this.isNewEntryModalOpen = false;
    }

    handleNewEntryTypeChange(e) { this.newEntryType = e.target.value; }
    handleNewDateChange(e) { this.newEntryDate = e.target.value; }
    handleNewStartTimeChange(e) { this.newStartTime = e.target.value; }
    handleNewEndTimeChange(e) { this.newEndTime = e.target.value; }
    handleNewAmountChange(e) { this.newAmount = e.target.value; }
    handleNewDescriptionChange(e) { this.newDescription = e.target.value; }

    async handleSaveNewEntry() {
        this.modalError = '';
        if (!this.newEntryDate) {
            this.modalError = 'אנא בחר תאריך';
            return;
        }

        if (this.isHoursBasedType && (!this.newStartTime || !this.newEndTime)) {
            this.modalError = 'אנא הזן שעת התחלה ושעת סיום';
            return;
        }

        if (this.isAmountBasedType && (!this.newAmount || parseFloat(this.newAmount) <= 0)) {
            this.modalError = 'אנא הזן סכום תקין';
            return;
        }

        this.isSubmitting = true;
        try {
            const entry = {
                Employee__c: this.employeeId,
                Work_Date__c: this.newEntryDate,
                Entry_Type__c: this.newEntryType,
                Description__c: this.newDescription,
                Is_Auto_Generated__c: false,
                Is_Manual_Edit__c: false,
                Status__c: 'אושר'
            };

            if (this.isHoursBasedType) {
                entry.Start_Time__c = this.newStartTime;
                entry.End_Time__c = this.newEndTime;
            } else if (this.isAmountBasedType) {
                entry.Total_Payment__c = parseFloat(this.newAmount);
            }

            await saveTimeEntry({ entry });
            this.isNewEntryModalOpen = false;
            await this.loadReport();
        } catch (e) {
            console.error('Error saving entry:', e);
            this.modalError = 'שגיאה בשמירת הדיווח: ' + (e.body ? e.body.message : e.message);
        } finally {
            this.isSubmitting = false;
        }
    }

    // Edit Modal Handlers
    handleEditEntry(e) {
        const id = e.currentTarget.dataset.id;
        const entry = this.summary.entries.find(item => item.Id === id);
        if (!entry) return;

        this.modalError = '';
        this.editingId = id;
        this.editingDate = entry.Work_Date__c;
        this.editingStartTime = entry.Start_Time__c || '09:00';
        this.editingEndTime = entry.End_Time__c || '13:00';
        this.editingDescription = entry.Description__c || '';
        this.editingEntryDesc = `${entry.Entry_Type__c} - ${entry.Description__c || ''}`;
        this.isEditModalOpen = true;
    }

    closeEditModal() {
        this.isEditModalOpen = false;
    }

    handleEditDateChange(e) { this.editingDate = e.target.value; }
    handleEditStartTimeChange(e) { this.editingStartTime = e.target.value; }
    handleEditEndTimeChange(e) { this.editingEndTime = e.target.value; }
    handleEditDescriptionChange(e) { this.editingDescription = e.target.value; }

    async handleSaveEditedEntry() {
        this.modalError = '';
        if (!this.editingStartTime || !this.editingEndTime) {
            this.modalError = 'אנא הזן שעת התחלה ושעת סיום';
            return;
        }

        this.isSubmitting = true;
        try {
            const entry = {
                Id: this.editingId,
                Employee__c: this.employeeId,
                Work_Date__c: this.editingDate,
                Start_Time__c: this.editingStartTime,
                End_Time__c: this.editingEndTime,
                Description__c: this.editingDescription,
                Is_Manual_Edit__c: true
            };

            await saveTimeEntry({ entry });
            this.isEditModalOpen = false;
            await this.loadReport();
        } catch (e) {
            console.error('Error updating entry:', e);
            this.modalError = 'שגיאה בעדכון השעות: ' + (e.body ? e.body.message : e.message);
        } finally {
            this.isSubmitting = false;
        }
    }

    // Delete Handler
    async handleDeleteEntry(e) {
        const id = e.currentTarget.dataset.id;
        if (!confirm('האם אתה בטוח שברצונך למחוק דיווח זה?')) return;

        this.isLoading = true;
        try {
            await deleteTimeEntry({ entryId: id });
            await this.loadReport();
        } catch (err) {
            console.error('Error deleting entry:', err);
            alert('שגיאה במחיקת הדיווח');
            this.isLoading = false;
        }
    }
}
