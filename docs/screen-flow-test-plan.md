# SMQS Screen Flow — Manual Test Plan

**Target org:** `thirdbuild`  
**Scope:** All Manage Contact Info screen flows (phone, email, address), both related list flows, and the blank-state Add All paths.

---

## Prerequisites

Identify or create one account of each type before starting:

| Type | Used for |
|---|---|
| Person Account — **no** CPP, CPE, or CPA records | Sections A-1, F-1, F-2 |
| Person Account — **with** existing CPP, CPE, and CPA records | Sections A-3, B, C, D, E-1 |
| Person Account — member of a Household (ACR: IsActive=true, Sync_Household_Phone__c=true, Roles=Household Member) | Sections B-7, D-6 |
| Business/Organization Account — **no** CPP or CPA records | Section A-2, F-3 |
| Business Account — **with** existing CPP and CPA records | Sections A-4, C-6 |
| Account with both valid and invalid CPPs | Section E-1 |
| Account with both valid and invalid CPEs | Section E-2 |

---

## Section A — Entry Routing

### A-1 Blank-state Person Account
1. Open a Person Account with no CPP, CPE, or CPA → click **Manage Contact Info**.
2. **Expect:** `Screen_Add_All_Person` loads with header: *"No contact information exists yet for this person."*
3. Confirm three repeater sections are visible: Mailing Address, Email Addresses, Phone Numbers.
4. Confirm a **Communication Preferences** section appears below the repeaters with checkboxes: Do Not Call, Do Not Mail, Email Opt Out.
5. Confirm each checkbox reflects the current Account field value.
6. Leave all sections empty → click **Next** → confirm the flow ends without error and no records were created.

Response: Passed

### A-2 Blank-state Business Account
1. Open a Business Account with no CPP or CPA → click **Manage Contact Info**.
2. **Expect:** `Screen_Add_All_Business` loads with header: *"No contact information exists yet for this account."*
3. Confirm only two repeater sections: Billing Address, Phone Numbers — **no Email section**.
4. Confirm Communication Preferences shows **only** Do Not Mail (no Do Not Call, no Email Opt Out).
5. Leave all sections empty → click **Next** → confirm clean exit.

Response: Passed

### A-3 Existing Person Account — merged picker screen
1. Open a Person Account with existing records → click **Manage Contact Info**.
2. **Expect:** Single screen `Screen_Select_And_Manage` with three areas:
   - **Add/Manage picker** — "Manage Existing Contact Info" is pre-selected by default.
   - **Type picker** — visible on load (Address, Email, Phone tiles shown).
   - **Communication Preferences** — Do Not Call, Do Not Mail, Email Opt Out pre-populated.
3. Switch picker to "Add New Contact Info" → confirm type picker **disappears**.
4. Switch back to "Manage Existing" → confirm type picker **reappears**.
5. Click **Next** without selecting a type while in Manage mode → confirm required-field validation fires.

Response: passed

Response 2:

### A-4 Existing Business Account — merged picker screen
1. Open a Business Account with existing records → click **Manage Contact Info**.
2. Confirm type picker shows Address and Phone but **no Email tile**.
3. Confirm Communication Preferences shows **only** Do Not Mail.
4. Confirm Do Not Call and Email Opt Out are **not visible**.

Response: passed

Response 2:

### A-5 Add New path from existing account — Person
1. On a Person Account with existing records → **Manage Contact Info**.
2. Select "Add New Contact Info" → click **Next**.
3. **Expect:** `Screen_Add_All_Person` with header: *"Add new contact information for this person below."*
4. Confirm existing addresses, emails, and phones appear as pre-populated rows above the repeater (read-only context — editing existing records requires "Manage Existing").
5. Confirm Communication Preferences section is present and pre-populated.
6. Add one phone number using the Add Row button → **Next** → confirm new CPP was created and existing CPPs are unchanged.

Response: failed, I want to see the exisiting contact info as read only on this screen so I don't enter info already in the system by by mistake.

Response 2:

### A-6 Communication preferences save correctly
1. On a Person Account → **Manage Contact Info** → keep Manage selected → note current Do Not Call value.
2. Toggle **Do Not Call** to the opposite value → select Phone → click **Next** → finish or back out of the phone subflow.
3. Reload the Account record → confirm **Do Not Call** reflects the toggled value.
4. Repeat for **Do Not Mail** and **Email Opt Out**.
5. On a Business Account → toggle **Do Not Mail** → confirm it saves; confirm PersonDoNotCall is unaffected.

Response: Passed

---

## Section B — Phone Subflow

### B-1 Map To column visible in repeater
1. Navigate to Manage Contact Info → Phone on a **Person Account** with a CPP that has `Map_To__c` set → confirm Map To is visible and populated.
2. Navigate to Manage Contact Info → Phone on a **Business Account** → confirm Map To column is **not visible**.

Resposne: fail, map to shouldn't be visable for business accounts

Response 2:

### B-2 Add a new phone
1. Manage Contact Info → Phone → click **Add Row**.
2. Enter a phone number, select Map To = Mobile, leave Extension blank.
3. Click **Save** → confirm new CPP created: `TelephoneNumber` set, `Map_To__c = Mobile`, `IsPrimary = false`, `Active__c = true`.

Response: passed, but their is no header for the untouched phone record in the data table on the confirmation screen. 

### B-3 Edit an existing phone
1. Manage Contact Info → Phone → change an existing row's **Extension** or **Map To**.
2. Save → confirm the CPP was **updated**, not re-created (same Id, new field value).

resonse: passed

### B-4 Primary validation — multiple primaries blocked
1. Manage Contact Info → Phone → mark **two rows** as Primary.
2. Click Save → **Expect:** `Screen_Error_Primary` appears with *"Only one record can be marked as Primary"*.
3. Confirm the flow does not commit any DML.

resonse: passed

### B-5 Delete with confirmation screen
1. Manage Contact Info → Phone → mark one phone as **Mark for Deletion** (leave at least one other unmarked).
2. Click Save → **Expect:** `Screen_Confirm_Delete_Phone` appears.
3. Confirm the **Phones to Delete** table contains the marked record.
4. Confirm the **Phones to Keep** table contains the remaining records.
5. Confirm the **Map To column** is visible in **both** tables.
6. Click **Go Back and Review** → confirm you return to the manage screen with your changes intact.
7. Re-submit → click **Confirm Delete** → confirm the CPP is deleted.

response: passed

### B-6 Delete all phones
1. On a Person Account with phones mapped to different Map To values (Home Phone, Mobile, Other Phone) → mark every CPP as Mark for Deletion.
2. Confirm the delete confirmation screen shows all records in the Delete table and an **empty** Keep table.
3. Confirm Delete → confirm all CPPs are deleted.
4. Reload the Account → confirm each Account phone field (`PersonHomePhone`, `PersonMobilePhone`, `PersonOtherPhone`) was cleared only for the matching Map To value.
5. Confirm the success screen shows the note about phone fields being cleared.

response: fail, the phone fields on the account aren't whiped. add that functionality and also add some text to the explanation explaining that behavior

Response 2:

### B-7 Household sync tables
1. Open a Person Account that is a member of a Household → Manage Contact Info → Phone.
2. Confirm the **sync-on table** appears above the repeater listing members whose `Sync_Household_Phone__c = true`.
3. Confirm the **no-sync notice** appears for members whose `Sync_Household_Phone__c = false`.
4. Confirm member names appear in the correct section.

response: fail from individual, pass from household

Response 2:

### B-8 Add and delete in the same session
1. In a single flow session: add one new phone row **and** mark one existing phone as Mark for Deletion.
2. Save → confirm delete confirmation screen appears.
3. Confirm Delete → verify the new phone was **created** and the marked phone was **deleted**.

response: pass

---

## Section C — Email Subflow

### C-1 View email manage screen
1. Manage Contact Info → Email → confirm existing emails populate in the repeater sorted primary first.

response: passs, this should be the expected behavior for phone and email as well 

### C-2 Add a new email
1. Click **Add Row** → confirm the **Active** checkbox is checked by default on the new row.
2. Enter an email address → Save.
3. Confirm new CPE created with `EmailAddress` set, `Active__c = true`, `IsPrimary = false`.

response: fail

Response 2:

### C-3 Email manage screen — no Usage Type field
1. Manage Contact Info → Email → confirm **Usage Type** is **not visible** on any row in the repeater.

response: usage type is not needed here remove

Response 2:

### C-4 Primary validation
1. Mark two email rows as Primary → Save.
2. **Expect:** `Screen_Error_Primary` appears; no DML runs.

response: pass

### C-5 Delete with confirmation
1. Mark one email as Mark for Deletion (with at least one other remaining).
2. Save → confirm `Screen_Confirm_Delete_Email` appears.
3. Confirm the **Emails to be Deleted** table shows the marked email address.
4. Confirm the **Emails that will be Kept** table shows only the remaining email(s) — no overlap.
5. Confirm Delete → confirm CPE is deleted.

resposne: fail the same email appears in both deleted and kept. even though one email was deleted

Response 2:

### C-6 Email not available for Business Accounts
1. On a Business Account → Manage Contact Info.
2. Confirm the **Email tile does not appear** in the type picker.

response: confirmed

---

## Section D — Address Subflow

### D-1 Screen title reflects account type
1. Person Account → Manage Contact Info → Address → confirm screen label reads **"Manage Mailing Addresses"**.
2. Business Account → Manage Contact Info → Address → confirm label reads **"Manage Billing Addresses"**.

Response: fail, business account has mailing address

Response 2:

### D-2 Add a new address
1. Click **Add Row** → enter Street, City, State, Zip → Save.
2. Confirm new CPA created.
3. Confirm the CPA's **Name** field follows the convention: `{Account Name} Mailing Address {Mon, YYYY}`.

resposne: pass 

### D-3 Edit an existing address
1. Change the **Street** value on an existing CPA row → Save.
2. Confirm CPA **updated**, not re-created.

resposne: pass

### D-4 Primary validation
1. Mark two addresses as Primary → Save → **Expect:** `Screen_Error_Primary`.

resposne: pass

### D-5 Delete with confirmation
1. Mark one address for deletion (with at least one remaining).
2. Save → confirm `Screen_Confirm_Delete_Address` appears.
3. Confirm the **Addresses to be Deleted** table shows the marked address (Street, City, State, Primary populated).
4. Confirm the **Addresses that will be Kept** table shows the remaining address(es) — not blank.
5. Confirm Delete → confirm CPA is deleted.

response: fail, data table were blank

Response 2:

### D-6 Household sync tables
1. Open a Person Account that is a member of a Household → Manage Contact Info → Address.
2. Confirm sync-on and sync-off ACR tables appear above the repeater.

response: pass

---

## Section E — Related List Flows

### E-1 Phone related list
1. Open an Account with both valid and invalid CPPs on the record page.
2. Confirm the Phone related list flow shows two sections: **Active Phone Numbers** and **Inactive / Invalid Phone Numbers**.
3. Confirm active table columns: Phone Number, Extension, Primary, Map To.
4. Confirm inactive table columns: Phone Number, Extension, Map To, Invalid Reason — **no Primary column**.
5. Confirm records split correctly: active = no `Invalid_Reason__c`; inactive = has `Invalid_Reason__c`.

Response: fail, remove primary on inactive list

Response 2:

### E-2 Email related list
1. Open an Account with both valid and invalid CPEs.
2. Confirm two sections: **Active Email Addresses** and **Inactive / Invalid Email Addresses**.
3. Confirm active table columns: Email Address, Active, Primary — **no Usage Type**.
4. Confirm inactive table columns: Email Address, Primary, Invalid Reason — **no Usage Type**.

Response: I stil see usage type on emails remove that, add active on active list

Response 2:

---

## Section F — Add All Save Paths

### F-1 Person Account — add one of each type
1. Blank-state Person Account → Manage Contact Info → add one address, one email, one phone (with Extension filled in) → **Next**.
2. Confirm no **Select Primary Contact Info** screen appears (only one of each type).
3. Confirm one CPP, one CPE, one CPA are created with `IsPrimary = true` and `Active__c = true` on all three.
4. Confirm the Account's `PersonMailingStreet` and `PersonHomePhone` (or matching Map To field) were written back.
5. Confirm the Account's `PersonEmail` was written back.

response: I want extension under phone number, address and phone wrote to contact, email didn't. all created a contact point record of the right type

Response 2:

### F-2 Person Account — add multiple phones (primary selection screen)
1. Blank-state Person Account → Manage Contact Info → add **two** phone numbers → **Next**.
2. **Expect:** `Screen_Primary_Selection_AddAll` appears.
3. Select one phone as primary → **Save**.
4. Confirm the selected CPP has `IsPrimary = true`; the other has `IsPrimary = false`.
5. Confirm the Account's `PersonEmail` was written back (email added in same session).

response: same issue as email as above but other wise pass

Response 2:

### F-3 Business Account — add address and phone
1. Blank-state Business Account → Manage Contact Info → add one address (using the Billing Address field) and one phone → **Next**.
2. Confirm no Email section was available.
3. Confirm one CPA and one CPP are created with `IsPrimary = true` and `Active__c = true`.
4. Confirm the Account's `BillingStreet` (and other Billing* fields) were written back.

respone: fail address didn't write the account

Response 2:

---

## Section G — Delete → Account Field Clear (New Tests)

### G-1 Delete primary email clears PersonEmail
1. Person Account with one primary CPE → Manage Contact Info → Email → mark it for deletion → Confirm Delete.
2. Reload the Account → confirm `PersonEmail` is now blank.

Response:

### G-2 Delete non-primary email does not clear PersonEmail
1. Person Account with a primary CPE and at least one non-primary CPE → mark only the **non-primary** for deletion → Confirm Delete.
2. Reload the Account → confirm `PersonEmail` still matches the primary CPE's address.

Response:

### G-3 Delete primary address clears Account address fields (Person)
1. Person Account with a primary CPA → Manage Contact Info → Address → mark it for deletion → Confirm Delete.
2. Reload the Account → confirm `PersonMailingStreet`, `PersonMailingCity`, `PersonMailingState`, `PersonMailingPostalCode`, `PersonMailingCountry` are all blank.

Response:

### G-4 Delete primary address clears Account address fields (Business)
1. Business Account with a primary CPA → Manage Contact Info → Address → mark it for deletion → Confirm Delete.
2. Reload the Account → confirm `BillingStreet`, `BillingCity`, `BillingState`, `BillingPostalCode`, `BillingCountry` are all blank.

Response:

### G-5 Delete non-primary address does not clear Account address fields
1. Person Account with a primary CPA and at least one non-primary CPA → mark only the **non-primary** for deletion → Confirm Delete.
2. Reload the Account → confirm `PersonMailingStreet` still matches the primary CPA's address.

Response: