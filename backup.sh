#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
DB_PATH="/home/ubuntu/data/method_know/var/production.sqlite3"
BACKUP_FILE="/tmp/backup_${DATE}.sqlite3"
S3_BUCKET="framework-bakeoff-backups"

echo "Creating SQLite backup..."

sqlite3 $DB_PATH ".backup '$BACKUP_FILE'"

echo "Uploading backup to S3..."
aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/backups/backup_$DATE.sqlite3

echo "Cleaning up local backup file..."
rm $BACKUP_FILE

echo "Backup complete: s3://$S3_BUCKET/backups/backup_$DATE.sqlite3"