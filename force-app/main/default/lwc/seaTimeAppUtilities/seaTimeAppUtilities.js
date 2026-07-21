/**
 * @description Java-Script utility class.
 * @author Ceptes
 * @date Friday-July-19-2024
 **/

let main
const MILLISECONDS_IN_HOUR = 3.6e+6

export default class Utility {

    constructor(superMain) {
        main = superMain
    }

    getTodaysDate() {
        return new Date().toISOString().slice(0, 10)
    }

    getDateFromDateTime(dateTime) {
        return new Date(dateTime).toISOString().slice(0, 10)
    }

    getDayIndexFromDate(date) {
        return new Date(date).getDay()
    }

    getDateTimeFromDate(date) {
        return new Date(date)
    }

    getFirstDayOfTheWeek(date) {
        date = new Date(date)
        const day = date.getDay(),
            diff = date.getDate() - day // adjust when day is monday
        return new Date(date.setDate(diff));
    }

    addDaysToDate(date, days) {
        date = new Date(date)
        date.setDate(date.getDate() + +days)
        return date
    }

    getNextStartTime(index, startTime) {
        const nextTime = index == 0 ? startTime : startTime + (MILLISECONDS_IN_HOUR * (main.boatDuration + 1) * index)

        return this.getFormattedTime(nextTime)
    }

    getNextBoatStartTime(index, startTime) {

        const date = new Date(startTime);
             let hours = date.getUTCHours();
            let minutes = date.getUTCMinutes();
            // If minutes are not zero, round up to the  hour
            if (minutes > 0 && index !=0 ) {
                // Round to the start of the next hour
                startTime = (Math.floor(startTime / MILLISECONDS_IN_HOUR)) * MILLISECONDS_IN_HOUR;
            } 

        const nextTime = index == 0 ? startTime : startTime + (MILLISECONDS_IN_HOUR * (1) * index)

        return this.getFormattedTime(nextTime)
    }

    getNextEndTime(startTime) {

        const starTimeArray = startTime.split(':')

        let [hour, minute] = starTimeArray

        hour = +hour + (main.boatDuration)

        return `${hour}:${minute}`
    }


    getFormattedTime(time) {
        let ms = time % 1000
        time = (time - ms) / 1000
        let secs = time % 60
        time = (time - secs) / 60
        let mins = time % 60;
        let hrs = (time - mins) / 60
        hrs = hrs < 10 ? '0' + hrs : hrs
        mins = mins < 10 ? '0' + mins : mins
        return hrs + ':' + mins
    }

    getFormattedDate(date) {
        date = date.replaceAll("-", "/");
        // Get the current date/time in UTC
        const currentDate = new Date(date)

        // Adjust for the user's time zone
        currentDate.setMinutes(
            new Date().getMinutes() - new Date().getTimezoneOffset()
        );

        // Return the date in "YYYY-MM-DD" format
        const yyyyMmDd = currentDate?.toISOString()?.slice(0, 10)
        return yyyyMmDd
    }

    getcurrentDateTimebyTimezone(){
        const now = new Date();
        // Format the date and time for the "Asia/Jerusalem" time zone
        const options = {
            timeZone: 'Asia/Jerusalem',//'Asia/Jerusalem'
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false
        };
    
        const israelTime = new Intl.DateTimeFormat('en-IL', options).format(now);
        return israelTime;
        }

    formatDateTime(date) {
        console.log('formatDateTime:'+date);
    // Manually parse the date and time components from the string
    let [datePart, timePart] = date.split('T');
    let [year, month, day] = datePart.split('-');
    
    
    // Convert to MM/DD/YYYY format required by Safari
    //let dateWithSlashes = `${month}/${day}/${year}`;
    let dateWithSlashes = `${year}-${month}-${day}`;
    console.log('dateWithSlashes:'+dateWithSlashes);
    console.log(`${dateWithSlashes} ${timePart}`);
    // Create a Date object using the date string in MM/DD/YYYY format
    let dateObj = new Date(date);
    console.log('dateObj:'+dateObj);

    // Format the date in the specified timezone using toLocaleString
    let options = {
        timeZone: "Asia/Jerusalem",
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
    };
    console.log('options:'+options);
    // Validate the date object
    if (isNaN(dateObj.getTime())) {
        throw new RangeError('Invalid time value');
    }

    let formatter = new Intl.DateTimeFormat('en-US', options);
    console.log('formatter:'+formatter);
    let parts = formatter.formatToParts(dateObj);
    console.log('parts:'+parts);

    // Extract year, month, day, hour, minute, and second from formatted parts
    let yearFormatted = parts.find(p => p.type === 'year').value;
    let monthFormatted = parts.find(p => p.type === 'month').value;
    let dayFormatted = parts.find(p => p.type === 'day').value;
    let hourFormatted = parts.find(p => p.type === 'hour').value;
    let minuteFormatted = parts.find(p => p.type === 'minute').value;
    let secondFormatted = parts.find(p => p.type === 'second').value;
    console.log('formatted:'+`${yearFormatted}-${monthFormatted}-${dayFormatted}T${hourFormatted}:${minuteFormatted}:${secondFormatted}.000Z`);
    // Construct ISO 8601 format string
    return `${yearFormatted}-${monthFormatted}-${dayFormatted}T${hourFormatted}:${minuteFormatted}:${secondFormatted}.000Z`;

    }

 // Function to round up to the  hour
   roundUpToNextHour(timeStr) {
      let [hrs, mins] = timeStr.split(':').map(Number);
  
      if (mins === 0) {
          // If minutes are already 0, no need to round up
          return timeStr;
      }
  
      // Calculate the next hour
      let nextHour = (hrs + 1) % 24;
      
      // Format hours with leading zeros if needed
      nextHour = nextHour < 10 ? '0' + nextHour : nextHour;
      
      // Format minutes as '00'
      let nextMinute = '00';
  
      return nextHour + ':' + nextMinute;
  } 

formatDateToSlash(date){
    date = typeof date !='string' ? JSON.stringify(date) : date;
    if(date && date.includes('/')){return date}

    let [year, month, day] = date.split('-');

    return `${year}/${month}/${day}`;
}

updateSelectedDayArray(selectedDate, weekArr) {
    // Format the selected date to 'YYYY/MM/DD'
    let selectedDateSlash = this.formatDateToSlash(selectedDate);
    // Get the day of the week (0 = Sunday, 1 = Monday, ...)
    const selectedDay = new Date(selectedDateSlash).getDay(); 
    const selectedDateObj = new Date(selectedDateSlash);
    
    // Iterate over weekArr and calculate the 'day' for each object
    weekArr = weekArr.map(day => {
        // Calculate the difference in days from the selected date
        const diff = day.index - selectedDay;
        const calculatedDate = new Date(selectedDateObj);
        calculatedDate.setDate(selectedDateObj.getDate() + diff);
        const dayOfMonth = calculatedDate.getDate();

        return {
            ...day,
            day: dayOfMonth
        };
    });

    return weekArr;
}

 addDays(dateString) {
    let date = new Date(dateString);
    date.setHours(date.getHours() + (main.boatDuration -1));
    return this.formatDateTime(date);
}

}