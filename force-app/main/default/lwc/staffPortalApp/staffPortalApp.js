import { LightningElement, track } from 'lwc';

export default class StaffPortalApp extends LightningElement {
    @track state = 'login'; // login, app
    @track currentPage = 'cruises'; // Default to 'cruises' as requested!
    employeeId;
    employeeName;

    connectedCallback() {
        try {
            const savedId = sessionStorage.getItem('staffEmployeeId');
            const savedName = sessionStorage.getItem('staffEmployeeName');
            const savedPage = sessionStorage.getItem('staffCurrentPage');
            if (savedId) {
                this.employeeId = savedId;
                this.employeeName = savedName || '';
                this.state = 'app';
                this.currentPage = savedPage || 'cruises';
            }
        } catch (e) {
            console.warn('Could not read sessionStorage', e);
        }
    }

    get isLoginState() {
        return this.state === 'login';
    }

    get isAppState() {
        return this.state === 'app';
    }

    get showCalendar() {
        return this.currentPage === 'calendar';
    }

    get showCruises() {
        return this.currentPage === 'cruises';
    }

    handleAuthenticated(event) {
        this.employeeId = event.detail.employeeId;
        this.employeeName = event.detail.employeeName;
        this.currentPage = 'cruises'; // Default on login is always 'cruises'
        try {
            sessionStorage.setItem('staffEmployeeId', this.employeeId);
            sessionStorage.setItem('staffEmployeeName', this.employeeName || '');
            sessionStorage.setItem('staffCurrentPage', 'cruises');
        } catch (e) {
            console.warn('Could not save to sessionStorage', e);
        }
        this.state = 'app';
    }

    handleNavigate(event) {
        this.currentPage = event.detail;
        try {
            sessionStorage.setItem('staffCurrentPage', this.currentPage);
        } catch (e) {
            console.warn('Could not save to sessionStorage', e);
        }
    }

    handleLogout() {
        this.employeeId = null;
        this.employeeName = null;
        this.currentPage = 'cruises';
        try {
            sessionStorage.removeItem('staffEmployeeId');
            sessionStorage.removeItem('staffEmployeeName');
            sessionStorage.removeItem('staffCurrentPage');
        } catch (e) {
            console.warn('Could not remove from sessionStorage', e);
        }
        this.state = 'login';
    }
}
