# Refactor Plan: SMQS_Screen_Manage_ContactInfo → Subflow Architecture

**Status:** Draft — not yet implemented  
**Scope:** Break one 124-element monolithic screen flow into 5 focused flows + 2 renames

---

## Problem

`SMQS_Screen_Manage_ContactInfo` has 124 named elements across 4 logical branches (Address, Email, Phone, AddAll). It cannot be converted to auto-layout and is difficult to test branch-by-branch or deploy incrementally.

---

## Target Architecture

```
SMQS_Screen_Manage_ContactPoints  (parent — ~46 elements, down from 124)
│
├── Start → SMQS_Screen_Manage_ContactPoints_Subflow  [new subflow call]
│              Returns: Account, AllAddresses, AllEmails, AllPhones,
│                       SyncACRs, NoSyncACRs, SyncPhoneACRs, NoSyncPhoneACRs
│
├── Decision_Account_Exists + Error_Screen  [stays in parent]
│
├── Decision_Blank_State → AddAll path  [stays in parent, untouched]
│
├── Decision_Account_Type → type pickers  [stays in parent]
│
└── Decision_Route_Type
      ├── → SMQS_Screen_Manage_ContactPoints_Address_Subflow  [new subflow call]
      ├── → SMQS_Screen_Manage_ContactPoints_Email_Subflow    [new subflow call]
      └── → SMQS_Screen_Manage_ContactPoints_Phone_Subflow    [new subflow call]
```

### Element count comparison

| Flow | Elements today | Elements after |
|---|---|---|
| SMQS_Screen_Manage_ContactPoints | 124 | ~46 |
| SMQS_Screen_Manage_ContactPoints_Subflow (Autolaunched) | — | ~10 |
| SMQS_Screen_Manage_ContactPoints_Address_Subflow | — | ~28 |
| SMQS_Screen_Manage_ContactPoints_Email_Subflow | — | ~26 |
| SMQS_Screen_Manage_ContactPoints_Phone_Subflow | — | ~28 |
| **Total across all flows** | **124 in 1 flow** | **~138 in 5 flows** |

Total count is slightly higher (subflow call elements + error screens add overhead), but no single flow exceeds ~46 elements — all are individually manageable and auto-layout compatible.

---

## Files Affected

### New files (4)

| API Name | Flow Type | Purpose |
|---|---|---|
| `SMQS_Screen_Manage_ContactPoints_Subflow` | Autolaunched Flow | Runs all startup queries; returns Account + 7 collections |
| `SMQS_Screen_Manage_ContactPoints_Address_Subflow` | Screen Flow | Full address management: validate → split → confirm → DML → success |
| `SMQS_Screen_Manage_ContactPoints_Email_Subflow` | Screen Flow | Full email management |
| `SMQS_Screen_Manage_ContactPoints_Phone_Subflow` | Screen Flow | Full phone management |

### Modified files (1)

| File | Change |
|---|---|
| `SMQS_Screen_Manage_ContactInfo` | Renamed to `SMQS_Screen_Manage_ContactPoints`; remove 9 query elements + 3 type branches (107 elements); replace with 1 subflow call + 3 subflow calls; keep AddAll path + orchestration (~46 elements remain) |

### Renamed files (3)

| Old API Name | New API Name | Reason |
|---|---|---|
| `SMQS_Screen_Manage_ContactInfo` | `SMQS_Screen_Manage_ContactPoints` | Consistent naming with subflows; reflects broader contact point scope |
| `SMQS_Screen_Manage_ContactPointEmail` | `SMQS_Screen_RelatedList_ContactPointEmail` | Frees the name for the new management subflow; clarifies these are read-only related-list displays |
| `SMQS_Screen_Manage_ContactPointPhone` | `SMQS_Screen_RelatedList_ContactPointPhone` | Same |

> **Note:** Check flexipages and quick actions for references to the old names before renaming.

---

## Phase 1 — Rename existing flows

**Goal:** Rename the parent flow and free the names `SMQS_Screen_Manage_ContactPointEmail` and `SMQS_Screen_Manage_ContactPointPhone` before building the new subflows.

**Steps:**
1. Search flexipages and any quick action metadata for references to the old names.
2. Create renamed copies:
   - `SMQS_Screen_Manage_ContactPoints` (from `SMQS_Screen_Manage_ContactInfo`)
   - `SMQS_Screen_RelatedList_ContactPointEmail` (from `SMQS_Screen_Manage_ContactPointEmail`)
   - `SMQS_Screen_RelatedList_ContactPointPhone` (from `SMQS_Screen_Manage_ContactPointPhone`)
3. Update any flexipage or quick action references to use the new names.
4. Deactivate and delete the old flows once references are confirmed clean.

**Files to check:** `force-app/main/default/flexipages/`, `force-app/main/default/quickActions/`

---

## Phase 2 — Build `SMQS_Screen_Manage_ContactPoints_Subflow`

**Flow type:** Autolaunched Flow (no screens — named with Screen prefix so all 4 subflows sort together in Setup)  
**API version:** 66.0

### Input variables

| Variable | Type | Description |
|---|---|---|
| `recordId` | String | Account Id — passed in from parent |

### Output variables (8)

| Variable | Type | Description |
|---|---|---|
| `out_Account` | SObject (Account) | Id, Name, IsPersonAccount |
| `out_AllAddresses` | SObject Collection (ContactPointAddress) | All CPAs for this Account |
| `out_AllEmails` | SObject Collection (ContactPointEmail) | All CPEs for this Account, IsPrimary DESC |
| `out_AllPhones` | SObject Collection (ContactPointPhone) | All CPPs for this Account |
| `out_SyncACRs` | SObject Collection (AccountContactRelation) | ACRs where address sync = true |
| `out_NoSyncACRs` | SObject Collection (AccountContactRelation) | ACRs where address sync = false |
| `out_SyncPhoneACRs` | SObject Collection (AccountContactRelation) | ACRs where phone sync = true |
| `out_NoSyncPhoneACRs` | SObject Collection (AccountContactRelation) | ACRs where phone sync = false |

### Elements (~10)

1. `Get_Account` — queries Account by recordId; outputs to `out_Account`
2. `Get_Addresses` — queries ContactPointAddress by ParentId; outputs to `out_AllAddresses`
3. `Get_Emails` — queries ContactPointEmail by ParentId, ordered IsPrimary DESC; outputs to `out_AllEmails`
4. `Get_Phones` — queries ContactPointPhone by ParentId; outputs to `out_AllPhones`
5. `Get_ACRs_Sync_Yes` — queries ACRs where address sync field = true; outputs to `out_SyncACRs`
6. `Get_ACRs_Sync_No` — queries ACRs where address sync field = false; outputs to `out_NoSyncACRs`
7. `Get_ACRs_Sync_Phone_Yes` — queries ACRs where phone sync field = true; outputs to `out_SyncPhoneACRs`
8. `Get_ACRs_Sync_Phone_No` — queries ACRs where phone sync field = false; outputs to `out_NoSyncPhoneACRs`

**Source elements** (to copy query criteria from):  
`Get_Account`, `Get_Addresses`, `Get_Emails`, `Get_Phones`, `Get_ACRs_Sync_Yes`, `Get_ACRs_Sync_No`, `Get_ACRs_Sync_Phone_No` in `SMQS_Screen_Manage_ContactPoints`

> **Error handling note:** Autolaunched flows cannot show screens. If a query fails, the subflow faults and the parent's fault connector on the subflow call routes to `Error_Screen`. Each `recordLookup` element should have its fault connector wired to the subflow's own fault path (which propagates to the parent).

---

## Phase 3 — Build `SMQS_Screen_Manage_ContactPoints_Address_Subflow`

**Flow type:** Screen Flow  
**API version:** 66.0

### Input variables (4)

| Variable | Type | Description |
|---|---|---|
| `recordId` | String | Account Id |
| `var_Account` | SObject (Account) | Pre-queried Account (for display on screens) |
| `var_AllAddresses` | SObject Collection (ContactPointAddress) | Pre-queried collection from parent |
| `var_SyncACRs` | SObject Collection (AccountContactRelation) | Pre-queried by parent |
| `var_NoSyncACRs` | SObject Collection (AccountContactRelation) | Pre-queried by parent |

### Elements to migrate from parent (~28)

**Assignments (8):** `Assign_Reset_Primary_Count_Address`, `Assign_Count_Primary_Address`, `Assign_Count_Primary_Address_Added`, `Assign_Build_Update_Address`, `Assign_Build_Delete_Address`, `Assign_Flag_New_Addresses`, `Assign_Flag_Update_Addresses`, `Assign_Build_New_Address`

**Decisions (6):** `Decision_Is_Address_Primary`, `Decision_Is_Address_Primary_Added`, `Decision_Address_Primary_Valid`, `Decision_Address_Marked_Delete`, `Decision_Has_Delete_Addresses`, `Decision_Has_New_Addresses`, `Decision_Has_Update_Addresses`

**Loops (4):** `Loop_Count_Primary_Addresses`, `Loop_Count_Primary_Addresses_Added`, `Loop_Split_Addresses`, `Loop_Split_Addresses_New`

**DML (3):** `Create_New_Addresses`, `Update_Addresses`, `Delete_Addresses`

**Screens (4):** `Screen_Manage_Addresses`, `Screen_Confirm_Delete_Address`, `Screen_Success_Address`, `Error_Screen` *(new copy — own error screen)*

**Variables to add locally:** `var_PrimaryCount`, `var_SingleAddress`, `var_NewAddresses`, `var_UpdateAddresses`, `var_DeleteAddresses`, `var_HasNewAddresses`, `var_HasUpdateAddresses`

**Entry point:** `Screen_Manage_Addresses` (start element connects directly here)

> **Note:** `Screen_Error_Primary` is shared across all three types. Either give each subflow its own copy, or keep one copy and reference it — since it contains no type-specific content, it could be identical in all three.

---

## Phase 4 — Build `SMQS_Screen_Manage_ContactPoints_Email_Subflow`

**Flow type:** Screen Flow  
**API version:** 66.0

### Input variables (3)

| Variable | Type | Description |
|---|---|---|
| `recordId` | String | Account Id |
| `var_Account` | SObject (Account) | Pre-queried Account |
| `var_AllEmails` | SObject Collection (ContactPointEmail) | Pre-queried collection from parent |

### Elements to migrate from parent (~26)

**Assignments (8):** `Assign_Reset_Primary_Count_Email`, `Assign_Count_Primary_Email`, `Assign_Count_Primary_Email_Added`, `Assign_Build_Update_Email`, `Assign_Build_Delete_Email`, `Assign_Flag_New_Emails`, `Assign_Flag_Update_Emails`, `Assign_Build_New_Email`

**Decisions (6):** `Decision_Is_Email_Primary`, `Decision_Is_Email_Primary_Added`, `Decision_Email_Primary_Valid`, `Decision_Email_Marked_Delete`, `Decision_Has_Delete_Emails`, `Decision_Has_New_Emails`, `Decision_Has_Update_Emails`

**Loops (4):** `Loop_Count_Primary_Emails`, `Loop_Count_Primary_Emails_Added`, `Loop_Split_Emails`, `Loop_Split_Emails_New`

**DML (2):** `Create_New_Emails`, `Update_Emails`, `Delete_Emails`

**Screens (4):** `Screen_Manage_Emails`, `Screen_Confirm_Delete_Email`, `Screen_Success_Email`, `Error_Screen` *(own copy)*

**Variables to add locally:** `var_PrimaryCount`, `var_SingleEmail`, `var_NewEmails`, `var_UpdateEmails`, `var_DeleteEmails`, `var_HasNewEmails`, `var_HasUpdateEmails`

---

## Phase 5 — Build `SMQS_Screen_Manage_ContactPoints_Phone_Subflow`

**Flow type:** Screen Flow  
**API version:** 66.0

### Input variables (5)

| Variable | Type | Description |
|---|---|---|
| `recordId` | String | Account Id |
| `var_Account` | SObject (Account) | Pre-queried Account |
| `var_AllPhones` | SObject Collection (ContactPointPhone) | Pre-queried collection from parent |
| `var_SyncPhoneACRs` | SObject Collection (AccountContactRelation) | Pre-queried by parent |
| `var_NoSyncPhoneACRs` | SObject Collection (AccountContactRelation) | Pre-queried by parent |

### Elements to migrate from parent (~28)

**Assignments (8):** `Assign_Reset_Primary_Count_Phone`, `Assign_Count_Primary_Phone`, `Assign_Count_Primary_Phone_Added`, `Assign_Build_Update_Phone`, `Assign_Build_Delete_Phone`, `Assign_Flag_New_Phones`, `Assign_Flag_Update_Phones`, `Assign_Build_New_Phone`

**Decisions (7):** `Decision_Is_Phone_Primary`, `Decision_Is_Phone_Primary_Added`, `Decision_Phone_Primary_Valid`, `Decision_Phone_Marked_Delete`, `Decision_Has_Delete_Phones`, `Decision_Has_New_Phones`, `Decision_Has_Update_Phones`

**Loops (4):** `Loop_Count_Primary_Phones`, `Loop_Count_Primary_Phones_Added`, `Loop_Split_Phones`, `Loop_Split_Phones_New`

**DML (3):** `Create_New_Phones`, `Update_Phones`, `Delete_Phones`

**Screens (4):** `Screen_Manage_Phones`, `Screen_Confirm_Delete_Phone`, `Screen_Success_Phone`, `Error_Screen` *(own copy)*

**Variables to add locally:** `var_PrimaryCount`, `var_SinglePhone`, `var_NewPhones`, `var_UpdatePhones`, `var_DeletePhones`, `var_HasNewPhones`, `var_HasUpdatePhones`

---

## Phase 6 — Refactor `SMQS_Screen_Manage_ContactInfo` (parent)

**Goal:** Replace the 9 startup queries + 3 type branches with subflow calls. Keep AddAll path and orchestration unchanged.

### Elements to remove (78 total)

- All Address-domain elements: 25 (the non-AddAll ones)
- All Email-domain elements: 23 (the non-AddAll ones)
- All Phone-domain elements: 24 (the non-AddAll ones)
- The 9 startup query elements (`Get_Account`, `Get_Addresses`, `Get_Emails`, `Get_Phones`, `Get_ACRs_*` — 7 elements)

### Elements to add (5)

1. **Subflow call:** `Get_ContactInfo` → calls `SMQS_Autolaunched_Get_ContactInfo`
   - Input: `recordId`
   - Outputs mapped: `out_Account → var_Account`, `out_AllAddresses → var_AllAddresses`, etc.
2. **Subflow call:** `Manage_Address` → calls `SMQS_Screen_Manage_ContactPointAddress`
   - Inputs: `recordId`, `var_Account`, `var_AllAddresses`, `var_SyncACRs`, `var_NoSyncACRs`
3. **Subflow call:** `Manage_Email` → calls `SMQS_Screen_Manage_ContactPointEmail`
   - Inputs: `recordId`, `var_Account`, `var_AllEmails`
4. **Subflow call:** `Manage_Phone` → calls `SMQS_Screen_Manage_ContactPointPhone`
   - Inputs: `recordId`, `var_Account`, `var_AllPhones`, `var_SyncPhoneACRs`, `var_NoSyncPhoneACRs`

### What stays in parent (unchanged, ~46 elements)

- `Start` → `Get_ContactInfo` (subflow) → `Decision_Account_Exists` → `Error_Screen`
- `Decision_Blank_State` → all AddAll elements (~30)
- `Decision_Account_Type` → `Screen_Select_Type_Person/Business` → `Assign_Set_Type_Person/Business` → `Decision_Route_Type`
- `Decision_Route_Type` → 3 subflow calls

---

## AddAll elements that reference Address/Email/Phone logic

The AddAll path in the parent references some elements that are being moved to subflows. These AddAll-specific elements stay in the parent:

- `Assign_Build_New_Address_AddAll`, `Assign_Build_New_Address_AddAll_Bus` — stay in parent (used by AddAll loops)
- `Assign_Build_New_Email_AddAll` — stays in parent
- `Assign_Build_New_Phone_AddAll`, `Assign_Build_New_Phone_AddAll_Bus` — stays in parent
- `Create_New_Addresses_AddAll`, `Create_New_Emails_AddAll`, `Create_New_Phones_AddAll` — stay in parent
- `Loop_Split_Addresses_AddAll_New`, `Loop_Split_Emails_AddAll_New`, `Loop_Split_Phones_AddAll_New` etc. — stay in parent
- `Update_Primary_*_AddAll` — stay in parent
- `Get_New_*_For_Primary` — stay in parent

> These are distinct from the main-path elements of the same type. The classification script counted them under Address/Email/Phone domains, but functionally they belong to AddAll and must remain in the parent.

---

## Decision: `Screen_Error_Primary`

This screen is reached from all three type subflows when `var_PrimaryCount > 1`. Two options:

**Option A (Recommended): One copy per subflow**
Each subflow gets its own `Screen_Error_Primary`. Identical content, 3 copies. Clean — each subflow is fully self-contained.

**Option B: Keep in parent, wire fault back**
Subflow cannot navigate to a screen in its parent. This option is not possible in Salesforce Flow — subflows can't route back up to a parent screen. **Option A is the only viable path.**

---

## Deployment order

1. Deploy renamed read-only flows (`RelatedList_*`) and update flexipage references
2. Deploy `SMQS_Autolaunched_Get_ContactInfo` (no dependencies)
3. Deploy `SMQS_Screen_Manage_ContactPointAddress`, `_Email`, `_Phone` (depend on nothing)
4. Deploy updated `SMQS_Screen_Manage_ContactInfo` (depends on all 4 above being active)

> Steps 2–3 can deploy together. Do not deploy step 4 until all subflows are Active.

---

## Open questions before implementation

- [ ] Confirm the exact SOQL and field lists on each `recordLookup` element are copied faithfully into the new subflows (especially ACR filter criteria and sort orders on Get_Emails).
- [ ] Confirm formula elements (`formula_AddressName` etc.) — these stay in the parent for AddAll use; the type subflows may need their own copies if they reference them.
- [ ] Confirm dynamic choice sets (`dynamicChoiceSets`) — check which ones are used only in type subflow screens vs. the type picker screens in the parent. Screens own their component fields, so dynamic choice sets needed by a subflow screen must live in that subflow.
- [ ] Confirm `choices` (`choice_Address`, `choice_Email`, `choice_Phone`) — used only in the type picker screens (`Screen_Select_Type_Person/Business`), which stay in the parent. These stay in parent.
- [ ] Check whether `Screen_Error_Primary` has any dynamic content (e.g. `$Flow.FaultMessage`, Account name display) that needs `var_Account` wired as input to each subflow — confirmed it should already be wired since `var_Account` is an input variable on all three type subflows.
