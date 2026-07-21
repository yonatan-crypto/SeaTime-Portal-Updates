/**
 * @description wrapper class for this component to wrap the data. This class is not meant for any logic based calculations.
 * @author Ceptes
 * @date Saturday-July-20-2024
 **/

import Utility from 'c/seaTimeAppUtilities'

let main,
    utility

export default class Service {

    boatInterval
    bookedBoatsArray
    cruiseAvailableBoats = [];

    constructor(superMain) {
        main = superMain
        utility = new Utility(main)
    }

    wrapBoatsArray() {
        main.boatsArray = []
        console.log('wrapBoatsArray'+main.boatsArrayRaw);
        main.boatsArrayRaw.forEach(boat => {
            let boatAvail;
            const { Id, Certified_boat__r, Boat_Availability__r,Boat__r} = boat
            
            if (!Boat_Availability__r) { 
                boatAvail= [{
                        "Boat__c": boat.Id,
                        "Id": "",
                        "Duration__c": 8,
                        "Start_Time__c": 32400000,
                        "End_Time__c": 61200000
                        }];
            }
            const cruise = Boat__r ? Boat__r:[];
            if(cruise.length && !this.cruiseAvailableBoats.includes(Boat__r[0].Boat__c)){ this.cruiseAvailableBoats.push(Boat__r[0].Boat__c); }
            
            const [boatAvailability] = Boat_Availability__r ? Boat_Availability__r : boatAvail;
            const { Duration__c } = boatAvailability
            console.log('boatAvailability'+JSON.stringify(boatAvailability));
            console.log('Duration__c'+JSON.stringify(Duration__c));
            if (!Duration__c) { return }
            const wrappedBoat = this.getWrappedBoat(boat)
            console.log('wrappedBoat'+wrappedBoat);
            this.populateDefaultBoatImage(wrappedBoat)
            this.checkIfCertificateRequired(wrappedBoat, Certified_boat__r)
            this.populateBoatIdToPriceLineMap(boat)
            this.populateBoatIterval(Duration__c);
            this.populateListOfBoats(wrappedBoat, boatAvailability,cruise)
            this.sortBoatsArray()
           
        })     
        //this.filterLeftOverHours()
        
    }

    sortBoatsArray() {
        console.log('sortBoatsArray');
        main.boatsArray = main.boatsArray.sort((a, b) => b.startTime > a.startTime ? -1 : 1);
        console.log('sortBoatsArray'+JSON.stringify(main.boatsArray));
    }

  
populateListOfBoats(boat, boatAvailability,cruise) {
    console.log('populateListOfBoats1: '+JSON.stringify(boat));
    console.log('populateListOfBoats2: '+JSON.stringify(boatAvailability));
    console.log('populateListOfBoats2: '+JSON.stringify(cruise));
        const { Start_Time__c, End_Time__c } = boatAvailability;
        const boatLastTIme = utility.getFormattedTime(End_Time__c);
        console.log('boatLastTIme: '+boatLastTIme);
   
        const removeSecondLast = boatLastTIme.split(':')[0] - (main.boatDuration + 1);
        console.log('removeSecondLast: '+removeSecondLast);
        let boatStartTime = utility.getFormattedTime(Start_Time__c);
        boatStartTime = parseInt(boatStartTime.split(':')[0]) + 1
         console.log('boatStartTime: '+boatStartTime);
        let boatTime = boatAvailability.Duration__c -  (main.boatDuration -1);
        let boatDuration = boatAvailability.Duration__c;
        let leftHours = main.boatDuration +1;
        console.log('boatTime: '+boatTime);
        console.log('leftHours: '+leftHours);
        boatTime = Math.ceil(boatTime);
        console.log('boatTime1: '+boatTime);
        for (let i = 0; i < boatTime; ++i) {
            const startTime = utility.getNextBoatStartTime(i,Start_Time__c);
            console.log('startTime: '+startTime);
            let startTimeHour = startTime.split(':')[0];
            const endTime = utility.getNextEndTime(startTime)
            const userDT = utility.getcurrentDateTimebyTimezone();
            console.log('endTime: '+endTime);
            console.log('userDT: '+userDT);
            const [datePart, isrTime] = userDT.split(', ');
            const [day, month, year] = datePart.split('/');
            const currentISRDate= `${year}-${month}-${day}`; 
            console.log('currentISRDate: '+currentISRDate);
            //boat optimization logic to display
            let isBoatBooked = false;
            if(!cruise.length && leftHours < boatDuration && (i == 1 || i == (boatTime -2))){
                continue;
            }else if(cruise.length && leftHours < boatDuration && (startTimeHour == boatStartTime ||  (startTimeHour == removeSecondLast && main.boatsArray.length > 2))){

                continue;
            }               
           //Displaying boats based on user time zone 
            if(currentISRDate == main.searchData.date){
                if(isrTime > startTime){
                       continue;
                }
            }
            console.log('currentISRDate1: '+currentISRDate);
            // checking boat availability for the time
            if(cruise && cruise.length){
                isBoatBooked =  this.filterApprovedBoats(startTime,cruise,boatLastTIme);
            }
            console.log('isBoatBooked: '+isBoatBooked);
            if(isBoatBooked){ continue };
            
            this.bookedBoatsArray = this.getSelectedDateBookedBoatsArray(boat);
            console.log('bookedBoatsArray: '+JSON.stringify(this.bookedBoatsArray));
            const isBoatAlreadyBooked = false;// this.isBoatAlreadyBooked(startTime, endTime)

         
            if (isBoatAlreadyBooked || endTime > boatLastTIme) { continue }
            const existingBoatData = this.getExistingBoatData(startTime);
            console.log('existingBoatData: '+JSON.stringify(existingBoatData));

            if (existingBoatData) {
                existingBoatData.listOfBoats.push(boat)
            } else {
                main.boatsArray.push({
                    startTime,
                    endTime,
                    listOfBoats: [boat]
                })
            }
        }
        console.log('existingBoatData11: '+JSON.stringify(main.boatsArray));
        this.handleCruiseHalfHourTimings(boat, boatLastTIme,cruise);
        console.log('populateListOfBoats end');
    }

    handleCruiseHalfHourTimings(boat, boatLastTIme,cruise){
        console.log('handleCruiseHalfHourTimings: ');
        const userDT = utility.getcurrentDateTimebyTimezone();
        const [datePart, isrTime] = userDT.split(', ');
        const [day, month, year] = datePart.split('/');
        const currentISRDate= `${year}-${month}-${day}`; 
       console.log('currentISRDate: '+currentISRDate);
    for (let i = 0; i < cruise.length; ++i) {
        let endDate = utility.formatDateTime(cruise[i].End_Date__c);
        console.log('endDate: '+endDate);
        const date = new Date(endDate);
        let minutes = date.getUTCMinutes();
        let startTime = date.getUTCHours() + ':' + minutes;
        let endTime = utility.getNextEndTime(startTime);
        console.log('endTime33333: '+endTime);
        //Displaying boats based on user time zone 
       if(currentISRDate == main.searchData.date){
        if(isrTime > startTime){
            continue;
        }
    }
        let isBoatAlreadyBooked; //= this.isBoatAlreadyBooked(startTime, endTime);
        if(cruise && cruise.length){
            isBoatAlreadyBooked =  this.filterApprovedBoats(startTime,cruise,boatLastTIme);
            
        }
        console.log('isBoatAlreadyBookeddddd: '+isBoatAlreadyBooked);
        if (isBoatAlreadyBooked || (endTime > boatLastTIme)) { continue }
        //&& ['Awaiting for Approval','Approved'].includes(cruise[i].Status__c)
        if(minutes > 0 ){
            main.boatsArray.push({
                startTime,
                endTime,
                listOfBoats: [boat]
            });
        }
    }
console.log('handleCruiseHalfHourTimings endd: ');
}


filterApprovedBoats(startTime,cruise,boatLastTIme){
console.log('filterApprovedBoats start: ');
        let lastHr = boatLastTIme.split(':')[0]; 
        let startTimeHour = startTime.split(':')[0];
        let cruiseFound = false;
        let boatStartTime = `${main.searchData.date}T${startTime}:00.000Z`;
        console.log('boatStartTime: '+boatStartTime);
        let order = cruise.sort((a, b) => b.Start_Date__c > a.Start_Date__c ? -1 : 1)
        console.log('order: '+JSON.stringify(order));
        order.forEach(ele=>{
            console.log('forEach start: ');
            let startDate = utility.formatDateTime(ele.Start_Date__c);
            console.log('startDate: '+startDate);
            let endDate = utility.formatDateTime(ele.End_Date__c);
            console.log('endDate: '+endDate);
            const formattedStartDate = new Date(startDate);
            console.log('formattedStartDate: '+formattedStartDate);
            formattedStartDate.setHours(formattedStartDate.getHours() - (main.boatDuration));
            console.log('formattedStartDate1111: '+formattedStartDate);
            if(formattedStartDate.toISOString() < boatStartTime && endDate > boatStartTime){
                cruiseFound = true;
                console.log('iffffff6666: '+cruiseFound);
                return;
            }
            let endTime = endDate.split('T')[1].split(':')[0];
            console.log('endTime: '+endTime);
            if(((parseInt(lastHr) - main.boatDuration) != parseInt(endTime)+1)  && (startTimeHour == parseInt(endTime)+1)){
                cruiseFound = true;
                console.log('iffffff: '+cruiseFound);
                return;
            }
           
        });
        console.log('order: '+JSON.stringify(order));
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

    populateBoatIdToPriceLineMap({ Id, PriceListLines__r }) {
        //PriceListLines__r = undefined;
        console.log('PriceListLines__r'+JSON.stringify(PriceListLines__r));
        if (!PriceListLines__r || !PriceListLines__r.length) { return }
        const uniquePriceList = this.filterDuplicatePriceListForStartTime(PriceListLines__r);
        const wrappedPriceLine = this.getWrappedPriceLine(uniquePriceList)
        console.log('wrappedPriceLine'+JSON.stringify(wrappedPriceLine));
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
    filterDuplicatePriceListForStartTime(priceListLines){
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
getPriceBasedOnDay(priceLine){
    console.log('getPriceBasedOnDay');
    let indexDay = utility.getDayIndexFromDate(main.searchData.date);
    console.log('indexDay'+JSON.stringify(indexDay));
    let price =  main.boatWeekendIndices.length && main.boatWeekendIndices.includes(indexDay) ? priceLine.HPrice__c : priceLine.Price__c
    console.log('price'+JSON.stringify(price));
    return price;
}
    populateBoatIterval(duration) {
        console.log('populateBoatIterval'+duration);
        if (main.searchData.boatDuration && main.searchData.boatDuration.startsWith("3")) {
            main.boatDuration = 3
            this.boatInterval = Math.floor(+duration / 3)
            console.log('populateBoatIterval1: '+this.boatInterval);
        } else if (main.searchData.boatDuration && main.searchData.boatDuration.startsWith("2")) {
            main.boatDuration = 2
            this.boatInterval = Math.floor(+duration / 2)
            console.log('populateBoatIterval2: '+this.boatInterval);
        }
    }

    getWrappedBoat(boat) {
        return {
            id: boat.Id,
            name: boat.Name,
            type: boat.Type__c
        }
    }

    checkIfCertificateRequired(boat, certificatesArray) {
        console.log('checkIfCertificateRequired: ');
        //it it is true boat does not require certificates
        if (!certificatesArray || !certificatesArray.length) {
            boat.isCertificateRequired = true
            boat.boatImgSelector = 'disable-boat'
            return
        }
        //if boat has certificates but the assigned account does not have 
        const accountWithCertificates = certificatesArray?.find(({ Account_Name__c }) => Account_Name__c == main.accountId)
        console.log('accountWithCertificates: '+JSON.stringify(accountWithCertificates));
        if (!accountWithCertificates) {
            boat.isCertificateRequired = true
            boat.boatImgSelector = 'disable-boat'
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
        console.log('populateDefaultBoatImage: '+JSON.stringify(boat));
    }
}