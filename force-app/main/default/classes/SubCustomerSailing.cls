public without sharing class SubCustomerSailing {
  
   public static void insertMethod(List<Co_Cruise_Members__c> newSubCustomerList){
        try{
            
            Map<Id,Integer> customerCountMap = new Map<Id,Integer>();
            Map<String,Integer> sailMonthCountMap = new Map<String,Integer>();
            Set<String> sailMonths = new Set<String>();
             Set<String> accountIds = new Set<String>();
             List<Co_Cruise_Members__c> newSubCustomerListQuery = new List<Co_Cruise_Members__c>();
            newSubCustomerListQuery = [Select Id, Name,Cruise__c,Cruise__r.Status__c,Account_Co__c,SailStartMonthYear__c From Co_Cruise_Members__c Where Id IN :newSubCustomerList ];
                        
            for(Co_Cruise_Members__c c : newSubCustomerList){
                if(c.Cruise__c!=null && c.Account_Co__c!=null){
                    accountIds.add(c.Account_Co__c);
                    if(c.SailStartMonthYear__c!=null){
                         sailMonths.add(c.SailStartMonthYear__c);
                    }
                     
                    if(!customerCountMap.containsKey(c.Cruise__c)){
                        customerCountMap.put(c.Cruise__c, 0);
                    }
                    
                    customerCountMap.put(c.Cruise__c,customerCountMap.get(c.Cruise__c) + 1);  
                       
                }
            }
            
           //edit by Yael on 1.12.21 List<Cruise__c> relatedCruiseRecords = new List<Cruise__c>([SELECT id,SCCount__c from Cruise__c where ID in:customerCountMap.keyset()]);
           List<Cruise__c> relatedCruiseRecords = new List<Cruise__c>([SELECT Id,SCCount__c from Cruise__c where Id IN :customerCountMap.keyset()]);          

            for(Cruise__c cruise : relatedCruiseRecords){
                if(cruise.SCCount__c !=null){
                    cruise.SCCount__c = cruise.SCCount__c + customerCountMap.get(cruise.Id);
                }
                else{
                    cruise.SCCount__c = customerCountMap.get(cruise.Id);
                }
            }
            update relatedCruiseRecords;
           //Yael update on 1.12.21 List<Co_Cruise_Members__c> s = [SELECT ID,Account_Co__c,SailStartMonthYear__c,noOfSCCountsForSelectedMonth__c,SailType__c from Co_Cruise_Members__c where SailStartMonthYear__c=:sailMonths AND Account_Co__c IN:accountIds]; 
          List<Co_Cruise_Members__c> cruiseMembers = [SELECT ID,Cruise_Points__c, Account_Co__c,SailStartMonthYear__c,noOfSCCountsForSelectedMonth__c,SailType__c from Co_Cruise_Members__c where Status__c !='Canceled' AND SailStartMonthYear__c=:sailMonths AND Account_Co__c IN:accountIds]; 
          List<Co_Cruise_Members__c> cruiseMembersAll = [SELECT Cruise_Points__c, ID,Account_Co__c,SailStartMonthYear__c,noOfSCCountsForSelectedMonth__c,SailType__c from Co_Cruise_Members__c where SailStartMonthYear__c=:sailMonths AND Account_Co__c IN:accountIds]; 
	
            Integer count;
            if(!cruiseMembers.isEmpty()){
                count = cruiseMembers.size();
            }
            else count=0;
            
            for(Co_Cruise_Members__c c : cruiseMembers){
                     if(!sailMonthCountMap.containsKey(c.Account_Co__c+'-'+c.SailStartMonthYear__c)){
                        sailMonthCountMap.put(c.Account_Co__c+'-'+c.SailStartMonthYear__c, 0);
                    }
                    sailMonthCountMap.put(c.Account_Co__c+'-'+c.SailStartMonthYear__c,sailMonthCountMap.get(c.Account_Co__c+'-'+c.SailStartMonthYear__c) + 1);
            }
            if(count >0){        
            for(Co_Cruise_Members__c cruise : cruiseMembersAll){
                cruise.noOfSCCountsForSelectedMonth__c = count;
            }
            }
            
            CoCruiseTriggerHandler.byPassTrigger = true;
            update cruiseMembersAll;
            CoCruiseTriggerHandler.byPassTrigger = false;
           
        }catch(Exception e){
            system.debug('Exception is:::'+e.getMessage());
            system.debug('at line number:::'+e.getLineNumber());
            
        } 

    }
    
    public static void updateMethod(Map<Id,Co_Cruise_Members__c> oldMap,Map<Id,Co_Cruise_Members__c> newMap){        
        Map<Id,Integer> addCountMap = new Map<Id,Integer>();  
        Map<Id,Integer> subtractCountMap = new Map<Id,Integer>();  
        Map<Id,Integer> accountAddCustomerCountMap = new Map<Id,Integer>();
        Map<Id,Integer> accountSubCustomerCountMap = new Map<Id,Integer>();
        
        for(Co_Cruise_Members__c c : oldMap.values()){
            if(oldMap.get(c.Id).Cruise__c!= newMap.get(c.Id).Cruise__c){
                if(oldMap.get(c.Id).Cruise__c!=null){
                    if(!subtractCountMap.containsKey(c.Cruise__c)){
                        subtractCountMap.put(c.Cruise__c,0); 
                    }
                    subtractCountMap.put(c.Cruise__c,subtractCountMap.get(c.Cruise__c) + 1);  
                }
                                
                if(newMap.get(c.Id).Cruise__c!=null){
                    if(!addCountMap.containsKey(newMap.get(c.Id).Cruise__c)){
                        addCountMap.put(newMap.get(c.Id).Cruise__c,0);
                    }
                    addCountMap.put(newMap.get(c.Id).Cruise__c,addCountMap.get(newMap.get(c.Id).Cruise__c) + 1);
                }

            }
            
            if(oldMap.get(c.Id).Account_Co__c!= newMap.get(c.Id).Account_Co__c){
                if(oldMap.get(c.Id).Account_Co__c!=null){
                    if(!accountSubCustomerCountMap.containsKey(c.Account_Co__c)){
                        accountSubCustomerCountMap.put(c.Account_Co__c,0); 
                    } 
                    accountSubCustomerCountMap.put(c.Account_Co__c,accountSubCustomerCountMap.get(c.Account_Co__c) + 1); 
                }
                if(newMap.get(c.Id).Account_Co__c!=null){
                    if(!accountAddCustomerCountMap.containsKey(newMap.get(c.Id).Account_Co__c)){
                        accountAddCustomerCountMap.put(newMap.get(c.Id).Account_Co__c,0);
                    }

                    accountAddCustomerCountMap.put(newMap.get(c.Id).Account_Co__c,accountAddCustomerCountMap.get(newMap.get(c.Id).Account_Co__c) + 1);
                    
                }
            }

            if(oldMap.get(c.Id).Status__c != newMap.get(c.Id).Status__c){
                if(newMap.get(c.Id).Status__c == 'Canceled' && oldMap.get(c.Id).Status__c != 'Canceled'){
                    if(newMap.get(c.Id).Cruise__c != null){
                        if(!subtractCountMap.containsKey(newMap.get(c.Id).Cruise__c)){
                            subtractCountMap.put(newMap.get(c.Id).Cruise__c, 0);
                        }
                        subtractCountMap.put(newMap.get(c.Id).Cruise__c, subtractCountMap.get(newMap.get(c.Id).Cruise__c) + 1);
                    }
                }
                else if(oldMap.get(c.Id).Status__c == 'Canceled' && newMap.get(c.Id).Status__c != 'Canceled'){
                    if(newMap.get(c.Id).Cruise__c != null){
                        if(!addCountMap.containsKey(newMap.get(c.Id).Cruise__c)){
                            addCountMap.put(newMap.get(c.Id).Cruise__c, 0);
                        }
                        addCountMap.put(newMap.get(c.Id).Cruise__c, addCountMap.get(newMap.get(c.Id).Cruise__c) + 1);
                    }
                }
            }
            
        }
        
        List<Cruise__c> relatedCruiseRecords = new List<Cruise__c>([SELECT id,SCCount__c from Cruise__c where ID in:addCountMap.keyset() OR ID in:subtractCountMap.keyset()]);
        
        for(Cruise__c c : relatedCruiseRecords){
            if(addCountMap.containskey(c.Id)){
                System.debug('SCCount__c-->'+c.SCCount__c); 
                if( c.SCCount__c!=null){
                    c.SCCount__c =  c.SCCount__c + addCountMap.get(c.Id);
                }
                else {
                    c.SCCount__c = addCountMap.get(c.Id);
                }
            }
            if(subtractCountMap.containskey(c.Id)){
                if( c.SCCount__c!=null){
                    c.SCCount__c =  c.SCCount__c - subtractCountMap.get(c.Id);
                } 
            }
        }
        
        update relatedCruiseRecords;

        // Recalculate month counts if status changed
        Set<String> sailMonths = new Set<String>();
        Set<String> accountIds = new Set<String>();
        for(Co_Cruise_Members__c c : newMap.values()){
            Co_Cruise_Members__c oldC = oldMap.get(c.Id);
            if(c.Status__c != oldC.Status__c){
                if(c.Account_Co__c != null) accountIds.add(c.Account_Co__c);
                if(c.SailStartMonthYear__c != null) sailMonths.add(c.SailStartMonthYear__c);
            }
        }

        if(!sailMonths.isEmpty() && !accountIds.isEmpty()){
            List<Co_Cruise_Members__c> cruiseMembers = [SELECT ID,Account_Co__c,SailStartMonthYear__c,noOfSCCountsForSelectedMonth__c from
                                                        Co_Cruise_Members__c where Status__c != 'Canceled' AND SailStartMonthYear__c in:sailMonths
                                                        AND Account_Co__c IN:accountIds];
            
            Map<String, Integer> counts = new Map<String, Integer>();
            for(Co_Cruise_Members__c member : cruiseMembers){
                String key = member.Account_Co__c + '-' + member.SailStartMonthYear__c;
                counts.put(key, (counts.containsKey(key) ? counts.get(key) : 0) + 1);
            }

            List<Co_Cruise_Members__c> membersToUpdate = [SELECT ID,Account_Co__c,SailStartMonthYear__c,noOfSCCountsForSelectedMonth__c from
                                                        Co_Cruise_Members__c where SailStartMonthYear__c in:sailMonths
                                                        AND Account_Co__c IN:accountIds];
            
            for(Co_Cruise_Members__c member : membersToUpdate){
                String key = member.Account_Co__c + '-' + member.SailStartMonthYear__c;
                member.noOfSCCountsForSelectedMonth__c = counts.get(key) != null ? counts.get(key) : 0;
            }
            
            if(!membersToUpdate.isEmpty()){
                CoCruiseTriggerHandler.byPassTrigger = true;
                update membersToUpdate;
                CoCruiseTriggerHandler.byPassTrigger = false;
            }
        }
                   
    }
    
    public static void deleteMethod(List<Co_Cruise_Members__c> oldSubCustomerList){
        try{
            
            Map<Id,Integer> customerCountMap = new Map<Id,Integer>();
            Set<String> sailMonths = new Set<String>();
            Set<String> accountIds = new Set<String>();
            Map<String,Integer> sailMonthCountMap = new Map<String,Integer>();
            List<Co_Cruise_Members__c> oldSubCustomerListQuery = new List<Co_Cruise_Members__c>();
            oldSubCustomerListQuery = [Select Id, Name,Cruise__c,Cruise__r.Status__c,Account_Co__c,SailStartMonthYear__c From Co_Cruise_Members__c Where Id IN :oldSubCustomerList];
            for(Co_Cruise_Members__c c : oldSubCustomerListQuery ){
                if(c.Cruise__c!=null && c.Account_Co__c!=null && c.Cruise__r.Status__c != 'Canceled'){
                    accountIds.add(c.Account_Co__c);
                    if(c.SailStartMonthYear__c!=null){
                        sailMonths.add(c.SailStartMonthYear__c);
                        if(!sailMonthCountMap.containsKey(c.Account_Co__c+'-'+c.SailStartMonthYear__c)){
                            sailMonthCountMap.put(c.Account_Co__c+'-'+c.SailStartMonthYear__c, 0);
                        }
                        sailMonthCountMap.put(c.Account_Co__c+'-'+c.SailStartMonthYear__c,sailMonthCountMap.get(c.Account_Co__c+'-'+c.SailStartMonthYear__c) + 1);
                    }
                    
                    if(!customerCountMap.containsKey(c.Cruise__c)){
                        customerCountMap.put(c.Cruise__c, 0);
                    }
                    customerCountMap.put(c.Cruise__c,customerCountMap.get(c.Cruise__c) + 1);
                    
                }
                
            }
            
            List<Cruise__c> relatedCruiseRecords = new List<Cruise__c>([SELECT id,SCCount__c,Name,Status__c,Guide__c, RemaingSeatsInBoat__c, Boat__c, 
                                                                        Boat_Name__c from Cruise__c where ID in:customerCountMap.keyset()]);
         
            
            for(Cruise__c cruise : relatedCruiseRecords){
                if(cruise.SCCount__c !=null && cruise.SCCount__c !=0){
                    if(customerCountMap.containskey(cruise.Id)){
                     cruise.SCCount__c = cruise.SCCount__c - customerCountMap.get(cruise.Id);   
                    }
                    
                }
                
            }
            if(!relatedCruiseRecords.isEmpty())
            update relatedCruiseRecords;
            
          List<Co_Cruise_Members__c> cruiseMembers = [SELECT ID,Account_Co__c,SailStartMonthYear__c,noOfSCCountsForSelectedMonth__c from
                                                      Co_Cruise_Members__c where SailStartMonthYear__c in:sailMonths
                                                      AND Account_Co__c IN:accountIds AND ID NOT IN:oldSubCustomerList]; 
            
                   
            for(Co_Cruise_Members__c cruise : cruiseMembers){
                if(cruise.noOfSCCountsForSelectedMonth__c!=null && sailMonthCountMap.containsKey(cruise.Account_Co__c+'-'+cruise.SailStartMonthYear__c))
                cruise.noOfSCCountsForSelectedMonth__c = cruise.noOfSCCountsForSelectedMonth__c - sailMonthCountMap.get(cruise.Account_Co__c+'-'+cruise.SailStartMonthYear__c);
            }
            if(!cruiseMembers.isEmpty())
            update cruiseMembers;
       
        }catch(Exception e){
            system.debug('Exception is:::'+e.getMessage());
            system.debug('at line number:::'+e.getLineNumber());
            
        } 
    }
    public static String findProfile(Id userId){
        User u = [SELECT Id,profileId from User where ID=:userId];
        Id profileId= u.profileId;
    String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
       return  profileName;
    }
}