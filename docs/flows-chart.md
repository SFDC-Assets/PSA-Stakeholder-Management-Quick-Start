# SMQS Flow Inventory

40 flows total, grouped by functional area.

**Type key:** `ALF` = AutoLaunchedFlow (record-triggered or subflow), `Screen` = user-initiated screen flow  
**Trigger key:** `AfterSave` / `BeforeSave` / `BeforeDelete` / `—` (no trigger; subflow or screen)

---

## Relationship Management

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Account_Account_Relationship_Post_Save_Flow` | SMQS Account Account Relationship - Post Save Flow | ALF | AfterSave | AccountAccountRelation | Creates and links inverse AccountAccountRelation (organizational affiliation) records after initial save. | No |
| `SMQS_Account_Account_Relationship_Delete` | SMQS Account Account Relationship - Delete | ALF | BeforeDelete | AccountAccountRelation | Handles inverse cleanup for AccountAccountRelation deletes to prevent orphaned inverse references. | No |
| `SMQS_Contact_Contact_Relationship_Post_Save_Flow` | SMQS Contact Contact Relationship - Post Save Flow | ALF | AfterSave | ContactContactRelation | Creates and links inverse ContactContactRelation records after create. | No |
| `SMQS_Contact_Contact_Relationship_Delete` | SMQS Contact Contact Relationship - Delete | ALF | BeforeDelete | ContactContactRelation | Handles inverse cleanup for ContactContactRelation deletes to keep relationship links consistent. | No |
| `SMQS_Party_Role_Relationship_Before_Save_Flow` | SMQS Party Role Relationship - Before Save Flow | ALF | BeforeSave | PartyRoleRelation | Determines PartyRoleRelation and derives inverse-role fields for use when creating or syncing inverse relationships. | No |

---

## Address Sync

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Address_Sync_Business_Account_to_ContactPointAddress` | SMQS Address Sync Business Account to ContactPointAddress | ALF | AfterSave | Account | Fires on non-PersonAccount Accounts. Calls the shared upsert subflow for the Billing address. | Yes → `SMQS_Address_Sync_Upsert_ContactPointAddress` |
| `SMQS_Address_Sync_Person_Account_to_ContactPointAddress` | SMQS Address Sync Person Account to ContactPointAddress | ALF | AfterSave | Account | Fires on PersonAccount Accounts. Calls the shared upsert subflow for the PersonMailing address. | Yes → `SMQS_Address_Sync_Upsert_ContactPointAddress` |
| `SMQS_Address_Sync_AccountContactRelation_Household` | SMQS Address Sync AccountContactRelation Household | ALF | AfterSave | AccountContactRelation | Fires when IsActive, Sync_Household_Address__c, or Roles changes. Copies Household Account Billing* to linked Person Account PersonMailing* when they differ. | No |
| `SMQS_Address_Sync_ContactPointAddress_to_Account` | SMQS Address Sync ContactPointAddress to Account | ALF | AfterSave | ContactPointAddress | Two paths: (1) invalidate-and-clear or (2) promote-to-primary on the parent Account. | No |
| `SMQS_Address_Sync_Delete_ContactPointAddress_to_Account` | SMQS Address Sync Delete ContactPointAddress to Account | ALF | BeforeDelete | ContactPointAddress | When a primary ContactPointAddress is deleted, clears the corresponding Account address fields. Person Accounts: clears PersonMailing fields. Business/Household Accounts: clears Billing fields. | No |
| `SMQS_Address_Sync_Set_ContactPointAddress_Defaults` | SMQS Address Sync Set ContactPointAddress Defaults | ALF | BeforeSave | ContactPointAddress | When IsUndeliverable becomes true, sets UsageType=Inactive, IsPrimary=false, and ActiveToDate=TODAY(). | No |
| `SMQS_Address_Sync_Upsert_ContactPointAddress` | SMQS Address Sync Upsert ContactPointAddress | ALF (subflow) | — | — | Shared subflow: upserts a ContactPointAddress for one Account and one address slot (new + old values). Called by the two Account→CPA flows above. | No |

---

## Email Sync

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Email_Sync_Account_to_ContactPointEmail` | SMQS Email Sync Account to ContactPointEmail | ALF | AfterSave | Account | Syncs Account.PersonEmail changes to ContactPointEmail records on Person Accounts. | No |
| `SMQS_Email_Sync_ContactPointEmail_to_Account` | SMQS Email Sync ContactPointEmail to Account | ALF | AfterSave | ContactPointEmail | Syncs ContactPointEmail IsPrimary changes back to the parent Account. | No |
| `SMQS_Email_Sync_Delete_ContactPointEmail_to_Account` | SMQS Email Sync Delete ContactPointEmail to Account | ALF | BeforeDelete | ContactPointEmail | When a primary ContactPointEmail is deleted, clears Account.PersonEmail on Person Accounts. | No |
| `SMQS_Screen_RelatedList_ContactPointEmail` | SMQS Screen RelatedList ContactPointEmail | Screen | — | — | Displays ContactPointEmail records in two read-only tables (active/valid and inactive/invalid). Surfaces email records where dynamic related list single is not supported. | No |

---

## Phone Sync

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Phone_Sync_Account_to_ContactPointPhone` | SMQS Phone Sync Account to ContactPointPhone | ALF | AfterSave | Account | Syncs phone field changes on an Account to ContactPointPhone records. Calls the helper subflow once per phone field. | Yes → `SMQS_Phone_ContactPointPhone_Helper_Subflow` |
| `SMQS_Phone_Sync_ContactPointPhone_to_Account` | SMQS Phone Sync ContactPointPhone to Account | ALF | AfterSave | ContactPointPhone | Syncs ContactPointPhone IsPrimary changes back to the parent Account. | No |
| `SMQS_Phone_Sync_Delete_ContactPointPhone_to_Account` | SMQS Phone Sync Delete ContactPointPhone to Account | ALF | BeforeDelete | ContactPointPhone | When a primary ContactPointPhone is deleted, clears Account.Phone. For Person Accounts also clears the typed field (PersonHomePhone, PersonMobilePhone, or PersonOtherPhone) based on Map_To__c. | No |
| `SMQS_Phone_Sync_AccountContactRelation_to_Household_Account` | SMQS Phone Sync AccountContactRelation to Household Account | ALF | AfterSave | AccountContactRelation | Fires when IsActive, Sync_Household_Phone__c, or Roles changes and all three sync conditions are met. | No |
| `SMQS_Phone_Sync_Household_Account_To_Person_Account` | SMQS Phone Sync Household Account To Person Account | ALF | AfterSave | Account | Fires on non-PersonAccount households. When Is_Household__c=true and Phone changes, cascades the new value to all synced member Person Accounts. | No |
| `SMQS_Phone_Sync_Person_Account_to_Household_Account` | SMQS Phone Sync Person Account to Household Account | ALF | AfterSave | Account | Fires on PersonAccounts. When PersonHomePhone changes, pushes the new value up to the first active synced Household Account via ACR. | No |
| `SMQS_Phone_ContactPointPhone_Helper_Subflow` | SMQS Phone ContactPointPhone Helper Subflow | ALF (subflow) | — | — | Shared subflow: for one Account phone field at a time, upserts the active ContactPointPhone for the new value. Called by `SMQS_Phone_Sync_Account_to_ContactPointPhone`. | No |
| `SMQS_Screen_RelatedList_ContactPointPhone` | SMQS Screen RelatedList ContactPointPhone | Screen | — | — | Displays ContactPointPhone records in two read-only tables (active/valid and inactive/invalid). Surfaces phone records where dynamic related list single is not supported. | No |

---

## Contact Point Management (Unified)

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Screen_Manage_ContactPoints` | SMQS Screen Manage ContactPoints | Screen | — | — | Unified screen flow for managing all contact point types (address, email, phone) for Person Accounts and Business/Household Accounts. Routes by account type and contact point type, then delegates DML to the type-specific subflows. | Yes → `SMQS_Screen_Manage_ContactPoints_Subflow`, `SMQS_Screen_Manage_ContactPoints_Address_Subflow`, `SMQS_Screen_Manage_ContactPoints_Email_Subflow`, `SMQS_Screen_Manage_ContactPoints_Phone_Subflow` |
| `SMQS_Screen_Manage_ContactPoints_Subflow` | SMQS Screen Manage ContactPoints Subflow | ALF (subflow) | — | — | Startup subflow for `SMQS_Screen_Manage_ContactPoints`. Queries the Account and all related ContactPoint records (address, email, phone) and ACRs; routes queries by account type (Person vs. Household/Business). Returns results as output variables to the parent. | No |
| `SMQS_Screen_Manage_ContactPoints_Address_Subflow` | SMQS Screen Manage ContactPoints Address Subflow | ALF (subflow) | — | — | Processes address screen output from `SMQS_Screen_Manage_ContactPoints`. Loops over screen results to build insert, update, and delete collections for ContactPointAddress, with primary-count validation. Performs DML. | No |
| `SMQS_Screen_Manage_ContactPoints_Email_Subflow` | SMQS Screen Manage ContactPoints Email Subflow | ALF (subflow) | — | — | Processes email screen output from `SMQS_Screen_Manage_ContactPoints`. Loops over screen results to build insert, update, and delete collections for ContactPointEmail, with primary-count validation. Performs DML. | No |
| `SMQS_Screen_Manage_ContactPoints_Phone_Subflow` | SMQS Screen Manage ContactPoints Phone Subflow | ALF (subflow) | — | — | Processes phone screen output from `SMQS_Screen_Manage_ContactPoints`. Loops over screen results to build insert, update, and delete collections for ContactPointPhone, with primary-count validation. Performs DML. | No |

---

## Household Setup

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Household_Setup_IsHousehold_Enforcement` | SMQS Household Setup IsHousehold Enforcement | ALF | BeforeSave | Account | Before Save on Account (create and update). Enforces coupling between the Household record type and Is_Household__c. When RecordType.Name contains "Household", sets Is_Household__c=true; otherwise false. Entry filter fires only when RecordTypeId is changing. In-memory assignment — no DML. | No |
| `SMQS_Household_Setup_Account_to_PartyRelationshipGroup` | SMQS Household Setup Account to PartyRelationshipGroup | ALF | AfterSave | Account | Fires when an Account is created with Is_Household__c checked. Creates a PartyRelationshipGroup if one does not already exist. | No |
| `SMQS_Household_Setup_Name_Sync_AccountContactRelationship_to_Account` | SMQS Household Setup Name Sync AccountContactRelationship to Account | ALF | AfterSave | AccountContactRelation | Updates the Household Account Name when IsPrimary changes on an AccountContactRelation. | No |
| `SMQS_Household_Setup_Name_Sync_ACR_Delete_to_Account` | SMQS Household Setup Name Sync ACR Delete to Account | ALF | BeforeDelete | AccountContactRelation | Before Delete companion to the ACR AfterSave name sync. Re-evaluates the household Account name after a member ACR is deleted using 3-state logic: primary member exists, members but no primary, or empty household. Excludes the deleting record from queries (Before Delete fires while record is still in DB). | No |
| `SMQS_Household_Setup_Name_Sync_Account_to_CPA` | SMQS Household Setup Name Sync Account to CPA | ALF | AfterSave | Account | When a Household Account Name changes, mirrors the new name onto all related ContactPointAddress records for the household and its members. | No |
| `SMQS_Household_Setup_Name_Sync_Account_to_PRG` | SMQS Household Setup Name Sync Account to PRG | ALF | AfterSave | Account | When a Household Account Name changes (ISCHANGED(Name) AND Is_Household__c=true), mirrors the new name onto all related PartyRelationshipGroup records. Retrieves all PRGs, loops to stamp names, then performs a single bulk update. | No |
| `SMQS_Screen_Manage_Household` | SMQS Screen Manage Household | Screen | — | — | Complex screen flow for creating new household accounts and managing household members. Handles new household creation, add/edit/remove member sequences, creation of contact-to-contact relationships between household members, and calls the Person Account creation subflow. | Yes → `SMQS_Screen_Manage_Household_Subflow_Create_Person_Accounts` |
| `SMQS_Screen_Manage_Household_Subflow_Create_Person_Accounts` | SMQS Screen Manage Household Subflow Create Person Accounts | ALF (subflow) | — | — | Subflow: uses Transform to create Person Accounts and AccountContactRelations in a single transaction. Called by `SMQS_Screen_Manage_Household`. | No |

---

## Person Account

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Person_Account_Conversion_from_Contact` | SMQS Person Account Conversion from Contact | ALF | AfterSave | Contact | Automatically transforms a Contact into a Person Account. | No |

---

## Relationships & Affiliations (User-Initiated)

| API Name | Label | Type | Trigger | Object | Description | Calls Subflow |
|---|---|---|---|---|---|---|
| `SMQS_Screen_Create_Relationship_or_Affiliation` | SMQS Screen Create Relationship or Affiliation | Screen | — | — | Guides users through creating person-to-person or person-to-organization relationships and affiliations. Branches into person, organization, and role paths. Replaces the legacy `SMQS_Create_Relationship_or_Affiliation` flow. | Yes → `SMQS_Screen_Manage_Household` |
| `SMQS_Screen_Create_Party_Role_Relationship_Setup` | SMQS Screen Create Party Role Relationship Setup | Screen | — | — | Provides a selection of possible party role relationship options for an end user to select and then create in the system. | No |

---

## Subflow Call Map

```
SMQS_Address_Sync_Business_Account_to_ContactPointAddress
  └─► SMQS_Address_Sync_Upsert_ContactPointAddress

SMQS_Address_Sync_Person_Account_to_ContactPointAddress
  └─► SMQS_Address_Sync_Upsert_ContactPointAddress

SMQS_Phone_Sync_Account_to_ContactPointPhone
  └─► SMQS_Phone_ContactPointPhone_Helper_Subflow  (called once per phone field)

SMQS_Screen_Manage_ContactPoints
  ├─► SMQS_Screen_Manage_ContactPoints_Subflow  (startup: queries Account + all CPs + ACRs)
  ├─► SMQS_Screen_Manage_ContactPoints_Address_Subflow  (DML for address changes)
  ├─► SMQS_Screen_Manage_ContactPoints_Email_Subflow  (DML for email changes)
  └─► SMQS_Screen_Manage_ContactPoints_Phone_Subflow  (DML for phone changes)

SMQS_Screen_Manage_Household
  └─► SMQS_Screen_Manage_Household_Subflow_Create_Person_Accounts

SMQS_Screen_Create_Relationship_or_Affiliation
  └─► SMQS_Screen_Manage_Household
        └─► SMQS_Screen_Manage_Household_Subflow_Create_Person_Accounts
```

---

## Summary

| Category | Count |
|---|---|
| Relationship Management | 5 |
| Address Sync | 7 |
| Email Sync | 4 |
| Phone Sync | 8 |
| Contact Point Management (Unified) | 5 |
| Household Setup | 8 |
| Person Account | 1 |
| Relationships & Affiliations (screen) | 2 |
| **Total** | **40** |

| Flow Type | Count |
|---|---|
| AutoLaunchedFlow — record-triggered | 25 |
| AutoLaunchedFlow — subflow/helper (no trigger) | 7 |
| Screen flow (user-initiated) | 8 |
| **Total** | **40** |
