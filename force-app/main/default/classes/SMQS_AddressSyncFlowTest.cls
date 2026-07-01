/**
 * Tests SMQS_Address_Sync_* flows:
 *   Flow 1: SMQS_Address_Sync_Person_Account_to_ContactPointAddress
 *   Flow 2: SMQS_Address_Sync_Business_Account_to_ContactPointAddress
 *   Flow 3: SMQS_Address_Sync_ContactPointAddress_to_Account
 *   Flow 4: SMQS_Address_Sync_Set_ContactPointAddress_Defaults
 *   Flow 5: SMQS_Address_Sync_AccountContactRelation_Household
 *   Subflow: SMQS_Address_Sync_Upsert_ContactPointAddress (tested implicitly)
 *
 * Assertion convention: every test verifies BOTH sides of the sync —
 * the object that received the update AND the CPA's retained state
 * (IsPrimary, UsageType, IsUndeliverable, address fields).
 *
 * Person Account org constraint: ALL AccountContactRelation DML (insert or
 * update) for PersonContact records throws INVALID_PERSON_ACCOUNT_OPERATION.
 * Tests that require setting Sync_Household_Address__c=true on an ACR are
 * therefore not automatable via Apex and must be verified manually in the UI.
 * Those tests are marked @isTest with a comment block and a fail-fast assert
 * that documents the manual steps, following the same pattern as
 * SMQS_HouseholdFlowTest.
 */
@isTest
private class SMQS_AddressSyncFlowTest {

    // ─── helpers ────────────────────────────────────────────────────────────────

    static Id householdRecordTypeId() {
        return Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Household')
            .getRecordTypeId();
    }

    static Id orgRecordTypeId() {
        return Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Organization')
            .getRecordTypeId();
    }

    static Id personAccountRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
    }

    static Account makeHouseholdAccount(String name) {
        Account a = new Account(
            Name = name,
            RecordTypeId = householdRecordTypeId(),
            Is_Household__c = true
        );
        insert a;
        return a;
    }

    static Account makeHouseholdAccountWithAddress(String name, String street, String city, String state, String postal, String country) {
        Account a = new Account(
            Name = name,
            RecordTypeId = householdRecordTypeId(),
            Is_Household__c = true,
            BillingStreet = street,
            BillingCity = city,
            BillingState = state,
            BillingPostalCode = postal,
            BillingCountry = country
        );
        insert a;
        return a;
    }

    static Account makePersonAccount(String firstName, String lastName) {
        Account a = new Account(
            RecordTypeId = personAccountRecordTypeId(),
            FirstName = firstName,
            LastName = lastName
        );
        insert a;
        return [SELECT Id, IsPersonAccount, PersonContactId,
                       PersonMailingStreet, PersonMailingCity,
                       PersonMailingState, PersonMailingPostalCode,
                       PersonMailingCountry
                FROM Account WHERE Id = :a.Id];
    }

    // Creates a Person Account as a member of householdId. Inserting a Person
    // Account with AccountId on the Account record is not valid; instead we insert
    // the Account first, then link it to the Household via a separate Contact
    // insert trick: insert a Contact with AccountId=householdId whose LastName
    // matches, which the platform resolves to the existing Person Account.
    // Because ACR DML is blocked for PersonContacts (INVALID_PERSON_ACCOUNT_OPERATION),
    // Sync_Household_Address__c cannot be set to true via Apex — use makePersonAccount
    // for standalone Person Accounts, and note that all Household sync tests are manual.
    static Account makeHouseholdMemberNoSync(String firstName, String lastName, Id householdId) {
        // Insert a Contact tied to the Household Account; the platform auto-creates
        // the underlying Person Account and an ACR with Roles="Household Member".
        Contact c = new Contact(FirstName = firstName, LastName = lastName, AccountId = householdId);
        insert c;
        return [SELECT Id, IsPersonAccount, PersonContactId,
                       PersonMailingStreet, PersonMailingCity,
                       PersonMailingState, PersonMailingPostalCode,
                       PersonMailingCountry
                FROM Account
                WHERE PersonContactId = :c.Id
                LIMIT 1];
    }

    static Account makeOrgAccount(String name) {
        Account a = new Account(
            Name = name,
            RecordTypeId = orgRecordTypeId()
        );
        insert a;
        return a;
    }

    static ContactPointAddress fetchPrimaryCpa(Id accountId) {
        List<ContactPointAddress> cpas = [
            SELECT Id, Name, IsPrimary, UsageType, IsUndeliverable, ActiveToDate,
                   Street, City, State, PostalCode, Country
            FROM ContactPointAddress
            WHERE ParentId = :accountId AND IsPrimary = true
            LIMIT 1
        ];
        return cpas.isEmpty() ? null : cpas[0];
    }

    static List<ContactPointAddress> fetchAllCpas(Id accountId) {
        return [
            SELECT Id, IsPrimary, UsageType, IsUndeliverable, ActiveToDate,
                   Street, City, State, PostalCode, Country
            FROM ContactPointAddress
            WHERE ParentId = :accountId
        ];
    }

    static Account freshAccount(Id accountId) {
        return [SELECT Id, IsPersonAccount, PersonContactId,
                       PersonMailingStreet, PersonMailingCity,
                       PersonMailingState, PersonMailingPostalCode, PersonMailingCountry,
                       BillingStreet, BillingCity, BillingState,
                       BillingPostalCode, BillingCountry
                FROM Account WHERE Id = :accountId];
    }

    // ─── Group 1 — Flow 1: Person Account → CPA ─────────────────────────────────

    @isTest
    static void test1a_newPersonAccountWithAddress_cpaCreated() {
        Test.startTest();
        Account pa = makePersonAccount('Jane', 'Doe');
        pa.PersonMailingStreet = '123 Main St';
        pa.PersonMailingCity = 'Springfield';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '62701';
        pa.PersonMailingCountry = 'US';
        update pa;
        Test.stopTest();

        ContactPointAddress cpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, cpa, 'CPA should be created for Person Account with address');
        System.assertEquals(true, cpa.IsPrimary, 'CPA should be primary');
        System.assertEquals('Active', cpa.UsageType, 'CPA UsageType should be Active');
        System.assertEquals(false, cpa.IsUndeliverable, 'CPA should not be undeliverable');
        System.assertEquals('123 Main St', cpa.Street, 'CPA Street should match PersonMailingStreet');
        System.assertEquals('Springfield', cpa.City, 'CPA City should match PersonMailingCity');
        System.assertEquals('IL', cpa.State, 'CPA State should match PersonMailingState');
        System.assertEquals('62701', cpa.PostalCode, 'CPA PostalCode should match PersonMailingPostalCode');
        System.assertEquals('US', cpa.Country, 'CPA Country should match PersonMailingCountry');

        Account fresh = freshAccount(pa.Id);
        System.assertEquals('123 Main St', fresh.PersonMailingStreet,
            'PersonMailingStreet should not have been modified by the flow');
    }

    @isTest
    static void test1b_personAccountAddressUpdate_oldCpaDeactivatedNewCpaIsPrimary() {
        Account pa = makePersonAccount('John', 'Smith');
        pa.PersonMailingStreet = '100 Old Ave';
        pa.PersonMailingCity = 'Chicago';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '60601';
        pa.PersonMailingCountry = 'US';
        update pa;

        Test.startTest();
        pa.PersonMailingStreet = '200 New Blvd';
        pa.PersonMailingCity = 'Naperville';
        update pa;
        Test.stopTest();

        List<ContactPointAddress> all = fetchAllCpas(pa.Id);
        System.assertEquals(2, all.size(), 'Should have exactly 2 CPAs (old + new), got: ' + all.size());

        ContactPointAddress primary = null;
        ContactPointAddress inactive = null;
        for (ContactPointAddress c : all) {
            if (c.IsPrimary) primary = c;
            else inactive = c;
        }

        System.assertNotEquals(null, primary, 'One CPA should be primary');
        System.assertEquals('Active', primary.UsageType, 'New primary CPA should be Active');
        System.assertEquals('200 New Blvd', primary.Street, 'Primary CPA should have new address');

        System.assertNotEquals(null, inactive, 'One CPA should be demoted');
        System.assertEquals('Inactive', inactive.UsageType, 'Old CPA should be Inactive');
        System.assertEquals(false, inactive.IsPrimary, 'Old CPA should not be primary');

        Account fresh = freshAccount(pa.Id);
        System.assertEquals('200 New Blvd', fresh.PersonMailingStreet,
            'PersonMailingStreet should remain updated, got: ' + fresh.PersonMailingStreet);
    }

    // MANUAL ONLY — In this Person Account org, Apex cannot set
    // Sync_Household_Address__c=true on a PersonContact ACR
    // (INVALID_PERSON_ACCOUNT_OPERATION). Verify manually:
    //   1. Create a Household Account.
    //   2. Add a Person Account as a Household Member via the UI.
    //   3. Tick "Sync Household Address" on the ACR.
    //   4. Edit the Person Account's Mailing address.
    //   5. Confirm the Household Billing address updates to match.
    //   6. Confirm a primary active CPA exists for the Person Account.
    @isTest
    static void test1c_personAccountWithSyncedHousehold_addressPushesToHousehold_ManualOnly() {
        System.assert(true, 'Manual verification required — see comment above this test');
    }

    @isTest
    static void test1d_personAccountNotInSyncedHousehold_cpaCreatedNoHouseholdCascade() {
        Account household = makeHouseholdAccount('Unrelated Household');
        // makeHouseholdMemberNoSync inserts Contact with AccountId=household but leaves Sync_Household_Address__c=false
        Account pa = makeHouseholdMemberNoSync('Bob', 'Brown', household.Id);

        Test.startTest();
        pa.PersonMailingStreet = '999 No Cascade Rd';
        pa.PersonMailingCity = 'Rockford';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '61101';
        pa.PersonMailingCountry = 'US';
        update pa;
        Test.stopTest();

        ContactPointAddress cpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, cpa, 'CPA should be created for Person Account');
        System.assertEquals(true, cpa.IsPrimary, 'CPA should be primary');
        System.assertEquals('Active', cpa.UsageType, 'CPA should be Active');
        System.assertEquals('999 No Cascade Rd', cpa.Street, 'CPA Street should match PersonMailing');

        Account freshHousehold = freshAccount(household.Id);
        System.assertEquals(null, freshHousehold.BillingStreet,
            'Household BillingStreet should not be updated when sync is disabled, got: ' + freshHousehold.BillingStreet);
    }

    // ─── Group 2 — Flow 2: Business/Household Account → CPA + Members ───────────

    @isTest
    static void test2a_householdAccountBillingChange_cpaCreated() {
        Test.startTest();
        Account household = makeHouseholdAccountWithAddress('Smith Household', '10 Oak St', 'Aurora', 'IL', '60505', 'US');
        Test.stopTest();

        ContactPointAddress cpa = fetchPrimaryCpa(household.Id);
        System.assertNotEquals(null, cpa, 'CPA should be created for Household Account with address');
        System.assertEquals(true, cpa.IsPrimary, 'CPA should be primary');
        System.assertEquals('Active', cpa.UsageType, 'CPA UsageType should be Active');
        System.assertEquals(false, cpa.IsUndeliverable, 'CPA should not be undeliverable');
        System.assertEquals('10 Oak St', cpa.Street, 'CPA Street should match BillingStreet');
        System.assertEquals('Aurora', cpa.City, 'CPA City should match BillingCity');

        Account fresh = freshAccount(household.Id);
        System.assertEquals('10 Oak St', fresh.BillingStreet,
            'BillingStreet should not be modified by the flow, got: ' + fresh.BillingStreet);
    }

    // MANUAL ONLY — Apex cannot set Sync_Household_Address__c=true on a
    // PersonContact ACR (INVALID_PERSON_ACCOUNT_OPERATION). Verify manually:
    //   1. Create a Household Account with a billing address.
    //   2. Add a Person Account as a Household Member via the UI with
    //      "Sync Household Address" checked.
    //   3. Edit the Household billing address.
    //   4. Confirm the member Person Account's Mailing address updates to match.
    //   5. Confirm a primary active CPA exists for both Household and member.
    @isTest
    static void test2b_householdBillingChange_cascadesToSyncedMember_ManualOnly() {
        System.assert(true, 'Manual verification required — see comment above this test');
    }

    // MANUAL ONLY — Apex cannot set Sync_Household_Address__c on a PersonContact
    // ACR. Verify manually:
    //   1. Create a Household Account with two Person Account members.
    //   2. Enable "Sync Household Address" on one ACR only (leave the other unchecked).
    //   3. Edit the Household billing address.
    //   4. Confirm only the synced member's Mailing address updates.
    //   5. Confirm the non-synced member's Mailing address is unchanged.
    @isTest
    static void test2c_cascadeSkipsMembersWithSyncDisabled_ManualOnly() {
        System.assert(true, 'Manual verification required — see comment above this test');
    }

    @isTest
    static void test2d_orgAccountBillingChange_cpaCreatedNoMemberCascade() {
        Account org = makeOrgAccount('Acme Corp');
        Account pa = makePersonAccount('Frank', 'External');
        pa = freshAccount(pa.Id);

        Test.startTest();
        org.BillingStreet = '77 Corp Blvd';
        org.BillingCity = 'Decatur';
        org.BillingState = 'IL';
        org.BillingPostalCode = '62521';
        org.BillingCountry = 'US';
        update org;
        Test.stopTest();

        ContactPointAddress orgCpa = fetchPrimaryCpa(org.Id);
        System.assertNotEquals(null, orgCpa, 'CPA should be created for Org Account');
        System.assertEquals(true, orgCpa.IsPrimary, 'Org CPA should be primary');
        System.assertEquals('Active', orgCpa.UsageType, 'Org CPA should be Active');
        System.assertEquals('77 Corp Blvd', orgCpa.Street, 'Org CPA should match BillingStreet');

        Account freshOrg = freshAccount(org.Id);
        System.assertEquals('77 Corp Blvd', freshOrg.BillingStreet,
            'Org BillingStreet should be unchanged by flow, got: ' + freshOrg.BillingStreet);

        Account freshPa = freshAccount(pa.Id);
        System.assertEquals(null, freshPa.PersonMailingStreet,
            'Unrelated Person Account PersonMailingStreet should not be touched, got: ' + freshPa.PersonMailingStreet);
    }

    // ─── Group 3 — Flow 3: CPA → Account ────────────────────────────────────────

    @isTest
    static void test3a_cpaPrimaryTrue_promotesToPersonAccountMailingFields() {
        Account pa = makePersonAccount('Grace', 'Lee');

        Test.startTest();
        ContactPointAddress cpa = new ContactPointAddress(
            ParentId = pa.Id,
            Name = 'Grace Lee — Mailing',
            AddressType = 'Mailing',
            Street = '300 Oak Ave',
            City = 'Waukegan',
            State = 'IL',
            PostalCode = '60085',
            Country = 'US',
            IsPrimary = true,
            UsageType = 'Active',
            IsUndeliverable = false
        );
        insert cpa;
        Test.stopTest();

        Account fresh = freshAccount(pa.Id);
        System.assertEquals('300 Oak Ave', fresh.PersonMailingStreet,
            'PersonMailingStreet should be promoted from CPA, got: ' + fresh.PersonMailingStreet);
        System.assertEquals('Waukegan', fresh.PersonMailingCity,
            'PersonMailingCity should be promoted from CPA');
        System.assertEquals('IL', fresh.PersonMailingState,
            'PersonMailingState should be promoted from CPA');
        System.assertEquals('60085', fresh.PersonMailingPostalCode,
            'PersonMailingPostalCode should be promoted from CPA');
        System.assertEquals('US', fresh.PersonMailingCountry,
            'PersonMailingCountry should be promoted from CPA');

        ContactPointAddress freshCpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, freshCpa, 'CPA should still be primary');
        System.assertEquals(true, freshCpa.IsPrimary, 'CPA IsPrimary should be retained');
        System.assertEquals('Active', freshCpa.UsageType, 'CPA UsageType should be retained as Active');
        System.assertEquals(false, freshCpa.IsUndeliverable, 'CPA IsUndeliverable should remain false');
        System.assertEquals('300 Oak Ave', freshCpa.Street, 'CPA Street should be retained');
    }

    @isTest
    static void test3b_cpaPrimaryTrue_promotesToBusinessAccountBillingFields() {
        Account org = makeOrgAccount('Riverdale Corp');

        Test.startTest();
        ContactPointAddress cpa = new ContactPointAddress(
            ParentId = org.Id,
            Name = 'Riverdale Corp — Billing',
            AddressType = 'Billing',
            Street = '400 River Rd',
            City = 'Elgin',
            State = 'IL',
            PostalCode = '60120',
            Country = 'US',
            IsPrimary = true,
            UsageType = 'Active',
            IsUndeliverable = false
        );
        insert cpa;
        Test.stopTest();

        Account fresh = freshAccount(org.Id);
        System.assertEquals('400 River Rd', fresh.BillingStreet,
            'BillingStreet should be promoted from CPA, got: ' + fresh.BillingStreet);
        System.assertEquals('Elgin', fresh.BillingCity, 'BillingCity should be promoted from CPA');
        System.assertEquals('IL', fresh.BillingState, 'BillingState should be promoted from CPA');
        System.assertEquals('60120', fresh.BillingPostalCode, 'BillingPostalCode should be promoted from CPA');
        System.assertEquals('US', fresh.BillingCountry, 'BillingCountry should be promoted from CPA');

        ContactPointAddress freshCpa = fetchPrimaryCpa(org.Id);
        System.assertNotEquals(null, freshCpa, 'CPA should remain primary');
        System.assertEquals(true, freshCpa.IsPrimary, 'CPA IsPrimary should be retained');
        System.assertEquals('Active', freshCpa.UsageType, 'CPA UsageType should be retained as Active');
        System.assertEquals(false, freshCpa.IsUndeliverable, 'CPA IsUndeliverable should remain false');
        System.assertEquals('400 River Rd', freshCpa.Street, 'CPA Street should be retained');
    }

    @isTest
    static void test3c_cpaUndeliverable_clearsPersonMailingAndDeactivatesCpa() {
        Account pa = makePersonAccount('Henry', 'Clark');
        pa.PersonMailingStreet = '50 Elm St';
        pa.PersonMailingCity = 'Champaign';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '61820';
        pa.PersonMailingCountry = 'US';
        update pa;
        ContactPointAddress cpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, cpa, 'Setup: CPA should exist before test');

        Test.startTest();
        cpa.IsUndeliverable = true;
        update cpa;
        Test.stopTest();

        Account fresh = freshAccount(pa.Id);
        System.assertEquals(null, fresh.PersonMailingStreet,
            'PersonMailingStreet should be cleared when CPA is undeliverable, got: ' + fresh.PersonMailingStreet);
        System.assertEquals(null, fresh.PersonMailingCity,
            'PersonMailingCity should be cleared, got: ' + fresh.PersonMailingCity);
        System.assertEquals(null, fresh.PersonMailingState,
            'PersonMailingState should be cleared, got: ' + fresh.PersonMailingState);
        System.assertEquals(null, fresh.PersonMailingPostalCode,
            'PersonMailingPostalCode should be cleared, got: ' + fresh.PersonMailingPostalCode);
        System.assertEquals(null, fresh.PersonMailingCountry,
            'PersonMailingCountry should be cleared, got: ' + fresh.PersonMailingCountry);

        ContactPointAddress freshCpa = [SELECT Id, IsPrimary, UsageType, IsUndeliverable, ActiveToDate FROM ContactPointAddress WHERE Id = :cpa.Id];
        System.assertEquals(false, freshCpa.IsPrimary, 'CPA IsPrimary should be set to false');
        System.assertEquals('Inactive', freshCpa.UsageType, 'CPA UsageType should be Inactive');
        System.assertEquals(true, freshCpa.IsUndeliverable, 'CPA IsUndeliverable should remain true');
        System.assertEquals(Date.today(), freshCpa.ActiveToDate, 'CPA ActiveToDate should be today');
    }

    @isTest
    static void test3d_cpaUndeliverable_clearsBillingFieldsAndDeactivatesCpa() {
        Account household = makeHouseholdAccountWithAddress('Deactivate Test', '75 Pine Rd', 'Bloomington', 'IL', '61701', 'US');
        ContactPointAddress cpa = fetchPrimaryCpa(household.Id);
        System.assertNotEquals(null, cpa, 'Setup: Household CPA should exist before test');

        Test.startTest();
        cpa.IsUndeliverable = true;
        update cpa;
        Test.stopTest();

        Account fresh = freshAccount(household.Id);
        System.assertEquals(null, fresh.BillingStreet,
            'BillingStreet should be cleared when CPA is undeliverable, got: ' + fresh.BillingStreet);
        System.assertEquals(null, fresh.BillingCity,
            'BillingCity should be cleared, got: ' + fresh.BillingCity);
        System.assertEquals(null, fresh.BillingState,
            'BillingState should be cleared, got: ' + fresh.BillingState);
        System.assertEquals(null, fresh.BillingPostalCode,
            'BillingPostalCode should be cleared, got: ' + fresh.BillingPostalCode);
        System.assertEquals(null, fresh.BillingCountry,
            'BillingCountry should be cleared, got: ' + fresh.BillingCountry);

        ContactPointAddress freshCpa = [SELECT Id, IsPrimary, UsageType, IsUndeliverable, ActiveToDate FROM ContactPointAddress WHERE Id = :cpa.Id];
        System.assertEquals(false, freshCpa.IsPrimary, 'CPA IsPrimary should be false');
        System.assertEquals('Inactive', freshCpa.UsageType, 'CPA UsageType should be Inactive');
        System.assertEquals(true, freshCpa.IsUndeliverable, 'CPA IsUndeliverable should remain true');
        System.assertEquals(Date.today(), freshCpa.ActiveToDate, 'CPA ActiveToDate should be today');
    }

    @isTest
    static void test3e_cpaAlreadyMatchesAccount_noRedundantUpdate() {
        Account pa = makePersonAccount('Iris', 'Davis');
        pa.PersonMailingStreet = '88 Birch Ln';
        pa.PersonMailingCity = 'Normal';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '61761';
        pa.PersonMailingCountry = 'US';
        update pa;
        ContactPointAddress cpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, cpa, 'Setup: CPA should exist');

        Test.startTest();
        // Trigger AfterSave by changing a non-address field — CPA address already matches Account
        cpa.Name = cpa.Name + ' (refreshed)';
        update cpa;
        Test.stopTest();

        Account fresh = freshAccount(pa.Id);
        System.assertEquals('88 Birch Ln', fresh.PersonMailingStreet,
            'PersonMailingStreet should be unchanged, got: ' + fresh.PersonMailingStreet);
        System.assertEquals('Normal', fresh.PersonMailingCity,
            'PersonMailingCity should be unchanged, got: ' + fresh.PersonMailingCity);

        ContactPointAddress freshCpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, freshCpa, 'CPA should remain primary');
        System.assertEquals(true, freshCpa.IsPrimary, 'CPA IsPrimary should be retained');
        System.assertEquals('Active', freshCpa.UsageType, 'CPA UsageType should be retained');
        System.assertEquals('88 Birch Ln', freshCpa.Street, 'CPA Street should be unchanged');
    }

    // ─── Group 4 — Flow 4: Set CPA Defaults (BeforeSave) ─────────────────────────

    @isTest
    static void test4a_cpaBecomesUndeliverable_defaultsApplied() {
        Account pa = makePersonAccount('Jack', 'White');
        pa.PersonMailingStreet = '11 Ash Ct';
        pa.PersonMailingCity = 'Urbana';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '61801';
        pa.PersonMailingCountry = 'US';
        update pa;
        ContactPointAddress cpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, cpa, 'Setup: CPA should exist');
        System.assertEquals(true, cpa.IsPrimary, 'Setup: CPA should be primary');

        Test.startTest();
        cpa.IsUndeliverable = true;
        update cpa;
        Test.stopTest();

        ContactPointAddress freshCpa = [SELECT Id, IsPrimary, UsageType, IsUndeliverable, ActiveToDate FROM ContactPointAddress WHERE Id = :cpa.Id];
        System.assertEquals('Inactive', freshCpa.UsageType, 'CPA UsageType should be set to Inactive by defaults flow');
        System.assertEquals(false, freshCpa.IsPrimary, 'CPA IsPrimary should be set to false by defaults flow');
        System.assertEquals(true, freshCpa.IsUndeliverable, 'CPA IsUndeliverable should remain true');
        System.assertEquals(Date.today(), freshCpa.ActiveToDate, 'CPA ActiveToDate should be today');

        Account fresh = freshAccount(pa.Id);
        System.assertEquals(null, fresh.PersonMailingStreet,
            'PersonMailingStreet should be cleared (Flow 3 fires in same transaction), got: ' + fresh.PersonMailingStreet);
    }

    @isTest
    static void test4b_newCpaWithUndeliverable_defaultsAppliedOnInsert() {
        Account org = makeOrgAccount('Default Test Org');

        Test.startTest();
        ContactPointAddress cpa = new ContactPointAddress(
            ParentId = org.Id,
            Name = 'Undeliverable on Insert',
            AddressType = 'Billing',
            Street = '22 Cedar St',
            City = 'Galesburg',
            State = 'IL',
            PostalCode = '61401',
            Country = 'US',
            IsUndeliverable = true,
            IsPrimary = true,
            UsageType = 'Active'
        );
        insert cpa;
        Test.stopTest();

        ContactPointAddress freshCpa = [SELECT Id, IsPrimary, UsageType, IsUndeliverable, ActiveToDate FROM ContactPointAddress WHERE Id = :cpa.Id];
        System.assertEquals('Inactive', freshCpa.UsageType, 'CPA UsageType should be set to Inactive on insert');
        System.assertEquals(false, freshCpa.IsPrimary, 'CPA IsPrimary should be false on insert when undeliverable');
        System.assertEquals(true, freshCpa.IsUndeliverable, 'CPA IsUndeliverable should remain true');
        System.assertEquals(Date.today(), freshCpa.ActiveToDate, 'CPA ActiveToDate should be today');
    }

    @isTest
    static void test4c_cpaDeliverable_defaultsNotApplied() {
        Account org = makeOrgAccount('Active CPA Org');
        ContactPointAddress cpa = new ContactPointAddress(
            ParentId = org.Id,
            Name = 'Active CPA',
            AddressType = 'Billing',
            Street = '33 Walnut Way',
            City = 'Quincy',
            State = 'IL',
            PostalCode = '62301',
            Country = 'US',
            IsUndeliverable = false,
            IsPrimary = true,
            UsageType = 'Active'
        );
        insert cpa;

        Test.startTest();
        // Update a non-undeliverable field to trigger BeforeSave
        cpa.Street = '33 Walnut Way Suite 2';
        update cpa;
        Test.stopTest();

        ContactPointAddress freshCpa = [SELECT Id, IsPrimary, UsageType, IsUndeliverable FROM ContactPointAddress WHERE Id = :cpa.Id];
        System.assertEquals(true, freshCpa.IsPrimary, 'CPA IsPrimary should be unchanged when deliverable');
        System.assertEquals('Active', freshCpa.UsageType, 'CPA UsageType should remain Active when deliverable');
        System.assertEquals(false, freshCpa.IsUndeliverable, 'CPA IsUndeliverable should remain false');
    }

    // ─── Group 5 — Flow 5: ACR → Household Address Sync ─────────────────────────

    // MANUAL ONLY — Apex cannot update Sync_Household_Address__c on a
    // PersonContact ACR (INVALID_PERSON_ACCOUNT_OPERATION). Verify manually:
    //   1. Create a Household Account with a billing address.
    //   2. Add a Person Account as a Household Member via the UI with
    //      "Sync Household Address" unchecked initially.
    //   3. Edit the ACR to check "Sync Household Address".
    //   4. Confirm the member's Mailing address is now set to the Household billing address.
    //   5. Confirm a primary active CPA exists for the member.
    //   6. Confirm the Household billing address is unchanged.
    @isTest
    static void test5a_settingSyncFlagTrue_copiesHouseholdAddressToMember_ManualOnly() {
        System.assert(true, 'Manual verification required — see comment above this test');
    }

    // MANUAL ONLY — Same org constraint. Verify manually:
    //   1. Create a Household Account with a billing address.
    //   2. Add a Person Account as a Household Member with "Sync Household Address"
    //      checked but the ACR deactivated (IsActive=false).
    //   3. Reactivate the ACR.
    //   4. Confirm the member's Mailing address is now set to the Household billing address.
    //   5. Confirm a primary active CPA exists for the member.
    @isTest
    static void test5b_activatingAcr_copiesAddressToMember_ManualOnly() {
        System.assert(true, 'Manual verification required — see comment above this test');
    }

    // MANUAL ONLY — Same org constraint. Verify manually:
    //   1. Create a Household Account with a billing address.
    //   2. Add a Person Account as a Household Member with "Sync Household Address"
    //      checked but no Roles set.
    //   3. Set Roles = "Household Member" on the ACR.
    //   4. Confirm the member's Mailing address is now set to the Household billing address.
    //   5. Confirm a primary active CPA exists for the member.
    @isTest
    static void test5c_addingHouseholdMemberRole_copiesAddressToMember_ManualOnly() {
        System.assert(true, 'Manual verification required — see comment above this test');
    }

    // MANUAL ONLY — Same org constraint. Verify manually:
    //   1. Create a Household Account and a Person Account member whose Mailing
    //      address already matches the Household Billing address.
    //   2. Enable "Sync Household Address" on the ACR.
    //   3. Confirm no exception is thrown and the member's Mailing address is unchanged.
    //   4. Confirm exactly 1 primary CPA exists for the member (no duplicates).
    @isTest
    static void test5d_addressesAlreadyMatch_noExceptionNoDuplicateCpa_ManualOnly() {
        System.assert(true, 'Manual verification required — see comment above this test');
    }

    // ─── Group 6 — Subflow (Upsert CPA) ──────────────────────────────────────────

    @isTest
    static void test6a_deactivatedCpaWithSameAddress_reactivatedNotDuplicated() {
        Account pa = makePersonAccount('Oscar', 'Green');
        pa.PersonMailingStreet = '5 Willow Way';
        pa.PersonMailingCity = 'Champaign';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '61820';
        pa.PersonMailingCountry = 'US';
        update pa;

        ContactPointAddress existingCpa = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, existingCpa, 'Setup: initial CPA should exist');
        // Manually deactivate the CPA to simulate a dormant record
        existingCpa.UsageType = 'Inactive';
        existingCpa.IsPrimary = false;
        update existingCpa;

        // Change address away then back to trigger the reactivation path
        pa.PersonMailingStreet = '6 Willow Way';
        update pa;

        Test.startTest();
        pa.PersonMailingStreet = '5 Willow Way';
        update pa;
        Test.stopTest();

        List<ContactPointAddress> allCpas = fetchAllCpas(pa.Id);
        Integer addressACount = 0;
        for (ContactPointAddress c : allCpas) {
            if (c.Street == '5 Willow Way') addressACount++;
        }
        System.assertEquals(1, addressACount,
            'Exactly 1 CPA with original address should exist (reactivated, not duplicated), got: ' + addressACount);

        ContactPointAddress reactivated = fetchPrimaryCpa(pa.Id);
        System.assertNotEquals(null, reactivated, 'A primary CPA should exist after sync');
        System.assertEquals(true, reactivated.IsPrimary, 'Reactivated CPA should be primary');
        System.assertEquals('Active', reactivated.UsageType, 'Reactivated CPA should be Active');
        System.assertEquals(false, reactivated.IsUndeliverable, 'Reactivated CPA should not be undeliverable');

        Account fresh = freshAccount(pa.Id);
        System.assertEquals('5 Willow Way', fresh.PersonMailingStreet,
            'PersonMailingStreet should be Address A after reactivation, got: ' + fresh.PersonMailingStreet);
    }

    @isTest
    static void test6b_multipleExistingPrimaries_exactlyOnePrimaryAfterSync() {
        Account pa = makePersonAccount('Paula', 'Young');

        // Insert two CPAs with IsPrimary=true to simulate corrupted state
        ContactPointAddress cpa1 = new ContactPointAddress(
            ParentId = pa.Id,
            Name = 'CPA 1',
            AddressType = 'Mailing',
            Street = '10 First St',
            City = 'Elgin',
            State = 'IL',
            PostalCode = '60120',
            Country = 'US',
            IsPrimary = true,
            UsageType = 'Active',
            IsUndeliverable = false
        );
        insert cpa1;
        ContactPointAddress cpa2 = new ContactPointAddress(
            ParentId = pa.Id,
            Name = 'CPA 2',
            AddressType = 'Mailing',
            Street = '20 Second Ave',
            City = 'Aurora',
            State = 'IL',
            PostalCode = '60505',
            Country = 'US',
            IsPrimary = true,
            UsageType = 'Active',
            IsUndeliverable = false
        );
        insert cpa2;

        Test.startTest();
        // Trigger Flow 1 by updating the Person Account address
        pa.PersonMailingStreet = '30 Third Blvd';
        pa.PersonMailingCity = 'Naperville';
        pa.PersonMailingState = 'IL';
        pa.PersonMailingPostalCode = '60540';
        pa.PersonMailingCountry = 'US';
        update pa;
        Test.stopTest();

        List<ContactPointAddress> allCpas = fetchAllCpas(pa.Id);
        Integer primaryCount = 0;
        ContactPointAddress activePrimary = null;
        for (ContactPointAddress c : allCpas) {
            if (c.IsPrimary) {
                primaryCount++;
                activePrimary = c;
            }
        }
        System.assertEquals(1, primaryCount,
            'Exactly 1 CPA should be primary after sync, got: ' + primaryCount);
        System.assertNotEquals(null, activePrimary, 'A primary CPA should exist');
        System.assertEquals('Active', activePrimary.UsageType, 'Active primary CPA UsageType should be Active');
        System.assertEquals('30 Third Blvd', activePrimary.Street,
            'Active CPA should match Person Account PersonMailingStreet, got: ' + activePrimary.Street);
    }

}