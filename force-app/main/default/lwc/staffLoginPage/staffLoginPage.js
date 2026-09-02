import { LightningElement, track } from 'lwc';
import isValidCredentials from '@salesforce/apex/StaffLoginController.isValidCredentials';
import isValidOtp from '@salesforce/apex/StaffLoginController.isValidOtp';
import createOtp from '@salesforce/apex/StaffLoginController.createOtp';
import saveStrongPassword from '@salesforce/apex/StaffLoginController.saveStrongPassword';
import LOGO from '@salesforce/resourceUrl/seaTimeLogo';

export default class StaffLoginPage extends LightningElement {
    logoUrl = LOGO;
    @track state = 'login'; // login, otp, createPassword, resetRequest
    @track userName = '';
    @track password = '';
    @track otp = '';
    @track newPassword = '';
    @track confirmPassword = '';
    @track resetEmail = '';
    @track resetPhone = '';
    @track errorMsg = '';
    @track successMsg = '';
    @track isLoading = false;
    @track showTooManyTries = false;
    
    employeeId;
    employeeName;
    employeeRecord;
    isFirstTimeStrongPassword = false;

    get isLoginState() { return this.state === 'login'; }
    get isOtpState() { return this.state === 'otp'; }
    get isCreatePasswordState() { return this.state === 'createPassword'; }
    get isResetRequestState() { return this.state === 'resetRequest'; }
    get passwordsMatch() { 
        return this.newPassword && this.confirmPassword && this.newPassword === this.confirmPassword && this.newPassword.length >= 8; 
    }
    get passwordError() {
        if (this.newPassword && this.newPassword.length < 8) return 'הסיסמה חייבת להכיל לפחות 8 תווים';
        if (this.newPassword && this.confirmPassword && this.newPassword !== this.confirmPassword) return 'הסיסמאות אינן תואמות';
        return '';
    }

    handleUserNameChange(e) { this.userName = e.target.value; }
    handlePasswordChange(e) { this.password = e.target.value; }
    handleOtpChange(e) { 
        const val = e.target.value;
        if (val.length <= 6) this.otp = val; 
    }
    handleNewPasswordChange(e) { this.newPassword = e.target.value; }
    handleConfirmPasswordChange(e) { this.confirmPassword = e.target.value; }
    handleResetEmailChange(e) { this.resetEmail = e.target.value; }
    handleResetPhoneChange(e) { this.resetPhone = e.target.value; }

    async handleLogin() {
        this.errorMsg = '';
        this.successMsg = '';
        if (!this.userName || !this.password) {
            this.errorMsg = 'אנא הזן אימייל וסיסמה';
            return;
        }

        this.isLoading = true;
        try {
            const result = await isValidCredentials({
                userCredentials: { userName: this.userName, password: this.password }
            });

            if (result.isValidCreds) {
                this.employeeRecord = result.employeeRecord;
                this.employeeId = this.employeeRecord.Id;
                this.employeeName = this.employeeRecord.Name;

                if (result.isPhoneUsedAsPassword && !result.isStrongPassword) {
                    // Phone used as password — require OTP then strong password creation
                    this.isFirstTimeStrongPassword = true;
                    await createOtp({ employeeId: this.employeeId });
                    this.state = 'otp';
                } else {
                    // Strong password — go directly to app
                    this.navigateToApp();
                }
            } else {
                if (this.employeeRecord && this.employeeRecord.Login_Attempt__c >= 5) {
                    this.showTooManyTries = true;
                    this.errorMsg = 'חשבונך נחסם עקב ניסיונות כניסה רבים. אנא פנה למנהל.';
                } else {
                    this.errorMsg = 'אימייל או סיסמה שגויים';
                }
            }
        } catch (e) {
            console.error('Login error:', e);
            this.errorMsg = 'שגיאת מערכת. אנא נסה שנית.';
        } finally {
            this.isLoading = false;
        }
    }

    async handleSubmitOtp() {
        this.errorMsg = '';
        if (!this.otp || this.otp.length < 4) {
            this.errorMsg = 'אנא הזן את הקוד שנשלח ב-SMS';
            return;
        }

        this.isLoading = true;
        try {
            const result = await isValidOtp({ employeeId: this.employeeId, otp: this.otp });

            if (result.isOtpValidated) {
                if (this.isFirstTimeStrongPassword) {
                    this.state = 'createPassword';
                } else {
                    this.navigateToApp();
                }
            } else {
                this.errorMsg = 'הקוד שהוזן שגוי';
            }
        } catch (e) {
            console.error('OTP error:', e);
            this.errorMsg = 'שגיאת מערכת';
        } finally {
            this.isLoading = false;
        }
    }

    async handleSavePassword() {
        this.errorMsg = '';
        if (!this.passwordsMatch) {
            this.errorMsg = this.passwordError || 'אנא מלא את שני שדות הסיסמה';
            return;
        }

        this.isLoading = true;
        try {
            const result = await saveStrongPassword({ 
                employeeId: this.employeeId, 
                newPassword: this.newPassword 
            });

            if (result) {
                this.successMsg = 'סיסמה נשמרה בהצלחה!';
                // Wait a moment then navigate
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => { this.navigateToApp(); }, 1500);
            } else {
                this.errorMsg = 'שגיאה בשמירת הסיסמה. הסיסמה חייבת להכיל 8 תווים לפחות.';
            }
        } catch (e) {
            console.error('Save password error:', e);
            this.errorMsg = 'שגיאת מערכת';
        } finally {
            this.isLoading = false;
        }
    }

    openResetPopup() {
        this.resetEmail = '';
        this.resetPhone = '';
        this.errorMsg = '';
        this.state = 'resetRequest';
    }

    closeResetPopup() {
        this.state = 'login';
        this.errorMsg = '';
    }

    async handleResetSubmit() {
        this.errorMsg = '';
        if (!this.resetEmail || !this.resetPhone) {
            this.errorMsg = 'אנא הזן אימייל ומספר טלפון';
            return;
        }

        this.isFirstTimeStrongPassword = true;
        this.isLoading = true;

        try {
            const result = await isValidCredentials({
                userCredentials: { userName: this.resetEmail, password: this.resetPhone }
            });

            if (result.isValidCreds && result.employeeRecord) {
                this.employeeId = result.employeeRecord.Id;
                this.employeeName = result.employeeRecord.Name;
                await createOtp({ employeeId: this.employeeId });
                this.state = 'otp';
            } else {
                this.errorMsg = 'אימייל או מספר טלפון שגויים';
            }
        } catch (e) {
            console.error('Reset error:', e);
            this.errorMsg = 'שגיאת מערכת';
        } finally {
            this.isLoading = false;
        }
    }

    navigateToApp() {
        this.dispatchEvent(new CustomEvent('authenticated', {
            detail: { employeeId: this.employeeId, employeeName: this.employeeName }
        }));
    }
}
