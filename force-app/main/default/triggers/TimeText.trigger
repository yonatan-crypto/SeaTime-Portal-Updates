trigger TimeText on PriceListLine__c (before insert,before update) {
    for(PriceListLine__c pl:Trigger.new){
        if(Trigger.isInsert){
            if(pl.StartText__c!=null){
                string [] spl = pl.StartText__c.split(':');
                pl.Start__c=Time.newinstance(integer.valueof(spl[0]),spl.size()>1?integer.valueof(spl[1]):0,0,0);
            }
        }
        else if(pl.StartText__c!=Trigger.oldmap.get(pl.id).StartText__c){
            if(pl.StartText__c!=null){
                string [] spl = pl.StartText__c.split(':');
                pl.Start__c=Time.newinstance(integer.valueof(spl[0]),spl.size()>1?integer.valueof(spl[1]):0,0,0);
            }
            else	pl.Start__c = null;
        }
    }

}