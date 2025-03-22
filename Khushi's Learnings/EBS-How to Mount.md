### **Mounting an EBS Volume in Linux - Step by Step Explanation**  

When you attach a new **EBS (Elastic Block Store) volume** to an **EC2 instance**, it won’t be usable until you **mount** it. Mounting means making the storage accessible by associating it with a directory.

---

## **Step 1: Attach the EBS Volume to the EC2 Instance**
📌 **Why?**  
Before mounting, the EBS volume must be attached to the EC2 instance so that the operating system recognizes it as a storage device.

1. **Go to AWS EC2 Dashboard → Volumes**
2. Select the **EBS volume** you want to attach.
3. Click **Actions → Attach Volume**.
4. Select the **EC2 instance** and assign a **device name** (e.g., `/dev/xvdf`).
5. Click **Attach**.

---

## **Step 2: Check if the Volume is Recognized**
📌 **Why?**  
To verify that Linux detects the new storage device.

Run the following command in your EC2 instance:  
```bash
lsblk
```
🔹 This lists all storage devices. Look for an **unmounted volume** (e.g., `/dev/xvdf`) with no associated mount point.

Example output:
```
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
xvda    202:0    0   10G  0 disk /
xvdf    202:1    0   20G  0 disk  # New unmounted EBS volume
```
Here, `/dev/xvdf` is the new EBS volume.

---

## **Step 3: Create a Filesystem on the EBS Volume (If New)**
📌 **Why?**  
New EBS volumes **do not come with a filesystem**. You need to format them before using them.

1. Use the following command to format the volume with an `ext4` filesystem:
   ```bash
   sudo mkfs -t ext4 /dev/xvdf
   ```
2. Once done, you have a formatted disk ready for use.

🔴 **Skip this step if the volume already has data!** Formatting erases everything.

---

## **Step 4: Create a Mount Point**
📌 **Why?**  
You need a directory where you can access the volume’s contents.

1. Create a mount directory:
   ```bash
   sudo mkdir /mnt/ebs
   ```
   - `/mnt/ebs` will be used to access the volume.

---

## **Step 5: Mount the Volume**
📌 **Why?**  
This step links the new EBS volume (`/dev/xvdf`) to `/mnt/ebs`, making it accessible like a regular folder.

```bash
sudo mount /dev/xvdf /mnt/ebs
```

Now, the volume is **mounted** and ready for use!

---

## **Step 6: Verify the Mounting**
📌 **Why?**  
To confirm that the volume is correctly mounted.

```bash
df -h
```
🔹 Look for an entry like:
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvdf       20G   0G   20G  0%   /mnt/ebs
```
This means `/dev/xvdf` is now accessible at `/mnt/ebs`.

---

## **Step 7: Make Mounting Persistent (Optional)**
📌 **Why?**  
If you **reboot** the instance, the volume will be unmounted. To keep it mounted permanently:

1. Get the **UUID** of the volume:
   ```bash
   sudo blkid /dev/xvdf
   ```
   Example output:
   ```
   /dev/xvdf: UUID="1234-5678-ABCD" TYPE="ext4"
   ```
2. Open the **fstab** file:
   ```bash
   sudo nano /etc/fstab
   ```
3. Add this line at the bottom:
   ```
   UUID=1234-5678-ABCD /mnt/ebs ext4 defaults,nofail 0 2
   ```
4. Save and exit (Ctrl + X → Y → Enter).

Now, the EBS volume will mount automatically at `/mnt/ebs` after a reboot.

---

## **Step 8: Unmounting the Volume (If Needed)**
📌 **Why?**  
If you need to detach or remount the volume, you must first **unmount** it.

```bash
sudo umount /mnt/ebs
```

🔹 After unmounting, the volume can be **re-mounted, resized, or detached** safely.

---

## **Final Thoughts**
✅ **Mounting links an EBS volume to a directory, making it accessible.**  
✅ **You must format new volumes before using them.**  
✅ **Persistent mounting ensures the volume is available after reboots.**  

### **Why Does the Filesystem Need to Be Resized After Resizing an EBS Volume?**  

When you resize an **EBS volume**, you are increasing the **physical storage size**, but the **filesystem (ext4, XFS, etc.) doesn’t automatically expand** to use the new space.  

🔹 Think of it like upgrading a **32GB pen drive to 64GB**—the extra space exists, but the filesystem still thinks it only has **32GB** until you expand it.  

---

### **How EBS Resizing Works**  
When you increase the size of an EBS volume:
1. **EBS Volume Size Increases**:  
   - AWS expands the disk at the **block storage level**.  
2. **Filesystem Remains the Same Size**:  
   - The operating system still sees the old size (e.g., 20GB even if you expanded to 50GB).  
3. **Filesystem Must Be Resized Manually**:  
   - You need to use commands like `resize2fs` or `xfs_growfs` to extend the filesystem so it can recognize and use the new space.  

---

### **Steps to Resize EBS Volume and Filesystem**
✅ **Step 1: Increase EBS Volume Size in AWS Console**  
- Go to **EC2 → Volumes → Modify Volume**  
- Increase the size (e.g., from 20GB to 50GB)  
- Wait for the modification to complete  

✅ **Step 2: Verify the New Size in Linux**  
```bash
lsblk
```
🔹 Output (before resize):  
```
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda    202:0    0  20G  0 disk /
```
🔹 Output (after resize in AWS, but before resizing filesystem):  
```
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda    202:0    0  50G  0 disk /
```
Even though the disk is now 50GB, **the filesystem still thinks it's 20GB**.

✅ **Step 3: Extend the Filesystem**  
- If your filesystem is **ext4**:  
```bash
sudo resize2fs /dev/xvda1
```
- If your filesystem is **XFS**:  
```bash
sudo xfs_growfs /
```
✅ **Step 4: Verify the Resized Filesystem**  
```bash
df -h
```
🔹 Output (after resizing):  
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1      50G   10G   40G  20% /
```
Now, the filesystem recognizes and uses the full **50GB**! 🎉  

---

### **Key Takeaways**
✅ **Resizing EBS only increases the block storage size**  
✅ **Filesystem must be resized separately** using `resize2fs` or `xfs_growfs`  
✅ **Always check with `df -h` and `lsblk` before and after resizing**  

### **How to Copy Data from One EBS Volume to Another on the Same EC2 Instance**  

If you have **two EBS volumes** attached to your EC2 instance and want to transfer data between them, follow these steps.  

---
## **🔹 Step 1: Attach Both EBS Volumes to EC2**
1. **Identify the Source and Destination Volumes**  
   - In AWS Console → **EC2 → Volumes**, attach both volumes to your instance.  
   - Assume:
     - **Source EBS** is `/dev/xvdf`
     - **Destination EBS** is `/dev/xvdg`

2. **Verify the Attached Volumes**  
   Run:
   ```bash
   lsblk
   ```
   🔹 Example Output:
   ```
   NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
   xvda    202:0    0  20G  0 disk /
   xvdf    202:1    0  50G  0 disk /mnt/source
   xvdg    202:2    0  100G  0 disk /mnt/destination
   ```
   This confirms that both volumes are attached.

---

## **🔹 Step 2: Mount the Volumes**
If the volumes are not mounted, create mount points and mount them.

### **For the Source Volume**
```bash
sudo mkdir -p /mnt/source
sudo mount /dev/xvdf /mnt/source
```

### **For the Destination Volume**
```bash
sudo mkdir -p /mnt/destination
sudo mount /dev/xvdg /mnt/destination
```


## **🔹 Step 3: Copy Data**
Now, you can copy data using one of the following methods:

### **1️⃣ Using `cp` Command (For Small Files)**
```bash
sudo cp -r /mnt/source/* /mnt/destination/
```
✅ Best for **small datasets** and **directories with files**.  

---


## **🔹 Step 5: Unmount the Volumes (If Needed)**
If you no longer need the volumes mounted:
```bash
sudo umount /mnt/source
sudo umount /mnt/destination
```

---
### **How to Resize the Root EBS Volume on an EC2 Instance**  

When you need to **increase the root volume size** of an EC2 instance, follow these steps:  

---

## **🔹 Step 1: Expand the Root Volume in AWS Console**
1. Go to **AWS Console → EC2 → Volumes**  
2. Find the **root volume** (usually attached as `/dev/xvda` or `/dev/nvme0n1`).  
3. Click **Modify Volume** → Increase the **Size** (e.g., from 20GB to 50GB).  
4. Click **Modify**, then wait for the status to change to **"optimizing"** or **"completed"**.

---

## **🔹 Step 2: Verify the New Size in Linux**
Once the volume has been expanded in AWS, log in to the instance and run:
```bash
lsblk
```
🔹 Example output **(before resizing filesystem)**:
```
NAME        MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda        202:0    0  50G  0 disk  # New volume size is 50GB
└─xvda1     202:1    0  20G  0 part  /
```
- The **disk (`xvda`) has expanded** to 50GB, but the **filesystem (`xvda1`) is still 20GB**.
- Now we need to resize the **partition and filesystem**.

---

## **🔹 Step 3: Grow the Partition Table**
If using **GPT partition table (most newer instances use this)**, run:
```bash
sudo growpart /dev/xvda 1
```
🔹 Example output:
```
CHANGED: partition=1 start=2048 old: size=41940992 end=41943040 new: size=104857536 end=104857584
```
---

## **🔹 Step 4: Resize the Filesystem**
Now, expand the **filesystem** based on its type:

✅ **If using ext4 (Ubuntu, Debian, Amazon Linux 2)**:
```bash
sudo resize2fs /dev/xvda1
```

✅ **If using XFS (Amazon Linux, RHEL, CentOS 7+):**
```bash
sudo xfs_growfs /
```

---

## **🔹 Step 5: Confirm the Resize**
Check the new available space:
```bash
df -h
```
🔹 Example output **(after resizing)**:
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1      50G   10G   40G  20% /
```
Now, the root volume has been **fully expanded and is usable**! 🎉  

---

## **📌 Quick Summary**
| **Step** | **Command** | **Purpose** |
|---------|------------|------------|
| 1️⃣ Modify Volume in AWS | AWS Console → EC2 → Modify Volume | Increase disk size |
| 2️⃣ Verify New Disk Size | `lsblk` | Check expanded volume |
| 3️⃣ Grow Partition Table | `sudo growpart /dev/xvda 1` | Extend partition |
| 4️⃣ Resize Filesystem | `sudo resize2fs /dev/xvda1` (ext4) or `sudo xfs_growfs /` (XFS) | Expand filesystem |
| 5️⃣ Confirm Resize | `df -h` | Verify available space |

### **How Does an EBS Snapshot Store Data?**  

📌 **EBS Snapshots are Incremental, Not Full Copies**  
An **EBS snapshot does not store the entire volume every time**. Instead, it works incrementally by storing only **the changes (deltas) made since the last snapshot**.  

---

## **🔹 How Snapshots Work?**
1️⃣ **First Snapshot (Full Backup)**  
   - When you create the first snapshot of a volume, AWS takes a **full copy** of the data.  
   - Example: If the EBS volume has **250MB** of data, the **first snapshot is also ~250MB**.

2️⃣ **Subsequent Snapshots (Incremental Backup)**  
   - After the first snapshot, AWS only **saves the changed data (deltas)**.  
   - Example: If you modify **50MB of data**, the next snapshot stores only those **50MB changes**, not the entire 250MB.

3️⃣ **Restoration**  
   - When restoring a volume from **any snapshot**, AWS **reconstructs it using the base snapshot + incremental changes**.  

---

## **🔹 Example of Incremental Storage**
| **Snapshot** | **Size Stored** | **Reason** |
|-------------|---------------|------------|
| **Snapshot 1** | **250MB** | First full copy |
| **Snapshot 2** | **50MB** | Only modified data |
| **Snapshot 3** | **30MB** | Only modified data |

🔹 Even though the **total volume size is still 250MB**, AWS **efficiently stores only the changes**.  

---

## **🔹 Key Benefits of Incremental Snapshots**
✅ **Saves Storage Space** – No need to store full copies every time  
✅ **Faster Backups** – Since only changes are stored, snapshot creation is quick  
✅ **Efficient Restoration** – AWS automatically reconstructs the full volume  

---

## **🔹 How to Check Snapshot Size?**
To check the snapshot size in AWS CLI:
```bash
aws ec2 describe-snapshots --snapshot-ids snap-xxxxxxxx
```
🔹 In the AWS Console, you’ll usually see a **size equal to the original volume** but **actual storage used is much less due to incremental storage**.

---

### **📌 Final Takeaway**
🔹 First snapshot = **full copy of volume**  
🔹 Next snapshots = **only changed data**  
🔹 Restoring = AWS **rebuilds volume from snapshots**  

