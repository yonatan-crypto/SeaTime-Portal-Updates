/**
 * @description Business logic related to login page of sea time blue app.
 * @author Ceptes
 * @date Saturday-June-29-2024
 **/

let main

const NUMBER_OF_FAILED_LOGINS = 7

export default class Service {

    constructor(superMain) {
        main = superMain
    }

    preValidateCredentials() {
        main.isMissingCredentials = !main.userCredentials.userName || !main.userCredentials.password
    }
    
    postValidateCredentials() {

    if (main.isPhoneUsedAsPassword && !main.isStrongPassword) {
        alert(main.usePasswordErrorMessage);
        return;
    }

    if (!main.accountId || !main.isValidCreds) {
        main.showIncorrectCredsVerbiage = true;
    } 
    else if (main.isStrongPassword) {
        sessionStorage['isLoggedIn'] = true;
        sessionStorage.setItem('SHOW_WELCOME_OVERLAY', 'true');
        this.navigateToHomePage();
    }
    else if (!main.showTooManyTriesVerbiage) {
        main.showOtpPage = true;
        main.showIncorrectCredsVerbiage = false;
    }
}


    postValidateOtp() {

        if (main.accountRecord.Login_Attempt__c >= NUMBER_OF_FAILED_LOGINS) {
            main.showTooManyTriesOtpVerbiage = true
            main.showOtpSpinner = false
        } else if (main.isValidOtp) {
            sessionStorage.setItem('isLoggedIn', 'true');
            sessionStorage.setItem('accountId', main.accountId);
            sessionStorage.setItem('SHOW_WELCOME_OVERLAY', 'true');
            this.navigateToHomePage()
        } else {
            main.showOtpSpinner = false
            main.showIncorrectOtpVerbiage = true
        }
    }

    populateAccountId() {
        if (main.accountRecord) {
            main.accountId = main.accountRecord.Id
        }
    }

    checkNumberOfFailedAttempts() {
        main.showTooManyTriesVerbiage = main.accountRecord?.Login_Attempt__c >= NUMBER_OF_FAILED_LOGINS
    }

    navigateToHomePage() {
        main.refs.navigation.navigateToAppPage('HomePage__c', { accountId: main.accountId })
    }
}