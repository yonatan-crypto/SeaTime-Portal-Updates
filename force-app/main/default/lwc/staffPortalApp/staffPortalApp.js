import { LightningElement, track } from 'lwc';
import getEmployeeDetails from '@salesforce/apex/StaffPortalController.getEmployeeDetails';

export default class StaffPortalApp extends LightningElement {
    @track state = 'login'; // login, app
    @track currentPage = 'cruises'; // Default to 'cruises' as requested!
    employeeId;
    employeeName;
    @track employeeType;

    async connectedCallback() {
        try {
            const savedId = sessionStorage.getItem('staffEmployeeId');
            const savedName = sessionStorage.getItem('staffEmployeeName');
            const savedType = sessionStorage.getItem('staffEmployeeType');
            const savedPage = sessionStorage.getItem('staffCurrentPage');
            if (savedId) {
                this.employeeId = savedId;
                this.employeeName = savedName || '';
                this.employeeType = savedType || '';
                this.state = 'app';
                this.currentPage = savedPage || 'cruises';

                // Always fetch fresh employee details
                this.loadEmployeeDetails();
            }
        } catch (e) {
            console.warn('Could not read sessionStorage', e);
        }
    }

    async loadEmployeeDetails() {
        if (!this.employeeId) return;
        try {
            const emp = await getEmployeeDetails({ employeeId: this.employeeId });
            if (emp) {
                this.employeeType = emp.Employee_Type__c;
                sessionStorage.setItem('staffEmployeeType', this.employeeType || '');
                if (this.isClubMember && this.currentPage === 'timeTracking') {
                    this.currentPage = 'cruises';
                    sessionStorage.setItem('staffCurrentPage', 'cruises');
                }
            }
        } catch (e) {
            console.warn('Could not load employee details', e);
        }
    }

    get isLoginState() {
        return this.state === 'login';
    }

    get isAppState() {
        return this.state === 'app';
    }

    get isClubMember() {
        return this.employeeType === 'חבר מועדון';
    }

    get showCalendar() {
        return this.currentPage === 'calendar';
    }

    get showCruises() {
        return this.currentPage === 'cruises';
    }

    get showTimeTracking() {
        return this.currentPage === 'timeTracking' && !this.isClubMember;
    }

    handleAuthenticated(event) {
        this.employeeId = event.detail.employeeId;
        this.employeeName = event.detail.employeeName;
        this.employeeType = event.detail.employeeType;
        this.currentPage = 'cruises'; // Default on login is always 'cruises'
        try {
            sessionStorage.setItem('staffEmployeeId', this.employeeId);
            sessionStorage.setItem('staffEmployeeName', this.employeeName || '');
            sessionStorage.setItem('staffEmployeeType', this.employeeType || '');
            sessionStorage.setItem('staffCurrentPage', 'cruises');
        } catch (e) {
            console.warn('Could not save to sessionStorage', e);
        }
        this.state = 'app';

        if (!this.employeeType) {
            this.loadEmployeeDetails();
        }
    }

    handleNavigate(event) {
        if (this.isClubMember && event.detail === 'timeTracking') {
            this.currentPage = 'cruises';
        } else {
            this.currentPage = event.detail;
        }
        try {
            sessionStorage.setItem('staffCurrentPage', this.currentPage);
        } catch (e) {
            console.warn('Could not save to sessionStorage', e);
        }
    }

    handleLogout() {
        this.employeeId = null;
        this.employeeName = null;
        this.employeeType = null;
        this.currentPage = 'cruises';
        try {
            sessionStorage.removeItem('staffEmployeeId');
            sessionStorage.removeItem('staffEmployeeName');
            sessionStorage.removeItem('staffEmployeeType');
            sessionStorage.removeItem('staffCurrentPage');
        } catch (e) {
            console.warn('Could not remove from sessionStorage', e);
        }
        this.state = 'login';
    }
}
