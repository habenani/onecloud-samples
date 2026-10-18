# S3 bucket

A private Amazon S3 bucket with server side encryption and public access blocked.

Brought over unchanged from a Cloud Provisioning and Governance template (S3) with the OneCloud CPG import: the files are the ones the dry run report listed. The provider block still takes `access_key`, `secret_key` and `region` as variables, the CPG way. OneCloud fills them from the imported provider mapping rows and the region picked on the order, so requesters only give the bucket name.
