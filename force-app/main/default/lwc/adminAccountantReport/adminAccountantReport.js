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

    formatNum(n) {
        if (n === null || n === undefined) return '0';
        const num = Number(n);
        return num % 1 === 0 ? String(Math.round(num)) : String(num.toFixed(1));
    }

    get formattedRows() {
        return this.reportRows.map((r, i) => {
            return {
                ...r,
                index: i + 1,
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
