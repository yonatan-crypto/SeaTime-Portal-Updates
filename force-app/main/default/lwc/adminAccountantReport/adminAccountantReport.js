import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountantMonthlyReport from '@salesforce/apex/StaffTimeTrackingController.getAccountantMonthlyReport';

const HEBREW_MONTHS = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'
];

export default class AdminAccountantReport extends LightningElement {
    @track selectedYear = new Date().getFullYear();
    @track selectedMonth = new Date().getMonth() + 1;
    @track isLoading = true;
    @track reportRows = [];
    @track selectedIds = new Set();
    @track searchTerm = '';

    connectedCallback() {
        this.loadReport();
    }

    async loadReport() {
        this.isLoading = true;
        try {
            const data = await getAccountantMonthlyReport({
                year: this.selectedYear,
                month: this.selectedMonth
            });
            this.reportRows = data || [];
            // By default, select all employees
            this.selectedIds = new Set(this.reportRows.map(r => r.employeeId));
        } catch (e) {
            console.error('Error fetching accountant report:', e);
            this.showToast('שגיאה', 'לא ניתן לטעון את נתוני הדוח: ' + (e.body ? e.body.message : e.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handlePrevMonth() {
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

    handleThisMonth() {
        const now = new Date();
        this.selectedYear = now.getFullYear();
        this.selectedMonth = now.getMonth() + 1;
        this.loadReport();
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value || '';
    }

    handleToggleEmployee(event) {
        const empId = event.target.dataset.id;
        const newSet = new Set(this.selectedIds);
        if (event.target.checked) {
            newSet.add(empId);
        } else {
            newSet.delete(empId);
        }
        this.selectedIds = newSet;
    }

    handleSelectAll() {
        const newSet = new Set(this.selectedIds);
        this.visibleRows.forEach(r => newSet.add(r.employeeId));
        this.selectedIds = newSet;
    }

    handleDeselectAll() {
        const newSet = new Set(this.selectedIds);
        this.visibleRows.forEach(r => newSet.delete(r.employeeId));
        this.selectedIds = newSet;
    }

    handleToggleSelectAll(event) {
        if (event.target.checked) {
            this.handleSelectAll();
        } else {
            this.handleDeselectAll();
        }
    }

    formatNum(n) {
        if (n === null || n === undefined) return '0';
        const num = Number(n);
        return num % 1 === 0 ? String(Math.round(num)) : String(num.toFixed(1));
    }

    get currentMonthHebrew() {
        return HEBREW_MONTHS[this.selectedMonth - 1] || '';
    }

    get employeesCount() {
        return this.reportRows.length;
    }

    get selectedCount() {
        return this.selectedIds.size;
    }

    get isExportDisabled() {
        return this.isLoading || this.selectedCount === 0;
    }

    get visibleRows() {
        if (!this.searchTerm.trim()) {
            return this.reportRows;
        }
        const term = this.searchTerm.trim().toLowerCase();
        return this.reportRows.filter(r =>
            (r.employeeName && r.employeeName.toLowerCase().includes(term)) ||
            (r.jobType && r.jobType.toLowerCase().includes(term))
        );
    }

    get hasVisibleRows() {
        return this.visibleRows && this.visibleRows.length > 0;
    }

    get isAllVisibleSelected() {
        if (!this.hasVisibleRows) return false;
        return this.visibleRows.every(r => this.selectedIds.has(r.employeeId));
    }

    get formattedRows() {
        return this.visibleRows.map((r, i) => {
            const isSelected = this.selectedIds.has(r.employeeId);
            return {
                ...r,
                index: i + 1,
                isSelected,
                rowClass: isSelected ? '' : 'unselected-row',
                jobBadgeClass: r.jobType && r.jobType.includes('מלאה') ? 'badge badge-monthly' : 'badge badge-hourly',
                bonusReasons: r.bonusReasons || '-',
                totalHours: this.formatNum(r.totalHours),
                grossPayment: this.formatNum(r.grossPayment),
                bonuses: this.formatNum(r.bonuses),
                travelPayment: this.formatNum(r.travelPayment),
                expenseReimbursement: this.formatNum(r.expenseReimbursement),
                sickDays: this.formatNum(r.sickDays),
                vacationDays: this.formatNum(r.vacationDays),
                finalPayment: this.formatNum(r.finalPayment)
            };
        });
    }

    get totals() {
        let hours = 0;
        let gross = 0;
        let travel = 0;
        let bonuses = 0;
        let expenses = 0;
        let sick = 0;
        let vacation = 0;
        let finalPayment = 0;
        let workDays = 0;

        for (const r of this.reportRows) {
            // Only sum selected employees!
            if (!this.selectedIds.has(r.employeeId)) continue;

            hours += (r.totalHours || 0);
            gross += (r.grossPayment || 0);
            travel += (r.travelPayment || 0);
            bonuses += (r.bonuses || 0);
            expenses += (r.expenseReimbursement || 0);
            sick += (r.sickDays || 0);
            vacation += (r.vacationDays || 0);
            finalPayment += (r.finalPayment || 0);
            workDays += (r.workDays || 0);
        }

        return {
            hours: this.formatNum(hours),
            gross: this.formatNum(gross),
            travel: this.formatNum(travel),
            bonuses: this.formatNum(bonuses),
            expenses: this.formatNum(expenses),
            bonusesAndExpenses: this.formatNum(bonuses + expenses),
            sick: this.formatNum(sick),
            vacation: this.formatNum(vacation),
            finalPayment: this.formatNum(finalPayment),
            workDays
        };
    }

    handleDownloadExcel() {
        if (this.selectedCount === 0) {
            this.showToast('שים לב', 'לא נבחרו מדריכים לייצוא', 'warning');
            return;
        }

        const monthName = this.currentMonthHebrew;
        const year = this.selectedYear;

        const escapeCsv = (val) => {
            if (val === null || val === undefined) return '';
            const s = String(val);
            if (s.includes(',') || s.includes('"') || s.includes('\n')) {
                return `"${s.replace(/"/g, '""')}"`;
            }
            return s;
        };

        const headers = [
            'שם עובד',
            'סוג המשרה',
            'סה״כ ימי עבודה',
            'סה״כ שעות עבודה',
            'שכר ברוטו',
            'בונוס',
            'סיבה לבונוס',
            'החזר נסיעות',
            'החזר הוצאות',
            'ימי מחלה שנוצלו בחודש',
            'ימי חופשה בחודש',
            'תשלומי הבראה',
            'סה״כ לתשלום'
        ];

        // Export ONLY selected employees!
        const exportRows = this.reportRows.filter(r => this.selectedIds.has(r.employeeId));

        const rows = exportRows.map(r => [
            escapeCsv(r.employeeName),
            escapeCsv(r.jobType),
            escapeCsv(r.workDays),
            escapeCsv(this.formatNum(r.totalHours)),
            escapeCsv(this.formatNum(r.grossPayment)),
            escapeCsv(this.formatNum(r.bonuses)),
            escapeCsv(r.bonusReasons),
            escapeCsv(this.formatNum(r.travelPayment)),
            escapeCsv(this.formatNum(r.expenseReimbursement)),
            escapeCsv(this.formatNum(r.sickDays)),
            escapeCsv(this.formatNum(r.vacationDays)),
            '0',
            escapeCsv(this.formatNum(r.finalPayment))
        ]);

        const summaryRow = [
            escapeCsv(`סה״כ (${this.selectedCount} עובדים)`),
            '',
            escapeCsv(this.totals.workDays),
            escapeCsv(this.totals.hours),
            escapeCsv(this.totals.gross),
            escapeCsv(this.totals.bonuses),
            '',
            escapeCsv(this.totals.travel),
            escapeCsv(this.totals.expenses),
            escapeCsv(this.totals.sick),
            escapeCsv(this.totals.vacation),
            '0',
            escapeCsv(this.totals.finalPayment)
        ];

        const csvLines = [
            `פירוט שכר לחודש ${monthName} לשנת ${year}`,
            '',
            headers.join(','),
            ...rows.map(row => row.join(',')),
            summaryRow.join(',')
        ];

        const csvContent = csvLines.join('\r\n');
        const filename = `דוח_שכר_למנהלת_חשבונות_${monthName}_${year}.csv`;

        this.triggerDownload(filename, csvContent);
    }

    triggerDownload(filename, csvContent) {
        try {
            // Method 1: Data URI on template anchor (most reliable in Lightning Locker)
            const link = this.template.querySelector('[data-id="downloadLink"]');
            if (link) {
                const encodedUri = 'data:text/csv;charset=utf-8,%EF%BB%BF' + encodeURIComponent(csvContent);
                link.setAttribute('href', encodedUri);
                link.setAttribute('download', filename);
                link.click();
                this.showToast('הצלחה', `קובץ הדוח (${filename}) הורד בהצלחה!`, 'success');
                return;
            }

            // Method 2: Blob fallback
            const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
            if (window.navigator && window.navigator.msSaveOrOpenBlob) {
                window.navigator.msSaveOrOpenBlob(blob, filename);
            } else {
                const a = document.createElement('a');
                a.href = URL.createObjectURL(blob);
                a.download = filename;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
            }
            this.showToast('הצלחה', `קובץ הדוח (${filename}) הורד בהצלחה!`, 'success');
        } catch (err) {
            console.error('Download error:', err);
            this.showToast('שגיאה בהורדה', err.message, 'error');
        }
    }

    showToast(title, message, variant) {
        try {
            this.dispatchEvent(new ShowToastEvent({
                title,
                message,
                variant
            }));
        } catch (e) {
            console.log(title, message);
        }
    }
}
