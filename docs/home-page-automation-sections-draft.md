# Home Page — Automation Sections Draft

Proposed content for the "Review Automation" accordion sections on the SMQS home page. Three sections: one per accordion (Relationships & Affiliations, Addresses/Emails/Phones, Groups/Households). Source of truth: ThirdBuild org (38 flows, repo-confirmed).

Excluded per decision:
- Subflows and helpers: `Screen_Manage_ContactPoints_Subflow`, `Screen_Manage_ContactPoints_Address_Subflow`, `Screen_Manage_ContactPoints_Email_Subflow`, `Screen_Manage_ContactPoints_Phone_Subflow`, `Address_Sync_Upsert_ContactPointAddress`, `Phone_ContactPointPhone_Helper_Subflow`, `Screen_Manage_Household_Subflow_Create_Person_Accounts`
- User excluded: `Screen_Create_Party_Role_Relationship_Setup`
- Removed from org/repo (replaced): `Create_Relationship_or_Affiliation`, `Screen_Manage_ContactPointEmail`, `Screen_Manage_ContactPointPhone`

---

## Accordion 1: Relationships and Affiliations

**Section label:** 1e. Review Automation

**Content:**

Review the flows below to understand what automation is included in this project for creating and managing relationships.

- **SMQS Screen Create Relationship or Affiliation** — Screen flow for creating an individual relationship, individual affiliation, or group affiliation from a single guided entry point.
- **SMQS Contact Contact Relationship Post Save Flow** — When a new individual relationship is created, automatically creates the inverse relationship record and links the two together.
- **SMQS Contact Contact Relationship Delete** — Automatically deletes the inverse relationship record when an individual relationship is deleted.
- **SMQS Account Account Relationship Post Save Flow** — When a new group affiliation is created, automatically creates the inverse affiliation record and links the two together.
- **SMQS Account Account Relationship Delete** — Automatically deletes the inverse affiliation record when a group affiliation is deleted.
- **SMQS Party Role Relationship Before Save Flow** — Completes fields on the inverse Party Role Relationship record when a new relationship is created.

---

## Accordion 2: Addresses, Emails, and Phones

**Section label:** 2c. Review Automation

**Content:**

Review the flows below to understand what automation is included in this project for managing and syncing contact information.

**Screen Flows**
- **SMQS Screen Manage ContactPoints** — Screen flow launched from an Account record for managing addresses, phones, and emails together for both individuals and organizations.
- **SMQS Screen RelatedList ContactPointEmail** — Read-only screen flow on the Account record page that displays ContactPointEmail records in two tables: active/valid emails and inactive/invalid emails. Because ContactPointEmail is not enabled for dynamic related list single, this flow provides a consolidated view of all email records. Use Manage Contact Info to edit existing records or add secondary email addresses.
- **SMQS Screen RelatedList ContactPointPhone** — Read-only screen flow on the Account record page that displays ContactPointPhone records in two tables: active/valid phones and inactive/invalid phones. Because ContactPointPhone is not enabled for dynamic related list single, this flow provides a consolidated view of all phone records. Use Manage Contact Info to edit existing records or add secondary phone numbers.

**Address Sync**
- **SMQS Address Sync AccountContactRelation Household** — When a household member's sync setting is active, copies the household billing address to the member's mailing address.
- **SMQS Address Sync Business Account to ContactPointAddress** — When a business account's billing address changes, syncs the update to its Contact Point Address records.
- **SMQS Address Sync ContactPointAddress to Account** — When a primary Contact Point Address changes, syncs the address back to the parent account.
- **SMQS Address Sync Person Account to ContactPointAddress** — When a person account's mailing address changes, syncs the update to its Contact Point Address records.
- **SMQS Address Sync Set ContactPointAddress Defaults** — Sets default field values on new Contact Point Address records before they are saved.

**Email Sync**
- **SMQS Email Sync Account to ContactPointEmail** — When an account's email field changes, creates or updates the corresponding Contact Point Email record.
- **SMQS Email Sync ContactPointEmail to Account** — When a primary Contact Point Email changes, syncs the email value back to the parent account.

**Phone Sync**
- **SMQS Phone Sync AccountContactRelation to Household Account** — When a household member's ACR is updated, syncs their phone to the household account.
- **SMQS Phone Sync Account to ContactPointPhone** — When an account's phone field changes, creates or updates the corresponding Contact Point Phone record.
- **SMQS Phone Sync ContactPointPhone to Account** — When a primary Contact Point Phone changes, syncs the phone value back to the parent account.
- **SMQS Phone Sync Household Account to Person Account** — Syncs the household account's phone to all member person accounts.
- **SMQS Phone Sync Person Account to Household Account** — Syncs a person account's phone change up to the household account.

---

## Accordion 3: Groups (Organizations and Households)

**Section label:** 3d. Review Automation

**Content:**

Review the flows below to understand what automation is included in this project for groups, organizations, and households.

- **SMQS Screen Manage Household** — Screen flow launched from an Account record for managing household members, addresses, phones, and emails, including which members will receive address syncs.
- **SMQS Person Account Conversion from Contact** — Automatically converts a standard Contact record to a Person Account when triggered.
- **SMQS Household Setup IsHousehold Enforcement** — Keeps the Household record type and the Is Household field in sync when household accounts are created or updated.
- **SMQS Household Setup Account to Party Relationship Group** — Creates a Party Relationship Group record when a new household account is set up.
- **SMQS Household Setup Name Sync Account to CPA** — When a household account name changes, updates the name on all related Contact Point Address records.
- **SMQS Household Setup Name Sync Account to PRG** — When a household account name changes, mirrors the update to all related Party Relationship Group records.
- **SMQS Household Setup Name Sync AccountContactRelationship to Account** — Updates the household account name when the primary household member changes.
- **SMQS Household Setup Name Sync ACR Delete to Account** — Re-evaluates the household account name when a household member is removed.
