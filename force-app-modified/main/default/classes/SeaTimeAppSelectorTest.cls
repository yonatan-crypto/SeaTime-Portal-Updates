@IsTest
public class SeaTimeAppSelectorTest {

    static SeaTimeAppSelector selector = new SeaTimeAppSelector();

    @testSetup
    static void setupData() {

        // ---------- Account ----------
        Account acc = new Account(
            Name = 'Test Student',
            Email__c = 'test@student.com',
            Phone = '9999999999',
            Login_Attempt__c = 0,
            Code__c = '123456',
            Is_Strong_Password__c = false,
            Student7Meter__c = true,
            StudentMeshit30__c = false
        );
        insert acc;

        // ---------- Boat ----------
        Boats__c boat = new Boats__c(
            Name = 'Test Boat',
            Type__c = 'Yacht',
            Active__c = true
        );
        insert boat;

        // ---------- Cruise__c ----------
        String cruiseStatus = 'Scheduled'; // Replace with valid picklist value
        try {
            Cruise__c cruise = new Cruise__c(
                Boat__c = boat.Id,
                Start_Date__c = System.today().addDays(1),
                End_Date__c = System.today().addDays(2),
                Status__c = cruiseStatus
            );
            insert cruise;
        } catch(Exception e) {
            System.debug('Skipping Cruise insert due to restrictions: ' + e.getMessage());
        }

        // ---------- Boat Weekends ----------
        Boat_Weekends__c bw = new Boat_Weekends__c(
            Is_Active__c = true,
            Start_Date__c = System.today().addDays(-1),
            End_Date__c = System.today().addDays(5),
            Is_Saturday__c = true,
            Is_Sunday__c = true
        );
        insert bw;

        // ---------- Transaction (only writable fields) ----------
        Transaction__c txn = new Transaction__c(
            Account_Name__c = acc.Id,
            Total_Points__c = 100,
            type_of_membership__c = 'חבר מועדון כולל פרטיות'
            // Points_Balance__c and Active__c removed, they are read-only
        );
        insert txn;
    }

    @IsTest
    static void testIsValidAccountCredentials() {
        Account[] accList = selector.isValidAccountCredentials('test@student.com');
        System.assertEquals(1, accList.size());
        System.assertEquals('9999999999', accList[0].Phone);
    }

    @IsTest
    static void testGetAccountFromId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Account result = selector.getAccountFromId(acc.Id);
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testGetAccountFromId_Null() {
        Account result = selector.getAccountFromId(null);
        System.assertEquals(null, result);
    }

    @IsTest
    static void testGetTransactionFromAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Transaction__c txn = selector.getTransactionFromAccount(acc.Id);
        System.assertNotEquals(null, txn);
    }

    @IsTest
    static void testGetBoatWeekEndIndices() {
        List<Object> indices = selector.getBoatWeekEndIndices(System.today());
        System.assert(indices.size() > 0);
    }

    @IsTest
    static void testGetRecordTypeFromName() {
        RecordType rt = [SELECT Name FROM RecordType WHERE SobjectType='Account' LIMIT 1];
        RecordType result = selector.getRecordTypeFromName(rt.Name);
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testGetBoatsArray() {
        Map<String,Object> searchData = new Map<String,Object>();
        searchData.put('boatTypes', new String[]{'Yacht'});
        searchData.put('date', String.valueOf(System.today()));

        Boats__c[] boats = selector.getBoatsArray(searchData);
        System.assertNotEquals(0, boats.size());
    }

    @IsTest
        static void testGetPriceListLinesFromBoatIds() {
        // Get inserted Boat
        Boats__c boat = [SELECT Id FROM Boats__c LIMIT 1];
    
        // Prepare JSON input with real Boat Id
        String jsonInput = '[{"id":"' + boat.Id + '","boatId":"' + boat.Id + '","recordTypeName":"Course","startDate":"' + String.valueOf(System.today()) + '"}]';
    
        PriceListLine__c[] lines = selector.getPriceListLinesFromBoatIds(jsonInput);
    
        System.assert(lines.size() > 0, 'PriceListLines should be returned');
	}

}