/**
 * @description
 * @author Ceptes
 * @date Wednesday-July-31-2024
 **/

let main

export default class Service {

    constructor(superMain) {
        main = superMain
    }

    updateSelectedClubCruisesArray() {
        if (!Array.isArray(main.clubCruisesArray) || !main.clubCruisesArray.length) {
            main.selectedClubCruisesArray = [];
            return;
        }

        // 1. REFLECTIVE Membership Detection (Robust Fallback)
        const trans = main.transaction || {};
        const acc = main.account || {};
        let rawMembership = "";
        
        const scan = (obj) => {
            if (!obj) return "";
            for (let key in obj) {
                const val = obj[key];
                if (typeof val === 'string' && (
                    val.includes('תלמיד') || val.includes('פרטיות') || val.includes('מועדון') || 
                    val.includes('מודרכות') || val.includes('student') || val.includes('priority') || 
                    val.includes('guided')
                )) {
                    return val.trim().toLowerCase();
                }
            }
            return "";
        };

        rawMembership = scan(trans);
        if (!rawMembership) rawMembership = scan(acc);

        const isFullClub = rawMembership.includes('פרטיות') || rawMembership.includes('חבר מועדון');
        const isGuidedOnly = rawMembership.includes('מודרכות בלבד') || rawMembership.includes('guided only');
        const isStudent = main.account?.StudentMeshit30__c === true;

        // Cleanup Debug Info
        main.debugInfo = "";

        main.selectedClubCruisesArray = main.clubCruisesArray.filter(cruise => {
            const rawType = (cruise.typeOfEnriching || '').trim().toLowerCase();
            const recType = (cruise.recordTypeName || '').trim();
            
            const isCert = recType === 'Certification' || recType === 'הסמכות' || recType === 'הסמכה';
            const isFriends = recType === 'Friends' || recType === 'חברים';
            const isEnriching = recType === 'Enriching' || recType === 'העשרה';
            
            const isClubType = isEnriching && (rawType === 'מועדון' || rawType === 'club' || rawType === 'enriching' || rawType === '');
            const isSchoolType = isEnriching && (rawType === 'בית ספר' || rawType === 'school' || rawType === 'lesson');
            const isTheoryType = isEnriching && (rawType === 'תאוריה' || rawType === 'theory');

            let isAllowed = false;
            if (isFriends) isAllowed = true;
            if (isCert && isFullClub) isAllowed = true;
            if (isClubType && (isFullClub || isGuidedOnly)) isAllowed = true;
            if ((isSchoolType || isTheoryType) && isStudent) isAllowed = true;

            if (!isAllowed) return false;

            if (isClubType && !main.filterClub) return false;
            if (isSchoolType && !main.filterSchool) return false;
            if (isTheoryType && !main.filterTheory) return false;
            if (isCert && !main.filterCert) return false;
            if (isFriends && !main.filterFriends) return false;
            
            return true;
        });

        // 3. Sorting & Button Logic
        main.selectedClubCruisesArray.forEach(cruise => {
            const userIsBooked = cruise.coCruiseRecords?.some(coCruise => coCruise.Account_Co__c === main.account?.Id);
            cruise.isJoinDisabled = cruise.remainingSlots <= 0 || userIsBooked;
            
            // Labels for specific cruise categories
            if (cruise.recordTypeName === 'Certification') {
                cruise.addtionalInfo = 'הפלגת הסמכה';
            } else if (cruise.recordTypeName === 'Friends') {
                cruise.addtionalInfo = 'הפלגת חברים';
            }
        });

        main.selectedClubCruisesArray.sort((a, b) => new Date(a.startDate) - new Date(b.startDate));
    }

    populateClubCruisesBoatIds() {
        main.boatIdsArray = main.clubCruisesArray.map(({ boatId }) => boatId)
    }

    populateBoatIdToPriceLines() {
        main.priceLinesArray.forEach(priceLine => {

            const wrappedPriceLine = this.getWrappedPriceLine(priceLine)

            if (main.boatIdToPriceLines[priceLine.Boat__c]) {
                main.boatIdToPriceLines[priceLine.Boat__c].push(wrappedPriceLine)
            } else {
                main.boatIdToPriceLines[priceLine.Boat__c] = [wrappedPriceLine]
            }
        })
      
    }

    getWrappedPriceLine(priceLine) {
        return {
            startTime: main.utility.getFormattedTime(priceLine.Start__c),
            price: priceLine.Price__c,
            type: priceLine.Type__c
        }
    }

    getBoatPrice(boatId, startTime, cruiseType) {
        console.log('getBoatPrice', boatId, startTime, cruiseType);
        
        let allPriceLines = [];
        
        // 1. Specific boat prices
        if (boatId && main.boatIdToPriceLines[boatId]) {
            allPriceLines = [...allPriceLines, ...main.boatIdToPriceLines[boatId]];
        }
        
        // 2. Generic prices (Boat__c is null/undefined in database)
        if (main.boatIdToPriceLines[null]) {
            allPriceLines = [...allPriceLines, ...main.boatIdToPriceLines[null]];
        }
        if (main.boatIdToPriceLines[undefined]) {
            allPriceLines = [...allPriceLines, ...main.boatIdToPriceLines[undefined]];
        }
        if (main.boatIdToPriceLines['null']) {
            allPriceLines = [...allPriceLines, ...main.boatIdToPriceLines['null']];
        }

        var selectedPriceLine = {};
        
        allPriceLines.forEach(priceLine => {
            if(startTime >= priceLine.startTime && priceLine.type == cruiseType){
                selectedPriceLine = priceLine;
            }
        });
        
        console.log('Final Selected Price:', selectedPriceLine?.price);
        return selectedPriceLine?.price || 0;
    }

    updateClubCruisePrices() {
        console.log('updateClubCruisePrices');
        console.log('main.clubCruisesArray'+JSON.stringify(main.clubCruisesArray));
        if(Array.isArray(main.clubCruisesArray) && (main.clubCruisesArray).length){
            main.clubCruisesArray.forEach(clubCruise => {
            clubCruise.price = this.getBoatPrice(clubCruise.boatId, clubCruise.formattedStartTime, clubCruise.recordTypeName);
            clubCruise.isBookingNotAvailable = this.bookingNotAvailable(clubCruise.price, clubCruise.startDate);
            clubCruise.searchTileSelector = this.searchTileSelector(clubCruise.isBookingNotAvailable);
            })
        }
    }

    populateRecentClubCruises() {

        if (!main.clubCruisesArray.length) { return }
        main.recentClubCruises.length = 0
        main.clubCruisesArray
            .forEach(cruise => {
                if (!cruise.coCruiseRecords?.length) {
                    return
                }
                for (const coCruise of cruise.coCruiseRecords) {
                    if (main.account?.Id != coCruise.Account_Co__c) { continue }
                    main.recentClubCruises.push(cruise)
                }
            })
    }

    bookingNotAvailable(boatPrice, startDate) {
        // Student check: use explicitly passed isStudentUser flag (more reliable than account field timing)
        const isStudent = main.isStudentUser === true;

        // Students can always book guided/friends cruises (no subscription needed)
        if (isStudent) return false;

        if (!main.transaction || !main.transaction.Active__c) return true;

        const membership = (main.transaction?.type_of_membership__c || '').trim();
        const isGuidedOnly = membership.includes('מודרכות בלבד');
        const isFullClub = membership.includes('חבר מועדון כולל פרטיות');

        // Students have no limitations (belt-and-suspenders)
        if (isStudent) return false;

        // 2. Logic for "Guided Only" and "Full Club Including Private"
        if (isGuidedOnly || isFullClub) {
            const endDateStr = main.transaction?.End_Date__c;
            let isExpired = false;
            if (endDateStr && startDate) {
                isExpired = new Date(startDate) > new Date(endDateStr);
            }
            const hasPoints = (main.transaction.Points_Balance__c || 0) >= (boatPrice || 0);

            return isExpired || !hasPoints;
        }

        // 3. For any other membership types, we default to the point/expiry check for safety
        const endDateStr = main.transaction?.End_Date__c;
        let isExpired = false;
        if (endDateStr && startDate) {
            isExpired = new Date(startDate) > new Date(endDateStr);
        }
        const hasPoints = (main.transaction.Points_Balance__c || 0) >= (boatPrice || 0);
        
        return isExpired || !hasPoints;
    }


    searchTileSelector(isBookingNotAvailable) {
            return Boolean(isBookingNotAvailable && (main.selectedClubCruisesArray.length>= 0)) ? 'search-tile grayed-search-tile' : 'search-tile'

    }
}