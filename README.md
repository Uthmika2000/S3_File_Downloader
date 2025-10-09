# Complete Guide: AWS S3 Setup and File Download Script

Created: October 9, 2025 8:49 PM

### Step 1: Prerequisites

**Install Required Tools:**

1. **AWS CLI** - Follow the official guide: [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. **Python 3.x** - Download from [https://www.python.org/downloads/](https://www.python.org/downloads/)

In Windows:

Create and activate a virtual environment:

```bash
python -m venv venv
```

Then activate the Environment:

```bash
venv\Scripts\activate
```

1. **Boto3 (AWS SDK for Python)**:

```bash
pip install boto3
```

### Step 2: Configure AWS Credentials

1. **Create an IAM User** (if you don't have one):
    - Go to AWS Console → IAM → Users → Add User
    - In set permissions: Select Attach policies directly option
    - Then, Attach policy: `AmazonS3FullAccess` (or create a custom policy with S3 permissions)
    - Create the user
    - Select the user and create Access Key
    - Save the Access Key ID and Secret Access Key
2. **Configure AWS CLI**:

```bash
aws configure
```

Enter:

- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-east-1`)
- Default output format: `json`

### Step 3: Create S3 Bucket(if you don't have)

**Option A: Using AWS Console**

1. Go to AWS Console → S3
2. Click "Create bucket"
3. Enter a unique bucket name (e.g., `my-download-bucket-12345`)
4. Choose your region
5. Keep default settings or adjust as needed
6. Click "Create bucket"

**Option B: Using AWS CLI:**

```bash
# For us-east-1
aws s3api create-bucket --bucket my-download-bucket-12345 --region us-east-1

# For other regions, add location constraint
aws s3api create-bucket --bucket my-download-bucket-12345 --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
```

### Step 4: Upload Sample Files (If you want)

Upload some test files to your bucket:

```bash
# Create sample files locally
echo "File 1 content" > file1.txt
echo "File 2 content" > file2.txt
echo "File 3 content" > file3.txt

# Upload to S3
aws s3 cp file1.txt s3://my-download-bucket-12345/
aws s3 cp file2.txt s3://my-download-bucket-12345/
aws s3 cp file3.txt s3://my-download-bucket-12345/
```

Step 5: Python Script for Interactive Download

### Step 6: Run the Script

1. **Save the script** as `s3_downloader.py`
2. **Make it executable** (Linux/Mac):

```bash
chmod +x s3_downloader.py
```

**Run the script**:

```bash
python s3_downloader.py
```

### Step 7: Using the Script

When you run the script:

1. **Enter your bucket name** when prompted
2. **View the file list** - all files with their sizes and modification dates
3. **Select files to download**:
    - Single files: `1` or `3`
    - Multiple files: `1,2,5`
    - Range: `1-3` (downloads files 1, 2, and 3)
    - Mixed: `1,3-5,7`
4. **Files are downloaded** to a `./downloads` folder
5. **Choose to continue or exit** after each download session
