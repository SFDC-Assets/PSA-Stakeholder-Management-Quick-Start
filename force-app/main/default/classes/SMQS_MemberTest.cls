@isTest
private class SMQS_MemberTest {
    @isTest
    static void testMemberFields() {
        // Instantiate the Member class
        SMQS_Member m = new SMQS_Member();
        
        // Set field values
        m.JoinId = '001XXXXXXXXXXXX';
        m.firstName = 'John';
        m.lastName = 'Doe';
        m.active = true;
        m.roles = 'Admin';
        m.accountId = '001YYYYYYYYYYYY';
        m.contactId = '003ZZZZZZZZZZZZ';
        m.syncHouseholdAddress = false;
        m.syncHouseholdPhone = true;
        m.includedInGroup = true;
        m.primaryGroup = false;
        m.primaryMember = true;
        
        // Verify that the field values are correctly assigned
        System.assertEquals('001XXXXXXXXXXXX', m.JoinId, 'JoinId should be set correctly.');
        System.assertEquals('John', m.firstName, 'First name should be John.');
        System.assertEquals('Doe', m.lastName, 'Last name should be Doe.');
        System.assertEquals(true, m.active, 'Active should be true.');
        System.assertEquals('Admin', m.roles, 'Role should be Admin.');
        System.assertEquals('001YYYYYYYYYYYY', m.accountId, 'Account Id should be set correctly.');
        System.assertEquals('003ZZZZZZZZZZZZ', m.contactId, 'Contact Id should be set correctly.');
        System.assertEquals(false, m.syncHouseholdAddress, 'Sync Household Address should be false.');
        System.assertEquals(true, m.syncHouseholdPhone, 'Sync Household Phone should be true.');
        System.assertEquals(true, m.includedInGroup, 'Included in Group should be true.');
        System.assertEquals(false, m.primaryGroup, 'Primary Group should be false.');
        System.assertEquals(true, m.primaryMember, 'Primary Member should be true.');
    }
}