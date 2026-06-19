![Public Sector Accelerators logo](/docs/Logo_GPSAccelerators_v01.png)

# Stakeholder Management Quick Start

Accelerator Listing: [tbd](https://gpsaccelerators.developer.salesforce.com/) (tbd once published)


## Description

The Stakeholder Management Quick Start helps nonprofit organizations set up the necessary features to track the variety of stakeholders using best practices through automation and clearer set up steps.

**Individuals, Organizations, and Households**
* Guidance and automation to ensure organization and household data quality (automatic creation of Party Relationship Groups, guidance on Account Record Types, and Household naming automation).  
* Ability to easily create organizations and households, along with individuals and their relationships and affiliations. 

**Contact Information Management**
* Guidance and automation to ensure appropriate movement and updating of addresses, emails, and phone numbers between individuals and their affiliated groups. 

**Relationships and Affiliations**
* Suggestion of common relationships and affiliations, and guided automation to assist admins with the population of the data model.   
* Automation to ensure reciprocal creation and deletion of relationships and affiliations.

**General Improvements**
* A custom app, dynamic lighting pages, quick actions and list views for relevant objects  
* Data model improvements through custom fields and the addition of help text, and descriptions for standard fields.   
* Permission sets to assist admins provide access to custom fields and functionality.  
* Custom report types and sample reports.


## Key Assets

This Accelerator includes the following assets:
* An **unmanaged package** (link below; metadata is also found in the [/force-app/main/default/](/force-app/main/default/) folder) that includes:
    * App
    * Custom fields on standard objects
    * Flows
    * Lightning record pages
    * List views
    * Permission sets
    * Quick actions
    * Reports
    * Report types
* **Documentation**, including:
    * This readme file


## Before You Install

**License Requirements**

* Nonprofit Cloud

**Accelerator or Technology-Specific Assumptions**

* This accelerator was built and designed for nonprofit organizations that are just beginning to use Nonprofit Cloud.

**General Assumptions**

* You are using this Accelerator in a sandbox or test environment. It is recommended that you not install any Accelerator directly into production environments and instead promote changes from a sandbox to production.
* If you do not have a Salesforce org licensed to you, try one of our industry solutions for free with one of our [trial environments](https://gpsaccelerators.developer.salesforce.com/trials).


## Installation

1. Install the unmanaged package in a sandbox using this link: https://test.salesforce.com/packaging/installPackage.apexp?p0=04tfn000002swVh
2. On the installation page, select "Install for Admins Only" to ensure the package components are only accessible by users with the Administrator profile until you assign the included permission sets.


## Post-Install Setup & Configuration

### 1. Assign Permission Set Licenses  
This Accelerator includes two permission sets that can be [assigned to users](https://help.salesforce.com/s/articleView?id=platform.perm_sets_manage_assignments.htm&type=5):
* "SMQS Person Account Fields":  This permission set is used to provide access for configuration elements included in the Stakeholder Management Quick Start.
* "SMQS Custom Fields":  This provides access to stand fields related to Person Accounts once those are enabled.

### 2. Assign Access to the App
If you are using the "Stakeholder Management Quick Start" app included in this Accelerator, assign it to your users:
1. From Setup, in the Quick Find box, enter "Manager", and then select App Manager.
2. Click the action menu next to the "Stakeholder Management Quick Start" app, and then select Edit.
3. From the User Profiles tab, select the user profiles you want to grant access to the app and save.

### 3. Add Picklist Values to Existing Fields
   1. **Account Account Relationship: Account**
      1. From Setup, click the Object Manager tab, and select the **Account Account Relationship** object.
      2. Under "Fields & Relationships", select the **Account** field and click "Edit".
      3. In the Lookup Filter Options section, click **Show Filter Settings** and specify the filter criteria a record must meet to be a valid value:
         1. In the first column, click the lookup icon or start typing in the text box and select type **Account: Is Person Account**.
         2. In the second column, select operator **Equals**.
         3. In the third column, select **Value**.
         4. In the fourth column, enter **False**.
      4. Specify the filter as **Required**.
      5. Enter the following error message:  `This field must be an account that represents an organization or household.`
      6. Click "Save".
   2. **Account Account Relationship: Related Account**
      1. From Object Manager, select the **Account Account Relationship** object.
      2. Under "Fields & Relationships", select the **Related Account** field and click "Edit".
      3. In the Lookup Filter Options section, click **Show Filter Settings** and specify the filter criteria:
         1. In the first column, click the lookup icon or start typing in the text box and select type **Account: Is Person Account**.
         2. In the second column, select operator **Equals**.
         3. In the third column, select **Value**.
         4. In the fourth column, enter **False**.
      4. Specify the filter as **Required**.
      5. Enter the following error message:  `This field must be an account that represents an organization or household.`
      6. Click "Save".
   3. **Account Account Relationship: Related Inverse Record**
      1. From Object Manager, select the **Account Account Relationship** object.
      2. Under "Fields & Relationships", select the **Related Inverse Record** field and click "Edit".
      3. In the Help Text enter the following:  `Keep this field blank. Automation will create an inverse record for the Related Account with the appropriate role.`
      4. Click "Save".
   4. **Account Account Relationship: Hierarchy Type**
      1. From Object Manager, select the **Account Account Relationship** object.
      2. Under "Fields & Relationships", select the **Hierarchy Type** field and click "Edit".
      3. In the Help Text enter the following:  `Specifies the hierarchy between groups that are related. For example, select parent if the group in Related Account reports to or is included within the group in Account.  For example, a group is related to another group as a parent, peer, or child.`
      4. In the Description enter the following:  `Possible values are: Child, Parent, Peer`
      5. Click "Save".
   5. **Account Contact Relationship: Account**  
      1. From Object Manager, select the **Account Contact Relationship** object.
      2. Under "Fields & Relationships", select the **Account** field and click "Edit".
      3. In the Lookup Filter Options section, click **Show Filter Settings** and specify the filter criteria:
         1. In the first column, click the lookup icon or start typing in the text box and select type **Account: Is Person Account**.
         2. In the second column, select operator **Equals**.
         3. In the third column, select **Value**.
         4. In the fourth column, enter **False**.
      4. Specify the filter as **Required**.
      5. Enter the following error message:  `This field must be an account that represents an organization or household.`
      6. Click "Save".
   6. **Account Contact Relationship: Roles**
      1. From Object Manager, select the **Account Contact Relationship** object.
      2. Under "Fields & Relationships", select the **Roles** field and click "Edit".
      3. In the Description enter the following:  `Editing the Household Member option here may require editing the roles presented in the "New Relationship or Affiliation".`
      4. Click "Save".
      5. Next to Economic Decision Maker click **Deactivate**.  Repeat for all Existing Picklist Values except for Other.
      6. In the Type Picklist Values section click "New".
      7. In the text box add the following values separated by line breaks:
         ```
         Household Member
         Board Member
         Volunteer
         Employee
         Owner
         ```
      11. Click "Save".
   7. **Contact Contact Relationship: Related Inverse Record**
      1. From Object Manager, select the **Account Account Relationship** object.
      2. Under "Fields & Relationships", select the **Related Inverse Record** field and click "Edit".
      3. In the Help Text enter the following:  `Keep this field blank. Automation will create an inverse record for the Related Account with the appropriate role.`
      4. Click "Save".
   8. **Contact Contact Relationship: Hierarchy Type**
      1. From Object Manager, select the **Contact Contact Relationship** object.
      2. Under "Fields & Relationships", select the **Hierarchy Type** field and click "Edit".
      3. In the Help Text enter the following:  `Specifies the hierarchy between people that are related with this record. For example, select Parent if the person selected in the Contact field, is the parent, superior, or boss of the person selected in the Related Contact field`
      4. In the Description enter the following:  `Possible values are: Child, Parent, Peer`
      5. Click "Save".
   9. **Party Relationship Group: Type**
       1. From Object Manager, select the **Party Relationship Group** object.
       2. Under "Fields & Relationships", select the **Type** field and click "Edit".
       3. In the Description enter the following:  `Possible values are Group and Household. Group is default.`
       4. Click "Save".
   10. **Party Role Relationship: Related Inverse Record**
       1. From Object Manager, select the **Party Role Relationship** object.
       2. Under "Fields & Relationships", select the **Related Inverse Record** field and click "Edit".
       3. In the Help Text enter the following:  `Keep this field blank. Automation will create an inverse record to allow a role to be created from either side of the relationship.`
       4. Click "Save".
   11. **Party Role Relationship: Relationship Object Name**
       1. From Object Manager, select the **Party Role Relationship** object.
       2. Under "Fields & Relationships", select the **Relationship Object Name** field and click "Edit".
       3. In the Help Text enter the following:  `Select Contact Contact Relationship if this record is to define the relationship between two individuals and Account Account Relationship if it defines the relationship between two groups (organizations or households).`
       4. In the Description enter the following:  `The object that’s associated with the relationship. Possible values are: Account\_Account\_Relationship and Contact\_Contact\_Relationship.  The default value is Account\_Account\_Relationship.`
       5. Click "Save".
   12. **Party Role Relationship: Create Inverse Role Automatically**
       1. From Object Manager, select the **Party Role Relationship** object.
       2. Under "Fields & Relationships", select the **Create Inverse Role Automatically** field and click "Edit".
       3. In the Help Text enter the following: `Check this box if the Role and the Related Role are different words, like Parent and Child.`
       4. Click "Save".

### 4. Assign Lightning Record Pages
Review and modify the Lightning Pages to ensure they meet your needs and considerations.  
     
* [Break Up Your Record Details with Dynamic Forms](https://help.salesforce.com/s/articleView?id=platform.dynamic_forms_overview.htm&language=en_US&type=5) (Help Article)
* [Lightning App Builder](https://trailhead.salesforce.com/content/learn/modules/lightning_app_builder) (Trailhead Badge)

### 5. Other Considerations

**1. Review flows**:  Review the following documentation and training resources to modify the flows included in this Quick Start Accelerator.

   * [What Is a Screen Flow?](https://admin.salesforce.com/blog/2023/what-is-a-screen-flow) (Blog Post)
   * [Automate Your Business Processes with Salesforce Flow](https://help.salesforce.com/s/articleView?id=sf.extend_click_process.htm&type=5) (Help Article)
   * [Automate Your Business Processes](https://help.salesforce.com/s/articleView?id=platform.platform_automation.htm&type=5) (Help Article)
   * [Build Flows with Flow Builder](https://trailhead.salesforce.com/content/learn/trails/build-flows-with-flow-builder) (Trailhead Badge)

**2. Review Nonprofit Cloud Setup steps**:  Stakeholder Management is a component of Nonprofit Cloud and has lots of additional functionality and features. In “Before You Install” steps you have enabled Interest Tags and Group Membership features. Beyond these two, looking at the applicability of Interaction Summaries, Record Alerts and Timeline features may be relevant to your use of Stakeholder Management.   
     
   * [Stakeholder Management in Agentforce Nonprofit](https://trailhead.salesforce.com/content/learn/modules/stakeholder-management-in-nonprofit-cloud) (Trailhead Badge)
   * [Complete Nonprofit Cloud Prerequisites](https://help.salesforce.com/s/articleView?id=sfdo.npc_prerequisites.htm&type=5) (Help Article)

**3. [Set up action plans](https://help.salesforce.com/s/articleView?id=ind.fsc_action_plans.htm&type=5) to create reusable task lists**.

**4. [Assign Record Types and Page Layouts in Profiles](https://help.salesforce.com/s/articleView?id=platform.users_profiles_record_types.htm&type=5)**:  Review your profiles and assign default Record Type for the new Person Account Record Type.

### 5. Navigate to Stakeholder Management Quick Start
   1. Click the App Launcher icon (represented by nine dots) located on the far left side of the top navigation bar.  
   2. The App Launcher menu will display a quick view of your most frequently used apps and items, if available select ‘Stakeholder Management Quick Start.’ If unavailable use the "Search apps and items" box.


## FAQs

**_Q: Do I really need an FAQ for my Accelerator?_**

A: Great question! Perhaps not, but if you had common misunderstandings or confusion during beta testing with an aspect of setup or use, you may find it helpful to create some related FAQs. You might also wish to use FAQs to reiterate a critical point found in this readme or any other included documentation. An FAQ may also help point out a recommendation or tip about how to use your Accelerator.

## Additional Resources

* [Group Membership](https://help.salesforce.com/s/articleView?id=ind.group_membership.htm) (Help Article)
* [Stakeholder Management in Agentforce Nonprofit](https://trailhead.salesforce.com/content/learn/modules/stakeholder-management-in-nonprofit-cloud) (Trailhead Module)
* Related Data Models
  * [Group Membership and Households Data Model](https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud.meta/nonprofit_cloud/psc_data_model_party_relationship_groups.htm)  
  * [Group Memberships and Households in Nonprofit Cloud](https://developer.salesforce.com/docs/atlas.en-us.nonprofit_cloud.meta/nonprofit_cloud/npc_group_memberships_households.htm)


## Revision History

<strong>1.0 Initial release (tbd)</strong>


## Backlog Items

* Gendered and Gender Neutral Roles using custom fields and formulas  
* Add new individual from ‘Create New Relationship and Affiliation’ flow  
* Direct to add new individual relationship after a person is added to household  
* Support for multiple household support in Manage Household flow  


## Acknowledgements

This Accelerator was developed by:
* **[Justin Gilmore](https://www.linkedin.com/in/justinsgilmore/)** - Senior, Account SE, Salesforce

## Terms of Use

Thank you for using Global Public Sector (GPS) Accelerators.  Accelerators are provided by Salesforce.com, Inc., located at 1 Market Street, San Francisco, CA 94105, United States.

By using this site and these accelerators, you are agreeing to these terms. Please read them carefully.

Accelerators are not supported by Salesforce, they are supplied as-is, and are meant to be a starting point for your organization. Salesforce is not liable for the use of accelerators.

For more about the Accelerator program, visit: [https://gpsaccelerators.developer.salesforce.com/](https://gpsaccelerators.developer.salesforce.com/)
