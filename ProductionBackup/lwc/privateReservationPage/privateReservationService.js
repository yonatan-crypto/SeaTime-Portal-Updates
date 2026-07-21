/**
 * @description Service class for this component with all the business logic.
 * @author Ceptes
 * @date Friday-July-19-2024
 **/

import Utility from 'c/seaTimeAppUtilities'
import invalidDateVerbiage from '@salesforce/label/c.invalidDateVerbiage'
import { loadStyle } from 'lightning/platformResourceLoader';
import RemoveDateFormatStyling from '@salesforce/resourceUrl/RemoveDateFormatStyle';


let main,
    utility

export default class Service {

    constructor(superMain) {
        main = superMain
        utility = new Utility(main)
        this.hideDate();
    }

   
hideDate(){
      Promise.all([
            loadStyle(this, RemoveDateFormatStyling)
        ]).then(() => {
        }).catch(error => {
            window.console.log("Error " + error.body.message);
        });
}
    updateSearchButtonsArray(buttonsArray, label) {
        
        for (const button of buttonsArray) {

            if (button.label == label) {
                button.selector = 'slds-button slds-button_brand dark-button search-button'
            } else {
                button.selector = 'slds-button slds-button_brand light-button search-button'
            }
        }
    }

    updateDaysArray(dataId, fieldName) {
        for (const day of main.daysArray) {
            if (day[fieldName] == dataId) {
                day.selector = 'day-button selected-day-button'
            } else {
                day.selector = 'day-button'
            }
        }
    }

    updateSearchDateWithOneWeek(isAddDay) {
        const currentDate = main.searchData.date
        const currentDateTime = utility.getDateTimeFromDate(currentDate)
        if (isAddDay) {
            currentDateTime.setDate(currentDateTime.getDate() + 7)
        } else {
            currentDateTime.setDate(currentDateTime.getDate() - 7)
        }
        main.searchData.date = utility.getDateFromDateTime(currentDateTime)
        this.validateSelectedDate(main.searchData.date)
    }

    validateSelectedDate(selectedDate) {
        const today = utility.getTodaysDate()
        if (selectedDate < today) {
            main.showInvalidDateVerbiage = true
            main.invalidDateVerbiage = invalidDateVerbiage;
        } else {
            main.showInvalidDateVerbiage = false
            main.searchData.date = selectedDate
            if(main.searchData.boatTypes.length == 0){
                main.showInvalidDateVerbiage = true;
                main.invalidDateVerbiage = main.boatTypeRequired;
            }
        }
        main.daysArray = utility.updateSelectedDayArray(selectedDate,main.daysArray);
    }

    updateTheDateOnDaySelect(dayIndex) {
        const { date } = main.searchData
        const firsDayOfTheWeek = utility.getFirstDayOfTheWeek(date)
        const adjustedDateTime = utility.addDaysToDate(firsDayOfTheWeek, dayIndex)
        main.searchData.date = utility.getDateFromDateTime(adjustedDateTime)  
    }

    populateSelectedBoat(dataset) {
        console.log('populateSelectedBoat'+JSON.stringify(dataset));
        const { boatId, name, startTime, endTime, boatType, isdisable } = dataset
        const { date } = main.searchData

        console.log('searchData'+JSON.stringify(main.searchData));
        const startDate = new Date(`${main.searchData.date}T${startTime}:00.000Z`);
        const endDate = new Date(`${main.searchData.date}T${endTime}:00.000Z`);
        console.log('startDate======',startDate.toISOString(),endDate.toISOString());
        let indexDay = utility.getDayIndexFromDate(main.searchData.date);
        let isHoliday =  main.boatWeekendIndices.length && main.boatWeekendIndices.includes(indexDay);
      
        const price = this.getBoatPrice(boatId, startTime, endTime)
         //price = price ? price:und
         console.log('price'+JSON.stringify(price));
         return {
            boatId,
            date,
            name,
            boatType,
            startTime,
            endTime,
            price,
            isdisable,
            accountId: main.accountId
        }
    }

    getPriceForDate(boatPriceLines, date) {
        console.log('inside boatPriceLines',boatPriceLines,' date=> ',date, typeof date);
         console.log('inside boatPriceLines222222',boatPriceLines[0]);
       // const hour = new Date(date);
       //   console.log('inside hour',hour);
        //let priceLine  = boatPriceLines.filter(interval => hour >= new Date(`${main.searchData.date}T${interval.startTime}:00.000Z`)).reverse().pop(); 
       const priceLine = boatPriceLines.filter(item => item.startTime < date.toString());
       console.log('priceLinej0'+JSON.stringify(priceLine));
        //let priceLine = this.findClosestObject(boatPriceLines,date);
        console.log('priceLine1'+JSON.stringify(priceLine));
        return priceLine[0]  ? priceLine[0].price : 0;
    }

findClosestObject(arr, target){
    const targetValue = Number(target);
    // Try to find the exact match
    const exactMatch = arr.find(item => item.Start__c === targetValue);
    if (exactMatch) return exactMatch;

    // If no exact match, find the nearest match
    return arr.reduce((closest, item) => {
        return Math.abs(item.Start__c - targetValue) < Math.abs(closest.Start__c - targetValue)
            ? item
            : closest;
    }); 
};
    getBoatPrice(boatId, startTime, endTime) {
        console.log('entered getBoatPrice==@ ',startTime);
        let boatStartTime = parseInt(startTime);
        console.log('main'+JSON.stringify(main.boatIdToPriceLines));
        const boatPriceLines = main.boatIdToPriceLines[boatId]
        if(!boatPriceLines){
            return 0;
        }
        
        console.log('boatPriceLines'+JSON.stringify(boatPriceLines));
        //const selectedPriceLine = boatPriceLines.find(priceLine => startTime > priceLine.startTime)
        const start = new Date(`${main.searchData.date}T${startTime}:00.000Z`);
        const end = new Date(`${main.searchData.date}T${endTime}:00.000Z`);
        console.log('start'+JSON.stringify(start));
        console.log('end'+JSON.stringify(end));
        let totalPrice = 0;
        let currentTime = new Date(start);
        console.log('currentTime'+JSON.stringify(currentTime));
        while (currentTime < end) {
        const nextHour = new Date(currentTime);
        nextHour.setUTCHours(currentTime.getUTCHours() + 1, 0, 0, 0);
        const overlapStart = Math.max(currentTime, start);
        console.log('overlapStart'+JSON.stringify(overlapStart));
        const overlapEnd = Math.min(nextHour, end);
        console.log('overlapEnd'+JSON.stringify(overlapEnd));
        if (overlapStart < overlapEnd) {
            const durationMinutes = (overlapEnd - overlapStart) / (1000 * 60);
            const pricePerHour = this.getPriceForDate(boatPriceLines, boatStartTime);
            boatStartTime = boatStartTime +1;
            console.log('boatStartTime==>',boatStartTime);
            console.log('pricePerHour'+JSON.stringify(pricePerHour));
            const pricePerMinute = pricePerHour / 60;
            totalPrice += pricePerMinute * durationMinutes;
            console.log('totalPrice'+JSON.stringify(totalPrice));
        }
        currentTime = nextHour;
        console.log('currentTime'+JSON.stringify(currentTime));
    }

    return  totalPrice ? totalPrice.toFixed(2) : 0;
        //return selectedPriceLine?.price
    }

    // Function to calculate the total price for a reservation
     calculateReservationPrice(startTime, durationHours) {
    // Convert start time to hour (24-hour format)
    const startHour = parseInt(startTime.split(':')[0]);
    let totalPrice = 0;

    for (let i = 0; i < durationHours; i++) {
        const currentHour = startHour + i;
        const currentTime = `${currentHour < 10 ? '0' : ''}${currentHour}:00`;
        
        if (prices[currentTime]) {
            totalPrice += prices[currentTime];
        } else {
            console.log(`No price available for ${currentTime}`);
            return null;
        }
    }

    return totalPrice;
}

formatDate(dateString) {
 const date = new Date(dateString);
    const day = date.getDate().toString().padStart(2, '0');
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const year = date.getFullYear();
    return `${day}.${month}.${year}`;
    }


    updateSelectedTypeButtonSelector(target) {

        const selectorArray = target.classList
        const selectedButtonName = target.dataset.id

        if (selectorArray.contains('dark-button')) {
            selectorArray.add('light-button')
            selectorArray.remove('dark-button')
            main.searchData.boatTypes = main.searchData.boatTypes.filter(boatType => boatType != selectedButtonName)
        } else {
            selectorArray.add('dark-button')
            selectorArray.remove('light-button')
            main.searchData.boatTypes.push(selectedButtonName)
        }
    }
}