import { LightningElement, api } from 'lwc'
import { NavigationMixin } from 'lightning/navigation'
import { CurrentPageReference } from 'lightning/navigation'

export default class SeaTimeAppNavigation extends NavigationMixin(LightningElement) {

    @api
    navigateToAppPage(name, state) {
        this.pageReference = {
            type: 'comm__namedPage',
            attributes: {
                name //api name of community page
            },
            state
        }

        this[NavigationMixin.GenerateUrl](this.pageReference)

        this[NavigationMixin.Navigate](this.pageReference)
    }

    renderedCallback() {
        if (this._hasInjectedStyle) return;
        this._hasInjectedStyle = true;

        // Salesforce Experience Cloud renders the language picker as an LWC component.
        // Its INTERNAL elements are in a Shadow DOM that querySelectorAll cannot reach.
        // Strategy: target HOST element tags directly (e.g. <c-language-selector>)
        // AND inject CSS that collapses those host elements.
        
        const LWC_HOST_SELECTORS = [
            'c-language-selector',
            'comm-language-selector-button',
            'c-comm-language-selector',
            'comm-language-selector',
            'c-language-picker',
            'force-community-language-selector',
        ];

        const CSS_SELECTORS = [
            '.language-selector',
            '.forceCommunityLanguageSelector',
            '[class*="languageSelector"]',
            '.slds-button[title*="Hebrew"]',
            '.slds-button[title*="עברית"]',
            '.head-m-language-selector',
            '.language-picker',
            '.languageSelector',
            '.community_language-selector',
        ];

        const ALL_SELECTORS = [...LWC_HOST_SELECTORS, ...CSS_SELECTORS];

        const hideAll = () => {
            ALL_SELECTORS.forEach(sel => {
                document.querySelectorAll(sel).forEach(el => {
                    el.style.setProperty('display', 'none', 'important');
                    el.style.setProperty('visibility', 'hidden', 'important');
                    el.style.setProperty('max-width', '0', 'important');
                    el.style.setProperty('max-height', '0', 'important');
                    el.style.setProperty('overflow', 'hidden', 'important');
                    el.style.setProperty('opacity', '0', 'important');
                    el.style.setProperty('pointer-events', 'none', 'important');
                });
            });
        };

        // Inject CSS that targets BOTH LWC host elements and class-based selectors
        const hostCssBlock = LWC_HOST_SELECTORS.map(s => s).join(', ');
        const classCssBlock = CSS_SELECTORS.join(', ');
        const styleText = `
            ${hostCssBlock},
            ${classCssBlock} {
                display: none !important;
                visibility: hidden !important;
                max-width: 0 !important;
                max-height: 0 !important;
                overflow: hidden !important;
                opacity: 0 !important;
                pointer-events: none !important;
                position: absolute !important;
                left: -9999px !important;
                margin: 0 !important;
                padding: 0 !important;
            }
        `;

        const injectStyle = (doc) => {
            if (!doc || !doc.head) return;
            // Avoid double-injecting
            if (doc.getElementById('sea-time-lang-kill')) return;
            const style = doc.createElement('style');
            style.id = 'sea-time-lang-kill';
            style.textContent = styleText;
            doc.head.appendChild(style);
        };

        injectStyle(document);
        try { if (window.top && window.top !== window) injectStyle(window.top.document); } catch(e) {}

        // Initial hide
        hideAll();

        // MutationObserver Guardian — watches for any new elements added to the DOM
        const observer = new MutationObserver(hideAll);
        observer.observe(document.documentElement, {
            childList: true,
            subtree: true
        });

        // Interval for 60 seconds as backup (every 500ms — less CPU aggressive)
        let elapsed = 0;
        const killInterval = setInterval(() => {
            hideAll();
            elapsed += 500;
            if (elapsed >= 60000) clearInterval(killInterval);
        }, 500);
    }
}