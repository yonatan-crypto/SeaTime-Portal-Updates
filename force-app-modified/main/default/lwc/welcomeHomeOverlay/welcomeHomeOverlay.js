import { LightningElement, track } from 'lwc';
import getWelcomeOverlayConfig from '@salesforce/apex/LoginPageAppController.getWelcomeOverlayConfig';
//import FORM_FACTOR from '@salesforce/client/formFactor';

export default class WelcomeHomeOverlay extends LightningElement {
    @track iframeUrl;
    @track overlayBg = 'transparent';
    @track blockPage = true;

   /* get showOverlay() {
        return FORM_FACTOR === 'Large';
    }*/

    get showOverlay() {
        return true;
    }

    connectedCallback() {
        if (this.showOverlay) {
            getWelcomeOverlayConfig()
                .then((config) => {
                    this.iframeUrl = config.overlayUrl;
                    this.overlayBg = config.overlayBg || 'transparent';
                    this.blockPage = config.blockPage;
                })
                .catch((error) => {
                    console.error(error);
                });
        }
    }

    get overlayStyle() {
        return `background:${this.overlayBg};`;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}