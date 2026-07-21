/**
* @author ben pony
* @date NOV 2017
* @desc seatime app authentication utilities service
* @class SeatimeAuthenticationService
*/
public without sharing class SeatimeAuthenticationService {
	
	public SeatimeAuthenticationService() {} //constructor:default

	/** 
	* @desc 
	* @method tokenizeAccountLoginDetails
	* @param accountEmail(String) ,accountPassword(String)
	* @return encryptedValue(String)
	*/
	public static String tokenizeAccountLoginDetails(String accountEmail, String accountPassword){
		String encryptionType = 'AES128';
		Blob encryptionKey = Crypto.generateAesKey(128);
		Blob encryptedRawValue = Blob.valueOf(accountEmail + accountPassword);
		Blob encryptedValue = Crypto.encryptWithManagedIV(encryptionType, encryptionKey, encryptedRawValue);
		return EncodingUtil.ConvertTohex(encryptedValue);
	}//method:tokenizer


	/**
	* @desc get account by cookie token. 
	* @developer does not support remoting !
	* @method getSecuredAccountByCookie
	* @param cookieName(String)
	* @return Account
	*/
	public static Account getSecuredAccountByCookie(String cookieName){  
		Cookie seatimeAccountCookie = getCookie(cookieName);
		String accountTokenValue = seatimeAccountCookie != null ? seatimeAccountCookie.getValue() : null;
		//seatimeAccountCookie.isSecure() : why not secure from apex, but secured from web
		if(String.isNotBlank(accountTokenValue)){
			List<Account> securedAccount =  [SELECT 
												Id,
												Name
												FROM Account 
												WHERE Login_Token__c =: accountTokenValue];

			if(!securedAccount.isEmpty() && securedAccount.size() == 1){
				return securedAccount[0];
			} 
		}
		return New Account();
	}//method:getter:account


	/**
	* @desc get account by cookie token. 
	* @method getSecuredAccountByToken
	* @param cookieName(String)
	* @return Account
	*/
	public static Account getSecuredAccountByToken(String securityToken){  
		//seatimeAccountCookie.isSecure() : why not secure from apex, but secured from web
		if(String.isNotBlank(securityToken)){
			List<Account> securedAccount =  [SELECT 
												Id,
												Name
												FROM Account 
												WHERE Login_Token__c =: securityToken];

			if(!securedAccount.isEmpty() && securedAccount.size() == 1){
				return securedAccount[0];
			} 
		}
		return New Account();
	}//method:getter:account	

	/** 
	* @desc 
	* @method setSecuredCookie
	* @param hashedToken(String)
	* @return void
	*/
	public static Cookie setSecuredCookie(String cookieName,String cookieValue){
		//cookie constructor(name, value, path, maxAge, isSecure)
		Cookie seatimeAccountCookie = new Cookie(cookieName, cookieValue, null, -1, true);
		ApexPages.currentPage().setCookies(new Cookie[]{seatimeAccountCookie});
		return seatimeAccountCookie;
	}//method:setter:cookie

	/** 
	* @desc 
	* @method getCookie
	* @param cookieName(String)
	* @return Cookie
	*/
	public static Cookie getCookie(String cookieName){
		return ApexPages.currentPage().getCookies().get(cookieName);
	}//method:util:getter:cookie

	/** 
	* @desc 
	* @method killCookie
	* @param cookieName(String)
	* @return void
	*/
	public static void killCookie(String cookieName){
		//setting cookie max age to 0 will delete the cookie
		Cookie seatimeAccountCookie = new Cookie(cookieName, '', null, 0, true);
		ApexPages.currentPage().setCookies(new Cookie[]{seatimeAccountCookie});
	}//method:setter:cookie
		

	public static Boolean isStandardUser(){
		return UserInfo.getUserType().equals('Standard');
	}//method:util

	public static Boolean isGuestUser(){
		return UserInfo.getUserType().equals('Guest');
	}//method:util

	public class DebugException extends Exception{}
	
}//class:service