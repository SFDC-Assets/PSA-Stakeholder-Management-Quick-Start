Id householdRtId = Schema.SObjectType.Account
    .getRecordTypeInfosByDeveloperName()
    .get('Household')
    .getRecordTypeId();

Account a = new Account(
    Name = 'DIAG Household',
    RecordTypeId = householdRtId,
    Is_Household__c = true
);
insert a;
System.debug('Account Id: ' + a.Id + ' IsPersonAccount: ' + [SELECT IsPersonAccount FROM Account WHERE Id = :a.Id].IsPersonAccount);

Contact c = new Contact(FirstName = 'Jane', LastName = 'Doe', AccountId = a.Id);
insert c;
System.debug('Contact Id: ' + c.Id + ' IsPersonAccount: ' + [SELECT IsPersonAccount FROM Contact WHERE Id = :c.Id].IsPersonAccount);

List<AccountContactRelation> acrs = [
    SELECT Id, IsPrimaryMember, Roles, IsActive
    FROM AccountContactRelation
    WHERE ContactId = :c.Id AND AccountId = :a.Id
];
System.debug('ACRs found: ' + acrs.size());
if (!acrs.isEmpty()) {
    AccountContactRelation acr = acrs[0];
    System.debug('ACR: ' + acr);
    try {
        acr.Roles = 'Household Member';
        acr.IsActive = true;
        acr.IsPrimaryMember = true;
        update acr;
        System.debug('ACR update succeeded');
    } catch (Exception e) {
        System.debug('ACR update FAILED: ' + e.getMessage());
    }
}
delete a;
