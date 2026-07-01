#!/usr/bin/env python3
"""
Flow test suite: SMQS Phone/Email Sync
Runs all test cases from the manual test plan against SecBuild via the Salesforce REST API.
Usage: python3 scripts/test_phone_email_sync.py
"""

import json
import sys
import time
import urllib.parse
import urllib.request
import ssl
import subprocess
from typing import Optional

# ---------------------------------------------------------------------------
# Salesforce REST helpers
# ---------------------------------------------------------------------------

ctx = ssl.create_default_context()

def _req(method: str, url: str, token: str, body=None) -> dict:
    data = json.dumps(body).encode() if body else None
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, context=ctx) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read()
        raise RuntimeError(f"HTTP {e.code} {method} {url}: {raw.decode()}") from e


def get_org_credentials() -> tuple[str, str]:
    result = subprocess.run(
        ["sf", "org", "display", "--target-org", "SecBuild", "--json"],
        capture_output=True, text=True, check=True
    )
    d = json.loads(result.stdout)["result"]
    return d["instanceUrl"], d["accessToken"]


class SF:
    def __init__(self, instance_url: str, token: str):
        self.base = f"{instance_url}/services/data/v62.0"
        self.token = token

    def create(self, obj: str, fields: dict) -> str:
        r = _req("POST", f"{self.base}/sobjects/{obj}", self.token, fields)
        if not r.get("success"):
            raise RuntimeError(f"Create {obj} failed: {r}")
        return r["id"]

    def update(self, obj: str, record_id: str, fields: dict):
        _req("PATCH", f"{self.base}/sobjects/{obj}/{record_id}", self.token, fields)

    def delete(self, obj: str, record_id: str):
        _req("DELETE", f"{self.base}/sobjects/{obj}/{record_id}", self.token)

    def query(self, soql: str) -> list[dict]:
        encoded = urllib.parse.quote(soql)
        r = _req("GET", f"{self.base}/query?q={encoded}", self.token)
        return r.get("records", [])

    def get_cpps(self, account_id: str) -> list[dict]:
        return self.query(
            f"SELECT Id, TelephoneNumber, IsPrimary, UsageType, Invalid_Reason__c "
            f"FROM ContactPointPhone WHERE ParentId = '{account_id}' ORDER BY CreatedDate"
        )

    def get_cpes(self, account_id: str) -> list[dict]:
        return self.query(
            f"SELECT Id, EmailAddress, IsPrimary, UsageType, Invalid_Reason__c "
            f"FROM ContactPointEmail WHERE ParentId = '{account_id}' ORDER BY CreatedDate"
        )

    def get_account(self, account_id: str) -> dict:
        return self.query(
            f"SELECT Id, Phone, PersonHomePhone, PersonMobilePhone, PersonOtherPhone, "
            f"Secondary_Phone__c, IsPersonAccount FROM Account WHERE Id = '{account_id}'"
        )[0]

    def wait_for_flow(self, seconds: float = 2.0):
        """Flows are async after-save — give them a moment to complete."""
        time.sleep(seconds)


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------

PASS = "PASS"
FAIL = "FAIL"
results: list[tuple[str, str, str]] = []  # (id, outcome, detail)
_created: list[tuple[str, str]] = []  # (object, id) for cleanup


def record(test_id: str, passed: bool, detail: str = ""):
    outcome = PASS if passed else FAIL
    results.append((test_id, outcome, detail))
    mark = "✓" if passed else "✗"
    print(f"  {mark} {test_id}: {detail}" if detail else f"  {mark} {test_id}")


def cleanup(sf: SF):
    # Delete in reverse creation order; ContactPointPhone/Email first, then Accounts
    cpp_cpe = [(o, i) for o, i in reversed(_created) if o in ("ContactPointPhone", "ContactPointEmail")]
    accounts = [(o, i) for o, i in reversed(_created) if o == "Account"]
    for obj, rid in cpp_cpe + accounts:
        try:
            sf.delete(obj, rid)
        except Exception:
            pass


def make_person_account(sf: SF, **phone_fields) -> str:
    fields = {"LastName": "FlowTest", "RecordTypeId": get_person_account_rtid(sf), **phone_fields}
    aid = sf.create("Account", fields)
    _created.append(("Account", aid))
    return aid


def make_org_account(sf: SF, **phone_fields) -> str:
    fields = {"Name": "FlowTest Org", **phone_fields}
    aid = sf.create("Account", fields)
    _created.append(("Account", aid))
    return aid


_pa_rtid: Optional[str] = None
def get_person_account_rtid(sf: SF) -> str:
    global _pa_rtid
    if not _pa_rtid:
        recs = sf.query("SELECT Id FROM RecordType WHERE SObjectType='Account' AND IsPersonType=true LIMIT 1")
        if not recs:
            raise RuntimeError("No Person Account record type found in this org")
        _pa_rtid = recs[0]["Id"]
    return _pa_rtid


# ---------------------------------------------------------------------------
# Test groups
# ---------------------------------------------------------------------------

def run_group_1(sf: SF):
    print("\nGroup 1 — Baseline")

    # T1.1 Single phone field
    aid = make_person_account(sf, Phone="555-123-4567")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    record("T1.1", len(cpps) == 1 and cpps[0]["TelephoneNumber"] == "5551234567" and cpps[0]["IsPrimary"],
           f"CPP count={len(cpps)}, TelephoneNumber={cpps[0]['TelephoneNumber'] if cpps else 'none'}, IsPrimary={cpps[0]['IsPrimary'] if cpps else 'n/a'}")

    # T1.2 Update to new number
    sf.update("Account", aid, {"Phone": "(888) 999-0000"})
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    old = next((c for c in cpps if c["TelephoneNumber"] == "5551234567"), None)
    new = next((c for c in cpps if c["TelephoneNumber"] == "8889990000"), None)
    record("T1.2",
           old and old["Invalid_Reason__c"] == "Wrong Number" and not old["IsPrimary"]
           and new and new["IsPrimary"],
           f"old invalidated={old['Invalid_Reason__c'] if old else 'missing'}, new primary={new['IsPrimary'] if new else 'missing'}")

    # T1.3 Clear phone field
    sf.update("Account", aid, {"Phone": None})
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    active = [c for c in cpps if not c["Invalid_Reason__c"]]
    record("T1.3", len(active) == 0, f"active CPPs after clear={len(active)}")

    # T1.4 Two distinct numbers
    aid2 = make_person_account(sf, Phone="555-100-0001", PersonMobilePhone="555-200-0002")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid2)
    nums = {c["TelephoneNumber"] for c in cpps}
    record("T1.4", nums == {"5551000001", "5552000002"} and len(cpps) == 2,
           f"CPP count={len(cpps)}, numbers={nums}")


def run_group_2(sf: SF):
    print("\nGroup 2 — Duplicate prevention")

    # T2.1 Same number in Phone + HomePhone on create
    aid = make_person_account(sf, Phone="555-123-4567", PersonHomePhone="555-123-4567")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    record("T2.1", len(cpps) == 1 and cpps[0]["TelephoneNumber"] == "5551234567",
           f"CPP count={len(cpps)}")

    # T2.2 Update HomePhone to match existing Phone
    aid2 = make_person_account(sf, Phone="555-100-0001")
    sf.wait_for_flow()
    sf.update("Account", aid2, {"PersonHomePhone": "555-100-0001"})
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid2)
    record("T2.2", len(cpps) == 1, f"CPP count={len(cpps)} (expect 1)")

    # T2.3 All five fields same number
    aid3 = make_person_account(sf, Phone="(555) 555-5555", PersonHomePhone="(555) 555-5555",
                               PersonMobilePhone="(555) 555-5555", PersonOtherPhone="(555) 555-5555")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid3)
    record("T2.3", len(cpps) == 1 and cpps[0]["TelephoneNumber"] == "5555555555",
           f"CPP count={len(cpps)}")

    # T2.4 Both Phone and MobilePhone change to same new number simultaneously
    aid4 = make_person_account(sf)
    sf.wait_for_flow()
    sf.update("Account", aid4, {"Phone": "555-777-8888", "PersonMobilePhone": "555-777-8888"})
    sf.wait_for_flow()
    cpps = [c for c in sf.get_cpps(aid4) if not c["Invalid_Reason__c"]]
    record("T2.4", len(cpps) == 1 and cpps[0]["TelephoneNumber"] == "5557778888",
           f"active CPP count={len(cpps)}")


def run_group_3(sf: SF):
    print("\nGroup 3 — Format normalization")

    # T3.1 Format-only change does not create new CPP
    aid = make_person_account(sf, Phone="5551234567")
    sf.wait_for_flow()
    cpps_before = sf.get_cpps(aid)
    sf.update("Account", aid, {"Phone": "(555) 123-4567"})
    sf.wait_for_flow()
    cpps_after = sf.get_cpps(aid)
    active = [c for c in cpps_after if not c["Invalid_Reason__c"]]
    record("T3.1", len(active) == 1 and active[0]["TelephoneNumber"] == "5551234567",
           f"active CPPs={len(active)}, TelephoneNumber={active[0]['TelephoneNumber'] if active else 'none'}")

    # T3.2 Normalize on store
    aid2 = make_person_account(sf, Phone="(555) 123-4567")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid2)
    record("T3.2", cpps and cpps[0]["TelephoneNumber"] == "5551234567",
           f"TelephoneNumber={cpps[0]['TelephoneNumber'] if cpps else 'none'}")

    # T3.3 Format-varied duplicate across two fields
    aid3 = make_person_account(sf, Phone="555.123.4567", PersonHomePhone="(555)1234567")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid3)
    record("T3.3", len(cpps) == 1 and cpps[0]["TelephoneNumber"] == "5551234567",
           f"CPP count={len(cpps)}")

    # T3.4 International prefix stripped to digits
    aid4 = make_person_account(sf, Phone="+15551234567")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid4)
    record("T3.4", cpps and cpps[0]["TelephoneNumber"] == "15551234567",
           f"TelephoneNumber={cpps[0]['TelephoneNumber'] if cpps else 'none'}")


def run_group_4(sf: SF):
    print("\nGroup 4 — Reverse sync: CPP → Account")

    aid = make_person_account(sf, Phone="555-100-0001", PersonMobilePhone="555-200-0002")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    cpp_a = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    cpp_b = next((c for c in cpps if c["TelephoneNumber"] == "5552000002"), None)
    if not cpp_a or not cpp_b:
        record("T4.1", False, f"Setup failed: cpps={[c['TelephoneNumber'] for c in cpps]}")
        return
    # Promote CPP-B
    sf.update("ContactPointPhone", cpp_b["Id"], {"IsPrimary": True})
    sf.wait_for_flow()
    acct = sf.get_account(aid)
    cpps2 = sf.get_cpps(aid)
    cpp_a2 = next((c for c in cpps2 if c["TelephoneNumber"] == "5551000001"), None)
    cpp_b2 = next((c for c in cpps2 if c["TelephoneNumber"] == "5552000002"), None)
    record("T4.1",
           acct["Phone"] == "5552000002"
           and cpp_b2 and cpp_b2["IsPrimary"]
           and cpp_a2 and not cpp_a2["IsPrimary"],
           f"Account.Phone={acct['Phone']}, CPP-A primary={cpp_a2['IsPrimary'] if cpp_a2 else 'missing'}, CPP-B primary={cpp_b2['IsPrimary'] if cpp_b2 else 'missing'}")


def run_group_5(sf: SF):
    print("\nGroup 5 — Organization/Household Account")

    aid = make_org_account(sf, Phone="555-800-0000", Secondary_Phone__c="555-900-0000")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    nums = {c["TelephoneNumber"] for c in cpps}
    primary = [c for c in cpps if c["IsPrimary"]]
    secondary = [c for c in cpps if not c["IsPrimary"] and not c["Invalid_Reason__c"]]
    record("T5.1",
           nums == {"5558000000", "5559000000"} and len(primary) == 1 and primary[0]["TelephoneNumber"] == "5558000000",
           f"numbers={nums}, primary={primary[0]['TelephoneNumber'] if primary else 'none'}")


def run_group_6(sf: SF):
    print("\nGroup 6 — Promoting a CPP to Primary")

    # T6.1 Promote secondary on Person Account
    aid = make_person_account(sf, Phone="555-100-0001", PersonMobilePhone="555-200-0002")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    cpp_b = next((c for c in cpps if c["TelephoneNumber"] == "5552000002"), None)
    if not cpp_b:
        record("T6.1", False, "Setup failed"); return
    sf.update("ContactPointPhone", cpp_b["Id"], {"IsPrimary": True})
    sf.wait_for_flow()
    acct = sf.get_account(aid)
    cpps2 = sf.get_cpps(aid)
    cpp_a2 = next((c for c in cpps2 if c["TelephoneNumber"] == "5551000001"), None)
    cpp_b2 = next((c for c in cpps2 if c["TelephoneNumber"] == "5552000002"), None)
    record("T6.1",
           acct["Phone"] == "5552000002"
           and cpp_b2 and cpp_b2["IsPrimary"]
           and cpp_a2 and not cpp_a2["IsPrimary"]
           and len(cpps2) == 2,
           f"Account.Phone={acct['Phone']}, CPP count={len(cpps2)}")

    # T6.2 Promote secondary on Business Account (secondary moves to Secondary_Phone__c)
    aid2 = make_org_account(sf, Phone="555-100-0001", Secondary_Phone__c="555-200-0002")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid2)
    cpp_b = next((c for c in cpps if c["TelephoneNumber"] == "5552000002"), None)
    if not cpp_b:
        record("T6.2", False, "Setup failed"); return
    sf.update("ContactPointPhone", cpp_b["Id"], {"IsPrimary": True})
    sf.wait_for_flow()
    acct2 = sf.get_account(aid2)
    record("T6.2",
           acct2["Phone"] == "5552000002" and acct2["Secondary_Phone__c"] == "5551000001",
           f"Account.Phone={acct2['Phone']}, Secondary_Phone__c={acct2['Secondary_Phone__c']}")

    # T6.3 Promote when old AccountPhone CPP is already invalidated (no Secondary promotion)
    aid3 = make_org_account(sf, Phone="555-100-0001", Secondary_Phone__c="555-200-0002")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid3)
    cpp_a = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    cpp_b = next((c for c in cpps if c["TelephoneNumber"] == "5552000002"), None)
    if not cpp_a or not cpp_b:
        record("T6.3", False, "Setup failed"); return
    # Invalidate CPP-A manually first
    sf.update("ContactPointPhone", cpp_a["Id"], {"Invalid_Reason__c": "Wrong Number", "IsPrimary": False})
    sf.wait_for_flow()
    sf.update("ContactPointPhone", cpp_b["Id"], {"IsPrimary": True})
    sf.wait_for_flow()
    acct3 = sf.get_account(aid3)
    # Secondary_Phone__c should NOT have been updated to the old Phone (5551000001) because
    # its CPP is already invalid. It retains whatever value it had before the promote.
    record("T6.3",
           acct3["Phone"] == "5552000002" and acct3["Secondary_Phone__c"] != "5551000001",
           f"Account.Phone={acct3['Phone']}, Secondary_Phone__c={acct3['Secondary_Phone__c']} (should not be 5551000001)")

    # T6.4 Promote CPP that already matches AccountPhone — no-op
    aid4 = make_person_account(sf, Phone="555-100-0001")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid4)
    cpp_a = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    if not cpp_a:
        record("T6.4", False, "Setup failed"); return
    acct_before = sf.get_account(aid4)
    sf.update("ContactPointPhone", cpp_a["Id"], {"IsPrimary": True})
    sf.wait_for_flow()
    acct_after = sf.get_account(aid4)
    record("T6.4",
           acct_after["Phone"] == acct_before["Phone"],
           f"Account.Phone before={acct_before['Phone']}, after={acct_after['Phone']}")


def run_group_7(sf: SF):
    print("\nGroup 7 — Demoting a CPP")

    # T7.1 Manually set IsPrimary=false — CPP→Account flow should NOT fire
    aid = make_person_account(sf, Phone="555-100-0001")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    cpp_a = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    if not cpp_a:
        record("T7.1", False, "Setup failed"); return
    sf.update("ContactPointPhone", cpp_a["Id"], {"IsPrimary": False})
    sf.wait_for_flow()
    acct = sf.get_account(aid)
    record("T7.1",
           acct["Phone"] == "5551000001",
           f"Account.Phone={acct['Phone']} (should be unchanged)")

    # T7.2 Indirect demote via promoting another CPP
    aid2 = make_person_account(sf, Phone="555-100-0001", PersonMobilePhone="555-200-0002")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid2)
    cpp_b = next((c for c in cpps if c["TelephoneNumber"] == "5552000002"), None)
    if not cpp_b:
        record("T7.2", False, "Setup failed"); return
    sf.update("ContactPointPhone", cpp_b["Id"], {"IsPrimary": True})
    sf.wait_for_flow()
    cpps2 = sf.get_cpps(aid2)
    cpp_a2 = next((c for c in cpps2 if c["TelephoneNumber"] == "5551000001"), None)
    record("T7.2",
           cpp_a2 and not cpp_a2["IsPrimary"],
           f"CPP-A IsPrimary={cpp_a2['IsPrimary'] if cpp_a2 else 'missing'}")


def run_group_8(sf: SF):
    print("\nGroup 8 — Invalid Reason")

    # T8.1 Flow invalidation: clear phone field
    aid = make_person_account(sf, Phone="555-100-0001")
    sf.wait_for_flow()
    sf.update("Account", aid, {"Phone": None})
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid)
    cpp_a = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    record("T8.1",
           cpp_a and cpp_a["Invalid_Reason__c"] == "Wrong Number" and not cpp_a["IsPrimary"],
           f"Invalid_Reason__c={cpp_a['Invalid_Reason__c'] if cpp_a else 'missing'}")

    # T8.2 Flow invalidation: change to new number
    aid2 = make_person_account(sf, Phone="555-100-0001")
    sf.wait_for_flow()
    sf.update("Account", aid2, {"Phone": "555-999-0000"})
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid2)
    old = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    new = next((c for c in cpps if c["TelephoneNumber"] == "5559990000"), None)
    record("T8.2",
           old and old["Invalid_Reason__c"] == "Wrong Number" and not old["IsPrimary"]
           and new and new["IsPrimary"],
           f"old={old['Invalid_Reason__c'] if old else 'missing'}, new primary={new['IsPrimary'] if new else 'missing'}")

    # T8.3 Released number still in another field → demote not invalidate
    aid3 = make_person_account(sf, Phone="555-100-0001", PersonMobilePhone="555-100-0001")
    sf.wait_for_flow()
    sf.update("Account", aid3, {"Phone": "555-999-0000"})
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid3)
    shared = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    new = next((c for c in cpps if c["TelephoneNumber"] == "5559990000"), None)
    record("T8.3",
           shared and not shared["Invalid_Reason__c"] and not shared["IsPrimary"]
           and new and new["IsPrimary"],
           f"shared CPP invalid={shared['Invalid_Reason__c'] if shared else 'missing'}, new primary={new['IsPrimary'] if new else 'missing'}")

    # T8.4 Manual Invalid_Reason__c — Account.Phone should NOT change
    aid4 = make_person_account(sf, Phone="555-100-0001")
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid4)
    cpp_a = next((c for c in cpps if c["TelephoneNumber"] == "5551000001"), None)
    if not cpp_a:
        record("T8.4", False, "Setup failed"); return
    sf.update("ContactPointPhone", cpp_a["Id"], {"Invalid_Reason__c": "Wrong Number", "IsPrimary": False})
    sf.wait_for_flow()
    acct = sf.get_account(aid4)
    record("T8.4",
           acct["Phone"] == "5551000001",
           f"Account.Phone={acct['Phone']} (should be unchanged)")

    # T8.5 Re-add a previously invalidated number → CPP reactivated, no duplicate
    aid5 = make_person_account(sf)
    sf.wait_for_flow()
    # Create a CPP manually and invalidate it
    cpp_id = sf.create("ContactPointPhone", {
        "ParentId": aid5,
        "TelephoneNumber": "5551000001",
        "Invalid_Reason__c": "Wrong Number",
        "IsPrimary": False,
        "UsageType": "Inactive"
    })
    _created.append(("ContactPointPhone", cpp_id))
    sf.update("Account", aid5, {"Phone": "555-100-0001"})
    sf.wait_for_flow()
    cpps = sf.get_cpps(aid5)
    active = [c for c in cpps if c["TelephoneNumber"] == "5551000001"]
    record("T8.5",
           len(active) == 1 and not active[0]["Invalid_Reason__c"] and active[0]["IsPrimary"],
           f"CPP count for number={len(active)}, Invalid_Reason__c={active[0]['Invalid_Reason__c'] if active else 'n/a'}, IsPrimary={active[0]['IsPrimary'] if active else 'n/a'}")


def run_email_group(sf: SF):
    print("\nGroup E — Email sync (parity checks)")

    # TE.1 Create CPE on new PersonEmail
    aid = make_person_account(sf, PersonEmail="test@example.com")
    sf.wait_for_flow()
    cpes = sf.get_cpes(aid)
    record("TE.1", len(cpes) == 1 and cpes[0]["EmailAddress"] == "test@example.com" and cpes[0]["IsPrimary"],
           f"CPE count={len(cpes)}")

    # TE.2 Change email → old invalidated, new created
    sf.update("Account", aid, {"PersonEmail": "new@example.com"})
    sf.wait_for_flow()
    cpes = sf.get_cpes(aid)
    old = next((c for c in cpes if c["EmailAddress"] == "test@example.com"), None)
    new = next((c for c in cpes if c["EmailAddress"] == "new@example.com"), None)
    # Email deactivation sets UsageType=Inactive + IsPrimary=false (no Invalid_Reason__c on email)
    record("TE.2",
           old and old["UsageType"] == "Inactive" and not old["IsPrimary"]
           and new and new["IsPrimary"],
           f"old UsageType={old['UsageType'] if old else 'missing'}, old IsPrimary={old['IsPrimary'] if old else 'n/a'}, new primary={new['IsPrimary'] if new else 'missing'}")

    # TE.3 Re-add previously invalidated email → reactivated, no duplicate
    sf.update("Account", aid, {"PersonEmail": "test@example.com"})
    sf.wait_for_flow()
    cpes = sf.get_cpes(aid)
    matching = [c for c in cpes if c["EmailAddress"] == "test@example.com"]
    record("TE.3",
           len(matching) == 1 and not matching[0]["Invalid_Reason__c"] and matching[0]["IsPrimary"],
           f"CPE count for address={len(matching)}, Invalid_Reason__c={matching[0]['Invalid_Reason__c'] if matching else 'n/a'}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("Connecting to SecBuild...")
    instance_url, token = get_org_credentials()
    sf = SF(instance_url, token)
    print(f"Connected: {instance_url}")

    try:
        run_group_1(sf)
        run_group_2(sf)
        run_group_3(sf)
        run_group_4(sf)
        run_group_5(sf)
        run_group_6(sf)
        run_group_7(sf)
        run_group_8(sf)
        run_email_group(sf)
    finally:
        print("\nCleaning up test data...")
        cleanup(sf)

    # Summary
    passed = sum(1 for _, o, _ in results if o == PASS)
    failed = sum(1 for _, o, _ in results if o == FAIL)
    print(f"\n{'='*60}")
    print(f"Results: {passed} passed, {failed} failed out of {len(results)} tests")
    if failed:
        print("\nFailed tests:")
        for tid, outcome, detail in results:
            if outcome == FAIL:
                print(f"  ✗ {tid}: {detail}")
    print("="*60)
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
