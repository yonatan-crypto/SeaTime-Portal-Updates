/*
 * @Author: ZedXagE 
 * @Date: 2019-04-23 11:10:23 
 * @Last Modified by: ZedXagE
 * @Last Modified time: 2019-04-28 10:06:11
 */

public  class TransactionPoints implements Queueable{
	public Set <String> tranids;
	public TransactionPoints(Set <String> trnids) {
		tranids = trnids;
	}
	public void execute(QueueableContext context) {
        Map <String, Transaction__c> trans = new Map <String, Transaction__c>();  
		for(String trid:tranids)   trans.put(trid,new Transaction__c(id=trid,Used_Points__c=0));
		List <Co_Cruise_Members__c> ccms = [select id,Cruise_Points__c,Transaction__c from Co_Cruise_Members__c where Transaction__c in:tranids and Transaction__c!=null and Cruise_Points__c!=null and Cruise__c!=null and Cruise__r.Status__c!='Canceled'];
		for(Cruise__c crs:[select id,Cruise_Points__c,Transaction__c from Cruise__c where Transaction__c in:tranids and Transaction__c!=null and Cruise_Points__c!=null and Status__c!='Canceled'])
			trans.get(crs.Transaction__c).Used_Points__c += crs.Cruise_Points__c;
		for(Co_Cruise_Members__c ccm:[select id,Cruise_Points__c,Transaction__c from Co_Cruise_Members__c where Transaction__c in:tranids and Transaction__c!=null and Cruise_Points__c!=null and Cruise__c!=null and Cruise__r.Status__c!='Canceled'])
			trans.get(ccm.Transaction__c).Used_Points__c += ccm.Cruise_Points__c;
		Database.update(trans.values(),false);
	}
	public Static Decimal getPTS(String typval,String btval,Boolean isHoliday,List <PriceListLine__c> plls,Decimal def,DateTime st,DateTime ed){
		Decimal pts=0;
		List <Decimal> ords = new List <Decimal>();
		Map <Decimal,Decimal> ptsbyjump = new Map <Decimal,Decimal>();
		for(PriceListLine__c pll:plls)
			if(pll.Type__c==typval&&pll.Boat__c==btval){
				Decimal jump = getDtm(pll.Start__c);
				ords.add(jump);
				ptsbyjump.put(jump,isHoliday ? (pll.Hprice__c!=null?pll.Hprice__c:pll.Price__c):pll.Price__c);
				if(pll.Global__c == true)	return isHoliday ? (pll.Hprice__c!=null?pll.Hprice__c:pll.Price__c):pll.Price__c;
			}
		if(ptsbyjump.keyset().size()==0){
			for(PriceListLine__c pll:plls)
				if(pll.Type__c==typval&&pll.Boat__c==null){
					Decimal jump = getDtm(pll.Start__c);
					ords.add(jump);
					ptsbyjump.put(jump,isHoliday ? (pll.Hprice__c!=null?pll.Hprice__c:pll.Price__c):pll.Price__c);
					if(pll.Global__c == true)	return isHoliday ? (pll.Hprice__c!=null?pll.Hprice__c:pll.Price__c):pll.Price__c;
				}
		}
		System.debug(ed+' '+st);
		Decimal tottime = ((Decimal)(ed.getTime()-st.getTime())/(1000*60*60));
		Decimal calctime = 0;
		Decimal star = getDtm(st.time());
		Decimal done = getDtm(ed.time());
		Date stDate = Date.newinstance(st.year(),st.month(),st.day());
		Date tempDate = stDate;
		Date edDate = Date.newinstance(ed.year(),ed.month(),ed.day());
		System.debug('Total time: '+tottime);
		while(tempDate<=edDate){
			Decimal st4day = tempDate==stDate?star:0;
			Decimal ed4day = tempDate==edDate?done:24;
			for(integer i=0;i<ords.size();i++){
				Decimal stjp = ords[i];
				Decimal edjp = ords.size()>i+1?ords[i+1]:24;
				Decimal hrs4jp = (ed4day<edjp?ed4day:edjp)-(st4day>stjp?st4day:stjp);
				if(hrs4jp>0){
					System.debug('Hours in jump: '+hrs4jp);
					calctime += hrs4jp;
					pts+=hrs4jp*ptsbyjump.get(stjp);
					System.debug('pts: '+pts+' calctime: '+calctime);
				}
			}
			tempDate = tempDate.addDays(1);
		}
		pts += (tottime-calctime)*def;
		pts = pts.setScale(2);
		System.debug('final pts: '+pts);
        return pts;
    }
	public static Decimal getDtm(Time tm){
		return tm.hour()+((Decimal)tm.minute()/60);
	}
}