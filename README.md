email_app
=========

The app accepts the following parameters to send emails via Mailgun -
1) "to" - email of the recipient
2) "to_name" - name of the recipient
3) "cc" - email of the cc'd recipient
4) "cc_name" - name of the cc'd recipient
5) "bcc" - email of the bcc'd recipient
6) "bcc_name" - name of the bcc'd recipient
7) "from" - email of the sender
8) "from_name" - name of the sender
9) "subject" - subject of the email
10) "body" - body of the email

The data is persisted through sqlite.

Sinatra is used as it is a lightweight framework that is ideal for dealing with HTTP requests.

Some additional features that can be added are -
1) Customizing the emails further by adding the ability to add attachments and tags, tracking opens and clicks, and setting a delivery time of up to three days (Mailgun's limit)
2) Silently failing requests to Mailgun by reverting to another service such as Mandrill
3) Increasing spec coverage for form validation and invalid parameters sent to Mailgun
4) Allowing the sender to mark an email as 'important', upon which he/she is notified (via email) about click and open actions by the recipient
5) Enabling sending emails to multiple recipients
6) Adding support for HTML elements in the body
7) Detecting spam (albeit a more involved task)

=========

Clone https://github.com/sachishah/email_app.git
