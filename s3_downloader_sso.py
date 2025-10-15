#!/usr/bin/env python3

import boto3
import os
from botocore.exceptions import ClientError, NoCredentialsError

class S3DownloadManager:
    def __init__(self, bucket_name, profile_name=None):
        
        try:
            # Create session with profile if provided
            if profile_name:
                session = boto3.Session(profile_name=profile_name)
                self.s3_client = session.client('s3')
                print(f" Using AWS profile: {profile_name}")
            else:
                self.s3_client = boto3.client('s3')
            
            self.bucket_name = bucket_name
            # Test connection by checking if bucket exists
            self.s3_client.head_bucket(Bucket=bucket_name)
            print(f" Successfully connected to bucket: {bucket_name}\n")
        except NoCredentialsError:
            print("ERROR: AWS credentials not found!")
            print("Please run 'aws configure sso' to set up your SSO credentials.")
            print("Then run 'aws sso login --profile <profile-name>' to authenticate.")
            exit(1)
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                print(f"ERROR: Bucket '{bucket_name}' does not exist!")
            elif error_code == '403':
                print(f"ERROR: Access denied to bucket '{bucket_name}'")
                print("Your SSO session may have expired. Try running:")
                print(f"  aws sso login --profile {profile_name if profile_name else '<profile-name>'}")
            else:
                print(f"ERROR: {e}")
            exit(1)

    def list_files(self):
        
        try:
            print(f"Listing files in bucket: {self.bucket_name}")
            print("-" * 60)
            
            response = self.s3_client.list_objects_v2(Bucket=self.bucket_name)
            
            if 'Contents' not in response:
                print("No files found in the bucket.")
                return []
            
            files = []
            for idx, obj in enumerate(response['Contents'], 1):
                file_name = obj['Key']
                file_size = obj['Size']
                last_modified = obj['LastModified'].strftime('%Y-%m-%d %H:%M:%S')
                files.append(file_name)
                print(f"{idx}. {file_name}")
                print(f"   Size: {self.format_size(file_size)} | Last Modified: {last_modified}")
            
            print("-" * 60)
            print(f"Total files: {len(files)}\n")
            return files
            
        except ClientError as e:
            print(f"ERROR listing files: {e}")
            return []

    def format_size(self, size_bytes):
        
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"

    def download_file(self, file_name, download_path='./downloads'):
        try:
            if not os.path.exists(download_path):
                os.makedirs(download_path)
            
            local_file_path = os.path.join(download_path, os.path.basename(file_name))
            
            print(f"Downloading: {file_name}...", end=' ')
            self.s3_client.download_file(self.bucket_name, file_name, local_file_path)
            print(" Success")
            print(f"   Saved to: {local_file_path}")
            return True
            
        except ClientError as e:
            print(f" Failed: {e}")
            return False

    def get_user_selection(self, total_files):
        while True:
            try:
                selection = input(f"\nEnter file numbers to download (e.g., 1,3,5 or 1-3): ").strip()
                
                if not selection:
                    print("No selection made. Please try again.")
                    continue
                
                selected_indices = set()
                
                
                parts = selection.split(',')
                for part in parts:
                    part = part.strip()
                    if '-' in part:
                        start, end = part.split('-')
                        start, end = int(start.strip()), int(end.strip())
                        if start < 1 or end > total_files or start > end:
                            raise ValueError
                        selected_indices.update(range(start, end + 1))
                    else:
                        num = int(part)
                        if num < 1 or num > total_files:
                            raise ValueError
                        selected_indices.add(num)
                
                return sorted(list(selected_indices))
                
            except ValueError:
                print(f"Invalid input! Please enter numbers between 1 and {total_files}")
                print("Examples: '1,2,3' or '1-3' or '1,3-5'")

    def run(self):
        while True:
            files = self.list_files()
            
            if not files:
                break
            
            selected_indices = self.get_user_selection(len(files))
            
            print(f"\nYou selected {len(selected_indices)} file(s)")
            print("-" * 60)
            
            # Download selected files
            success_count = 0
            for idx in selected_indices:
                file_name = files[idx - 1]
                if self.download_file(file_name):
                    success_count += 1
            
            print("-" * 60)
            print(f"Download complete: {success_count}/{len(selected_indices)} files downloaded successfully\n")
            
            while True:
                continue_choice = input("Do you want to download more files? (yes/no): ").strip().lower()
                if continue_choice in ['yes', 'y']:
                    print("\n")
                    break
                elif continue_choice in ['no', 'n']:
                    print("\nExiting... Goodbye!")
                    return
                else:
                    print("Please enter 'yes' or 'no'")


def list_available_profiles():
    try:
        session = boto3.Session()
        profiles = session.available_profiles
        return profiles
    except Exception as e:
        print(f"Warning: Could not list profiles: {e}")
        return []


def main():
    print("=" * 60)
    print("        AWS S3 File Download Manager (SSO)")
    print("=" * 60)
    print()
    
    profiles = list_available_profiles()
    
    if profiles:
        print("Available AWS profiles:")
        for idx, profile in enumerate(profiles, 1):
            print(f"  {idx}. {profile}")
        print()
    
    profile_name = input("Enter your AWS profile name (press Enter for default): ").strip()
    
    if not profile_name:
        profile_name = None
        print("Using default profile")
    
    print()
    
    bucket_name = input("Enter your S3 bucket name: ").strip()
    
    if not bucket_name:
        print("ERROR: Bucket name cannot be empty!")
        return
    
    print()
    
    manager = S3DownloadManager(bucket_name, profile_name)
    manager.run()


if __name__ == "__main__":
    main()