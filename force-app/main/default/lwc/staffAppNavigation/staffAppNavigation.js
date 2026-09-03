import { LightningElement, api } from 'lwc';

export default class StaffAppNavigation extends LightningElement {
    @api currentPage;
    @api employeeName;
    @api employeeType;

    get isClubMember() {
        return this.employeeType === 'חבר מועדון';
    }

    get isCalendarActive() {
        return this.currentPage === 'calendar';
    }

    get isCruisesActive() {
        return this.currentPage === 'cruises';
    }

    get isTimeTrackingActive() {
        return this.currentPage === 'timeTracking';
    }

    get calendarClass() {
        return this.isCalendarActive ? 'nav-item active' : 'nav-item';
    }

    get cruisesClass() {
        return this.isCruisesActive ? 'nav-item active' : 'nav-item';
    }

    get timeTrackingClass() {
        return this.isTimeTrackingActive ? 'nav-item active' : 'nav-item';
    }

    handleNavigate(e) {
        const page = e.currentTarget.dataset.page;
        this.dispatchEvent(new CustomEvent('navigate', { detail: page }));
    }

    handleLogout() {
        this.dispatchEvent(new CustomEvent('logout'));
    }
}
