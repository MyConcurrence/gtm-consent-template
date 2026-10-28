# Concurrence CMP for Google Tag Manager

Tag template that loads the Concurrence consent banner and updates Google Consent Mode v2.

## Install

1. In Google Tag Manager, open **Templates** → **Tag Templates** → **Search Gallery** and add **Concurrence CMP**. Until the gallery listing is live, import `template.tpl` with **Templates** → **New** → menu → **Import**.
2. Create a tag from that template.
3. Enter the **Brand ID** from Concurrence Brand → Consent Management.
4. Leave **Consent origin** at `https://consent.myconcurrence.com` unless Concurrence gives you another https origin.
5. Leave the default consent table empty, or add one row with a blank region and all four signals **Denied**. That applies to every country. Add extra rows only when a region needs a different default.
6. Set the tag’s trigger to **Consent Initialization - All Pages**.
7. Do not also paste the Concurrence CDN snippet on the page. The template loads the banner.

The banner appears for every visitor. There is no country gate.

## What the tag does

- Sets `ad_storage`, `analytics_storage`, `ad_user_data`, and `ad_personalization` before other tags fire.
- Waits up to the configured time for a decision already saved for that visitor.
- Updates those four signals when the visitor makes or changes a choice.
- Does not grant advertising storage for a first-party Concurrence decision. A TCF configuration can grant a signal when the matching purposes are allowed.

## Gallery publish

This repository root must contain `template.tpl`, `metadata.yaml`, and `LICENSE`. Enable GitHub Issues.

`metadata.yaml` points at the commit that contains this `template.tpl`. Submit https://github.com/MyConcurrence/gtm-consent-template at [tagmanager.google.com/gallery](https://tagmanager.google.com/gallery).

The gallery link exists after Google approves the template. Loader `0.2.9` must be on `https://cdn.myconcurrence.com/cmp/releases/0.2.9/loader.min.js` before reviewers load the tag.
