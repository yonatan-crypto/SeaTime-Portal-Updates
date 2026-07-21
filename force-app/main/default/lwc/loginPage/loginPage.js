/**
 * @description login page for seaTimeApp
 * @author Ceptes
 * @date Saturday-June-29-2024
 **/

import { LightningElement } from 'lwc'
import isValidCredentials from '@salesforce/apex/LoginPageAppController.isValidCredentials'
import isValidOtp from '@salesforce/apex/LoginPageAppController.isValidOtp'
import createOtp from '@salesforce/apex/LoginPageAppController.createOtp'
import Service from './loginPageService'
import AppVerbiages from 'c/seaTimeAppVerbiages'
import LOGO from '@salesforce/resourceUrl/seaTimeLogo'
import FORM_FACTOR from '@salesforce/client/formFactor'
import saveStrongPassword from '@salesforce/apex/LoginPageAppController.saveStrongPassword';


let service,
    verbiage

export default class LoginPage extends LightningElement {

    userCredentials = {}
    showSpinner
    showOtpPage
    accountRecord
    accountId
    otp
    isValidOtp
    isValidCreds
    isStrongPassword = false  // NEW: Track strong password usage
    companyLogo = LOGO

    showIncorrectCredsVerbiage
    showIncorrectOtpVerbiage
    showTooManyTriesVerbiage
    showTooManyTriesOtpVerbiage
    showFaqsVerbiage
    showOtpSpinner
    isMissingCredentials
    missingCredentialsVerbiage 
    usePasswordErrorMessage
    strongPasswordCreatedSuccessMessage

    //Variables for login page
    incorrectCredentialVerbiage
    incorrectOtpVerbiage
    tooManyTriesVerbiage
    faqsVerbiage

    // strong password
    showStrongPasswordModal = false;
    isFirstTimeStrongPassword = false;
    password1 = '';
    password2 = '';
    passwordsMatch = true;
    passwordErrorMessage = '';


    showResetPopup = false;
    resetEmail = '';
    resetMobile = '';


    //page labels
    userNameLabel
    paswwordLabel
    userNamePlaceHolder
    paswwordPlaceHolder
    loginButtonLabel
    otpLabel
    submitOtpButtonLabel
    loginpageHeaderLabel
    loginpageHeaderLabel2
    faqsLabel
    otpHeaderlabel
    signupResetPasswordButtonLabel
    signupResetPasswordTitle
    emailLabel
    mobileNumberLabel
    sendOtpButtonLabel
    createStrongPasswordTitle
    passwordLabel
    confirmPasswordLabel
    submitButtonLabel
    cancelLabel

    get faqsStyle() {
        return FORM_FACTOR == 'Large' ? 'width:26rem' : ''
    }

    constructor() {
        super()
        service = new Service(this)
        verbiage = new AppVerbiages(this)
        verbiage.loadLoginPageVerbiages()
        verbiage.loadLoginPageLabels()
    }

    handleUserNameChange(event) {
        const userName = event.target.value
        this.userCredentials.userName = userName
        console.log('Username changed:', userName)
    }

    handlePasswordChange(event) {
        const password = event.target.value
        this.userCredentials.password = password
        console.log('Password changed:', password)
    }

    handleOtpChange(event) {
        const OTP = event.target.value

        if (OTP.valueOf(OTP).length > 6) {
            this.refs['otp-input'].value = OTP.substring(0, 6)
            return
        }

        this.otp = OTP
        console.log('OTP changed:', OTP)
    }

    handleShowFaqsVerbiage() {
        this.showFaqsVerbiage = !this.showFaqsVerbiage
        console.log('FAQ toggled, now:', this.showFaqsVerbiage)
    }

    async handleLogin() {
    service.preValidateCredentials();
    if (this.isMissingCredentials) { return }

    try {
        this.showSpinner = true;
        const loginDetails = await isValidCredentials({ 
            userCredentials: this.userCredentials 
        });

        this.isValidCreds = loginDetails.isValidCreds === true;
        this.accountRecord = loginDetails.accountRecord || null;
        this.isStrongPassword = loginDetails.isStrongPassword === true;

        this.isPhoneUsedAsPassword = loginDetails.isPhoneUsedAsPassword === true;

        if (this.isValidCreds && this.accountRecord) {
            this.accountId = this.accountRecord.Id;
        }

        service.checkNumberOfFailedAttempts();
        service.postValidateCredentials();

    } catch (error) {
        console.error(error);
    } finally {
        this.showSpinner = false;
    }
}


    async handleSubmitOtp() {
        try {
            if (!this.accountId) {
                console.log('Cannot submit OTP - accountId undefined');
                return;
            }

            console.log('Before OTP submit:', this.accountId, this.otp);

            this.showIncorrectOtpVerbiage = false;
            this.showOtpSpinner = true;

            const otpDetails = await isValidOtp({ accountId: this.accountId, otp: this.otp });
            console.log('OTP Details from Apex:', otpDetails);

            const { isOtpValidated, accountRecord } = otpDetails;
            this.accountRecord = accountRecord;
            this.isValidOtp = isOtpValidated;

            if (!this.isValidOtp) {
                this.showIncorrectOtpVerbiage = true;
                console.log('OTP validation failed');
                return;
            }

            console.log('OTP validation successful');

            if (this.isFirstTimeStrongPassword) {
                this.showOtpPage = false;
                this.showStrongPasswordModal = true;
                console.log('Show strong password modal');
            } else {
                service.postValidateOtp();
            }

        } catch (error) {
            console.log('Error in handleSubmitOtp:', JSON.stringify(error));
        } finally {
            this.showOtpSpinner = false;
        }
    }

    async handleCreateStrongPassword() {
        if (!this.userCredentials.userName || !this.userCredentials.password) {
            alert('Please enter your email and password first.');
            return;
        }

        this.isFirstTimeStrongPassword = true;
        this.showSpinner = true;

        try {
            const loginDetails = await isValidCredentials({ userCredentials: this.userCredentials });
            const { isValidCreds, accountRecord } = loginDetails;
            this.accountRecord = accountRecord;

            if (!isValidCreds || !this.accountRecord) {
                alert('Incorrect credentials.');
                this.isFirstTimeStrongPassword = false;
                return;
            }

            this.accountId = this.accountRecord.Id;
            console.log('After Strong Password login - accountId:', this.accountId, 'Code__c:', this.accountRecord.Code__c);

            this.showOtpPage = true;

        } catch (error) {
            console.log('Error in handleCreateStrongPassword:', error);
        } finally {
            this.showSpinner = false;
        }
    }

    handlePassword1Change(event) {
        this.password1 = event.target.value;
        console.log('Password1 changed:', this.password1)
        this.checkPasswordMatch();
    }

    handlePassword2Change(event) {
        this.password2 = event.target.value;
        console.log('Password2 changed:', this.password2)
        this.checkPasswordMatch();
    }

    checkPasswordMatch() {
        console.log('Checking passwords:', this.password1, this.password2)

        if (this.password1 && this.password2) {
            if (this.password1.length < 8 || this.password2.length < 8) {
                this.passwordsMatch = false;
                this.passwordErrorMessage = 'Password must be at least 8 characters long!';
                console.log('Password length < 8');
            } else if (this.password1 !== this.password2) {
                this.passwordsMatch = false;
                this.passwordErrorMessage = 'Passwords do not match!';
                console.log('Passwords do NOT match');
            } else {
                this.passwordsMatch = true;
                this.passwordErrorMessage = '';
                console.log('Passwords match and length ok!');
            }
        } else {
            this.passwordsMatch = false;
            this.passwordErrorMessage = '';
            console.log('Passwords not fully entered yet');
        }
    }

    async handleSubmitStrongPassword() {
        console.log('Submit Strong Password clicked');
        if (!this.password1 || !this.password2) {
            alert('Please enter both password fields.');
            return;
        }

        if (this.password1 !== this.password2) {
            alert('Passwords do not match.');
            return;
        }

        this.showSpinner = true;

        try {
            const result = await saveStrongPassword({ accountId: this.accountId, newPassword: this.password1 });
            if (result) {
                alert(this.strongPasswordCreatedSuccessMessage);
                console.log('Strong password saved:', this.password1)

                this.showStrongPasswordModal = false;
                window.location.reload();
            } else {
                alert('Failed to save strong password.');
                console.log('Failed to save strong password');
            }
        } catch (error) {
            console.log('Error saving strong password:', error);
        } finally {
            this.showSpinner = false;
        }
    }

    handleCancelStrongPassword() {
        this.showStrongPasswordModal = false;
        this.password1 = '';
        this.password2 = '';
        this.passwordErrorMessage = '';
    }

    get isSubmitDisabled() {
        console.log('Password submit disabled?', !this.passwordsMatch)
        return !this.passwordsMatch;
    }


    openResetPopup() {
    this.showResetPopup = true;
    }

    handleResetEmailChange(event) {
    this.resetEmail = event.target.value;
}

handleResetMobileChange(event) {
    this.resetMobile = event.target.value;
}
closeResetPopup() {
    this.showResetPopup = false;
    this.resetEmail = '';
    this.resetMobile = '';
}
async handleResetSubmit() {
    console.log('Reset Email:', this.resetEmail);
    console.log('Reset Mobile:', this.resetMobile);

     if (!this.resetEmail || !this.resetMobile) {
        alert('Please enter email and mobile number');
        return;
    }

    this.userCredentials = {
        userName: this.resetEmail,
        password: this.resetMobile
    };

    this.isFirstTimeStrongPassword = true; 
    this.showResetPopup = false;
    this.showSpinner = true;

    try {
        const loginDetails = await isValidCredentials({
            userCredentials: this.userCredentials
        });

        this.isValidCreds = loginDetails.isValidCreds;
        this.accountRecord = loginDetails.accountRecord;

        if (!this.isValidCreds || !this.accountRecord) {
            alert('Invalid email or mobile number');
            return;
        }

        this.accountId = this.accountRecord.Id;

        // Create OTP when user clicks "Send OTP" button
        await createOtp({ accountId: this.accountId });

        this.showOtpPage = true;

    } catch (error) {
        console.log('Error in handleResetSubmit:', error);
    } finally {
        this.showSpinner = false;
    }
}


}