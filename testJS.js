const main = { searchData: { date: '2026-04-10'}, boatDuration: 3 };
const startTime = "09:00";
let proposedStartLocalStr = `${main.searchData.date}T${startTime}:00`;
let proposedStart = new Date(proposedStartLocalStr);
let proposedEnd = new Date(proposedStart.getTime() + (main.boatDuration * 60 * 60 * 1000));

// Cruise created for April 10 at 12:00 Israel time (09:00 UTC) 
const ele = {
    Start_Date__c: "2026-04-10T09:00:00.000+0000",
    End_Date__c: "2026-04-12T13:15:00.000+0000"
};

let cruiseStart = new Date(ele.Start_Date__c);
let cruiseEnd = new Date(ele.End_Date__c);

console.log('proposedStart:', proposedStart.toString());
console.log('proposedEnd:', proposedEnd.toString());
console.log('cruiseStart:', cruiseStart.toString());
console.log('cruiseEnd:', cruiseEnd.toString());

console.log('proposedStart < cruiseEnd:', proposedStart < cruiseEnd);
console.log('proposedEnd > cruiseStart:', proposedEnd > cruiseStart);

// Now test overlapping
const overlapTime = "10:00";
let overlapStart = new Date(`${main.searchData.date}T${overlapTime}:00`);
let overlapEnd = new Date(overlapStart.getTime() + (main.boatDuration * 60 * 60 * 1000));
console.log('10:00 > cruiseStart:', overlapEnd > cruiseStart);
