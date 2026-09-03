import { LightningElement, track } from 'lwc';
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
        } catch (e) {
            console.error('Error fetching accountant report:', e);
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

    get currentMonthHebrew() {
        return HEBREW_MONTHS[this.selectedMonth - 1] || '';
    }

    get employeesCount() {
        return this.reportRows.length;
    }

    get hasRows() {
        return this.reportRows && this.reportRows.length > 0;
    }

    get formattedRows() {
        return this.reportRows.map((r, i) => {
            return {
                ...r,
                index: i + 1,
                jobBadgeClass: r.jobType && r.jobType.includes('מלאה') ? 'badge badge-monthly' : 'badge badge-hourly',
                bonusReasons: r.bonusReasons || '-'
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
            hours: hours.toFixed(2),
            gross: gross.toFixed(2),
            travel: travel.toFixed(2),
            bonuses: bonuses.toFixed(2),
            expenses: expenses.toFixed(2),
            bonusesAndExpenses: (bonuses + expenses).toFixed(2),
            sick: sick.toFixed(1),
            vacation: vacation.toFixed(1),
            finalPayment: finalPayment.toFixed(2),
            workDays
        };
    }

    handleDownloadExcel() {
        if (!this.hasRows) {
            alert('אין נתונים להורדה לחודש זה');
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

        const rows = this.reportRows.map(r => [
            escapeCsv(r.employeeName),
            escapeCsv(r.jobType),
            escapeCsv(r.workDays),
            escapeCsv(r.totalHours),
            escapeCsv(r.grossPayment),
            escapeCsv(r.bonuses),
            escapeCsv(r.bonusReasons),
            escapeCsv(r.travelPayment),
            escapeCsv(r.expenseReimbursement),
            escapeCsv(r.sickDays),
            escapeCsv(r.vacationDays),
            '0',
            escapeCsv(r.finalPayment)
        ]);

        const summaryRow = [
            escapeCsv('סה״כ כללי'),
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
        // Add UTF-8 BOM so Excel opens Hebrew without garbled characters
        const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.setAttribute('download', `דוח_שכר_למנהלת_חשבונות_${monthName}_${year}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }
}
