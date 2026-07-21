/**
 * @description Service class for home page
 * @author Ceptes
 * @date Saturday-July-06-2024
 **/

let main

export default class Service {

    constructor(superMain) {
        main = superMain
    }

    loadNavigationItems() {
        main.navigationItemsArray = [{
            key: 'dashboard',
            dataId: 'renderDashboard',
            selector: 'selected-nav-item',
            label: 'דף הבית' 
        }, {
            key: 'charters',
            dataId: 'renderCharters',
            label: main.chartersLabel
        }, {
            key: 'mySubscription',
            dataId: 'renderMySubscription',
            label: main.mySubscriptionLabel
        }, {
            key: 'privateReservation',
            dataId: 'renderPrivateReservation',
            label: main.privateReservationLabel
        }, {
            key: 'joinClub',
            dataId: 'renderJoinClubSailing',
            label: main.joinClubSailingLabel
        }]
    }

    highlightSelectedTab(selectedNavigationItem) {
        main.navigationItem[selectedNavigationItem] = true

        for (const navItem of main.navigationItemsArray) {
            delete navItem.selector

            if (navItem.dataId == selectedNavigationItem) {
                navItem.selector = 'selected-nav-item'
            }
        }
    }
}