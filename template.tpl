___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.

___INFO___

{
  "type": "TAG",
  "id": "concurrence_cmp",
  "version": 1,
  "securityGroups": [],
  "displayName": "Concurrence CMP",
  "categories": ["TAG_MANAGEMENT", "PERSONALIZATION"],
  "description": "Loads the Concurrence consent banner and sends Consent Mode v2 defaults and updates to Google tags. Trigger on Consent Initialization - All Pages.",
  "containerContexts": ["WEB"]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "brandId",
    "displayName": "Brand ID",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "help": "The brand id from Concurrence Brand → Consent Management."
  },
  {
    "type": "TEXT",
    "name": "consentOrigin",
    "displayName": "Consent origin",
    "simpleValueType": true,
    "defaultValue": "https://consent.myconcurrence.com",
    "help": "Leave the default unless Concurrence gives you a different https origin."
  },
  {
    "type": "TEXT",
    "name": "waitForUpdate",
    "displayName": "Wait for update (milliseconds)",
    "simpleValueType": true,
    "defaultValue": "2000",
    "help": "How long Google tags wait for a stored decision before firing. Minimum 500."
  },
  {
    "type": "PARAM_TABLE",
    "name": "defaultSettings",
    "displayName": "Default consent state",
    "help": "Leave the region blank to apply the row everywhere. Add rows for ISO 3166-2 regions when a region needs a different default. An empty table denies all four signals in every region.",
    "paramTableColumns": [
      {
        "param": {
          "type": "TEXT",
          "name": "region",
          "displayName": "Region (blank = all regions)",
          "simpleValueType": true,
          "canBeEmptyString": true,
          "help": "Comma-separated ISO 3166-2 codes, for example AT, DE, US-CA."
        },
        "isUnique": true
      },
      {
        "param": {
          "type": "SELECT",
          "name": "ad_storage",
          "displayName": "ad_storage",
          "selectItems": [
            { "value": "denied", "displayValue": "Denied" },
            { "value": "granted", "displayValue": "Granted" }
          ],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "ad_user_data",
          "displayName": "ad_user_data",
          "selectItems": [
            { "value": "denied", "displayValue": "Denied" },
            { "value": "granted", "displayValue": "Granted" }
          ],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "ad_personalization",
          "displayName": "ad_personalization",
          "selectItems": [
            { "value": "denied", "displayValue": "Denied" },
            { "value": "granted", "displayValue": "Granted" }
          ],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "analytics_storage",
          "displayName": "analytics_storage",
          "selectItems": [
            { "value": "denied", "displayValue": "Denied" },
            { "value": "granted", "displayValue": "Granted" }
          ],
          "simpleValueType": true,
          "defaultValue": "denied"
        },
        "isUnique": false
      }
    ]
  },
  {
    "type": "CHECKBOX",
    "name": "ads_data_redaction",
    "checkboxText": "Redact ads data when ad_storage is denied",
    "simpleValueType": true,
    "defaultValue": true
  },
  {
    "type": "CHECKBOX",
    "name": "url_passthrough",
    "checkboxText": "Pass ad click and analytics identifiers through URLs",
    "simpleValueType": true,
    "defaultValue": false
  },
  {
    "type": "LABEL",
    "name": "triggerHelp",
    "displayName": "Fire this tag on the Consent Initialization - All Pages trigger. Do not also paste the Concurrence CDN snippet on the page."
  }
]

___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const log = require('logToConsole');
const makeNumber = require('makeNumber');
const makeString = require('makeString');
const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const gtagSet = require('gtagSet');
const setInWindow = require('setInWindow');
const injectScript = require('injectScript');
const callInWindow = require('callInWindow');
const copyFromWindow = require('copyFromWindow');

const LOADER_URL = 'https://cdn.myconcurrence.com/cmp/releases/0.2.9/loader.min.js';
const SIGNALS = ['ad_storage', 'ad_user_data', 'ad_personalization', 'analytics_storage'];

const splitRegions = (input) => {
  const raw = makeString(input || '');
  if (!raw) return [];
  const parts = raw.split(',');
  const out = [];
  for (let i = 0; i < parts.length; i++) {
    const region = parts[i].trim();
    if (region) out.push(region);
  }
  return out;
};

const parseCommandData = (settings) => {
  const commandData = {};
  const regions = splitRegions(settings.region);
  if (regions.length) commandData.region = regions;
  for (let i = 0; i < SIGNALS.length; i++) {
    const key = SIGNALS[i];
    const value = settings[key];
    commandData[key] = value === 'granted' ? 'granted' : 'denied';
  }
  return commandData;
};

const onUserConsent = (consent) => {
  if (!consent) return;
  const update = {};
  let any = false;
  for (let i = 0; i < SIGNALS.length; i++) {
    const key = SIGNALS[i];
    const value = consent[key];
    if (value === 'granted' || value === 'denied') {
      update[key] = value;
      any = true;
    }
  }
  if (any) updateConsentState(update);
};

const main = () => {
  const brandId = makeString(data.brandId || '').trim();
  if (!brandId) {
    log('Concurrence CMP requires a brand id.');
    data.gtmOnFailure();
    return;
  }

  let origin = makeString(data.consentOrigin || '').trim();
  if (!origin) origin = 'https://consent.myconcurrence.com';
  if (origin.indexOf('https://') !== 0) {
    log('Concurrence CMP consent origin must be https.');
    data.gtmOnFailure();
    return;
  }
  while (origin.length && origin.charAt(origin.length - 1) === '/') {
    origin = origin.substring(0, origin.length - 1);
  }

  gtagSet('ads_data_redaction', data.ads_data_redaction);
  gtagSet('url_passthrough', data.url_passthrough);

  let wait = makeNumber(data.waitForUpdate);
  if (!wait || wait < 500) wait = 500;

  const rows = data.defaultSettings && data.defaultSettings.length ? data.defaultSettings : [{}];
  for (let i = 0; i < rows.length; i++) {
    const commandData = parseCommandData(rows[i] || {});
    commandData.wait_for_update = wait;
    setDefaultConsentState(commandData);
  }

  setInWindow('__concurrenceGtmConsent', true, true);
  setInWindow('__concurrenceCmpBootstrap', {
    brandId: brandId,
    consentOrigin: origin
  }, true);

  injectScript(LOADER_URL, () => {
    const api = copyFromWindow('ConcurrenceCMP');
    if (!api) {
      log('Concurrence CMP loader did not start.');
      data.gtmOnFailure();
      return;
    }
    callInWindow('ConcurrenceCMP.addConsentListener', onUserConsent);
    data.gtmOnSuccess();
  }, () => {
    log('Concurrence CMP loader failed to load.');
    data.gtmOnFailure();
  });
};

main();

___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": { "publicId": "logging", "versionId": "1" },
      "param": [
        {
          "key": "environments",
          "value": { "type": 1, "string": "debug" }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "inject_script", "versionId": "1" },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              { "type": 1, "string": "https://cdn.myconcurrence.com/cmp/releases/0.2.9/loader.min.js" }
            ]
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "access_globals", "versionId": "1" },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "__concurrenceGtmConsent" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "__concurrenceCmpBootstrap" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ConcurrenceCMP" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": false }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ConcurrenceCMP.addConsentListener" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              }
            ]
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "write_data_layer", "versionId": "1" },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              { "type": 1, "string": "ads_data_redaction" },
              { "type": 1, "string": "url_passthrough" }
            ]
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": { "publicId": "access_consent", "versionId": "1" },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_storage" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_user_data" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_personalization" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "analytics_storage" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": true }
                ]
              }
            ]
          }
        }
      ]
    },
    "isRequired": true
  }
]
