/**
 * @description
 * @author Ceptes
 * @date Tuesday-July-09-2024
 **/

import Utility from 'c/seaTimeAppUtilities'

let main, utility

const CLUB_CRUSIES_RECORD_TYPES = ['Enriching', 'Friends', 'Certification', 'Course']

const STATUS_MAP = {
    'Awaiting for Approval': 'ממתין לאישור',
    'Approved': 'מאושר',
    'Canceled': 'בוטל',
    'No Qualification': 'חסרה הסמכה בתוקף',
    'For Payment': 'לתשלום'
};

export default class Wrapper {

    constructor(superMain) {
        main = superMain
        utility = new Utility()
    }

    wrapCruiseRecordsArray() {

        main.privateReservationArray.length = 0
        main.clubCruisesArray.length = 0
        for (const cruise of main.cruiseRecordsArray) {

            if (!cruise.Boat__r || cruise.Status__c == 'Canceled') { continue }

            const recordName = cruise.RecordType.Name
            const wrappedCruiseData = this.getWrappedCruiseData(cruise)
         
            if (wrappedCruiseData.accountId == main.accountId ) {
                     main.privateReservationArray.push(wrappedCruiseData)
            } if (CLUB_CRUSIES_RECORD_TYPES.includes(recordName)) {
                main.clubCruisesArray.push(wrappedCruiseData)
            }
        }

        main.clubCruisesArray = [...main.clubCruisesArray]
    }

    wrapPastClubCruises(pastCruises) {
        if (!pastCruises) return [];
        return pastCruises.map(pc => {
            const startDate = pc.Cruise__r?.Start_Date__c;
            const endDate = pc.Cruise__r?.End_Date__c;
            
            let displayDate = '';
            let displayTime = '';
            
            if (startDate) {
                const [fDate, fStartTime] = this.getFormattedTimeFromDateTime(startDate);
                displayDate = this.getFormattedDateToDisplay(fDate);
                
                if (endDate) {
                    const [, fEndTime] = this.getFormattedTimeFromDateTime(endDate);
                    displayTime = `${fStartTime}-${fEndTime}`;
                } else {
                    displayTime = fStartTime;
                }
            }

            return {
                Id: pc.Id,
                displayDate: displayDate,
                displayTime: displayTime,
                boatName: pc.Cruise__r?.Boat__r?.Name || '',
                SailType__c: pc.SailType__c || '',
                additionalInfo: pc.Cruise__r?.Additional_Info__c || '',
                status: pc.Status__c
            };
        });
    }

    getWrappedCruiseData(cruise) {
        const isalreadyBooked = cruise?.Co_Cruise_Sailres__r !=null &&  cruise.Co_Cruise_Sailres__r.length ? true : false;
        const [startDate, startTime] = this.getFormattedTimeFromDateTime(cruise.Start_Date__c)
        const [endDate, endTime] = this.getFormattedTimeFromDateTime(cruise.End_Date__c)
        const startDateToDisplay = this.getFormattedDateToDisplay(startDate)
        const isDisableBooking = cruise.RemaingSeatsInBoat__c <= 0 || isalreadyBooked

        // NEW: parse the special saildate__c (date) and cruise_time_formula__c (time string)
        const customDisplayDate = cruise.saildate__c ? this.getFormattedDateToDisplay(cruise.saildate__c) : startDateToDisplay;
        const customDisplayTime = cruise.cruise_time_formula__c || startTime;

        // Calculate if cancelable (using 48 hours for private, 24 for club)
        const cruiseDate = new Date(cruise.Start_Date__c);
        const now = new Date();
        const diffHours = (cruiseDate - now) / (1000 * 60 * 60);
        const canCancelPrivate = diffHours > 48;
        const canCancelClub = diffHours > 24;

        return {
            id: cruise.Id,
            accountId: cruise.AccountName__c,
            recordTypeName: cruise.RecordType.Name,
            boatId: cruise.Boat__r?.Id,
            boatName: cruise.Boat__r?.Name,
            boatType: cruise.Boat__r?.Type__c,
            startDate: cruise.Start_Date__c,
            endTime: cruise.End_Date__c,
            formattedStartTime: startTime,
            formattedEndime: endTime,
            formattedStartDate: startDate,
            formattedEndDate: endDate,
            startDateToDisplay,
            customDisplayDate: customDisplayDate,
            customDisplayTime: customDisplayTime,
            status: STATUS_MAP[cruise.Status__c] || cruise.Status__c, // Translated status
            remainingSlots: cruise.RemaingSeatsInBoat__c,
            additionalInfo: cruise.Additional_Info__c,
            guideName: cruise.Skipper__r?.Name,
            courseType: cruise.Course_Type__c,
            isPrivateCourse: cruise.IsPrivateCourse__c,
            coCruiseRecords: cruise.Co_Cruise_Sailres__r,
            isDisableBooking,
            isalreadyBooked,
            transaction: cruise.Transaction__r,
            addtionalInfo: cruise.Additional_Info__c,
            bookingButtonLabel: this.getBookingButtonLabel(isDisableBooking,isalreadyBooked),
            duration: this.getFormattedDuration(cruise),
            canCancelPrivate: canCancelPrivate,
            canCancelClub: canCancelClub,
            typeOfEnriching: cruise.type_of_enriching__c
        }
    }

    getBookingButtonLabel(isDisableBooking,isBooked) {
        return isDisableBooking ? isBooked ? main.alreadyBooked : main.fullyBooked : main.booking
    }

    getFormattedTimeFromDateTime(dateTime) {
        
        const currentDate = new Date(dateTime)
        
        const localDate = currentDate.toLocaleString('he-IL', { timeZone: 'asia/jerusalem' })
        
        const [date, time] = localDate.split(',')
        const dateValue = date.split('.').reverse().join('-')
        //Commented to handle the Daylight Saving transitions
        //const formattedDate = utility.getFormattedDate(dateValue)
        const formattedDate = dateValue;
        
        const timesArray = time.split(':')
        const formattedTime = `${timesArray[0]}:${timesArray[1]}`

        return [formattedDate.trim(), formattedTime.trim()]
    }

    getFormattedDateToDisplay(date) {
        return date.split('-').reverse().join('.')
    }

    getFormattedDuration({ Duration_HHMM__c }) {

        const durationArray = Duration_HHMM__c.split(':')
        const [hour, minute] = durationArray
        const hr = hour % 100;
        return `${hr} ${main.hour}`
    }
}