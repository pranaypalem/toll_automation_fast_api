import boto3
import os
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

class DatabaseBackup:
    def __init__(self):
        self.s3_client = boto3.client('s3')
        self.bucket_name = 'toll-automation-processed-files'
        self.db_backup_key = 'database/toll_automation.db'
        self.local_db_path = '/tmp/toll_automation.db'
    
    def restore_database_from_s3(self) -> bool:
        """Restore database from S3 backup on Lambda startup"""
        if not os.environ.get("AWS_LAMBDA_FUNCTION_NAME"):
            return False  # Only for Lambda environment
        
        try:
            # Check if backup exists in S3
            self.s3_client.head_object(Bucket=self.bucket_name, Key=self.db_backup_key)
            
            # Download database backup
            self.s3_client.download_file(self.bucket_name, self.db_backup_key, self.local_db_path)
            logger.info(f"Database restored from S3: {self.db_backup_key}")
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                logger.info("No database backup found in S3, starting with fresh database")
            else:
                logger.error(f"Failed to restore database from S3: {e}")
            return False
    
    def backup_database_to_s3(self) -> bool:
        """Backup current database to S3"""
        if not os.environ.get("AWS_LAMBDA_FUNCTION_NAME"):
            return False  # Only for Lambda environment
        
        if not os.path.exists(self.local_db_path):
            logger.warning("No local database file found to backup")
            return False
        
        try:
            self.s3_client.upload_file(self.local_db_path, self.bucket_name, self.db_backup_key)
            logger.info(f"Database backed up to S3: {self.db_backup_key}")
            return True
        except ClientError as e:
            logger.error(f"Failed to backup database to S3: {e}")
            return False

# Create singleton instance
db_backup = DatabaseBackup()