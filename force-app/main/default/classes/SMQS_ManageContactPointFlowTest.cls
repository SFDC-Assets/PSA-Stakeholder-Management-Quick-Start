/**
 * Tests the outcomes of SMQS_Manage_ContactPointPhone and
 * SMQS_Manage_ContactPointEmail screen flows by simulating the DML those
 * flows perform and asserting:
 *   1. CPP/CPE fields are committed as intended.
 *   2. Account phone/email fields are not corrupted by the sync flows that
 *      fire reactively to CPP/CPE changes (changing only IsPrimary or
 *      Invalid_Reason__c is a no-op for those flows, so Account fields
 *      should remain unchanged).
 *
 * Person Account note: Person Accounts are created by inserting a Contact
 * with no AccountId; the platform auto-generates the Account record.
 */
@isTest
private class SMQS_ManageContactPointFlowTest {

    // ─── helpers ────────────────────────────────────────────────────────────────

    static Id personAccountRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
    }

    static Account makePersonAccount(String phone, String email) {
        Account a = new Account(
            FirstName = 'Test',
            LastName = 'User',
            RecordTypeId = personAccountRecordTypeId(),
            Phone = phone,
            PersonEmail = email
        );
        insert a;
        return [SELECT Id, IsPersonAccount, Phone, PersonEmail FROM Account WHERE Id = :a.Id];
    }

    static ContactPointPhone makePhone(Id accountId, String phoneNumber, Boolean isPrimary) {
        ContactPointPhone cpp = new ContactPointPhone(
            ParentId = accountId,
            TelephoneNumber = phoneNumber,
            IsPrimary = isPrimary
        );
        insert cpp;
        return cpp;
    }

    static ContactPointEmail makeEmail(Id accountId, String emailAddress, Boolean isPrimary) {
        ContactPointEmail cpe = new ContactPointEmail(
            ParentId = accountId,
            EmailAddress = emailAddress,
            IsPrimary = isPrimary
        );
        insert cpe;
        return cpe;
    }

    static ContactPointPhone freshPhone(Id cppId) {
        return [SELECT Id, IsPrimary, Invalid_Reason__c, TelephoneNumber FROM ContactPointPhone WHERE Id = :cppId];
    }

    static ContactPointEmail freshEmail(Id cpeId) {
        return [SELECT Id, IsPrimary, Invalid_Reason__c, EmailAddress FROM ContactPointEmail WHERE Id = :cpeId];
    }

    static Account freshAccount(Id accountId) {
        return [SELECT Id, Phone, PersonEmail FROM Account WHERE Id = :accountId];
    }

    // ─── Phone — Mark as Primary ─────────────────────────────────────────────────

    @isTest
    static void testPhone_MarkAsPrimary() {
        Account pa = makePersonAccount('4155550001', 'test@example.com');
        ContactPointPhone cpp = makePhone(pa.Id, '4155550001', false);
        String originalPhone = freshAccount(pa.Id).Phone;

        Test.startTest();
        cpp.IsPrimary = true;
        update cpp;
        Test.stopTest();

        ContactPointPhone result = freshPhone(cpp.Id);
        System.assertEquals(true, result.IsPrimary, 'IsPrimary should be true after marking as primary');
        System.assertEquals(null, result.Invalid_Reason__c, 'Invalid_Reason__c should remain null');
        System.assertEquals(originalPhone, freshAccount(pa.Id).Phone, 'Account Phone should not be overwritten by the sync flow');
    }

    @isTest
    static void testPhone_MarkAsPrimary_DemotesPrevious() {
        Account pa = makePersonAccount('4155550002', 'test2@example.com');
        ContactPointPhone cppA = makePhone(pa.Id, '4155550002', true);
        ContactPointPhone cppB = makePhone(pa.Id, '4155550003', false);

        Test.startTest();
        cppA.IsPrimary = false;
        cppB.IsPrimary = true;
        update new List<ContactPointPhone>{ cppA, cppB };
        Test.stopTest();

        System.assertEquals(false, freshPhone(cppA.Id).IsPrimary, 'Previous primary phone should be demoted');
        System.assertEquals(true, freshPhone(cppB.Id).IsPrimary, 'Selected phone should be promoted to primary');
    }

    // ─── Phone — Mark as Invalid ─────────────────────────────────────────────────

    @isTest
    static void testPhone_MarkInvalid_OldNumber() {
        Account pa = makePersonAccount('4155550010', 'old@example.com');
        ContactPointPhone cpp = makePhone(pa.Id, '4155550010', true);
        String originalPhone = freshAccount(pa.Id).Phone;

        Test.startTest();
        cpp.Invalid_Reason__c = 'Old Number';
        cpp.IsPrimary = false;
        update cpp;
        Test.stopTest();

        ContactPointPhone result = freshPhone(cpp.Id);
        System.assertEquals('Old Number', result.Invalid_Reason__c, 'Invalid_Reason__c should be Old Number');
        System.assertEquals(false, result.IsPrimary, 'IsPrimary should be false when marked invalid');
        System.assertEquals(originalPhone, freshAccount(pa.Id).Phone, 'Account Phone should not be cleared by the sync flow');
    }

    @isTest
    static void testPhone_MarkInvalid_WrongNumber() {
        Account pa = makePersonAccount('4155550011', 'wrong@example.com');
        ContactPointPhone cpp = makePhone(pa.Id, '4155550011', false);

        Test.startTest();
        cpp.Invalid_Reason__c = 'Wrong Number';
        cpp.IsPrimary = false;
        update cpp;
        Test.stopTest();

        ContactPointPhone result = freshPhone(cpp.Id);
        System.assertEquals('Wrong Number', result.Invalid_Reason__c, 'Invalid_Reason__c should be Wrong Number');
        System.assertEquals(false, result.IsPrimary, 'IsPrimary should be false');
    }

    @isTest
    static void testPhone_MarkInvalid_Disconnected() {
        Account pa = makePersonAccount('4155550012', 'disc@example.com');
        ContactPointPhone cpp = makePhone(pa.Id, '4155550012', false);

        Test.startTest();
        cpp.Invalid_Reason__c = 'Disconnected';
        cpp.IsPrimary = false;
        update cpp;
        Test.stopTest();

        ContactPointPhone result = freshPhone(cpp.Id);
        System.assertEquals('Disconnected', result.Invalid_Reason__c, 'Invalid_Reason__c should be Disconnected');
        System.assertEquals(false, result.IsPrimary, 'IsPrimary should be false');
    }

    @isTest
    static void testPhone_MarkMultipleInvalid() {
        Account pa = makePersonAccount('4155550020', 'multi@example.com');
        ContactPointPhone cpp1 = makePhone(pa.Id, '4155550020', true);
        ContactPointPhone cpp2 = makePhone(pa.Id, '4155550021', false);
        ContactPointPhone cpp3 = makePhone(pa.Id, '4155550022', false);

        Test.startTest();
        for (ContactPointPhone cpp : new List<ContactPointPhone>{ cpp1, cpp2, cpp3 }) {
            cpp.Invalid_Reason__c = 'Old Number';
            cpp.IsPrimary = false;
        }
        update new List<ContactPointPhone>{ cpp1, cpp2, cpp3 };
        Test.stopTest();

        for (Id cppId : new List<Id>{ cpp1.Id, cpp2.Id, cpp3.Id }) {
            ContactPointPhone result = freshPhone(cppId);
            System.assertEquals('Old Number', result.Invalid_Reason__c, 'All selected phones should be marked invalid');
            System.assertEquals(false, result.IsPrimary, 'All selected phones should have IsPrimary = false');
        }
    }

    // ─── Email — Mark as Primary ─────────────────────────────────────────────────

    @isTest
    static void testEmail_MarkAsPrimary() {
        Account pa = makePersonAccount('4155550030', 'primary@example.com');
        ContactPointEmail cpe = makeEmail(pa.Id, 'primary@example.com', false);
        String originalEmail = freshAccount(pa.Id).PersonEmail;

        Test.startTest();
        cpe.IsPrimary = true;
        update cpe;
        Test.stopTest();

        ContactPointEmail result = freshEmail(cpe.Id);
        System.assertEquals(true, result.IsPrimary, 'IsPrimary should be true after marking as primary');
        System.assertEquals(null, result.Invalid_Reason__c, 'Invalid_Reason__c should remain null');
        System.assertEquals(originalEmail, freshAccount(pa.Id).PersonEmail, 'Account PersonEmail should not be overwritten by the sync flow');
    }

    @isTest
    static void testEmail_MarkAsPrimary_DemotesPrevious() {
        Account pa = makePersonAccount('4155550031', 'demote_a@example.com');
        ContactPointEmail cpeA = makeEmail(pa.Id, 'demote_a@example.com', true);
        ContactPointEmail cpeB = makeEmail(pa.Id, 'demote_b@example.com', false);

        Test.startTest();
        cpeA.IsPrimary = false;
        cpeB.IsPrimary = true;
        update new List<ContactPointEmail>{ cpeA, cpeB };
        Test.stopTest();

        System.assertEquals(false, freshEmail(cpeA.Id).IsPrimary, 'Previous primary email should be demoted');
        System.assertEquals(true, freshEmail(cpeB.Id).IsPrimary, 'Selected email should be promoted to primary');
    }

    // ─── Email — Mark as Invalid ─────────────────────────────────────────────────

    @isTest
    static void testEmail_MarkInvalid_Typo() {
        Account pa = makePersonAccount('4155550040', 'typo@example.com');
        ContactPointEmail cpe = makeEmail(pa.Id, 'typo@example.com', true);
        String originalEmail = freshAccount(pa.Id).PersonEmail;

        Test.startTest();
        cpe.Invalid_Reason__c = 'Typo';
        cpe.IsPrimary = false;
        update cpe;
        Test.stopTest();

        ContactPointEmail result = freshEmail(cpe.Id);
        System.assertEquals('Typo', result.Invalid_Reason__c, 'Invalid_Reason__c should be Typo');
        System.assertEquals(false, result.IsPrimary, 'IsPrimary should be false');
        System.assertEquals(originalEmail, freshAccount(pa.Id).PersonEmail, 'Account PersonEmail should not be cleared by the sync flow');
    }

    @isTest
    static void testEmail_MarkInvalid_WrongPerson() {
        Account pa = makePersonAccount('4155550041', 'wrongperson@example.com');
        ContactPointEmail cpe = makeEmail(pa.Id, 'wrongperson@example.com', false);

        Test.startTest();
        cpe.Invalid_Reason__c = 'Wrong Person';
        cpe.IsPrimary = false;
        update cpe;
        Test.stopTest();

        ContactPointEmail result = freshEmail(cpe.Id);
        System.assertEquals('Wrong Person', result.Invalid_Reason__c, 'Invalid_Reason__c should be Wrong Person');
        System.assertEquals(false, result.IsPrimary, 'IsPrimary should be false');
    }

    @isTest
    static void testEmail_MarkInvalid_ManualUnsubscribe() {
        Account pa = makePersonAccount('4155550042', 'unsub@example.com');
        ContactPointEmail cpe = makeEmail(pa.Id, 'unsub@example.com', false);

        Test.startTest();
        cpe.Invalid_Reason__c = 'Manual Unsubscribe';
        cpe.IsPrimary = false;
        update cpe;
        Test.stopTest();

        ContactPointEmail result = freshEmail(cpe.Id);
        System.assertEquals('Manual Unsubscribe', result.Invalid_Reason__c, 'Invalid_Reason__c should be Manual Unsubscribe');
        System.assertEquals(false, result.IsPrimary, 'IsPrimary should be false');
    }

    @isTest
    static void testEmail_MarkInvalid_NoLongerUsed() {
        Account pa = makePersonAccount('4155550043', 'nolonger@example.com');
        ContactPointEmail cpe = makeEmail(pa.Id, 'nolonger@example.com', false);

        Test.startTest();
        cpe.Invalid_Reason__c = 'No Longer Used';
        cpe.IsPrimary = false;
        update cpe;
        Test.stopTest();

        ContactPointEmail result = freshEmail(cpe.Id);
        System.assertEquals('No Longer Used', result.Invalid_Reason__c, 'Invalid_Reason__c should be No Longer Used');
        System.assertEquals(false, result.IsPrimary, 'IsPrimary should be false');
    }

}
