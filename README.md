![Public Sector Accelerators logo](/docs/Logo_GPSAccelerators_v01.png)
# Stakeholder Management Quick Start

https://sfdc.co/stakeholder-quick-start

## Description

The Stakeholder Management Quick Start helps nonprofit organizations set up the necessary features to track the variety of stakeholders using best practices through automation and clearer setup steps. It addresses the most common data quality and usability gaps in a standard Salesforce implementation, reducing the manual configuration work required of admins and the manual data entry required of staff.

Individuals, Organizations, and Households

* Guidance and automation to ensure organization and household data quality, including automatic creation of Party Relationship Groups, guidance on Account Record Types, and household naming automation.

Contact Information Management

* Guidance and automation to ensure appropriate movement and updating of addresses, emails, and phone numbers between individuals and their household.  
* Automation to sync a household account's address and phone to all linked individual (Person Account) records that are active household members with address sync enabled.   
* Automation to sync email and phone fields to the ContactPointEmail and Contact Point Phone objects to support the tracking of the best contact point and data quality. 

Relationships and Affiliations

* Suggestion of common relationships and affiliations, and guided automation to assist admins with the population of Party Role Relationships records.  
* Automation to ensure reciprocal creation, updating, and deletion of relationships and affiliations across all supported relationship types: Relationships (ContactContactRelationships), Individual Affiliations (AccountContactRelationships), and Organizational Affiliations (AccountContactRelationship).   
* Ability to mark relationships and affiliations as former, preserving historical data without cluttering active relationship views.

General Improvements

* A custom app, Dynamic Lightning Pages for Account, Contact, relationship, and affiliation records, Quick Actions for the most common tasks, and List Views for relevant objects.  
* Data model improvements through custom fields, including External IDs on all objects, the addition of help text and descriptions for standard fields, reducing support burden and improving clarity for admins and end users.  
* Permission sets to assist admins in providing access to custom fields and functionality, including a dedicated permission set for Person Account fields.

### Included Assets

An unmanaged package (link in the installation section of this document; metadata is also found in the /force-app/main/default/ folder) that includes:

This Accelerator includes the following additional documents 

* Metadata Inventory  
* Flow Descriptions

### Documentation Including

This readme file

* Group Membership Documentation  
  * [https://help.salesforce.com/s/articleView?id=ind.group\_membership.htm](https://help.salesforce.com/s/articleView?id=ind.group_membership.htm)  
* Stakeholder Management in Nonprofit Cloud \- Trailhead  Module  
  * [https://trailhead.salesforce.com/content/learn/modules/stakeholder-management-in-nonprofit-cloud](https://trailhead.salesforce.com/content/learn/modules/stakeholder-management-in-nonprofit-cloud)  
* Stakeholder Management Data Model  
  * [https://developer.salesforce.com/docs/atlas.en-us.nonprofit\_cloud.meta/nonprofit\_cloud/psc\_data\_model\_party\_relationship\_groups.htm](https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud.meta/nonprofit_cloud/psc_data_model_party_relationship_groups.htm)  
  * [https://developer.salesforce.com/docs/atlas.en-us.nonprofit\_cloud.meta/nonprofit\_cloud/npc\_group\_memberships\_households.htm](https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud.meta/nonprofit_cloud/npc_group_memberships_households.htm)

### License Requirements

* Agentforce Nonprofit / Nonprofit Cloud

### Accelerator or Technology-Specific Assumptions

This accelerator was built and designed for nonprofit organizations that are just beginning to use Agentforce Nonprofit / Nonprofit Cloud. It is intended to help a Salesforce Administrator to not only set up Stakeholder Management but also to understand the functionality. 

## Implementation Steps

### Determine Install Location

1. Determine where you will install the unmanaged package:  
   1. **New Customer:** If you are a new customer we encourage you to install the Stakeholder Management accelerator into a base org available here: [https://www.salesforce.com/form/sfdo/signup/nonprofit/nonprofit-cloud-base-trial/](https://www.salesforce.com/form/sfdo/signup/nonprofit/nonprofit-cloud-base-trial/)

   

   2. **Existing Customer:** Create either a sandbox or a scratch org. It is possible to install into production but that is only advised if you have no existing configuration and have already confirmed all elements of the Stakeholder Management Quick Start are applicable.  
         
2. Review this file and other appropriate documentation linked in this document. You can see a video of a walk through of the instructions: https://salesforce.vidyard.com/watch/pAbgYfbsBhf61RGtBvLUq9

### Before You Install

*Notice: Activation of Person Accounts is a prerequisite for package installation. This process entails establishing a pair of record types—specifically for business and individual entities. While the provided labels and names serve as recommendations and the unmanaged package will deploy with alternatives, it is critical to verify any automation pertaining to household records if custom names and labels are chosen.*

1. Create **Account** Record Type for Groups  
   1. From Setup, at the top of the page, select **Object Manager**.  
   2. Click the **Account** object in the list then select **Record Types** on the left-hand side.  
   3. Create **Organization** Record  
      1. Click **New**.  
      2. Select **Master** from the Existing Record Type dropdown list to copy all available picklist values, or choose an existing record type to clone its picklist values.  
      3. Enter a **Record Type Label** that is unique within the object. The recommended label is: **Organization**  
      4. Enter a description. The recommended description is: *Select this for any type of organization, formal or informal. This will create a business account.*  
      5. Select **Active** to activate the record type.  
      6. Select **Make Available** next to a profile to make the record type available to users with that profile. Select the checkbox in the header row to make it available for all profiles.  
      7. For selected profiles, select **Make Default** next to a profile to make it the default record type for users of that profile. Select the checkbox in the header row to make it the default for all profiles.  
      8. Click **Next**.  
      9. Choose a page layout option to determine what page layout displays for records with this record type:  
         1. To apply a single page layout for all profiles, select **Apply one layout to all profiles** and choose the page layout from the dropdown list.  
         2. To apply different page layouts based on user profiles, select **Apply a different layout for each profile** and choose a page layout for each profile.  
      10. Click **Save**.  
   4. Create Household Record   
      1. Click **New**.  
      2. Select **Master** from the Existing Record Type dropdown list to copy all available picklist values, or choose an existing record type to clone its picklist values.  
      3. Enter a **Record Type Label** that is unique within the object. The recommended label is: **Household**  
      4. Enter a description. The recommended description is: *Select this for any type of household. This will create a business account.*  
      5. Select **Active** to activate the record type.  
      6. Select **Make Available** next to a profile to make the record type available to users with that profile. Select the checkbox in the header row to make it available for all profiles.  
      7. For selected profiles, select **Make Default** next to a profile to make it the default record type for users of that profile. Select the checkbox in the header row to make it the default for all profiles.  
      8. Click **Next**.  
      9. Choose a page layout option to determine what page layout displays for records with this record type:  
         1. To apply a single page layout for all profiles, select **Apply one layout to all profiles** and choose the page layout from the dropdown list.  
         2. To apply different page layouts based on user profiles, select **Apply a different layout for each profile** and choose a page layout for each profile.  
      10. Click **Save**.  
2. Enable Person Accounts  
   1. From **Setup**, enter ‘Person Accounts’ in the **Quick Find** box, and then select **Person Accounts**.  
   2. Go through the steps listed on the Setup page.  
   3. Click **View Org Impacts**, then Review the Org Impact Acknowledgement.   
   4. If you accept the Org Impact Acknowledgement, then click **Enable Person Accounts**.  
   5. Click **Enable** to turn on Person Accounts.  
   6. After **Person Accounts** is enabled, a **Person Account** object with a corresponding **Individual** record type is created.  
   7. Assign the person account record type to user profiles.  
3. Rename **Person Account** Record Type to **Individuals**  
   1. From Setup, at the top of the page, select **Object Manager**.  
   2. Search for **Person Account** and click the **Person** **Account** object in the list then select **Record** **Types** on the left hand side.  
   3. Underneath Record Type Label, click **Person Account**.  
   4. Click **Edit**.  
   5. Enter a Record Type Label that's unique within the object. The recommended label is: **Individual**  
   6. Change the Record Type Name. The recommended name is: **Individual**  
   7. Enter a description. The recommended description is: *Select this for any individual. This will create a person account.*  
   8. Click **Save**.  
4. Enable ‘Group Membership’ in Setup  
   1. From **Setup**, in the **Quick Find** box, enter ‘Group Membership’, and then select **Group Membership Settings**.  
   2. Turn on **Create and manage households and groups**.  
5. Enable ‘Fundraising Settings’  
   1. In Setup, search for Fundraising, and select **Fundraising Settings**.  
   2. Turn on Fundraising Tools for Everyone  
6. Assign Fundraising\_Admin Permission Set Group  
   1. From Setup, in the Quick Find box, enter Permission Set Groups, and then select **Permission Set Groups**.   
   2. Click ‘Recently Viewed’ and then select ‘All Permission Set Groups’   
   3. Click the permission set group name ‘**Fundraising\_Admin’** in the list view.  
   4. Click **Manage Assignments** and then **Add Assignments**.  
   5. Select each user to whom you want to assign the group, and then click **Next**.  
   6. Optionally, select an expiration date for the user assignment to expire.  
   7. Click **Assign**. When the update is complete, the permission set group status changes to Updated.  
7. Enable Contacts to Multiple Accounts  
   1. From Setup, enter Account Settings in the Quick Find box, and then select **Account Settings**. 

      Note: Only users with the Customize Application permission can view or edit Account Settings.  
        
   2. Click **Edit**.  
   3. Select **Allow users to relate a contact to multiple accounts** and click **Save**.  
   4. When the Contacts to Multiple Accounts Settings section appears, review the default options and save your changes.  
8. Enable Field History Tracking on Account  
   1. From Setup, click the **Object Manager** tab.  
   2. Click the object name **Account**.  
   3. Click **Fields & Relationships**, and then click **Set History Tracking**.   
   4. Check **Enable Account History**.  
   5. Click **Save**.  
   6. Under ‘Track old and new values’ select the fields you wish to track, suggested fields are  
      1. Billing Address  
      2. Email  
      3. Mailing Address  
      4. Phone  
   7. Click **Save.**

Supporting documentation:

* [https://help.salesforce.com/s/articleView?id=sales.account\_person\_enable.htm\&type=5](https://help.salesforce.com/s/articleView?id=sales.account_person_enable.htm&type=5)  
* [https://help.salesforce.com/s/articleView?id=platform.perm\_set\_groups\_assign.htm\&type=5](https://help.salesforce.com/s/articleView?id=platform.perm_set_groups_assign.htm&type=5)  
* [https://help.salesforce.com/s/articleView?id=ind.group\_membership\_set\_up.htm\&type=5](https://help.salesforce.com/s/articleView?id=ind.group_membership_set_up.htm&type=5)  
* [https://help.salesforce.com/s/articleView?id=sfdo.fundraising\_enable\_person\_accounts\_for\_fundraising.htm\&type=5](https://help.salesforce.com/s/articleView?id=sfdo.fundraising_enable_person_accounts_for_fundraising.htm&type=5)  
* [https://help.salesforce.com/s/articleView?id=sfdo.fundraising\_assign\_fundraising\_permission\_sets.htm\&type=5](https://help.salesforce.com/s/articleView?id=sfdo.fundraising_assign_fundraising_permission_sets.htm&type=5)  
* [https://help.salesforce.com/s/articleView?id=sfdo.fundraising\_enable\_fundraising.htm\&type=5](https://help.salesforce.com/s/articleView?id=sfdo.fundraising_enable_fundraising.htm&type=5)  
* [https://help.salesforce.com/s/articleView?id=sfdo.fundraising\_manage\_constituent\_addresses.htm\&type=5](https://help.salesforce.com/s/articleView?id=sfdo.fundraising_manage_constituent_addresses.htm&type=5)

### Installation

1. Install the unmanaged package  
   1. Login into your sandbox or scratch org.  
   2. Choose the appropriate URL  
      1. For Sandboxes and Scratch Orgs:   
         [https://test.salesforce.com/packaging/installPackage.apexp?p0=04tfn000005a8Vd](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tfn000005a8Vd)

      2. For Production Environments: [https://login.salesforce.com/packaging/installPackage.apexp?p0=04tfn000005a8Vd](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tfn000005a8Vd)  
           
   3. Paste the URL into your browser navigation bar and press Enter.  
   4. Select Installation Scope: Choose how to install the package:   
      1. Recommended: Install for Admins Only: The package components are only accessible by users with the Administrator profile.   
      2. Install for All Users: The components are available to all users in your organization.   
      3. Install for Specific Profiles: You can choose to install for particular profiles, giving you more granular control.  
   5. Click Install.  
   6. If the installation takes a while, you can click Done and the installation completes in the background. Check your email for confirmation that the installation was successful.

### Post-Install Setup and Configuration

**I. Enable Settings**

1. **Enable Name Fields**  
   1. From Setup, in the Quick Find box, enter ‘User Interface’, and then select **User Interface**.  
   2. Under Name Settings, select the following options:  
      1. **Enable Middle Names for Person Names**  
      2. **Enable Name Suffixes for Person Names**  
   3. Click Save.  
2. **Enable Multiple Address Management**  
   1. Enable Multiple Address Management   
      1. From Setup, in the Quick Find box, enter **Multiple Address Management**, under Fundraising Settings.   
      2. Turn on **Automatic Person Account Mailing Address Synchronization**.

      Note: There is no requirement to ‘Clone and Activate Sync Account Addresses Flow’ the standard template flow suggested here is superseded by a flow included in the unmanaged package.
3. **Enable Data Protection and Privacy**
   1. From Setup, in the Quick Find box, enter **Data Protection and Privacy**, and then select Data Protection and Privacy.
   2. Click **Edit**.
   3. Select 'Make data protection details available in records', and then click **Save**.

   Note: This setting is necessary to provide access to Contact Point Address, Contact Point Phone, and Contact Point Email objects. It may already be enable in some Salesforce instances by default.

**II. Assign Permission Sets**

1. **Assign the Group Management Permission Set**  
   1. From Setup, in the Quick Find box, enter ‘Permission Sets’, and then select **Permission Sets**.  
   2. Click the permission set **Group Membership** in the list view.  
   3. To assign your user:  
      1. Click **Manage** **Assignments.**   
      2. Click **Add** **Assignments**.  
      3. Select each user to whom you want to assign the group, and then click **Next**.  
      4. *Optional:* Select an expiration date for the user assignment to expire.  
      5. Click **Assign**.  
2. **Assign the Stakeholder Management Quick Start Permission Sets**  
   1. From Setup, in the Quick Find box, enter ‘Permission Sets’, and then select **Permission Sets**.  
   2. Click the permission set **SMQS Custom Fields** in the list view.  
   3. To assign your user:  
      1. Click **Manage** **Assignments.**   
      2. Click **Add** **Assignments**.  
      3. Select each user to whom you want to assign the group, and then click **Next**.  
      4. *Optional:* Select an expiration date for the user assignment to expire.  
      5. Click **Assign**.  
      6. Click **Done**.  
3. **Assign the SMQS Person Account Fields Permission Set**  
   1. From Setup, in the Quick Find box, enter ‘Permission Sets’, and then select **Permission Sets**.  
   2. Click the permission set **SMQS Person Account Fields** in the list view.  
   3. To assign your user:  
      1. Click **Manage** **Assignments.**   
      2. Click **Add** **Assignments**.  
      3. Select each user to whom you want to assign the group, and then click **Next**.  
      4. *Optional:* Select an expiration date for the user assignment to expire.  
      5. Click **Assign**.  
      6. Click **Done**.  
4. **Assign the SMQS Split and Merge Households Permission Set**  
   1. From Setup, in the Quick Find box, enter ‘Permission Sets’, and then select **Permission Sets**.  
   2. Click the permission set **SMQS Split and Merge Households** in the list view.  
   3. To assign your user:  
      1. Click **Manage** **Assignments.**   
      2. Click **Add** **Assignments**.  
      3. Select each user to whom you want to assign the group, and then click **Next**.  
      4. *Optional:* Select an expiration date for the user assignment to expire.  
      5. Click **Assign**.  
      6. Click **Done**.

**III. Configure Person Account Access and Account Settings**

1. **Provide access to the Individual Record Type**  
   1. From Setup, in the Quick Find box, **enter** ‘Permission Sets’, and then select **Permission Sets**.  
   2. Click the permission set **SMQS Person Account Fields** in the list view.  
   3. Click **Object Settings**.  
   4. Click **Accounts** under Object Name to modify the object.  
   5. Click **Edit**.  
   6. Check the **Assigned Record Types** checkbox next to **Individual**.  
   7. Click **Save**.  
2. **Modify Account Page Layouts**  
   1. From Setup, click the **Object Manager** tab.  
   2. Click the object name **Account** then select **Page Layouts**.  
   3. Click **Page Layout Assignment.**  
   4. Click **Edit Assignment**.  
   5. Use the table to specify the **SMQS Account Layout** for the relevant profiles.  
   6. Click **Save**.  
3. **Modify Account Search Layouts**  
   1. From Setup, click the **Object Manager** tab.  
   2. Click the object name **Account** then select **Search Layouts**.  
   3. Edit the Default Layout: Click the down arrow to access the dropdown menu, then select **Edit**.  
   4. Move the fields from **Available** **Fields** to **Selected** **Fields** to match the following list:  
      1. Account Name  
      2. Phone  
      3. Email  
      4. Website  
      5. Account Record Type  
   5. Click **Save**.  
4. **Modify Account List View Button Layout**  
   1. From Setup, click the **Object Manager** tab.  
   2. Click the object name **Account** then select **List View Button Layout**.  
   3. Edit the Default Layout: Click the down arrow to access the dropdown menu, then select **Edit**.  
   4. Unselect all Standard Buttons, except **New**.  
   5. Click **Save**.  
5. **Modify Person Account Layouts**  
   1. From Setup, click the **Object Manager** tab.  
   2. Click the object name **Person** **Account** then select **Page Layouts**.  
   3. Click **Page Layout Assignment.**  
   4. Click **Edit Assignment**.  
   5. Use the table to specify the **SMQS Person Account Layout** for the relevant profiles.  
   6. Click **Save**.

**IV. Configure Relationship and Group Objects**

1. **Modify the Party Role Relationship Object**  
   1. **Modify List View Button Layout**  
      1. From Setup, **click** the **Object Manager** tab.  
      2. Click the object name **Party Role Relationship** then select **List View Button Layout**.  
      3. Edit the Default Layout: Click the down arrow to access the dropdown menu, then select **Edit**.  
      4. Unselect all **Standard Buttons**.  
      5. Click **Save**.  
   2. **Edit Related Inverse Record field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Party Role Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Related Inverse Record** to update.  
      4. Click **Edit**.  
      5. In the Help Text, enter the following: *Keep this field blank. Automation will create the reciprocal relationship record and populate this field. This will allow the system to create inverse role records for either side of the relationship.*  
      6. Click **Save**.  
   3. **Edit Relationship Object Name field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Party Role Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Relationship Object Name** to update.  
      4. Click **Edit**.  
      5. In the Description, enter the following: *The object that’s associated with the relationship. Possible values are: Account\_Account\_Relationship and Contact\_Contact\_Relationship. The default value is Account\_Account\_Relationship.*  
      6. In the Help Text, enter the following: *Select Contact Contact Relationship if this record is to define the relationship between two individuals and Account Account Relationship if it defines the relationship between two groups (organizations or households).*  
      7. Click **Save**.  
   4. **Edit Create Inverse Role Automatically field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Party Role Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Create Inverse Role Automatically** to update.  
      4. Click **Edit**.  
      5. In the Help Text, enter the following: *Check this box if the Role and the Related Role are different words, like Parent and Child.*  
      6. Click **Save**.  
2. **Modify the Account Account Relationship Object**  
   1. **Edit Account field Lookup Filter**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Account Account Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Account** to update.  
      4. Click **Edit**.  
      5. In the Lookup Filter Options section, **click** **Show Filter Settings**.  
      6. Specify the filter criteria:  
         1. In the first column, select **Account: Is Person Account**.  
         2. In the second column, select operator **Equals**.  
         3. In the third column, select **Value**.  
         4. In the fourth column, enter **False**.  
      7. Specify the filter as **Required**.  
      8. Enter the following error message under “If it doesn’t, display this error message on save:”: *This field must be an account that represents an organization or household.*  
      9. Leave **Enable this filter** selected.  
      10. Click **Save**.

			![][image1]

2. **Edit Related Account field Lookup Filter**  
   1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Account Account Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Related Account** to update.  
      4. Click **Edit**.  
      5. In the Lookup Filter Options section, click **Show Filter Settings**.  
      6. Specify the filter criteria:  
         1. In the first column, select **Related Account: Is Person Account**.  
         2. In the second column, select operator **Equals**.  
         3. In the third column, select **Value**.  
         4. In the fourth column, enter **False**.  
      7. Specify the filter as **Required**.  
      8. Enter the following error message under “If it doesn’t, display this error message on save:”:: *This field must be an account that represents an organization or household.*  
      9. Leave **Enable this filter** selected.  
      10. Click **Save**.  
   3. **Edit Related Inverse Record field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Account Account Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Related Inverse Record** to update.  
      4. Click Edit.  
      5. In the Help Text, enter the following: *Keep this field blank. Automation will create an inverse record for the Related Account with the appropriate role.*  
      6. Click **Save**.  
   4. **Edit Hierarchy Type field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Account Account Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Hierarchy Type** to update.  
      4. Click **Edit**.  
      5. In the Description, enter the following: *Possible values are: Child, Parent, Peer.*  
      6. In the Help Text, enter the following: *Specifies the hierarchy between groups that are related. For example, select parent if the group in Related Account reports to or is included within the group in Account.*  
      7. Click **Save**.  
3. **Modify the Account Contact Relationship Object**  
   1. **Modify Page Layouts**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Account Contact Relationship** then select **Page Layouts**.  
      3. Click **Page Layout Assignment.**  
      4. Click **Edit Assignment**.  
      5. Use the table to specify the **SMQS Account Contact Relationship Layout** for the relevant profiles.  
      6. Click **Save**.  
   2. **Edit Account field Lookup Filter**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Account Contact Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Account** to update.  
      4. Click **Edit**.  
      5. In the Lookup Filter Options section, click **Show Filter Settings**.  
      6. Specify the filter criteria:  
         1. In the first column, select **Account: Is Person Account**.  
         2. In the second column, select operator **Equals**.  
         3. In the third column, select **Value**.  
         4. In the fourth column, enter **False**.  
      7. Specify the filter as **Required**.  
      8. Enter the following error message under “If it doesn’t, display this error message on save:”:: *This field must be an account that represents an organization or household.*  
      9. Leave **Enable this filter** selected.  
      10. Click **Save**.  
   3. **Update Roles Picklist Field**  
      1. From Setup, at the top of the page, select **Object Manager**.  
      2. Click the **Account Contact Relationship** object in the list.  
      3. Select **Fields & Relationships** on the left-hand side, then click the **Roles** field.  
      4. Update the field description:  
         1. Click **Edit**.  
         2. In the Description, enter: *Editing the Household Member option here may require editing the roles presented in the "New Relationship or Affiliation".*  
         3. Click **Save**.  
      5. Disable the current picklist options:  
         1. Select **Deactivate** next to **Economic Decision Maker**.  
         2. **Deactivate** all remaining values, ensuring **Other** remains active.  
         3. In the Roles Picklist Values section, click **New**.  
         4. Add these values to the text area, separating them with line breaks: **Household Member, Board Member, Volunteer, Employee, Owner**.  
         5. Click **Save**.  
      6. Organize the order of picklist values:  
         1. Click **Reorder**.  
         2. Select **Other** from the list.  
         3. Use the arrow buttons to move it to the bottom of the list.  
         4. Click **Save**.  
      7. Set the Household Member default:  
         1. Select **Edit** next to **Household Member**.  
         2. Check the box for **Make this value the default for the master picklist**.  
         3. Click **Save**.  
4. **Modify the Contact Contact Relationship Object**  
   1. **Edit Related Inverse Record field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Contact Contact Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Related Inverse Record** to update.  
      4. Click **Edit**.  
      5. In the Help Text, enter the following: *Keep this field blank. Automation will create an inverse record for the Related Account with the appropriate role.*  
      6. Click **Save**.  
   2. **Edit Hierarchy Type field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Contact Contact Relationship**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Hierarchy Type** to update.  
      4. Click **Edit**.  
      5. In the Help Text, enter the following: *Specifies the hierarchy between people that are related to this record. For example, select Parent if the person selected in the Contact field, is the parent, superior, or boss of the person selected in the Related Contact field.*  
      6. In the Description, enter the following: *Possible values are: Child, Parent, Peer.*  
      7. Click **Save**.  
5. **Modify the Party Relationship Group object**  
   1. **Modify Type field**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Party Relationship Group**.  
      3. Click **Fields & Relationships**, and then click the name of the field **Type** to update.  
      4. Click **Edit**.  
      5. In the Description, enter the following: *Possible values are Group and Household. Group is default.*  
      6. Click **Save**.  
   2. **Modify List View Button Layout**  
      1. From Setup, click the **Object Manager** tab.  
      2. Click the object name **Party Relationship Group** then select **List View Button Layout**.  
      3. Edit the Default Layout: Click the down arrow to access the dropdown menu, then select **Edit**.  
      4. **Unselect** all Standard Buttons, except **Merge** and **Split**.  
      5. Click **Save**.

**V. Configure Group and App Access**

1. **Change Access to Lightning Apps**  
   1. From Setup, in the Quick Find box, **enter** ‘App Manager’, and then select **App Manager**.  
   2. Click the \[image\] icon on a ‘Stakeholder Management Quick Start’ app’s row, and **select** **Edit**.  
   3. Under ‘App Settings’, click on **User Profiles**.  
   4. **Select** the appropriate Profiles in the **Available Profiles** column and move to **Selected Profiles**.  
   5. Click **Save**.  
2. **Navigate to Stakeholder Management Quick Start**  
   1. Click the **App Launcher** icon (represented by nine dots) located on the far left side of the top navigation bar.  
   2. The App Launcher menu will display a quick view of your most frequently used apps and items, if available select ‘Stakeholder Management Quick Start.’ If unavailable use the **Search apps and items** box.

## Post-Install Considerations: Making This Work For You In Your Existing Setup

While this package installs a standalone custom app, it is highly likely that your stakeholders are involved in multiple operational processes across your organization (such as fundraising, programs, or case management).

Rather than forcing users to switch between disconnected apps, **the goal of this post-install process is to adopt and integrate these new components—the modular flows, custom fields, and dynamic pages—into your primary, existing business apps.** Use the following steps to review, adjust, and embed the accelerator into your live environment.

### 1. Review Component Configurations via the Home Page

The homepage of the Stakeholder Management Quick Start Lightning App serves as your starting point to learning and mastering the various components of the package. Review the page and follow the page to complete the set up.

* **1a. Relationships and Affiliations:**  
  * On the home screen there is a guided flow that allows you to select suggested roles for **Individual Relationships** and **Individual Affiliations**. Select the roles that your nonprofit organization will track and use.  
  * Go to Object Manager and inspect the **Account Contact Relationship (ACR)** object to update the multi-select *Role* picklist field to align with your organization's standard individual affiliation terminology.  
  * Review the active relationship automation (such as the inverse relationship creation and deletion flows) to ensure they do not conflict with any pre-existing custom triggers on your relationship objects.  
* **1b. Contact Points:**  
  * Review the extensive list of contact sync automations (15 flows total across Address, Email, and Phone syncs) that map standard Account fields back and forth to **Contact Point Address**, **Contact Point Phone**, and **Contact Point Email** records.  
  * Test the SMQS Screen Manage Contact Info component on a sample record to see how it consolidates these objects for end-users.  
* **1c. Individuals, Organizations, and Households (Accounts):**  
  * **Determine Need for Householding:** If your nonprofit exclusively engages with individuals one-on-one (meaning most stakeholders live in single-person households), you should turn off or remove the household features to keep your architecture lean.  
  * Verify your **Account** and **Person Account** record types. The package assumes a clean, minimalist model (typically two record types for Organizations under Account, and one for Individuals under Person Account).  
  * Review the household setup flows which automatically handle background Party Relationship Group (PRG) creation and synchronize household naming updates when primary members or account names change.

**Flow Resources:**

* **Introductory Guide:** [What Is a Screen Flow?](https://admin.salesforce.com/blog/2023/what-is-a-screen-flow) — An administrative deep dive explaining how screen flows capture user data and guide staff through interactive UI wizards.  
* **Process Automation:** [Extend Salesforce with Click-Not-Code Processes](https://help.salesforce.com/s/articleView?id=sf.extend_click_process.htm&type=5) — Core Help documentation covering how to design declarative, point-and-click automation workflows without writing custom Apex code.  
* **Core Documentation:** [Platform Automation Overview](https://help.salesforce.com/s/articleView?id=platform.platform_automation.htm&type=5) — The master hub for Salesforce business process automation, outlining multi-step orchestration, automation limits, and system features.  
* **Trailhead Trail:** [Build Flows with Flow Builder](https://trailhead.salesforce.com/content/learn/trails/build-flows-with-flow-builder) — A hands-on, guided learning path designed to take administrators from flow concepts to complex backend automation design.

### 2. Review Agentforce Nonprofit / Nonprofit Cloud Setup Steps

Stakeholder Management is a component of Agentforce Nonprofit / Nonprofit Cloud and has lots of additional functionality and features. In “Before You Install” steps you have enabled Group Membership features. Beyond these two, looking at the applicability of Interaction Summaries, Record Alerts and Timeline features may be relevant to your use of Stakeholder Management.

**Salesforce Documentation**

* **Setup Guide:** [Complete Nonprofit Cloud Prerequisites](https://help.salesforce.com/s/articleView?id=sfdo.npc_prerequisites.htm&type=5) — Official Salesforce Help documentation detailing how to configure baseline features—such as Person Accounts, Data Pipelines, Actionable Segmentation, Interest Tags, and the Timeline—before turning on Nonprofit Cloud.  
* **Trailhead Module:** [Stakeholder Management in Nonprofit Cloud](https://trailhead.salesforce.com/content/learn/modules/stakeholder-management-in-nonprofit-cloud) — A hands-on learning module explaining how to effectively track individuals, organizations, and households using the native Nonprofit Cloud data model and Party Relationship Groups.

### 3. Review Profiles and Permission Sets

The package does not include rigid, pre-packaged permission sets for field, object, and flow access. You will need to design your own access strategy based on your data governance model:

* **Determine Data Entry Paths:** Decide how and where your users will enter data and design permission sets and access to remove options that will not be supported.  
* **Build Custom Permission Sets and Groups:** The accelerator includes basic permission sets for you to adopt and merge with your own custom permission sets and groups.

**Salesforce Documentation:**

* **Core Guide:** [Permission Sets Overview](https://help.salesforce.com/s/articleView?id=platform.perm_sets_overview.htm&language=en_US&type=5) — Learn about the types of permission sets, standard setups, and foundational configuration options.  
* **Assignment Guide:** [Manage Permission Set Assignments](https://help.salesforce.com/s/articleView?id=platform.perm_sets_manage_assignments.htm&language=en_US&type=5) — Step-by-step instructions for assigning or removing permission sets for single or multiple users.  
* **Best Practices:** [Guidelines for Creating Permission Sets and Permission Set Groups](https://help.salesforce.com/s/articleView?id=platform.perm_sets_best_practices.htm&language=en_US&type=5) — Strategic recommendations for organizing your object, field, and user security permissions cleanly.

### 4. Review Lightning Apps, Pages, and Page Layouts

To deliver a seamless user experience, transition the components from the standalone package app into your primary operational apps:

**Migrate Dynamic Pages:** Review the single, dynamic Lightning record pages provided by the package. Instead of using the default standalone app layout, use the Lightning App Builder to assign these dynamic pages (or migrate their conditional visibility components) to your organization's primary working apps.

**Consolidate Page Layouts:** Audit your existing Account and Person Account page layouts to embed the custom checkboxes (like Is Household) and replace standard related lists with the package's modular screen flow components where appropriate.

**Salesforce Documentation:**

* **Guide:** [Break Up Your Record Details with Dynamic Forms](https://help.salesforce.com/s/articleView?id=platform.dynamic_forms_overview.htm&language=en_US&type=5) — Learn how to migrate standard record details sections into modular field components, allowing you to configure granular, conditional visibility rules directly on the page layout.  
* **Access Control:** [Assign Record Types and Page Layouts in Profiles](https://help.salesforce.com/s/articleView?id=platform.users_profiles_record_types.htm&type=5) — Official Help documentation on mapping record types and page layouts to specific user profiles to control object layout options and UI visibility.  
* **Trailhead Module:** [Lightning App Builder](https://trailhead.salesforce.com/content/learn/modules/lightning_app_builder) — A hands-on module teaching you how to use drag-and-drop standard, custom, and managed package components to build bespoke desktop and mobile app pages.

### 5. Establish Data Integrity Guardrails

Because the accelerator relies entirely on background automation without hardcoded restrictions, you should establish your own guardrails before roll-out:

**Provide Guardrails for Automated Fields:** Create custom Validation Rules to lock critical data points (like the Is Household checkbox) after a record is created. This prevents users from accidentally breaking the underlying automation.

**Adjust Duplicate Rules:** Review and update your standard Salesforce Duplicate and Matching Rules to support the new record types.

**Build an Automation Bypass:** The package contains ~30 active flows but no global “off switch.” Before running any large data migrations, either plan to manually deactivate these sync flows or add a custom Bypass\_Automation\_\_c checkbox to their entry criteria to prevent system timeouts.

**Salesforce Documentation:**

* **Validation Rules Guide:** [Validation Rules Documentation](https://help.salesforce.com/s/articleView?id=platform.fields_about_field_validation.htm&language=en_US&type=5) — Detailed information on defining, cloning, activating, and reviewing validation rule parameters.  
* **Duplicate Rules Guide:** [Duplicate Rules Map of Reference](https://help.salesforce.com/s/articleView?id=sales.duplicate_rules_map_of_reference.htm&type=5) — Comprehensive guide covering duplicate management, cross-object logic, and error tracking logs.  
* **Duplicate Rules Framework:** [Things to Know About Duplicate Rules](https://help.salesforce.com/s/articleView?id=sales.duplicate_rules_overview.htm&type=5) — Outlines rule limits, the impact of user access permissions on rule triggers, and specific conditions under which rules bypass execution.  
* **Standard OOTB Rules:** [Standard Duplicate Rules Reference](https://help.salesforce.com/s/articleView?id=sales.duplicate_rules_standard_rules.htm&type=5) — Focuses on standard out-of-the-box duplicate behaviors for Business Accounts, Contacts, Person Accounts, and Leads.

### 6. Standard Address Feature Review

The Salesforce platform offers various native address management tools designed to bolster data integrity and streamline the user interface. We recommend evaluating each setting to determine which configurations best support your specific operational requirements.

**Google Address Autocomplete:** Enhances data entry speed by providing real-time address suggestions as staff type. Note of Caution: This feature is intended for efficiency only; it does not perform address standardization or validate accuracy post-entry.

**Address Geocoding:** Automatically assigns latitude and longitude coordinates to your records. This is a vital implementation milestone for organizations utilizing territory management, advanced mapping, or location-specific reporting.

**State and Country/Territory Picklists:** By default, these address components are open text fields, which often leads to data quality gaps. Activating this feature standardizes entry through dependent picklists. Administrators have the flexibility to define default countries and manage the visibility of specific regional values.

*Notice: Salesforce displays full names (e.g., California) for state and province labels by default. If your organization utilizes standard abbreviations (e.g., CA), these labels must be manually updated within the State and Country/Territory Picklists setup menu; these specific UI labels cannot be modified via a metadata deployment.*

**Documentation Resources:**

* [Configure Maps Address Autocomplete](https://help.salesforce.com/s/articleView?id=xcloud.customize_maps_autocomplete.htm&type=5)  
* [Automated Geocode Clean Rules](https://help.salesforce.com/s/articleView?id=sales.data_dot_com_clean_admin_automatically_get_geocodes_for_addresses.htm&type=5)  
* [State and Country Picklists Overview](https://help.salesforce.com/s/articleView?id=xcloud.admin_state_country_picklists_overview.htm&language=en_US&type=5)

## Known Issues

* None

## Backlog Items

* **Multi-Household Support:** Architectural updates to allow individuals to maintain active memberships across several households simultaneously.  
* **Inline Person Account Creation:** Adding the ability to create new individual records directly within the relationship and affiliation screen flows.  
* **Unified Household Management:** Improving the user interface to manage multiple household memberships within a single runtime session.  
* **Contact Point Field Synchronization:** Automation to sync communication type parameters to Account fields when a contact point is designated as primary.  
* **Deceased Status Automation:** Workflows to handle communication opt-outs and relationship terminations automatically when a person is marked as deceased.  
* **Restoration Framework:** A process to reverse deceased automations and restore historical data in the event of an identity error.  
* **Localization and Translation:** Moving hardcoded flow text to metadata labels to support future Spanish and French translation packs.

## Miscellaneous 

### Revision History

1.0 May 2026 Initial release  
2.0 July 2026 Second release

* Addressed bugs in Manage Household flow addresses  
* Improved Household Setup flows  
* Introduced Managed Contact Point flow to replace Manage ContactPointEmail and Manage ContactPointPhone flows

### Acknowledgements

Justin Gilmore — Architect

Specific thanks to:

* Emily Beach — For contributions related to the Manage Household Flow  
* Cassie Bartelme, Tara Pawlowski, Christy Lambert, Chris Geady, Dar Veverka - For excellent and consistent testers
* Maddy Earhart — For reviewing text and documentation.

### Terms of Use

Thank you for using Global Public Sector (GPS) Accelerators. Accelerators are provided by Salesforce.com, Inc., located at 1 Market Street, San Francisco, CA 94105, United States.

By using this site and these accelerators, you are agreeing to these terms. Please read them carefully.

Accelerators are not supported by Salesforce, they are supplied as-is, and are meant to be a starting point for your organization. Salesforce is not liable for the use of accelerators.

For more about the Accelerator program, visit: https://gpsaccelerators.developer.salesforce.com/
