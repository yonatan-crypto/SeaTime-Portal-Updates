import { LightningElement,wire, track } from 'lwc';
import Id from '@salesforce/user/Id';
import UserNameFIELD from '@salesforce/schema/User.Name';
import LanguageLocaleKeyField from '@salesforce/schema/User.LanguageLocaleKey';
import LocaleSidKeyField from '@salesforce/schema/User.LocaleSidKey';
import isguest from '@salesforce/user/isGuest';
import subscriptionDetails from '@salesforce/label/c.subscriptionDetails';

import { getRecord } from 'lightning/uiRecordApi';
export default class UserDetail extends LightningElement {
    labels={subscriptionDetails}
@track userId = Id;
@track currentUserLanguage;
@track currentUserLocale;
@track currentUserName;
isGuestUser = isguest;

@wire(getRecord, { recordId: Id, fields: [UserNameFIELD, LanguageLocaleKeyField, LocaleSidKeyField ]}) 
    currentUserInfo({error, data}) {
        if (data) {
  
            this.currentUserName = data.fields.Name.value;
            this.currentUserLanguage = data.fields.LanguageLocaleKey.value;
            this.currentUserLocale = data.fields.LocaleSidKey.value;
        } else if (error) {
          console.log(error);
            this.error = error ;
        }
    }

}