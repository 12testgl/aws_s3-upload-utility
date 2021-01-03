# How to upload files to Amazon-AWS-S3 from a remote server? 

[![aws_s3-upload](aws-s3-bucket.svg)](repo_url)

The purpose of this script is to upload various microservice-logs from various servers to amazon s3 for audit and other stuff. Configure your application details in the variable function and you can configure as many as you want or you can put that configuration meta-data somewhere else and pass them as an argument to upload those files to s3. Jenkins/Cron/Airflow friendly bash_script. It comes with slack alerts to track daily status. 

#  Features!

  - variables - Dynamic variable(s), configure your details here
  - ping - Is that Bucket-exists / Is that server up
  - validation - File validation(s) [avoiding empty or old files uploads]
  - download - download that file from remote server [using rsync for performance]
  - upload - Upload downloaded file from remote server to s3 and after that delete them from local disk
  - alert - Slack/Mattermost alerts
  - controller - Main controller which handles everythig 

### How to run

From linux:

* chmod +x fileUpload.sh 
* ./fileUpload.sh ms_name[signup_ms/payment_ms]

