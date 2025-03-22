## **Step-by-Step Guide to Configuring EFS in AWS (with Security Group Explanation)**  

We'll go through a **complete example** where we:  
1️⃣ Create an **EFS file system**.  
2️⃣ Configure **Security Groups** to allow EC2 access.  
3️⃣ Mount EFS on multiple **EC2 instances**.  
4️⃣ Test file sharing between EC2 instances.  

---

## **🎯 Scenario:**
🔹 You have two EC2 instances and want to share files between them using **EFS**.  
🔹 The EC2 instances are in the same **VPC** and **subnet**.  
🔹 You'll create an **EFS security group** that allows access only from your EC2 instances.  

---

## **🛠 Step 1: Create an EFS File System**
1. Go to **AWS Management Console** → **EFS (Elastic File System)**.  
2. Click **"Create file system"**.  
3. Configure the **EFS Name** (e.g., `MySharedEFS`).  
4. Select a **VPC** (same as your EC2 instances).  
5. Choose **"Regional"** for multiple AZ access.  
6. Set **Lifecycle Management** to **"None"** (or configure it based on your needs).  
7. Click **Next** → **Create File System**.  

---

## **🛡 Step 2: Configure Security Groups for EFS**
🔹 **Why?**  
EFS uses **NFS (port 2049)**, so we need to allow traffic between EC2 and EFS.

1. Go to **EC2** → **Security Groups** → **Create Security Group**.  
2. Name: `EFS-SG` (Security Group for EFS).  
3. **Inbound Rules:**  
   - **Type:** NFS  
   - **Protocol:** TCP  
   - **Port Range:** `2049`  
   - **Source:** `EC2 Security Group` (not `0.0.0.0/0`, for security).  
4. **Outbound Rules:** (Allow all traffic)  
   - **Type:** All traffic  
   - **Destination:** Anywhere (`0.0.0.0/0`).  
5. Click **Create Security Group**.  
6. Attach this **EFS-SG** to your **EFS file system**.  

---

## **🚀 Step 3: Launch EC2 Instances & Attach Security Groups**
1. Go to **EC2** → **Launch Instances**.  
2. Choose **Amazon Linux 2** or **Ubuntu** (EFS works with both).  
3. Select a **VPC and Subnet** (same as EFS).  
4. Create/Attach a **Security Group for EC2**:  
   - Allow **SSH (22)** from your IP.  
   - Allow **NFS (2049)** from the **EFS security group**.  
5. Launch **two EC2 instances** (`EC2-1` and `EC2-2`).  

---

## **🔗 Step 4: Mount EFS on EC2 Instances**
### **Step 4.1: Install NFS Client on EC2**
Connect to both EC2 instances via **SSH**, then run:  

For **Amazon Linux 2**:
```sh
sudo yum install -y amazon-efs-utils
```
For **Ubuntu**:
```sh
sudo apt update -y
sudo apt install -y nfs-common
```

### **Step 4.2: Mount EFS File System**
1. Find your **EFS DNS name** under **EFS > File System ID**.  
   - Example: `fs-12345678.efs.us-east-1.amazonaws.com`.  
2. Create a directory to mount the EFS:
```sh
sudo mkdir /mnt/efs
```
3. Mount the EFS file system:
```sh
sudo mount -t nfs4 -o nfsvers=4.1,tcp fs-12345678.efs.us-east-1.amazonaws.com:/ /mnt/efs
```
4. Verify the mount:
```sh
df -h
```
You should see the EFS mount point in the output.

### **Step 4.3: Make the Mount Persistent (Optional)**
To remount EFS after reboot, edit the **/etc/fstab** file:
```sh
echo "fs-12345678.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab
```

---

## **📂 Step 5: Test File Sharing Between EC2 Instances**
### **Step 5.1: Create a Test File**
On **EC2-1**, create a test file:
```sh
echo "Hello from EC2-1" | sudo tee /mnt/efs/hello.txt
```
On **EC2-2**, check if the file is there:
```sh
cat /mnt/efs/hello.txt
```
✔ If you see **"Hello from EC2-1"**, your EFS is working perfectly!

---

## **🎯 Recap of Security Groups Setup**
| Security Group | Purpose | Inbound Rule |
|---------------|---------|-------------|
| **EFS-SG** | Allow EC2 to access EFS | NFS (2049) from EC2-SG |
| **EC2-SG** | Allow access from EFS | SSH (22) from your IP, NFS (2049) from EFS-SG |

---

## **✅ Summary**
- **EFS allows multiple EC2 instances to share files.**  
- **Security Groups** restrict access **only to trusted EC2 instances**.  
- **EFS automatically scales** and is replicated across multiple AZs.  
- **No need to manage storage capacity**—AWS handles it.  

Would you like a **Terraform script** to automate EFS setup? 🚀
