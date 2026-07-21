@isTest(seealldata=true)
public class TransactionPointsTest {
	static testMethod void tes() {
		PriceList__c pl = new PriceList__c();
		pl.name='teszed';
		pl.Start_Date__c = System.Today();
		pl.Price__c=50;
		insert pl;
		String btid = [select id from Boats__c where Active__c=true limit 1].id;
		PriceListLine__c pls = new PriceListLine__c();
		pls.PriceList__c=pl.id;
		pls.Type__c='Club';
		pls.Boat__c=btid;
		pls.StartText__c='10:00';
		pls.Price__c=40;
		Pls.HPrice__c=45;
		insert pls;
		pls.StartText__c='11:00';
		update pls;
		Set <String> transchanged = new Set <String>();
		String accid = [select id from Account limit 1].id;
		Transaction__c tran = new Transaction__c();
		tran.Name='teszed';
		tran.RecordTypeid = [select id from RecordType Where Name='נקודות' limit 1].id;
		tran.Account_Name__c = accid;
		tran.Start_Date__c = System.today();
		tran.Date_of_Transaction__c = System.today();
		tran.type_of_membership__c = 'חבר מועדון כולל פרטיות';
		insert tran;
		transchanged.add(tran.id);
		Cruise__c crs = new Cruise__c();
		crs.Boat__c = btid;
		crs.AccountName__c = accid;
		crs.Start_Date__c = System.Today();
		crs.End_Date__c = System.Today().addDays(30);
		crs.Status__c='Awaiting for Approval';
		crs.Transaction__c = tran.id;
		crs.RecordTypeId = [select id from RecordType Where Name='Club' limit 1].id;
		insert crs;
		ID jobID = System.enqueueJob(new TransactionPoints(transchanged));

	}
}