# Ansible rapsqlbench

- [Ansible rapsqlbench](#ansible-rapsqlbench)
  - [Prerequisites](#prerequisites)
  - [2. Deployment Description](#2-deployment-description)
  - [2. Configuration](#2-configuration)
  - [3. Implementation](#3-implementation)
  - [2. Usage](#2-usage)
  - [Perform a benchmark](#perform-a-benchmark)
    - [Start the benchmark](#start-the-benchmark)
    - [Monitor measurment files](#monitor-measurment-files)
  - [RAPSQLBench v2](#rapsqlbench-v2)
    - [Monitor measurment file](#monitor-measurment-file)

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

2. Inside the `terraform` directory:

    ```bash
    ansible-playbook -i ./inventory/vm1-eip.txt ../ansible/deploy.yml
    ansible-playbook -i ./inventory/vm2-eip.txt ../ansible/deploy.yml
    ```

3. Passing [Ansible Variables via CLI](https://docs.ansible.com/archive/ansible/2.4/playbooks_variables.html#passing-variables-on-the-command-line)

    ```bash
    ansible-playbook -i ./inventory/vm1k-eip.txt ../ansible/deploy.yml -e "triples=1000"
    ansible-playbook -i ./inventory/vm10k-eip.txt ../ansible/deploy.yml -e "triples=10000"
    ansible-playbook -i ./inventory/vm100k-eip.txt ../ansible/deploy.yml -e "triples=100000"
    ```

## Perform a benchmark

### Start the benchmark

```bash
ansible-playbook -i ./inventory/vm1m-eip.txt ../ansible/deploy.yml -e "graphname=sp1m triples=1000000"
ansible-playbook -i ./inventory/vm1m-eip.txt ../ansible/deploy.yml -e "graphname=sp125m triples=125000000"
ansible-playbook -i ./inventory/vm1m-eip.txt ../ansible/deploy.yml -e "graphname=sp250m triples=250000000"
ansible-playbook -i ./inventory/vm1m-eip.txt ../ansible/deploy.yml -e "graphname=sp500m triples=500000000"
ansible-playbook -i ./inventory/vm1m-eip.txt ../ansible/deploy.yml -e "graphname=sp1bil triples=1000000000"
```

### Monitor measurment files

To monitor the measurement files, you can use the following command:

```bash
tail -f -n +1 /mnt/benchmark/measurement/sp1m/measurement.csv
tail -f -n +1 /mnt/benchmark/measurement/sp125m/measurement.csv
tail -f -n +1 /mnt/benchmark/measurement/sp250m/measurement.csv
tail -f -n +1 /mnt/benchmark/measurement/sp500m/measurement.csv
tail -f -n +1 /mnt/benchmark/measurement/sp1bil/measurement.csv
```

## RAPSQLBench v2

1. Login to AWS CLI via `aws configure sso` and your credentials.
2. Build the desired infrastructure using Terraform via `main.tf` and setup `variables.tf`, e.g. navigate to terraform directory `cd terraform` and run `terraform apply`.
3. Perform benchmark using Ansible via `deploy-conf.yml` and Posgres setup via `pgconf.yml`, e.g. with vm for 50k triple dataset `vm50k` from `terraform` directory`:

```bash
# general (dynamic vm name)
ansible-playbook -i ./inventory/VMNAME-eip.txt ../ansible/deploy-conf.yml -e "@../ansible/pgconf.yml"
# e.g. 
ansible-playbook -i ./inventory/vm50k-eip.txt ../ansible/deploy-conf.yml -e "@../ansible/pgconf.yml"
```

### Monitor measurment file

```bash
# general (dynamic ip)
ssh ubuntu@INVENTORY_IP_TXT
# e.g. 
ssh ubuntu@3.66.144.155
```

```bash
# general (dynamic graph name)
tail -f -n +1 /tmp/benchmark/measurement/GRAPH_NAME/measurement.csv
# e.g. 
tail -f -n +1 /tmp/benchmark/measurement/sp50k6/measurement.csv
```
