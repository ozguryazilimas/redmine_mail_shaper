
# Mail Shaper

Mail shaper plugin adds a new capabilities to Redmine email system.

This plugin is compatible with Redmine 4.x. If you want to use it with Redmine 3.x please use redmine3 branch.

Compatible with Redmine 4.x and 5.x.

## Features

1. Wiki page updates and new wiki page content are received via email.
2. If the issue is subtask,the parent issue's subject is received with the subtask.
3. When email sending for wiki changes is enabled, it is possible to limit the number of rows for this email to avoid long email.
4. Users get email for time entries.
5. You can configure mail shaper not to send email when there is one change at a time and the change is a preconfigured value, such as assigned part.

## Settings

* Plugin settings are accessible at /administration/plugins/redmine_mail_shaper address with administration account.

## Usage

* Issue parent subject: If activated, if the job is subtask, parent issue's subject is written in the email.
* Changes on wiki page updates: Users get email for the updates in the wiki pages.
* Content of new wiki pages: New wiki page's content is received via email.
* Number of lines around differences:How many unchanged lines to show before and after the lines that has changed in wiki difference emails.
Example:
If 4 is entered here, 4 top and 4 bottom rows for the changes in the wiki are received by email.Green parts in the email show the amendments.
* Maximum number of diff lines displayed: In order to avoid long email, it is to possible to limit changes in the wiki page by writing number.
Example: 
If 50 is written in this area,50 changes are shown in the email.
* Time entries trigger email notification: If activated, time entries are received via email.
* Time entries create issue journal: If activated, time entry is shown on the issue as a comment.
* Spent time:If activated, users get email when the only change in the issue is time entry.
* Files: If activated,users get email when file is uploaded in the issue.
* Attributes: Option that you do not want to get email about changes in the issue is selected.
* Custom fields: If there is only one change and the change is in any one of these custom fields, email will not be be send

## License

Copyright (c) 2012, Onur Küçük. Licensed under [GNU GPLv2](LICENSE)


