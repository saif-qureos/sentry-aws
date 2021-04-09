*hint:* *I skipped using terraform-docs to generate the readme.md.* 
*Hint2: I used AWS US-EAST-1 as my default region.*

# Prerequisites

This automation mechanism requires the following components to be already available.
- [Packer](https://learn.hashicorp.com/tutorials/packer/getting-started-install)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [AWS Cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- Your AWS account configured:```$aws configure```, with [environment variables set](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html#envvars-set).

# How to use it

## Prepare the AMI image with Packer

Generate your personal keys (Pub, Priv) if you don't have it already:

``ssh-keygen -t rsa -C "user@domain.lcl" -f ./the-keys``

if you have them already place both your keys in the `./packer/` directory and update the file names inside `./packer/image.pkr.hcl`

The default region is `us-east-1` and IaaS Provider is AWS. If you want another region update them in `./packer/image.pkr.hcl`  in the `region` block and `./terraform/variables.tf` in the `region` block.

Execute the following command from inside ``./packer/`` directory:

```bash
packer build image.pkr.hcl
```
The last line shows the name of new ami ID alongside with its deployment region that can be used for the deployment. Copy it.

## Service deployment:

Go to the `ami_id` variable block of `./terraform/variables.tf` and replace your *ami ID* with the old one.

review `./terraform/variables.tf` throughly and update it accordingly, setting the value for Certificate ARN is a must!

then from the directory where `main.tf` exists execute this command: 

```terraform init && terraform plan -out=main.plan```

 if you are happy with what you see then you can execute `terraform apply "main.plan"` to make the service available.

* *hint: If you want to connect to the server for some reason: `ssh theuser@$(terraform output -raw public_ip) -i ./packer/the-keys`*

- *hint2: In case you get an error stating that you are using two subnets in the same region, destroy the deployment with `terraform destroy` and again use `terraform plan -out=main.plan` and apply it*

Once the deployment was successful, go to AWS Route53 and create a `A` record, set its destination as *alias*  then select **Alias to Application and Classic Load Balancer** fill the form to your deployment region, you should see a new **load balancer ID** with the name of **lb-sentry** mentioned in it. select it and create the record.

Once the record is created give it some few seconds and the navigate to your created address using *https://*.

- *hint: if you don't want to use the service anymore just go to the same directory of `./terraform/` and execute this command: `terraform destroy` and then type `yes`*
