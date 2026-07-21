/**
 * @description Verbiages to be used in the sea time blue app.
 * @author Ceptes
 * @date Saturday-June-29-2024
 **/

import loginButtonLabel from '@salesforce/label/c.loginButtonLabel'
import privateReservationLabel from '@salesforce/label/c.privateReservationLabel'
import loginpageHeaderLabel from '@salesforce/label/c.loginpageHeaderLabel'
import nameOfTheBoat from '@salesforce/label/c.nameOfTheBoat'
import additionalInfo from '@salesforce/label/c.additionalInfo'
import aiPlaceHolder from '@salesforce/label/c.aiPlaceHolder'
import certificate from '@salesforce/label/c.certificate'
import otpHeaderlabel from '@salesforce/label/c.otpHeaderlabel'
import faqsLabel from '@salesforce/label/c.faqsLabel'
import invalidDateVerbiage from '@salesforce/label/c.invalidDateVerbiage'
import incorrectOtpVerbiage from '@salesforce/label/c.incorrectOtpVerbiage'
import incorrectCredentialVerbiage from '@salesforce/label/c.incorrectCredentialVerbiage'
import startTime from '@salesforce/label/c.startTime'
import submitOtpButtonLabel from '@salesforce/label/c.submitOtpButtonLabel'
import Yacht from '@salesforce/label/c.Yacht'
import paswwordLabel from '@salesforce/label/c.paswwordLabel'
import nextReservationLabel from '@salesforce/label/c.nextReservationLabel'
import Confirm from '@salesforce/label/c.Confirm'
import X3_Hours from '@salesforce/label/c.X3_Hours'
import userNamePlaceHolder from '@salesforce/label/c.userNamePlaceHolder'
import endTime from '@salesforce/label/c.endTime'
import Sailboat from '@salesforce/label/c.Sailboat'
import paswwordPlaceHolder from '@salesforce/label/c.paswwordPlaceHolder'
import userNameLabel from '@salesforce/label/c.userNameLabel'
import X2_Hours from '@salesforce/label/c.X2_Hours'
import tooManyTriesVerbiage from '@salesforce/label/c.tooManyTriesVerbiage'
import faqsVerbiage from '@salesforce/label/c.faqsVerbiage'
import loginpageHeaderLabel2 from '@salesforce/label/c.loginpageHeaderLabel2'
import CancelLabel from '@salesforce/label/c.CancelLabel'
import sailingDetails from '@salesforce/label/c.sailingDetails'
import joinClubSailingLabel from '@salesforce/label/c.joinClubSailingLabel'
import date from '@salesforce/label/c.date'
import Catamaran from '@salesforce/label/c.Catamaran'
import cruiseValue from '@salesforce/label/c.cruiseValue'
import addNewReservation from '@salesforce/label/c.addNewReservation'
import typeOfTheBoat from '@salesforce/label/c.typeOfTheBoat'
import otpLabel from '@salesforce/label/c.otpLabel'
import footerLabel from '@salesforce/label/c.sea_time_app_footer_label'
import footerLabel2 from '@salesforce/label/c.sea_time_app_footer_label2'
import weekDays from '@salesforce/label/c.weekDays'
import My_Subscriptions from '@salesforce/label/c.My_Subscriptions'
import Charters from '@salesforce/label/c.Charters'
import privateReservation from '@salesforce/label/c.privateReservation'
import nextReservation from '@salesforce/label/c.nextReservation'
import boatType from '@salesforce/label/c.boatType'
import duration from '@salesforce/label/c.duration'
import newClubCruises from '@salesforce/label/c.newClubCruises'
import recentCruises from '@salesforce/label/c.recentCruises'
import Enriching from '@salesforce/label/c.Enriching'
import Friends from '@salesforce/label/c.Friends'
import Certification from '@salesforce/label/c.Certification'
import Course from '@salesforce/label/c.Course'
import noCruiseAvailable from '@salesforce/label/c.noCruiseAvailable'
import price from '@salesforce/label/c.price'
import reachOutToClub from '@salesforce/label/c.reachOutToClub'
import clubCruiseBookingLabel from '@salesforce/label/c.clubCruiseBookingLabel'
import noSlotLeft from '@salesforce/label/c.noSlotLeft'
import clubCruise from '@salesforce/label/c.clubCruise'
import cruiseTypeLabel from '@salesforce/label/c.cruiseTypeLabel'
import Hour from '@salesforce/label/c.Hour'
import fullyBooked from '@salesforce/label/c.fullyBooked'
import alreadyBooked from '@salesforce/label/c.alreadyBooked'
import Booking from '@salesforce/label/c.Booking'
import slotsLeft from '@salesforce/label/c.slotsLeft'
import boatRequiresCertificate from '@salesforce/label/c.boatRequiresCertificate'
import missingCredentialsVerbiage from '@salesforce/label/c.missingCredentialsVerbiage'
import boatTypeRequired from '@salesforce/label/c.boatTypeRequired'
import Subscription_Check from '@salesforce/label/c.Subscription_Check'
import signupResetPasswordButtonLabel from '@salesforce/label/c.signupResetPasswordButtonLabel'
import signupResetPasswordTitle from '@salesforce/label/c.signupResetPasswordTitle'
import emailLabel from '@salesforce/label/c.emailLabel'
import mobileNumberLabel from '@salesforce/label/c.mobileNumberLabel'
import sendOtpButtonLabel from '@salesforce/label/c.sendOtpButtonLabel'
import createStrongPasswordTitle from '@salesforce/label/c.createStrongPasswordTitle'
import passwordLabel from '@salesforce/label/c.passwordLabel'
import confirmPasswordLabel from '@salesforce/label/c.confirmPasswordLabel'
import submitButtonLabel from '@salesforce/label/c.submitButtonLabel'
import usePasswordErrorMessage from '@salesforce/label/c.usePasswordErrorMessage'
import strongPasswordCreatedSuccessMessage from '@salesforce/label/c.strongPasswordCreatedSuccessMessage'


let main

export default class SeaTimeAppVerbiages {

    constructor(superMain) {
        main = superMain
    }

    loadLoginPageVerbiages() {
        main.incorrectCredentialVerbiage = incorrectCredentialVerbiage
        main.incorrectOtpVerbiage = incorrectOtpVerbiage
        main.tooManyTriesVerbiage = tooManyTriesVerbiage
        main.faqsVerbiage = faqsVerbiage
        main.missingCredentialsVerbiage = missingCredentialsVerbiage
        main.usePasswordErrorMessage = usePasswordErrorMessage
        main.strongPasswordCreatedSuccessMessage = strongPasswordCreatedSuccessMessage
    }

    loadLoginPageLabels() {
        main.userNameLabel = userNameLabel
        main.paswwordLabel = paswwordLabel
        main.userNamePlaceHolder = userNamePlaceHolder
        main.paswwordPlaceHolder = paswwordPlaceHolder
        main.loginButtonLabel = loginButtonLabel
        main.otpLabel = otpLabel
        main.otpHeaderlabel = otpHeaderlabel
        main.submitOtpButtonLabel = submitOtpButtonLabel
        main.loginpageHeaderLabel = loginpageHeaderLabel
        main.loginpageHeaderLabel2 = loginpageHeaderLabel2
        main.faqsLabel = faqsLabel
        main.signupResetPasswordButtonLabel = signupResetPasswordButtonLabel
        main.signupResetPasswordTitle = signupResetPasswordTitle
        main.emailLabel = emailLabel
        main.mobileNumberLabel = mobileNumberLabel
        main.sendOtpButtonLabel = sendOtpButtonLabel
        main.createStrongPasswordTitle = createStrongPasswordTitle
        main.passwordLabel = passwordLabel
        main.confirmPasswordLabel = confirmPasswordLabel
        main.submitButtonLabel = submitButtonLabel
        main.cancelLabel = CancelLabel
    }

    loadHomePageLabels() {
        main.privateReservationLabel = privateReservationLabel
        main.joinClubSailingLabel = joinClubSailingLabel
        main.chartersLabel = Charters
        main.mySubscriptionLabel = My_Subscriptions
        main.hour = Hour
        main.fullyBooked = fullyBooked
        main.alreadyBooked = alreadyBooked
        main.booking = Booking
    }

    loadFooterVerbiages() {
        main.footerLabel = footerLabel
        main.footerLabel2 = footerLabel2
    }

    loadPrivateReservationLabels() {
        const WEEK_DAYS_ARRAYS = weekDays.split(';')
        main.daysArray = [{ label: WEEK_DAYS_ARRAYS[6], value: 'Sat', selector: 'day-button', index: 6 },
        { label: WEEK_DAYS_ARRAYS[5], value: 'Fri', selector: 'day-button', index: 5 },
        { label: WEEK_DAYS_ARRAYS[4], value: 'Thu', selector: 'day-button', index: 4 },
        { label: WEEK_DAYS_ARRAYS[3], value: 'Wed', selector: 'day-button', index: 3 },
        { label: WEEK_DAYS_ARRAYS[2], value: 'Tue', selector: 'day-button', index: 2 },
        { label: WEEK_DAYS_ARRAYS[1], value: 'Mon', selector: 'day-button', index: 1 },
        { label: WEEK_DAYS_ARRAYS[0], value: 'Sun', selector: 'day-button', index: 0 }]

        main.boatTypesArray = [{ label: Sailboat, value: 'Sailboat', selector: 'slds-button slds-button_brand light-button search-button' },
        { label: Catamaran, value: 'Catamaran', selector: 'slds-button slds-button_brand light-button search-button' },
        { label: Yacht, value: 'Yacht', selector: 'slds-button slds-button_brand dark-button search-button' }]

        main.boatDurationArray = [{ label: X3_Hours, selector: 'slds-button slds-button_brand light-button search-button' },
        { label: X2_Hours, selector: 'slds-button slds-button_brand dark-button search-button' }]
        
        main.nextReservationLabel = nextReservationLabel
        main.addNewReservation = addNewReservation
        main.invalidDateVerbiage = invalidDateVerbiage
        main.boatType = boatType
        main.duration = duration
        main.privateReservation = privateReservation
        main.nextReservation = nextReservation
        main.submit = submitOtpButtonLabel
        main.catamaran = Catamaran
        main.yacht = Yacht
        main.x3_Hours = X3_Hours
        main.x2_Hours = X2_Hours
        main.boatTypeRequired = boatTypeRequired
        main.Subscription_Check= Subscription_Check
        
    }

    loadBookPrivateBoatVerbiages() {
        main.sailingDetails = sailingDetails
        main.date = date
        main.nameOfTheBoat = nameOfTheBoat
        main.additionalInfo = additionalInfo
        main.aiPlaceHolder = aiPlaceHolder
        main.typeOfTheBoat = typeOfTheBoat
        main.startTime = startTime
        main.endTime = endTime
        main.cruiseValue = cruiseValue
        main.confirm = Confirm
        main.cancel = CancelLabel
        main.certificate = certificate
        main.needSkipperLabel = 'זקוק לסקיפר (בתוספת תשלום לפי מחירון המועדון)';
        
        main.boatRequiresCertificate = boatRequiresCertificate;
    }

    loadClubCruisesLabels() {
        main.newClubCruises = newClubCruises
        main.clubCruise = clubCruise
        main.recentCruises = recentCruises
        main.cruiseTypesArray = [{ label: Enriching, value: 'Enriching' },
        { label: Friends, value: 'Friends' },
        { label: Certification, value: 'Certification' },
        { label: Course, value: 'Course' }]
        main.noCruiseAvailable = noCruiseAvailable
        main.price = price
        main.slotsLeft = slotsLeft
        main.cruiseTypeLabel = cruiseTypeLabel
    }

    loadBookClubCruiseLabels() {
        main.reachOutToClub = reachOutToClub
        main.clubCruiseBookingLabel = clubCruiseBookingLabel
        main.cancel = CancelLabel
        main.confirm = Confirm
        main.noSlotLeft = noSlotLeft
    }
}