# RAPSQLBench

- [RAPSQLBench](#rapsqlbench)
  - [Repositories](#repositories)
  - [Prerequisites](#prerequisites)
  - [Terraform Infrastructure Graph](#terraform-infrastructure-graph)
  - [Benchmark Usage](#benchmark-usage)
  - [License](#license)
  - [Authors](#authors)

## Repositories

- [RDF2PG](https://github.com/raederan/rdf2pg)
- [RAPSQLTranspiler](https://github.com/OpenSemanticWorld/rapsqltranspiler)

## Prerequisites

- [AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#pip-install)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Terraform Infrastructure Graph

![Terraform Graph](./img/terraform-graph.svg)
**Terraform AWS Cloud Infrastructure of RAPSQLBench.**

## Benchmark Usage

1. Clone this repository:

    ```bash
    git clone https://github.com/OpenSemanticWorld/rapsqlbench.git
    ```

2. Login to AWS via the CLI, e.g. using single sign-on (SSO):

    ```bash
    aws configure sso 
    ```

3. Change directory to `rapsqlbench/terraform` and run `terraform init` to initialize the Terraform configuration:

    ```bash
    cd rapsqlbench/terraform; terraform init
    ```

4. Setup your own Terraform configuraton in [variables.tf](terraform/variables.tf) (!rsa pubkey for ssh).

5. Build the desired infrastructure using Terraform via [main.tf](terraform/main.tf), run

    ```bash
    terraform apply
    ```

    and confirm with `yes` if plan is correct and fullfills your requirements.

6. Important! Configure your `RAPSQLBench` setup in [config.yml](ansible/config.yml) before starting the benchmark.

7. Perform `RAPSQLBench` using Ansible via [deploy.yml](ansible/deploy.yml). The extra vars argument is required!

    ```bash
    ansible-playbook -i ./inventory/vm50k-eip.txt ../ansible/deploy.yml -e "@../ansible/config.yml"
    ```

    and confirm with `yes` if prompted for ssh fingerprint. Deprecation warning of sync module is a [known issue](https://github.com/ansible-collections/ansible.posix/issues/468) and can be ignored. Please also note that the calculated performance results at the end of `RAPSQLBench` are extracted from the postgres timings and may differ slightly from the results of the measurement file due to the low script overhead of the benchmark procedure.

8. (Optional) To monitor the measurement files, connect to your remote vm via ssh and use `tail` as soon as `Ansible` reaches task `Perform benchmark`. The hole measurement will be tracked in `measurement.csv` and gives a live overview of all metrics.

    ```bash
    tail -f -n +1 /tmp/benchmark/measurement/sp50kr2v1i2/measurement.csv
    ```

9. Destroy the infrastructure using Terraform via `main.tf`, run

    ```bash
    terraform destroy
    ```

    and confirm with `yes` if you have all your results backed up.

## License

Apache License 2.0

## Authors

Andreas Räder (<https://github.com/raederan>)
