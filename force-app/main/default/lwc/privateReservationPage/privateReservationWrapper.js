/**
 * @description wrapper class for this component to wrap the data. This class is not meant for any logic based calculations.
 * @author Ceptes
 * @date Saturday-July-20-2024
 **/

import Utility from 'c/seaTimeAppUtilities'
import FORM_FACTOR from '@salesforce/client/formFactor';

let main,
    utility,
    isDesktopDevice;

export default class Service {

    boatInterval
    bookedBoatsArray
    cruiseAvailableBoats = [];

    constructor(superMain) {
        main = superMain
        utility = new Utility(main)
        isDesktopDevice = FORM_FACTOR === 'Large';
    }

    wrapBoatsArray() {
        main.boatsArray = []
        console.log('wrapBoatsArray' + main.boatsArrayRaw);
        main.boatsArrayRaw.forEach(boat => {
            let boatAvail;
            const Boat_Availability_Raw = boat.Boat_Availability__r;
            const Boat_Records_Raw = boat.Boat__r;
            const Certified_Records_Raw = boat.Certified_boat__r;

            const Boat_Availability_List = this.getRecords(Boat_Availability_Raw);
            const cruise = this.getRecords(Boat_Records_Raw);
            const Certified_List = this.getRecords(Certified_Records_Raw);

            if (Boat_Availability_List.length === 0) {
                boatAvail = [{
                    "Boat__c": boat.Id,
                    "Id": "",
                    "Duration__c": 8,
                    "Start_Time__c": 32400000,
                    "End_Time__c": 61200000
                }];
            } else {
                boatAvail = Boat_Availability_List;
            }

            if (cruise.length && !this.cruiseAvailableBoats.includes(cruise[0].Boat__c)) { 
                this.cruiseAvailableBoats.push(cruise[0].Boat__c); 
            }

            const boatAvailability = boatAvail[0];
            const { Duration__c } = boatAvailability
            console.log('boatAvailability' + JSON.stringify(boatAvailability));
            console.log('Duration__c' + JSON.stringify(Duration__c));
            if (!Duration__c) { return }
            const wrappedBoat = this.getWrappedBoat(boat)
            console.log('wrappedBoat' + wrappedBoat);
            this.populateDefaultBoatImage(wrappedBoat)
            this.checkIfCertificateRequired(wrappedBoat, Certified_List)
            this.populateBoatIdToPriceLineMap(boat)
            this.populateBoatIterval(Duration__c);
            this.populateListOfBoats(wrappedBoat, boatAvailability, cruise)
            this.sortBoatsArray()

        })
        //this.filterLeftOverHours()

    }

    sortBoatsArray() {
        console.log('sortBoatsArray');
        main.boatsArray = main.boatsArray.sort((a, b) => b.startTime > a.startTime ? -1 : 1);
        console.log('sortBoatsArray' + JSON.stringify(main.boatsArray));
    }


    populateListOfBoats(boat, boatAvailability, cruise) {
        console.log('populateListOfBoats1: ' + JSON.stringify(boat));
        console.log('populateListOfBoats2: ' + JSON.stringify(boatAvailability));
        console.log('populateListOfBoats2: ' + JSON.stringify(cruise));
        const { Start_Time__c, End_Time__c } = boatAvailability;
        const boatLastTIme = utility.getFormattedTime(End_Time__c);
        console.log('boatLastTIme: ' + boatLastTIme);

        const removeSecondLast = boatLastTIme.split(':')[0] - (main.boatDuration + 1);
        console.log('removeSecondLast: ' + removeSecondLast);
        let boatStartTime = utility.getFormattedTime(Start_Time__c);
        boatStartTime = parseInt(boatStartTime.split(':')[0]) + 1
        console.log('boatStartTime: ' + boatStartTime);
        let boatTime = boatAvailability.Duration__c - (main.boatDuration - 1);
        let boatDuration = boatAvailability.Duration__c;
        let leftHours = main.boatDuration + 1;
        console.log('boatTime: ' + boatTime);
        console.log('leftHours: ' + leftHours);
        boatTime = Math.ceil(boatTime);
        console.log('boatTime1: ' + boatTime);
        for (let i = 0; i < boatTime; ++i) {
            const startTime = utility.getNextBoatStartTime(i, Start_Time__c);
            console.log('startTime: ' + startTime);
            let startTimeHour = startTime.split(':')[0];
            const endTime = utility.getNextEndTime(startTime)
            const userDT = utility.getcurrentDateTimebyTimezone();
            console.log('endTime: ' + endTime);
            console.log('userDT: ' + userDT);
            const [datePart, isrTime] = userDT.split(', ');
            const [day, month, year] = datePart.split('/');
            const currentISRDate = `${year}-${month}-${day}`;
            console.log('currentISRDate: ' + currentISRDate);
            // boat optimization logic to display - relaxed to allow 3h bookings within exact gaps
            let isBoatBooked = false;
            /* 
            // Commenting out the rigid hardcoded 1-hour blockers for specific loop indexes
            if (!cruise.length && leftHours < boatDuration && (i == 1 || i == (boatTime - 2))) {
                continue;
            } else if (cruise.length && leftHours < boatDuration && (startTimeHour == boatStartTime || (startTimeHour == removeSecondLast && main.boatsArray.length > 2))) {
                continue;
            }
            */
            //Displaying boats based on user time zone 
            if (currentISRDate == main.searchData.date) {
                if (isrTime > startTime) {
                    continue;
                }
            }
            console.log('currentISRDate1: ' + currentISRDate);
            // checking boat availability for the time
            if (cruise && cruise.length) {
                isBoatBooked = this.filterApprovedBoats(startTime, cruise, boatLastTIme);
            }
            console.log('isBoatBooked: ' + isBoatBooked);
            if (isBoatBooked) { continue };

            this.bookedBoatsArray = this.getSelectedDateBookedBoatsArray(boat);
            console.log('bookedBoatsArray: ' + JSON.stringify(this.bookedBoatsArray));
            const isBoatAlreadyBooked = false;// this.isBoatAlreadyBooked(startTime, endTime)


            if (isBoatAlreadyBooked || endTime > boatLastTIme) { continue }
            const existingBoatData = this.getExistingBoatData(startTime);
            console.log('existingBoatData: ' + JSON.stringify(existingBoatData));

            const threshold = isDesktopDevice ? 4 : 1;
            const priority = { 'מפרשית': 1, 'יאכטה': 2, 'קטמרן': 3 };
            
            if (existingBoatData) {
                existingBoatData.listOfBoats.push(boat);
                // Sort boats by type priority
                existingBoatData.listOfBoats.sort((a, b) => (priority[a.type] || 99) - (priority[b.type] || 99));
                existingBoatData.hasManyBoats = existingBoatData.listOfBoats.length > threshold;
            } else {
                main.boatsArray.push({
                    startTime,
                    endTime,
                    listOfBoats: [boat],
                    hasManyBoats: false
                })
            }
        }
        console.log('existingBoatData11: ' + JSON.stringify(main.boatsArray));
        this.handleCruiseHalfHourTimings(boat, boatLastTIme, cruise);
        console.log('populateListOfBoats end');
    }

    handleCruiseHalfHourTimings(boat, boatLastTIme, cruise) {
        const userDT = utility.getcurrentDateTimebyTimezone();
        const [datePart, isrTime] = userDT.split(', ');
        const [day, month, year] = datePart.split('/');
        const currentISRDate = `${year}-${month}-${day}`;
        
        for (let i = 0; i < cruise.length; ++i) {
            let cruiseEnd = new Date(cruise[i].End_Date__c);
            let searchDate = new Date(`${main.searchData.date}T00:00:00`);
            
            if (cruiseEnd.getFullYear() === searchDate.getFullYear() &&
                cruiseEnd.getMonth() === searchDate.getMonth() &&
                cruiseEnd.getDate() === searchDate.getDate()) {
                
                let minutes = cruiseEnd.getMinutes();
                if (minutes > 0) {
                    let h = cruiseEnd.getHours();
                    let startTime = (h < 10 ? '0' : '') + h + ':' + (minutes < 10 ? '0' : '') + minutes;
                    let endTime = utility.getNextEndTime(startTime);
                    
                    if (currentISRDate == main.searchData.date) {
                        if (isrTime > startTime) continue;
                    }
                    
                    let isBoatAlreadyBooked = false;
                    if (cruise && cruise.length) {
                        isBoatAlreadyBooked = this.filterApprovedBoats(startTime, cruise, boatLastTIme);
                    }
                    
                    if (isBoatAlreadyBooked || (endTime > boatLastTIme)) continue;
                    
                    main.boatsArray.push({
                        startTime,
                        endTime,
                        listOfBoats: [boat]
                    });
                }
            }
        }
    }


    filterApprovedBoats(startTime, cruise, boatLastTIme) {
        let lastHr = parseInt(boatLastTIme.split(':')[0]);
        let startTimeHour = parseInt(startTime.split(':')[0]);
        let cruiseFound = false;

        let proposedStartLocalStr = `${main.searchData.date}T${startTime}:00`;
        let proposedStart = new Date(proposedStartLocalStr);
        let proposedEnd = new Date(proposedStart.getTime() + (main.boatDuration * 60 * 60 * 1000));

        cruise.forEach(ele => {
            let cruiseStart = new Date(ele.Start_Date__c);
            let cruiseEnd = new Date(ele.End_Date__c);

            if (proposedStart < cruiseEnd && proposedEnd > cruiseStart) {
                cruiseFound = true;
                return;
            }

            let searchDate = new Date(`${main.searchData.date}T00:00:00`);
            if (cruiseEnd.getFullYear() === searchDate.getFullYear() &&
                cruiseEnd.getMonth() === searchDate.getMonth() &&
                cruiseEnd.getDate() === searchDate.getDate()) {
                
                let cruiseEndLocalHour = cruiseEnd.getHours();
                if (((lastHr - main.boatDuration) != cruiseEndLocalHour + 1) && (startTimeHour == cruiseEndLocalHour + 1)) {
                    cruiseFound = true;
                    return;
                }
            }
        });
        
        return cruiseFound;
    }
    getExistingBoatData(startTime) {
        console.log('getExistingBoatData: ');
        return main.boatsArray.find(existingBoat => existingBoat.startTime == startTime)
    }

    isBoatAlreadyBooked(startTime, endTime) {
        console.log('isBoatAlreadyBookedggggg: ');
        return this.bookedBoatsArray.some(({ formattedStartTime }) => formattedStartTime >= startTime && formattedStartTime <= endTime)
    }

    getSelectedDateBookedBoatsArray(boat) {
        console.log('getSelectedDateBookedBoatsArrayyyy: ');
        return main.privateReservationArray.filter(({ boatId, formattedStartDate }) => boatId == boat.id && formattedStartDate == main.searchData.date)
    }

    getRecords(obj) {
        if (!obj) return [];
        if (Array.isArray(obj)) return obj;
        if (obj.records && Array.isArray(obj.records)) return obj.records;
        return [];
    }

    populateBoatIdToPriceLineMap({ Id, PriceListLines__r }) {
        //PriceListLines__r = undefined;
        console.log('PriceListLines__r' + JSON.stringify(PriceListLines__r));
        const priceListLines = this.getRecords(PriceListLines__r);
        if (priceListLines.length === 0) { return }
        const uniquePriceList = this.filterDuplicatePriceListForStartTime(priceListLines);
        const wrappedPriceLine = this.getWrappedPriceLine(uniquePriceList)
        console.log('wrappedPriceLine' + JSON.stringify(wrappedPriceLine));
        main.boatIdToPriceLines[Id] = wrappedPriceLine
    }

    getWrappedPriceLine(priceListLines) {
        console.log('getWrappedPriceLineeee: ');
        return priceListLines.map(priceLine => {
            return {
                startTime: utility.getFormattedTime(priceLine.Start__c),
                price: this.getPriceBasedOnDay(priceLine)//priceLine.Price__c
            }
        })
    }
    filterDuplicatePriceListForStartTime(priceListLines) {
        console.log('filterDuplicatePriceListForStartTime: ');
        const seen = new Set();
        return priceListLines.filter(item => {
            if (!seen.has(item.Start__c)) {
                seen.add(item.Start__c);
                return true;
            } else {
                return false;
            }
        });
    }
    getPriceBasedOnDay(priceLine) {
        console.log('getPriceBasedOnDay');
        let indexDay = utility.getDayIndexFromDate(main.searchData.date);
        console.log('indexDay' + JSON.stringify(indexDay));
        let price = main.boatWeekendIndices.length && main.boatWeekendIndices.includes(indexDay) ? priceLine.HPrice__c : priceLine.Price__c
        console.log('price' + JSON.stringify(price));
        return price;
    }
    populateBoatIterval(duration) {
        console.log('populateBoatIterval' + duration);
        if (main.searchData.boatDuration && main.searchData.boatDuration.startsWith("3")) {
            main.boatDuration = 3
            this.boatInterval = Math.floor(+duration / 3)
            console.log('populateBoatIterval1: ' + this.boatInterval);
        } else if (main.searchData.boatDuration && main.searchData.boatDuration.startsWith("2")) {
            main.boatDuration = 2
            this.boatInterval = Math.floor(+duration / 2)
            console.log('populateBoatIterval2: ' + this.boatInterval);
        }
    }

    getWrappedBoat(boat) {
        const typeMapping = {
            'Yacht': 'יאכטה',
            'Catamaran': 'קטמרן',
            'Sailboat': 'מפרשית'
        };
        return {
            id: boat.Id,
            name: boat.Name,
            type: typeMapping[boat.Type__c] || boat.Type__c
        }
    }

    checkIfCertificateRequired(boat, certificatesArray) {
        console.log('checkIfCertificateRequired: ');
        //it it is true boat does not require certificates
        if (!certificatesArray || !certificatesArray.length) {
            boat.isCertificateRequired = true
            boat.boatSelector = 'boat-tile disable-boat'
            return
        }
        //if boat has certificates but the assigned account does not have 
        const accountWithCertificates = certificatesArray?.find(({ Account_Name__c }) => Account_Name__c == main.accountId)
        console.log('accountWithCertificates: ' + JSON.stringify(accountWithCertificates));
        if (!accountWithCertificates) {
            boat.isCertificateRequired = true
            boat.boatSelector = 'boat-tile disable-boat'
        } else {
            boat.boatSelector = 'boat-tile'
        }
    }

    populateDefaultBoatImage(boat) {

        const boatType = boat.type
        let defaultBoatImage

        switch (boatType) {
            case 'Yacht':
                defaultBoatImage = main.defaultBoatImages + '/Yacht.jpeg'
                break
            case 'Catamaran':
                defaultBoatImage = main.defaultBoatImages + '/Catamaran.jpeg'
                break
            case 'Sailboat':
                defaultBoatImage = main.defaultBoatImages + '/Sailboat.jpeg'
                break
        }
        boat.boatImage = defaultBoatImage
        console.log('populateDefaultBoatImage: ' + JSON.stringify(boat));
    }
}