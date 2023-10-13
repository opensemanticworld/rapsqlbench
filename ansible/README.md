# Ansible rapsqlbench

- [Ansible rapsqlbench](#ansible-rapsqlbench)
  - [Prerequisites](#prerequisites)
  - [2. Deployment Description](#2-deployment-description)
  - [2. Configuration](#2-configuration)
  - [3. Implementation](#3-implementation)
  - [2. Usage](#2-usage)

## Prerequisites

- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#pip-install
)

## 2. Deployment Description

- Automated installations
  - python3,
  - pip,
  - docker,
  - rapsql,
  - rapsqlbench
- Automated deployment
  - rapsql database container

## 2. Configuration

To configure the AWS EBS disk 'xvdh' based on the output of the `lsblk` command, you can follow these steps:

1. Run the `lsblk` command to identify the disk you want to configure. In this case, it is 'xvdh'.

2. Determine the file system type you want to use for the disk. For example, if you want to use the ext4 file system, you can run the following command to create the file system:

   ```bash
   sudo mkfs -t ext4 /dev/xvdh
   ```

   Replace 'ext4' with the desired file system type if you prefer a different one.

3. After creating the file system, you can mount the disk to a directory on your system. For example, to mount it to '/mnt/data', run the following command:

   ```bash
   sudo mount /dev/xvdh /mnt/data
   ```

   Replace '/mnt/data' with the directory where you want to mount the disk.

4. If you want the disk to be mounted automatically on system boot, you need to add an entry to the '/etc/fstab' file. Run the following command to open the file in a text editor:

   ```bash
   sudo nano /etc/fstab
   ```

   Add the following line at the end of the file:

   ```bash
   /dev/xvdh   /mnt/data   ext4   defaults,nofail   0   2
   ```

   Save the file and exit the text editor.

5. Finally, you can verify that the disk is correctly configured by running the `df -h` command, which will display the mounted disks and their usage.

Please note that these steps assume you have the necessary permissions to perform disk configuration operations.

## 3. Implementation

[Stackoverflow Mount Disk](https://stackoverflow.com/a/69947951)

## 2. Usage

1. To install required software for `rapsqlbench` using `ansible`, run:

    ```bash
    ansible-playbook -i terraform/inventory/vm-pubip-1.txt deploy.yml
    ansible-playbook -i terraform/tf-vm-pubip-1-inventory.txt ansible/deploy.yml 
    ```
