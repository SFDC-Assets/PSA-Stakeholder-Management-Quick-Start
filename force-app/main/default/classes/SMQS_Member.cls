public class SMQS_Member {
    @AuraEnabled
    public String JoinId;
    
    @AuraEnabled
    public String firstName;
    
    @AuraEnabled
    public String lastName;
    
    @AuraEnabled
    public Boolean active;
    
    @AuraEnabled
    public String roles;
    
    @AuraEnabled
    public String accountId;
    
    @AuraEnabled
    public String contactId;
    
    @AuraEnabled
    public Boolean syncHouseholdAddress;
    
    @AuraEnabled
    public Boolean syncHouseholdPhone;
    
    @AuraEnabled
    public Boolean includedInGroup;
    
    @AuraEnabled
    public Boolean primaryGroup;
    
    @AuraEnabled
    public Boolean primaryMember;
}