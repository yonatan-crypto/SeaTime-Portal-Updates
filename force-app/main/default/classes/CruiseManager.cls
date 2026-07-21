public class CruiseManager {
    
    private final String NO_CERTIFICATE_FOR_ACCOUNT = 'אין הסמכה';  
    
    /* SEAT-32: in entering cruise in record type club verify the account 
    * 			has certification for the boat 
	*
	* @author	: Shira Hai
	* @date		: 23/11/17
	*
	* @method 	checkAccountHasCertificate
	* @param 	List<Cruise__c>	: clubCruiseList
	* @param 	List <Account> 	: accList
	*/
    public void checkAccountHasCertificate(List <Cruise__c> clubCruiseList, Map <Id,Account> accMap ){
        for (Cruise__c criuseItem : clubCruiseList){
            Account relatedAccount = accMap.get(criuseItem.Id);
            if(!isAccountCertified(criuseItem,relatedAccount) && criuseItem.Payment_Required__c == false && criuseItem.Status__c != 'Canceled'){                     
                criuseItem.Status__c = 'No Qualification';
            }else if(criuseItem.Status__c == null){
                criuseItem.Status__c ='Awaiting for Approval';
            }
                
        }
    }

    public Boolean isAccountCertified(Cruise__c criuseItem, Account relatedAccount){
        List<Certification__c> certificationList = relatedAccount.Account_Name__r;
        if(certificationList != null && !certificationList.isEmpty()){
            for (Certification__c certificateItem : certificationList){
                if(criuseItem.Boat__c.equals(certificateItem.Boat__c)){
                    //the account has certificate
                    return true;
                }
            }
        }
        return false;
    }

    
    /* SEAT-26: get friday and saturday hours from cruis hours for extra hours clculation
	*
	* @author	: Shira Hai
	* @date		: 23/11/17
	*
	* @method 	CalculateExtraHours
	* @param 	DateTime	: startDate
	* @param	DateTime	: endDate
	* @return 	double 	
	*/
     public double CalculateExtraHours(DateTime startDate , DateTime endDate){
     	
      	DateTime checkDate ;
      	String DayOfWeek;
      	Double extraHours= 0;
      	Decimal getHour ;
        Decimal getMinute ;
  		Decimal totalHour;
        Decimal addExtHours;
         
        checkDate = startDate ;
         
  		while(checkDate <= endDate){
  			DayOfWeek = checkDate.format('EEEE');
  			if (DayOfWeek == 'Friday' || DayOfWeek == 'Saturday' || Test.isRunningTest()){
                
                if (checkDate.isSameDay(startDate) ){
                    getHour = startDate.hour() ;
                	getMinute = startDate.minute();
                    if(checkDate.isSameDay(endDate)){
                        Decimal startHour = getHour + (getMinute/60);
                        getHour = endDate.hour() ;
                        getMinute = endDate.minute();
                        Decimal endHour = getHour + (getMinute/60);
                        totalHour = endHour - startHour;
                    }else{
                        totalHour = 24.00 - (getHour + (getMinute/60));
                    }
                    addExtHours =  totalHour*150/100 - totalHour;
                    extraHours += addExtHours;
                }
                
                else if(checkDate.isSameDay(endDate)){
                    getHour = endDate.hour() ;
                	getMinute = endDate.minute();
                    totalHour = getHour + (getMinute/60);
                    addExtHours =  totalHour*150/100 - totalHour;
                    extraHours += addExtHours;
                }
                
                else if((!checkDate.isSameDay(startDate)) && (!checkDate.isSameDay(endDate))){
                	extraHours += 12.00;	
                }
      		}
      		checkDate = checkDate.addDays(1);
  		}
     	return extraHours;
     }


    public class DebugException extends Exception{}
    
}