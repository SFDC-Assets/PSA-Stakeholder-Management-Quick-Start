# Contact Points Flow Review

Audit of the five SMQS_Screen_Manage_ContactPoints flows. Respond inline under each item.

---

## Functional Gaps

### 1. Address sync tables not gated to household accounts
Phone sync tables check `Is_Household__c = true` before showing. Address sync tables don't — a Business Account user will see household sync membership tables even though they're irrelevant.

**Your response:**
The should not show up for organization accounts, but they should show up for households and individuals

---

### 2. Email has no `Active__c` field
`ContactPointAddress` and `ContactPointPhone` both have `Active__c`. `ContactPointEmail` has neither a field nor a UI control for it.

**Your response:**
That should be added, and the field should exist

---

### 3. New addresses added via manage-addresses subflow get no Name
The blank-state path stamps a formula name (`[Account Name] Mailing Address [Mon, YYYY]`). The normal subflow path creates new addresses without setting `Name` — they land with a blank Name in Salesforce.

**Your response:**
Make this consistent with the formula name.

---

### 4. Blank-state phone path may not stamp `Active__c = true`
The blank-state loops (`Assign_Build_New_Phone_AddAll`) stamp `IsPrimary` and `UsageType`, but it's worth confirming `Active__c = true` is set there too.

**Your response:**
Agree

---

### 5. Business account blank-state has no Email section
Person blank-state has Address + Email + Phone. Business has Address + Phone only.

**Your response (intentional?):**
Thats intentional. Business accounts only have two phone fields, so they don't need usage type. And there are no email fields. 

---

## UX / Consistency Issues

### 6. Primary validation is a dead-end
When a user marks >1 record as Primary, they hit `Screen_Error_Primary` with no Back button — they must cancel the entire flow and start over.

**Your response:**
Alow them to go back, and provide them instructions on that option.

---

### 7. UsageType values inconsistent between paths
Blank-state phone repeater uses static choices (Mobile, Home, Other). The manage-phone repeater uses a dynamic choice set from the org (Home, Work, Temporary, Inactive). A user entering "Mobile" in blank-state, then editing that phone later, sees a different option set.

**Your response:**
Usage type will be inconsistent.

---

### 8. Deletion confirmation has no escape hatch
Once on the confirmation screen, the user can complete deletion or cancel the whole flow — there's no "go back and un-mark" option.

**Your response:**
Agreed that should be supported. 

---

### 9. Success screens vary across subflows
Address, Email, and Phone each have separate success screens. Worth confirming they show consistent confirmation detail.

**Your response:**
agreed

---

## Architecture / Quality

### 10. Four ACR queries always run
All four ACR queries (SyncYes/SyncNo for address and phone) run unconditionally, including for Business Accounts with no household context. Minor performance waste.

**Your response:**
I don't think we need to worry about this. 

---

### 11. Error screen duplicated four times
Identical error HTML exists in the main flow, Address subflow, Email subflow, and Phone subflow. One change currently requires four edits.

**Your response:**
thats fine

---
