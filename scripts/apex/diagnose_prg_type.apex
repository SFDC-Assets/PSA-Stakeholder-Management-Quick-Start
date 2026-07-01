// Check what happens when PRG is inserted with no Type
Account a = new Account(Name = 'DIAG PRG', RecordTypeId =
    Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household').getRecordTypeId(),
    Is_Household__c = true);
insert a;

// Try inserting a PRG with no type to see if blank passes and if
// the "Not Household" check in the flow would catch it
try {
    PartyRelationshipGroup prg = new PartyRelationshipGroup(
        AccountId = a.Id,
        Name = 'Test PRG'
        // omit Type
    );
    insert prg;
    PartyRelationshipGroup fresh = [SELECT Id, Name, Type FROM PartyRelationshipGroup WHERE Id = :prg.Id];
    System.debug('PRG Type when omitted: "' + fresh.Type + '"');
} catch (Exception e) {
    System.debug('Insert without Type FAILED: ' + e.getMessage());
}
delete a;
