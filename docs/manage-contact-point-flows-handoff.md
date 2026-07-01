# Handoff: SMQS Manage ContactPoint Screen Flows

## What exists

Two screen flow files were created and are committed locally:
- `force-app/main/default/flows/SMQS_Manage_ContactPointPhone.flow-meta.xml`
- `force-app/main/default/flows/SMQS_Manage_ContactPointEmail.flow-meta.xml`

One Apex test class is ready and compiles cleanly:
- `force-app/main/default/classes/SMQS_ManageContactPointFlowTest.cls`

Two custom fields were successfully deployed to `firstbuild` sandbox:
- `ContactPointPhone.Invalid_Reason__c`
- `ContactPointEmail.Invalid_Reason__c`

## What the flows are supposed to do

Each flow is a Screen Flow embedded on the Account record page via `recordId` input variable.

**Intended UX:**
1. Screen 1 — RadioButtons: "What would you like to do?" → Mark as Primary / Mark as Invalid
2. Decision routes on the answer
3. **Primary path:** Data table (single-select) → user picks one record → loop sets `IsPrimary=true` on that record → criteria-based update demotes all other primaries → update staged collection → success screen
4. **Invalid path:** Data table (multi-select) → user picks one or more records → Screen 2 RadioButtons: choose Invalid Reason → loop sets `Invalid_Reason__c` and `IsPrimary=false` on each selected record → update staged collection → success screen

## The blocking problem

The Salesforce metadata API rejects `Screen_Choose_Action.radio_Action` when it appears in a Decision condition or an Assignment `elementReference`. Exact error:

```
field integrity exception: unknown (The "Screen_Choose_Action.radio_Action" element
doesn't exist. Remove references to the element in all conditions.)
```

This applies even when:
- `allowBack=true` and `allowFinish=false` (forcing Next-only exit, guaranteeing the field was populated)
- The reference is in an Assignment immediately downstream of the screen, not a Decision

**What has been tried and rejected:**
| Attempt | Error |
|---|---|
| `Screen_Choose_Action.radio_Action` in Decision condition | field integrity exception |
| Intermediate Assignment to `var_Action`, then Decision on `var_Action` | same error on the Assignment |
| `<outputParameters>` on RadioButtons field | "Outputs aren't supported for fieldType RadioButtons" |
| `<value><elementReference>var_Action</elementReference></value>` on RadioButtons field | XML parse error: element `value` invalid at this location |
| `<defaultValue><elementReference>var_Action</elementReference></defaultValue>` on RadioButtons field | XML parse error |
| `allowBack=true, allowFinish=false` on Screen_Choose_Action | did not unblock the reference error |

## Resolution

**Bare field name references (no `Screen_X.` prefix) are accepted by the metadata API.**

The fix is to reference screen RadioButtons fields by their API name alone — `radio_Action` and `radio_InvalidReason` — without the `Screen_X.` prefix. The API resolves screen field names as flow-scope identifiers when they are unique across the flow.

What was tried and rejected before finding this:
| Attempt | Error |
|---|---|
| `Screen_Choose_Action.radio_Action` in Decision condition | field integrity exception |
| `<formulas>` with `{!Screen_Choose_Action.radio_Action}` expression | formula field does not exist |
| `<formulas>` with `{!radio_Action}` expression | radio_Action variable does not exist |
| `storeOutputAutomatically=true` on RadioButtons field | not supported for RadioButtons |
| `conditionLogic=formula` with `<formulaExpression>` in `<conditions>` | element invalid at this location |
| `conditionLogic=formula` with `<formulaExpression>` in `<rules>` | element invalid at this location |
| Bare `radio_Action` reference in Decision condition | **succeeds** |

Both flows deployed successfully to `SecBuild` on 2026-05-20.

## Sandbox

Alias: `SecBuild`  
Username: `justinsgilmore-zbrs@force.com.secbuild`

> Note: The handoff doc originally referenced `firstbuild`. Builds are now done in `secbuild`.

## Data table columns (match existing related list layouts)

**Phone (`SMQS_Manage_ContactPointPhone`):**  
`TelephoneNumber`, `IsPrimary`, `UsageType`, `Invalid_Reason__c`  
(Note: `Map_To__c` is NOT deployed to `firstbuild` — omit from this sandbox)

**Email (`SMQS_Manage_ContactPointEmail`):**  
`EmailAddress`, `IsPrimary`, `UsageType`, `Invalid_Reason__c`

## Invalid_Reason__c picklist values

**Phone:** Old Number, Wrong Number, Disconnected  
**Email:** Typo, Wrong Person, Manual Unsubscribe, No Longer Used

## Apex test class

[SMQS_ManageContactPointFlowTest.cls](../force-app/main/default/classes/SMQS_ManageContactPointFlowTest.cls)

12 tests. Does NOT invoke the flows — simulates the DML the flows perform and asserts:
1. CPP/CPE field values are committed correctly
2. Account Phone/PersonEmail fields are not overwritten by the sync flows reacting to the changes

Deploy and run:
```bash
sf project deploy start \
  --source-dir force-app/main/default/classes/SMQS_ManageContactPointFlowTest.cls \
  --source-dir force-app/main/default/classes/SMQS_ManageContactPointFlowTest.cls-meta.xml \
  --target-org firstbuild --wait 30

sf apex run test \
  --class-names SMQS_ManageContactPointFlowTest \
  --target-org firstbuild --synchronous --result-format human
```
