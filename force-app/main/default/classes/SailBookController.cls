public class SailBookController {
    @TestVisible
    public static String accountId{get;set;}
    
    public SailBookController(){
        try{
            String queryString = ApexPages.currentPage().getParameters().get('recordId');
            System.debug('queryString--->'+queryString); 
        }catch(exception e){
            system.debug('Message::'+e.getMessage()); 
            system.debug('Line::'+e.getLineNumber());
             
            
        }
        
    }
}