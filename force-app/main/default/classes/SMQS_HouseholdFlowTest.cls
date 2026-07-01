/**
 * Tests SMQS_Household_Setup_Account_to_PartyRelationshipGroup and
 * SMQS_Household_Setup_Name_Sync_AccountContactRelationship_to_Account.
 *
 * Household members are always Person Accounts (Individual record type).
 * We link them to a Household Account via AccountContactRelation using
 * the Person Account's PersonContactId.
 */
@isTest
private class SMQS_HouseholdFlowTest {

    // ─── helpers ────────────────────────────────────────────────────────────────

    static Id householdRecordTypeId() {
        return Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Household')
            .getRecordTypeId();
    }

    static Id individualRecordTypeId() {
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

    static AccountContactRelation addMember(
            Id householdId, String first, String last, Boolean isPrimary) {
        Account pa = new Account(
            FirstName = first,
            LastName = last,
            RecordTypeId = individualRecordTypeId()
        );
        insert pa;
        pa = [SELECT Id, PersonContactId FROM Account WHERE Id = :pa.Id];
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = householdId,
            ContactId = pa.PersonContactId,
            Roles = 'Household Member',
            IsActive = true,
            IsPrimaryMember = isPrimary
        );
        insert acr;
        return acr;
    }

    static String freshAccountName(Id accountId) {
        return [SELECT Name FROM Account WHERE Id = :accountId].Name;
    }

    static PartyRelationshipGroup fetchPRG(Id accountId) {
        List<PartyRelationshipGroup> prgs = [
            SELECT Id, Name, Type FROM PartyRelationshipGroup WHERE AccountId = :accountId
        ];
        return prgs.isEmpty() ? null : prgs[0];
    }

    // ─── 1. New Household, no members → "Empty Household" ───────────────────────

    @isTest
    static void testNewHouseholdNoMembers() {
        Test.startTest();
        Account a = makeHouseholdAccount('New Household');
        Test.stopTest();

        PartyRelationshipGroup prg = fetchPRG(a.Id);
        System.assertNotEquals(null, prg, 'PRG should be created for a new Household Account');
        System.assertEquals('Household', prg.Type, 'PRG Type should be Household');
        System.assertEquals('Empty Household', freshAccountName(a.Id),
            'Account Name should be "Empty Household" when no members exist');
        System.assertEquals('Empty Household', prg.Name,
            'PRG Name should be "Empty Household" when no members exist');
    }

    // ─── 2. Adding a primary member updates the Account and PRG name ─────────────

    @isTest
    static void testAddPrimaryMemberSetsName() {
        Account a = makeHouseholdAccount('Empty Household');

        Test.startTest();
        addMember(a.Id, 'Jane', 'Doe', true);
        Test.stopTest();

        System.assertEquals('Jane Doe\'s Household', freshAccountName(a.Id),
            'Account Name should reflect the primary member');
        System.assertEquals('Jane Doe\'s Household', fetchPRG(a.Id).Name,
            'PRG Name should match Account Name');
    }

    // ─── 3. Swap primary → new primary member drives the name ───────────────────

    @isTest
    static void testSwapPrimary() {
        Account a = makeHouseholdAccount('Empty Household');
        AccountContactRelation acr1 = addMember(a.Id, 'Jane', 'Doe', true);
        AccountContactRelation acr2 = addMember(a.Id, 'Bob', 'Smith', false);

        // Must unset current primary before setting a new one — Salesforce enforces
        // only one IsPrimaryMember=true per PartyRelationshipGroup at a time.
        acr1.IsPrimaryMember = false;
        update acr1;

        Test.startTest();
        acr2.IsPrimaryMember = true;
        update acr2;
        Test.stopTest();

        System.assertEquals('Bob Smith\'s Household', freshAccountName(a.Id),
            'Account Name should update to the new primary member');
    }

    // ─── 4. Remove primary, other members remain → falls back to recent member ───

    @isTest
    static void testRemovePrimaryFallsBackToRecentMember() {
        Account a = makeHouseholdAccount('Empty Household');
        AccountContactRelation acr1 = addMember(a.Id, 'Jane', 'Doe', true);
        addMember(a.Id, 'Bob', 'Smith', false);

        Test.startTest();
        acr1.IsPrimaryMember = false;
        update acr1;
        Test.stopTest();

        String name = freshAccountName(a.Id);
        System.assert(
            name == 'Jane Doe\'s Household' || name == 'Bob Smith\'s Household',
            'Account Name should fall back to a remaining household member, got: ' + name
        );
    }

    // ─── 5. Remove primary, no members left → "Empty Household" ─────────────────

    @isTest
    static void testRemovePrimaryNoMembersGivesEmptyHousehold() {
        Account a = makeHouseholdAccount('Empty Household');
        AccountContactRelation acr = addMember(a.Id, 'Jane', 'Doe', true);

        Test.startTest();
        acr.IsPrimaryMember = false;
        acr.IsActive = false;
        update acr;
        Test.stopTest();

        System.assertEquals('Empty Household', freshAccountName(a.Id),
            'Account Name should be "Empty Household" when no active household members remain');
    }

    // ─── 6. Manual Account Name edit is overwritten back to convention ───────────

    @isTest
    static void testManualNameEditOverwritten() {
        Account a = makeHouseholdAccount('Empty Household');
        addMember(a.Id, 'Jane', 'Doe', true);
        a = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

        Test.startTest();
        a.Name = 'My Custom Name';
        update a;
        Test.stopTest();

        System.assertEquals('Jane Doe\'s Household', freshAccountName(a.Id),
            'Flow should overwrite a manually changed Account Name back to convention');
        System.assertEquals('Jane Doe\'s Household', fetchPRG(a.Id).Name,
            'PRG Name should be synced after name correction');
    }

    // ─── 7. Adding a non-primary member to Empty Household renames it ────────────

    @isTest
    static void testNonPrimaryMemberOnEmptyHouseholdRenames() {
        Account a = makeHouseholdAccount('Empty Household');

        Test.startTest();
        addMember(a.Id, 'Jane', 'Doe', false);
        Test.stopTest();

        System.assertNotEquals('Empty Household', freshAccountName(a.Id),
            'Account Name should not stay "Empty Household" when an active member exists');
        System.assertEquals('Jane Doe\'s Household', freshAccountName(a.Id),
            'Account Name should be set from the new non-primary member');
    }

    // ─── 8. PRG Name syncs when Account Name was already at convention ───────────

    @isTest
    static void testPRGNameSyncsOnNameConsistentPath() {
        Account a = makeHouseholdAccount('Empty Household');
        addMember(a.Id, 'Tom', 'Jones', true);

        // Corrupt PRG Name to simulate drift
        PartyRelationshipGroup prg = fetchPRG(a.Id);
        prg.Name = 'Stale PRG Name';
        update prg;

        Test.startTest();
        // Setting the same Name value doesn't trigger ISCHANGED, so toggle
        // Is_Household__c off then back on to re-fire the flow while the
        // Name is already at convention → hits the Yes_Name_Consistent branch.
        a = [SELECT Id, Name, Is_Household__c FROM Account WHERE Id = :a.Id];
        a.Is_Household__c = false;
        update a;
        a.Is_Household__c = true;
        update a;
        Test.stopTest();

        System.assertEquals('Tom Jones\'s Household', fetchPRG(a.Id).Name,
            'PRG Name should sync even when Account Name was already at convention');
    }
}