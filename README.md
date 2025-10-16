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

## Approach 1 - Using Python Script

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


## Approach 1A - Using Python Script with AWS SSO Authentication

This approach is for users who authenticate to AWS using SSO (Single Sign-On) instead of Access Keys.

### Prerequisites

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

3. **Boto3 (AWS SDK for Python)**:

```bash
pip install boto3
```

### Step 1: Configure AWS SSO

**Get SSO Information from Your AWS Administrator:**

Ask your AWS administrator for:
- **SSO Start URL** (e.g., `https://my-company.awsapps.com/start`)
- **SSO Region** (e.g., `us-east-1`)
- Your **SSO username/email**

**Configure SSO:**

```bash
aws configure sso
```

Follow the prompts and enter:
- **SSO session name**: `my-company-sso` (or any name you prefer)
- **SSO start URL**: `https://my-company.awsapps.com/start` (provided by admin)
- **SSO region**: `us-east-1` (provided by admin)
- **SSO registration scopes**: Press Enter for default
- A browser window will open - login with your credentials
- Select your AWS account
- Select a permission set (role)
- **CLI default client Region**: `us-east-1` (or your preferred region)
- **CLI default output format**: `json`
- **CLI profile name**: `my-sso-profile` (choose any name)

### Step 2: Login to SSO

Before running the script, authenticate with SSO:

```bash
aws sso login --profile my-sso-profile
```

This will open a browser for authentication. You'll need to do this each time your SSO session expires (typically every 8-12 hours).

### Step 3: Run the SSO-enabled Script

1. **Save the script** as `s3_downloader_sso.py`

2. **Make it executable** (Linux/Mac):

```bash
chmod +x s3_downloader_sso.py
```

3. **Run the script**:

```bash
python s3_downloader_sso.py
```

### Step 4: Using the SSO Script

When you run the script:

1. **View available AWS profiles** - The script will list all configured profiles
2. **Enter your AWS profile name** when prompted (e.g., `my-sso-profile`) or press Enter for default
3. **Enter your bucket name** when prompted
4. **View the file list** - all files with their sizes and modification dates
5. **Select files to download**:
    - Single files: `1` or `3`
    - Multiple files: `1,2,5`
    - Range: `1-3` (downloads files 1, 2, and 3)
    - Mixed: `1,3-5,7`
6. **Files are downloaded** to a `./downloads` folder
7. **Choose to continue or exit** after each download session

### Troubleshooting SSO

**If you get "credentials expired" error:**

```bash
aws sso login --profile my-sso-profile
```

**To check your SSO session status:**

```bash
aws sts get-caller-identity --profile my-sso-profile
```

**To list all configured profiles:**

```bash
aws configure list-profiles
```


## Approach 2 - Using Powershell Script

### Prerequisites

PowerShell 5.1 or later (PowerShell Core 7+ recommended)
AWS.Tools.S3 module

### Installation Steps

1. Install AWS.Tools.S3 module:

```powershell   
Install-Module -Name AWS.Tools.S3 -Scope CurrentUser
```

2. Configure AWS Credentials Choose one of these methods: 
**Option A: Using AWS CLI**

```bash   
aws configure
```
**Option B: Using PowerShell**

```powershell   
Set-AWSCredential -AccessKey YOUR_ACCESS_KEY -SecretKey YOUR_SECRET_KEY -StoreAs default
```
**Option C: Environment Variables**

```powershell   
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_KEY"
```
### Run the PowerShell Script

1. Save the script as download.ps1
2. Navigate to the script directory:

### Run the script:

```powershell   
.\s3_download.ps1
```


## Approach 2A - Using PowerShell Script with AWS SSO Authentication

This approach is for users who authenticate to AWS using SSO (Single Sign-On) instead of Access Keys.

### Prerequisites

1. **PowerShell 5.1 or later** (PowerShell Core 7+ recommended)
2. **AWS CLI** - Follow the official guide: [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **AWS.Tools.S3 module**

### Installation Steps

1. **Install AWS.Tools.S3 module:**

```powershell
Install-Module -Name AWS.Tools.S3 -Scope CurrentUser
```

### Step 1: Configure AWS SSO

**Get SSO Information from Your AWS Administrator:**

Ask your AWS administrator for:
- **SSO Start URL** (e.g., `https://my-company.awsapps.com/start`)
- **SSO Region** (e.g., `us-east-1`)
- Your **SSO username/email**

**Configure SSO:**

```bash
aws configure sso
```

Follow the prompts and enter:
- **SSO session name**: `my-company-sso` (or any name you prefer)
- **SSO start URL**: `https://my-company.awsapps.com/start` (provided by admin)
- **SSO region**: `us-east-1` (provided by admin)
- **SSO registration scopes**: Press Enter for default
- A browser window will open - login with your credentials
- Select your AWS account
- Select a permission set (role)
- **CLI default client Region**: `us-east-1` (or your preferred region)
- **CLI default output format**: `json`
- **CLI profile name**: `my-sso-profile` (choose any name)

### Step 2: Login to SSO

Before running the script, authenticate with SSO:

```bash
aws sso login --profile my-sso-profile
```
or if it doesn't work.
Force it for the whole PS session before running the script:

```bash
$env:AWS_PROFILE = 'your_profile'
aws sso login --profile $env:AWS_PROFILE
```

This will open a browser for authentication. You'll need to do this each time your SSO session expires (typically every 8-12 hours).

### Step 3: Run the SSO-enabled PowerShell Script

1. **Save the script** as `s3_downloader_sso.ps1`

2. **Navigate to the script directory:**

```powershell
cd path\to\script\directory
```

3. **Run the script:**

```powershell
.\s3_downloader_sso.ps1
```

### Step 4: Using the SSO PowerShell Script

When you run the script:

1. **View available AWS profiles** - The script will list all configured profiles
2. **Enter your AWS profile name** when prompted (e.g., `my-sso-profile`) or press Enter for default
3. **Enter your bucket name** when prompted
4. **View the file list** - all files with their sizes and modification dates
5. **Select files to download**:
    - Single files: `1` or `3`
    - Multiple files: `1,2,5`
    - Range: `1-3` (downloads files 1, 2, and 3)
    - Mixed: `1,3-5,7`
6. **Files are downloaded** to a `.\downloads` folder
7. **Choose to continue or exit** after each download session

### Troubleshooting SSO

**If you get "credentials expired" or "Access Denied" error:**

The script will provide helpful instructions. Run:

```bash
aws sso login --profile my-sso-profile
```

**To check your SSO session status:**

```bash
aws sts get-caller-identity --profile my-sso-profile
```

**To list all configured profiles:**

```bash
aws configure list-profiles
```


### Required AWS Permissions
Your AWS IAM user/role needs these permissions:
```json{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    }
  ]
}
```
### Using the Scripts
**Both scripts work similarly:**
### Example Session
```
============================================================
        AWS S3 File Download Manager
============================================================

Enter S3 bucket name: my-download-bucket-12345

[OK] Connected to: my-download-bucket-12345 (Region: us-east-1)

Listing files...
------------------------------------------------------------
1. document.pdf
   2.45 MB | 2024-10-01 14:30:22
2. image.png
   856.34 KB | 2024-10-02 09:15:10
3. data.csv
   124.56 KB | 2024-10-03 16:45:33
------------------------------------------------------------
Total: 3 files

Enter file numbers (e.g., 1,3,5 or 1-3): 1,3

Downloading 2 file(s)...
------------------------------------------------------------
Downloading: document.pdf... [OK]
   -> ./downloads/document.pdf
Downloading: data.csv... [OK]
   -> ./downloads/data.csv
------------------------------------------------------------
Complete: 2/2 downloaded

Download more? (yes/no): no

Goodbye!
```
### Selection Syntax
When selecting files to download:

* Single file: 1 or 3
* Multiple files: 1,2,5
* Range: 1-3 (downloads files 1, 2, and 3)
* Mixed: 1,3-5,7

### Download Location
Files are downloaded to the ```./downloads``` folder in the current directory. The folder is created automatically if it doesn't exist.

### Features

* 🔍 Auto-detect bucket region - No need to specify the region manually
* 📋 Interactive file listing - See all files with sizes and modification dates
* 🎯 Flexible selection - Download single files, multiple files, or ranges
* 📦 Batch downloads - Download multiple files in one go
* 🔄 Repeat sessions - Download multiple batches without restarting
