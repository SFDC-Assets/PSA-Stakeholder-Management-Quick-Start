# SMQS Telemetry & Feedback System — Build Plan

## Executive Summary

The Stakeholder Management Quick Start (SMQS) is distributed as an unmanaged package with no native Salesforce mechanism to track installations or collect user feedback. This plan describes a lightweight, privacy-respecting system to address both needs.

**What it does:**
- Records which Salesforce orgs have installed SMQS (org name and org ID only — no personal information) as GitHub Issues in a private telemetry repository
- Provides an in-app screen for administrators to submit anonymous feedback and bug reports, which create GitHub Issues in the main repository
- Gives the GPS Accelerator team a publisher-controlled kill switch to close feedback collection at any time via a single environment variable

**What it does not do:**
- Collect any personally identifiable information
- Provide support — submissions are anonymous and no response is guaranteed
- Require any configuration by the subscriber org administrator beyond installing the package
- Require a Salesforce publisher org

**Key design choices:**
- No Apex code in the package — all subscriber-side logic runs in a Screen Flow and Named Credential
- A single LWC wraps the Flow and can be placed on any App page or utility bar
- A thin proxy function (Vercel, free tier, ~50 lines of JavaScript) sits between the subscriber org and the GitHub API, protecting the GitHub token and hosting the kill switch
- The proxy URL is the only publicly visible endpoint — the GitHub token never leaves the proxy's environment variables
- Feedback collection is gated on Salesforce System Administrator profile by default
- Two explicit consent checkboxes are required before any data is transmitted

---

## Architecture Overview

```
Subscriber Org (SMQS installed)       Proxy Function (Vercel)     GitHub
────────────────────────────────      ───────────────────────     ──────────────────────────
smqsPackageSupport (LWC)              POST /register          →   Issue: private telemetry repo
  └─ SMQS_PackageSupportFlow          GET  /status            →   Reads FEEDBACK_ENABLED env var
       └─ External Service calls      POST /feedback          →   Issue: main SMQS repo
            └─ Named Credential
                 (No Auth, ships
                  in pkg)
```

The LWC is a thin wrapper that renders the Screen Flow. All business logic — admin check, registration state, consent, status check, feedback submission — lives in the Flow. No Apex is required in the subscriber org.

The proxy function holds the GitHub Personal Access Token as an environment variable. It is never in the package, never in the repository, and never visible to subscriber org admins. The Named Credential in the package points only to the proxy URL.

**Why two GitHub repositories:**
- Registration issues (org name + org ID) go to a **private** repository to keep installation data off a public issue tracker
- Feedback issues go to the **main public SMQS repository** so the community can see reported bugs and feature requests

---

## Data Collected

### Transmitted to proxy at registration

| Field | Value |
|---|---|
| Org ID | `UserInfo.getOrganizationId()` — 18-character Salesforce org identifier |
| Org Name | `UserInfo.getOrganizationName()` |
| Package Version | Static value stored in `SMQS_PackageConfig__c` at deploy time |

**No personal information is collected.** No names, emails, usernames, or contact details are transmitted at any point. Feedback submissions are anonymous — there is no mechanism to reply to a submission.

### Stored in GitHub per registration

GitHub Issue in private telemetry repo, label: `installation`

```
Title:   [Registration] <Org Name> (<Org ID>)
Body:    Org ID: <orgId>
         Org Name: <orgName>
         Package Version: <packageVersion>
         Registered At: <ISO timestamp>
```

One issue per org. The proxy searches for an existing open issue by org ID title pattern before creating — duplicate registrations add a comment to the existing issue instead of opening a new one.

### Stored in GitHub per feedback submission

GitHub Issue in main SMQS repo, label: `smqs-feedback` + one of `bug`, `enhancement`, or `feedback`

```
Title:   <User-entered subject>
Body:    **Type:** <Bug Report | Feature Request | General Feedback>
         **Org ID:** <orgId>
         **Package Version:** <packageVersion>

         <User-entered description>
```

---

## Proxy Function Infrastructure (Phase 1)

A single Vercel project with three serverless functions. Vercel free tier supports up to 100,000 invocations/month — sufficient for this use case.

### Environment variables (set in Vercel dashboard — never in code)

| Variable | Purpose |
|---|---|
| `GITHUB_TOKEN` | Personal Access Token with `repo` scope on both repositories |
| `FEEDBACK_ENABLED` | `"true"` or `"false"` — the kill switch |
| `TELEMETRY_REPO` | `owner/private-smqs-telemetry` |
| `FEEDBACK_REPO` | `owner/PSA-Stakeholder-Management-Quick-Start-DEV-1` |

### Endpoints

**`POST /register`**

Accepts: `{ orgId, orgName, packageVersion }`

Behavior:
- Validates org ID format (15/18 char alphanumeric) — rejects invalid payloads with 400
- Searches private repo for existing issue with org ID in title
- If found: adds a comment with updated timestamp and version; returns existing issue number
- If not found: creates new issue with `installation` label
- Returns: `{ "status": "ok", "registrationId": "<issue number>" }`

**`GET /status`**

Accepts: no parameters

Behavior:
- Reads `FEEDBACK_ENABLED` environment variable
- Returns: `{ "feedbackEnabled": true }` or `{ "feedbackEnabled": false }`

**`POST /feedback`**

Accepts: `{ registrationId, type, subject, description, orgId, packageVersion }`

Behavior:
- Checks `FEEDBACK_ENABLED` — returns `{ "status": "disabled" }` immediately if false
- Validates field lengths (subject ≤ 200 chars, description ≤ 2000 chars)
- Validates `type` is one of the three allowed values
- Creates GitHub Issue in main SMQS repo with appropriate labels
- Returns: `{ "status": "ok" }` or `{ "status": "disabled" }`

### Abuse mitigations (in proxy)

- Org ID format validation on all endpoints
- Input field length caps before hitting the GitHub API
- GitHub's own authenticated rate limit (5,000 requests/hour) is the outer bound
- `FEEDBACK_ENABLED` kill switch cuts off all feedback creation instantly
- Registration deduplication prevents issue spam from repeated registrations

---

## Package Components (Phases 2–4)

### Named Credential — `SMQS_TelemetryEndpoint`

- URL: Vercel proxy URL (e.g., `https://smqs-telemetry.vercel.app`)
- Authentication: No Authentication
- Ships in the package
- Bypasses Remote Site Settings requirement — no subscriber org admin action needed

### External Service Registration — `SMQS_PublisherAPI`

OpenAPI spec defining the three endpoints (`/register`, `/status`, `/feedback`). Ships in the package. Exposes invocable actions that the Screen Flow calls directly.

### Custom Setting (Hierarchy) — `SMQS_PackageConfig__c`

Writable at runtime by Flow's Update Records element.

| Field | Type | Notes |
|---|---|---|
| `Registration_Id__c` | Text(20) | GitHub Issue number, populated after first successful registration |
| `Package_Version__c` | Text(20) | Static value set at deploy time |

Custom Metadata is not used here — it cannot be written by Flow at runtime.

### Permission Set — `SMQS_Feedback_Submitter`

Ships unassigned. Grants non-admin users access to the feedback form. Admins assign this deliberately; no one has it by default.

### LWC — `smqsPackageSupport`

Thin wrapper component:

```html
<lightning-flow flow-api-name="SMQS_PackageSupportFlow"></lightning-flow>
```

Placement options: SMQS App home page, utility bar item.

### Screen Flow — `SMQS_PackageSupportFlow`

Full logic sequence:

```
START
 │
 ├─ [Get Records] SMQS_PackageConfig__c (org-level)
 ├─ [Get Records] Profile WHERE Id = $User.ProfileId → check PermissionsModifyAllData
 │
 ├─ [Decision] Is user a System Admin OR has SMQS_Feedback_Submitter permission set?
 │   └─ No → Screen: Access Restricted
 │             "This feature is available to Salesforce administrators only."
 │
 ├─ [Decision] Registration_Id__c populated?
 │   │
 │   ├─ NO  → Screen: Terms of Use + Consent
 │   │         [Terms text rendered verbatim — see below]
 │   │         [Checkbox 1 required] I ACCEPT THE ABOVE TERMS OF USE FOR THIS ACCELERATOR
 │   │         [Checkbox 2 required] I consent to sending my organization's name and
 │   │             Salesforce Org ID to the GPS Accelerator team for the purpose of
 │   │             tracking active installations.
 │   │         [Informational note] Only your org name and org ID are transmitted.
 │   │             No personal information is collected. There is no way to reply
 │   │             to feedback submissions.
 │   │         → [Action] Call /register (orgId, orgName, packageVersion)
 │   │         → [Update Records] SMQS_PackageConfig__c.Registration_Id__c
 │   │
 │   └─ YES → skip registration
 │
 ├─ [Action] Call /status → { feedbackEnabled: true/false }
 │
 ├─ [Decision] feedbackEnabled?
 │   │
 │   ├─ NO  → Screen: Feedback Closed
 │   │         "Feedback is not currently being accepted."
 │   │         "For Salesforce product support, [Salesforce Support](https://help.salesforce.com/s/support)."
 │   │         "For questions and conversation, visit the [Trailblazer Community](https://trailhead.salesforce.com/trailblazer-community)."
 │   │
 │   └─ YES → Screen: Feedback Form
 │             ─────────────────────────────────────────────────────
 │             [Banner — always visible, non-dismissible]
 │             "Feedback is anonymous. Only your org name and org ID
 │              are associated with this submission. No response is
 │              guaranteed and no support is provided through this
 │              channel.
 │              For Salesforce product support, [Salesforce Support](https://help.salesforce.com/s/support).
 │              For questions and conversation, visit the
 │              [Trailblazer Community](https://trailhead.salesforce.com/trailblazer-community)."
 │             ─────────────────────────────────────────────────────
 │             Type (picklist): Bug Report / Feature Request / General Feedback
 │             Subject (text, required)
 │             Description (textarea)
 │             ─────────────────────────────────────────────────────
 │             → [Action] Call /feedback (registrationId, type, subject, description, orgId, packageVersion)
 │             │
 │             ├─ status=disabled → Screen: Feedback Closed (same as above)
 │             └─ status=ok       → Screen: Success
 │                                   "Thank you. Your feedback has been received."
 │                                   (no issue number shown — submission is anonymous)
```

---

## Terms of Use Text

Rendered verbatim on the registration screen:

---

**Terms of Use**

Please scroll to review and accept the terms and conditions that govern the use of this Accelerator.

Thank you for using Public Sector Accelerators. Accelerators are provided by Salesforce.com, Inc., located at 1 Market Street, San Francisco, CA 94105, United States.

By using these accelerators, you are agreeing to these terms. Please read them carefully.

1. Accelerators are not supported by Salesforce, they are supplied as-is, and are meant to be a starting point for your organization. Salesforce is not liable for the use of accelerators.
2. In addition, this accelerator tool is intended to provide capabilities for Customers to configure and optimize use of their implemented Salesforce Services. Customers should ensure that their use of this tool meets their own use case needs and compliance requirements (including any applicable public sector and privacy laws, rules, and regulations).

---

---

## Risks

### R1 — Proxy URL is publicly visible (High likelihood, Low impact)

**Risk:** The proxy URL ships in the Named Credential inside the unmanaged package and is visible on GitHub. Anyone can call the proxy endpoints directly, creating fake registration issues or spamming the feedback repo.

**Mitigations:**
- Org ID format validation rejects malformed payloads immediately
- Registration deduplication (comment on existing issue) makes repeated calls harmless
- Feedback input is capped at reasonable lengths before hitting the GitHub API
- Kill switch (`FEEDBACK_ENABLED=false`) stops all issue creation instantly
- GitHub Issues in the feedback repo are publicly visible anyway — the only harm from spam is noise, which can be closed/labeled by maintainers
- Private telemetry repo spam is constrained by the same rate limiting

**Residual risk:** Manageable noise. Not a data breach risk.

---

### R2 — GitHub token exposure (Low likelihood, High impact)

**Risk:** The GitHub PAT in the proxy's environment variables grants `repo` scope. If the Vercel project is misconfigured and environment variables are accidentally exposed (e.g., returned in a response body), the token could be used to push code or delete issues.

**Mitigations:**
- Token is a fine-grained PAT scoped to only the two specific repositories with Issues write permission only — not full `repo` scope
- Vercel environment variables are never returned in function responses (enforced in code)
- Token should be rotated annually or on any suspected exposure
- Vercel project access is restricted to GPS Accelerator team members only

**Residual risk:** Low if token is correctly scoped. Use a fine-grained PAT, not a classic PAT.

---

### R3 — Shared secret not viable (Known limitation)

**Risk:** Because the package is unmanaged and source is public, any secret baked into the package (HMAC key, static API token) is immediately discoverable. It provides a speed bump only, not real security.

**Decision:** No shared secret is used. The proxy URL is treated as public. Mitigations rely on server-side validation, idempotency, and the kill switch instead. This is documented here so it is not revisited as a future "improvement" — it is not an improvement for an unmanaged package.

---

### R4 — Custom Setting readable in subscriber org (Low likelihood, Low impact)

**Risk:** `SMQS_PackageConfig__c` stores the `Registration_Id__c` (a GitHub Issue number). This value is visible to any user who can query Custom Settings in the subscriber org. A malicious user could call `/feedback` with a valid registration ID and org ID to submit feedback attributed to their org.

**Mitigation:** This is the intended behavior — the submission is still attributed to their org. The only harm is noise in the feedback repo, which maintainers can close. There is no sensitive data at risk.

---

### R5 — Proxy function availability (Low likelihood, Medium impact)

**Risk:** If the Vercel deployment is unavailable, registration and feedback calls fail silently. The subscriber org's Flow would show an error state.

**Mitigations:**
- Vercel free tier has 99.9% uptime SLA for serverless functions
- Flow handles errors gracefully — a failed callout shows a friendly error message, not an uncaught exception
- Registration failure does not block access to the rest of the SMQS app
- Vercel deployment can be redeployed in minutes from the GitHub-connected project

---

### R6 — No response capability is permanent (Known limitation)

**Risk:** By design, there is no contact information on submissions. If a user submits a bug report, there is no way to follow up with them. This is intentional for privacy but means feedback is one-directional.

**Mitigation:** The feedback form, success screen, and feedback closed screen all direct users to the Trailblazer Community for discussion. Users who want a conversation have a clear path.

---

### R7 — Kill switch latency (Low likelihood, Low impact)

**Risk:** The `/status` check happens when the Flow loads. If the kill switch is flipped between a user opening the form and submitting it, the `/feedback` endpoint returns `status=disabled` and the Flow shows the Feedback Closed screen.

**Mitigation:** Already handled — the Flow checks the `/feedback` response and routes to the Feedback Closed screen on `status=disabled`. No orphaned submissions possible.

---

### R8 — Registration data visible in private repo (Low likelihood, Low impact)

**Risk:** Org names and org IDs are stored as GitHub Issues in a private repository. Anyone with access to that repository can see which orgs have installed SMQS.

**Mitigation:** Access to the private telemetry repository is restricted to GPS Accelerator team members. The data collected (org name + org ID) is low sensitivity — org IDs are not secrets and org names are not PII. This risk is noted in the consent checkbox shown to the registering admin.

---

## What Ships in the Package vs. External Infrastructure

| Component | Location |
|---|---|
| `smqsPackageSupport` LWC | SMQS unmanaged package |
| `SMQS_PackageSupportFlow` Screen Flow | SMQS unmanaged package |
| `SMQS_TelemetryEndpoint` Named Credential | SMQS unmanaged package |
| `SMQS_PublisherAPI` External Service | SMQS unmanaged package |
| `SMQS_PackageConfig__c` Custom Setting | SMQS unmanaged package |
| `SMQS_Feedback_Submitter` Permission Set | SMQS unmanaged package |
| Vercel proxy project + 3 functions | Vercel (GPS Accelerator team) |
| `GITHUB_TOKEN` + `FEEDBACK_ENABLED` env vars | Vercel environment (never in code) |
| Registration issues | Private GitHub telemetry repo |
| Feedback issues | Main SMQS GitHub repo |

---

## Release Checklist

Before publishing a new package version:

- [ ] Update `Package_Version__c` value in `SMQS_PackageConfig__c` default record
- [ ] Verify Named Credential URL still points to active Vercel deployment
- [ ] Smoke test: register → check issue created in private telemetry repo
- [ ] Smoke test: submit feedback → check issue created in main SMQS repo with correct labels
- [ ] Smoke test: set `FEEDBACK_ENABLED=false` in Vercel → verify Feedback Closed screen appears
- [ ] Confirm Terms of Use text matches current approved version
- [ ] Confirm GitHub PAT has not expired (check token expiry in GitHub Settings)
