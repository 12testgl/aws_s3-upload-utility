#!/bin/bash
#  Upload files to AWS S3 bucket
variables()
{
    if [[ $# -eq 0 ]] ; then
        echo 'Please provide application name!'
        return 1;
    else
        case "$1" in
            signup_ms)
                echo "Setting $1 variables";
                declare -g BUCKET_NAME="prod_logs-backup";
                declare -g BUCKET_LOG_PATH="signup/access/";
                declare -g SSH_USER="ubuntu";
                declare -g SSH_SERVER="x.x.x.x";
                declare -g PREVIOUS_DAY=`TZ=MYT+16 date +%Y-%m-%d`;
                declare -g LOG_FILE="signup_access_$PREVIOUS_DAY.gz";
                declare -g REMOTE_LOG_PATH=("/home/ubuntu/logs/signup/$LOG_FILE");
                declare -g LOCAL_LOG_PATH=("/home/ubuntu/logs/signup/access/");
                declare -g APP_NAME="signup_ms";
            ;;
            
            login_ms)
                echo "Setting $1 variables";
                declare -g BUCKET_NAME="prod_logs-backup";
                declare -g BUCKET_LOG_PATH="login/application/";
                declare -g SSH_USER="centos";
                declare -g SSH_SERVER="x.x.x.x";
                declare -g PREVIOUS_DAY=`TZ=MYT+16 date +%Y-%m-%d`;
                declare -g LOG_FILE="login_app_$PREVIOUS_DAY.gz";
                declare -g REMOTE_LOG_PATH=("/home/ubuntu/logs/login/$LOG_FILE");
                declare -g LOCAL_LOG_PATH=("/home/ubuntu/logs/login/application/");
                declare -g APP_NAME="login_ms";
            ;;
            
            payment_ms)
                echo "Setting $1 variables";
                declare -g BUCKET_NAME="prod_logs-backup";
                declare -g BUCKET_LOG_PATH="payment/access/";
                declare -g SSH_USER="log";
                declare -g SSH_SERVER="x.x.x.x";
                declare -g PREVIOUS_DAY=`TZ=MYT+16 date +%Y-%m-%d`;
                declare -g LOG_FILE="payment_access$PREVIOUS_DAY.gz";
                declare -g REMOTE_LOG_PATH=("/home/ubuntu/logs/payment/$LOG_FILE");
                declare -g LOCAL_LOG_PATH=("/home/ubuntu/logs/payment/access/");
                declare -g APP_NAME="payment_ms";
            ;;
            *) echo 'Please provide correct application name!' ;;
        esac
        return 0;
    fi
}

ping()
{
    if /usr/local/bin/aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo "s3 bucket found"
        if ssh -q $SSH_USER@$SSH_SERVER exit 2>/dev/null; then
            echo "ssh connectivity available"
            return 0;
        else
            return 1;
        fi
    else
        return 1;
    fi
}

validation()
{
    if ssh $SSH_USER@$SSH_SERVER [[ -f "$REMOTE_LOG_PATH" ]]; then
        echo "file_exists"
        if ssh $SSH_USER@$SSH_SERVER [[ -s "$REMOTE_LOG_PATH" ]]; then
            echo "file has something";
            return 0;
        else
            echo "file is empty";
            return 1;
        fi
    else
        {
            echo "File not found!"
            return 1;
        }
    fi
}

download()
{
    echo "Downloading file from remote server"
    if rsync -avzh --progress -e ssh $SSH_USER@$SSH_SERVER:"$REMOTE_LOG_PATH" "$LOCAL_LOG_PATH" 2>/dev/null; then
        return 0;
    else
        return 1;
    fi
}

upload()
{
    
    echo "Log Uploading"
    if /usr/local/bin/aws s3 cp "$LOCAL_LOG_PATH"/"$LOG_FILE" "s3://$BUCKET_NAME/$BUCKET_LOG_PATH" 2>/dev/null; then
        rm "$LOCAL_LOG_PATH"/"$LOG_FILE"
        return 0;
    else
        return 1;
    fi
}

alert()
{
    echo "Mattermost/Slack Notification"
    if [[ $# -eq 0 ]] ; then
        echo 'No alert type!'
        exit 0
    else
        case "$1" in
            success)
                echo "success alert"
                local escapedText=":white_check_mark: Application - $APP_NAME || Log File -  $LOCAL_LOG_PATH/$LOG_FILE || S3-Bucket - $BUCKET_NAME/$BUCKET_LOG_PATH";
            ;;
            upload_error)
                echo "error alert"
                escapedText=":x: Application - $APP_NAME || Log File -  $LOCAL_LOG_PATH/$LOG_FILE || S3-Bucket - $BUCKET_NAME/$BUCKET_LOG_PATH || Reason - upload failed";
            ;;
            download_error)
                echo "error0 alert"
                escapedText=":x: Application - $APP_NAME || Log File -  $LOCAL_LOG_PATH/$LOG_FILE || S3-Bucket - $BUCKET_NAME/$BUCKET_LOG_PATH || Reason - download failed";
            ;;
            validation_error)
                echo "validation alert"
                escapedText=":warning: Application - $APP_NAME || Log File -  $LOCAL_LOG_PATH/$LOG_FILE || S3-Bucket - $BUCKET_NAME/$BUCKET_LOG_PATH || Reason - validation failed";
            ;;
            ping_error)
                echo "ping alert"
                escapedText=":signal_strength: Application - $APP_NAME || Log File -  $LOCAL_LOG_PATH/$LOG_FILE || S3-Bucket - $BUCKET_NAME/$BUCKET_LOG_PATH || Reason - ping failed";
            ;;
            variable_error)
                echo "ping alert"
                escapedText=":signal_strength: Application - $APP_NAME || Log File -  $LOCAL_LOG_PATH/$LOG_FILE || S3-Bucket - $BUCKET_NAME/$BUCKET_LOG_PATH || Reason - variable failed";
            ;;
            *) echo 'Alert type not supported!' ;;
        esac
    fi
    echo "$escapedText";
    curl -X POST -H 'Content-type: application/json' --data '{"text": "'"$escapedText"'"}' https://chat.example.in/hooks/abcdsabdjbs324nmgndmsgb
}

controller()
{
    
    if variables $1; then
        if ping; then
            if validation; then
                if download; then
                    if upload; then
                        alert success
                    else
                        alert upload_error
                    fi
                else
                    alert download_error
                fi
            else
                alert validation_error
            fi
        else
            alert ping_error
        fi
    else
        alert variable_error
    fi
}

controller $1
