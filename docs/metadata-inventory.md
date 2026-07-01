# Metadata Inventory

## Application
- Stakeholder_Management_Quick_Start

## Lightning Pages (Flexipages)
- SMQS_Account_Record_Page
- SMQS_Account_Account_Relationship_Record_Page
- SMQS_Contact_Contact_Relationship_Record_Page
- SMQS_Contact_Point_Address_Record_Page
- SMQS_Contact_Point_Email_Record_Page
- SMQS_Contact_Point_Phone_Record_Page
- SMQS_HomePageDefault
- SMQS_Party_Relationship_Group_Record_Page
- SMQS_Party_Role_Relationship_Record_Page
- SMQS_Stakeholder_Management_Quick_Start_UtilityBar

## Flows

### Relationship Automation
- SMQS_Account_Account_Relationship_Delete
- SMQS_Account_Account_Relationship_Post_Save_Flow
- SMQS_Contact_Contact_Relationship_Delete
- SMQS_Contact_Contact_Relationship_Post_Save_Flow
- SMQS_Party_Role_Relationship_Before_Save_Flow

### Address Sync
- SMQS_Address_Sync_AccountContactRelation_Household
- SMQS_Address_Sync_Business_Account_to_ContactPointAddress
- SMQS_Address_Sync_ContactPointAddress_to_Account
- SMQS_Address_Sync_Delete_ContactPointAddress_to_Account
- SMQS_Address_Sync_Person_Account_to_ContactPointAddress
- SMQS_Address_Sync_Set_ContactPointAddress_Defaults
- SMQS_Address_Sync_Upsert_ContactPointAddress

### Email Sync
- SMQS_Email_Sync_Account_to_ContactPointEmail
- SMQS_Email_Sync_ContactPointEmail_to_Account
- SMQS_Email_Sync_Delete_ContactPointEmail_to_Account

### Phone Sync
- SMQS_Phone_Sync_Account_to_ContactPointPhone
- SMQS_Phone_Sync_ContactPointPhone_to_Account
- SMQS_Phone_Sync_AccountContactRelation_to_Household_Account
- SMQS_Phone_Sync_Delete_ContactPointPhone_to_Account
- SMQS_Phone_Sync_Household_Account_To_Person_Account
- SMQS_Phone_Sync_Person_Account_to_Household_Account
- SMQS_Phone_ContactPointPhone_Helper_Subflow

### Contact Point Management (Screen Flows)
- SMQS_Screen_Manage_ContactPoints
- SMQS_Screen_Manage_ContactPoints_Subflow
- SMQS_Screen_Manage_ContactPoints_Address_Subflow
- SMQS_Screen_Manage_ContactPoints_Email_Subflow
- SMQS_Screen_Manage_ContactPoints_Phone_Subflow
- SMQS_Screen_RelatedList_ContactPointEmail
- SMQS_Screen_RelatedList_ContactPointPhone

### Household Setup
- SMQS_Household_Setup_Account_to_PartyRelationshipGroup
- SMQS_Household_Setup_IsHousehold_Enforcement *(renamed from SMQS_Household_Setup_Coupling_Account)*
- SMQS_Household_Setup_Name_Sync_AccountContactRelationship_to_Account
- SMQS_Household_Setup_Name_Sync_ACR_Delete_to_Account
- SMQS_Household_Setup_Name_Sync_Account_to_CPA
- SMQS_Household_Setup_Name_Sync_Account_to_PRG

### Screen Flows
- SMQS_Screen_Create_Relationship_or_Affiliation
- SMQS_Screen_Create_Party_Role_Relationship_Setup
- SMQS_Screen_Manage_Household
- SMQS_Screen_Manage_Household_Subflow_Create_Person_Accounts
- SMQS_Person_Account_Conversion_from_Contact

## Record Types
- Account: Household, Organization
- PersonAccount: Individual *(included in unmanaged package via SMQS_Person_Account_Fields)*

## Page Layouts
- Account – SMQS Account Layout
- AccountAccountRelation – Account Account Relationship Layout
- AccountContactRelation – SMQS Account Contact Relationship Layout
- ContactContactRelation – Contact Contact Relationship Layout
- ContactPointAddress – Contact Point Address Layout
- ContactPointEmail – SMQS Contact Point Email Layout
- ContactPointPhone – Contact Point Phone Layout
- PartyRelationshipGroup – Party Relationship Group Layout
- PartyRoleRelation – Party Role Relationship Layout
- PersonAccount – Person Account Layout
- SMQS_Party_Relationship_Role__mdt – Party Relationship Role Layout

## List Views
- Account: All_Households, All_Individuals, All_Organizations
- PartyRoleRelation: Group_Affiliations_AAR, Individual_Relationships_CCR

## Quick Actions
- Account: Create_Relationship_or_Affiliation, Householding_Guide, Manage_Contact_Info, Manage_Household, New_Relationship_or_Affiliation
- AccountAccountRelation: Mark_as_Former
- AccountContactRelation: Mark_as_Former, Mark_as_Primary, Unmark_as_Primary, Update_Relationship
- ContactContactRelation: Mark_as_Former
- ContactPointAddress: Mark_as_Primary, Mark_as_Undeliverable, Remove_as_Primary
- ContactPointEmail: Mark_Invalid, Mark_as_Primary
- ContactPointPhone: Mark_Invalid, Mark_as_Primary
- PartyRoleRelation: New_Role

## Objects & Custom Fields

- Account (custom fields: Do_Not_Mail__c, Is_Household__c, Secondary_Phone__c)
- AccountAccountRelation (fields: External_ID__c, Explanation__c, RelatedInverseRecordId; index: External_ID__c)
- AccountContactRelation (custom fields: Account_Name__c, Contact_Name__c, External_ID__c, Is_Household_Member__c, Sync_Household_Address__c, Sync_Household_Phone__c; index: External_ID__c)
- ContactContactRelation (fields: Contact_Name__c, Description__c, Explanation__c, External_ID__c, Related_Contact_Name__c, Relationship_Role__c, RelatedInverseRecordId; index: External_ID__c)
- ContactPointAddress (custom fields: Active__c, External_ID__c, Marked_For_Deletion__c; index: External_ID__c)
- ContactPointEmail (custom fields: External_ID__c, Invalid_Reason__c, Marked_For_Deletion__c; index: External_ID__c)
- ContactPointPhone (custom fields: Active__c, External_ID__c, Invalid_Reason__c, Map_To__c, Marked_For_Deletion__c; index: External_ID__c)
- PartyRelationshipGroup
- PartyRoleRelation (fields: Default_Hierarchy_Type__c, External_Id__c, RelatedInverseRecordId, Type__c; index: External_Id__c)

### Custom Metadata Type
- SMQS_Party_Relationship_Role__mdt (24 records; fields: Create_Inverse_Role_Automatically__c, Default_Hierarchy_Type__c, Related_Role_Name__c, Relationship_Object_Type__c, Role_Name__c, Role_Type__c)

## Apex Classes
- SMQS_Member / SMQS_MemberTest
- SMQS_AddressSyncFlowTest *(not in unmanaged package)*
- SMQS_HouseholdFlowTest *(not in unmanaged package)*
- SMQS_ManageContactPointFlowTest *(not in unmanaged package)*

## Permission Sets
- SMQS_Custom_Fields — read/edit on all SMQS custom fields across Account, AccountAccountRelation, AccountContactRelation, ContactContactRelation, ContactPointAddress, ContactPointEmail, ContactPointPhone, PartyRoleRelation
- SMQS_Person_Account_Fields — read/edit on Person Account fields (Account.Person*) plus the mirrored Contact standard fields (Birthdate, DoNotCall, Email, GenderIdentity, HasOptedOutOfEmail, HomePhone, MailingAddress, MobilePhone, OtherPhone, Phone, Pronouns); also grants PersonAccount.Individual record type visibility. Assign when Person Accounts are enabled.
- SMQS_Split_and_Merge_Households — grants MergeAndSplitGroups user permission + read/edit/delete on Account and Contact. Assign alongside SMQS_Custom_Fields.

## Report Types
- SMQS_Account_to_Account_Relationships
- SMQS_Account_Contact_Point_Addresses
- SMQS_Account_Contact_Point_Emails
- SMQS_Account_Contact_Point_Phones
- SMQS_Individual_Affiliations_Account_Contact_Relationships
- SMQS_Individual_Relationships_Contact_Contact_Relationships
- SMQS_Party_Role_Relationships_to_Groups_Organization_and_Households
- SMQS_Party_Role_Relationships_to_Individuals

## Reports
- Report Folder: Stakeholder Management Quick Start
- SMQS_AA_Roles_Report_for_Page_Layouts_UXE
- SMQS_CC_Roles_Report_for_Page_Layout_mFI

## Relationship Graph Definitions
- SMQS_Simple_Household
- SMQS_Simple_Individual
- SMQS_Simple_Organization

## UI Format Specification Sets
- Do_Not_Call
- Do_Not_Mail
- Email_Opt_Out

## Miscellaneous *(not in unmanaged package)*
- FundraisingConfig (fundraisingConfig)
- Name.settings (org name settings)
- AccountContactMultiRoles (standardValueSet)
