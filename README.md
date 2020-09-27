# How to setup a personal cloud lab

Provisioning a minimal Kubernetes cluster with the help of K3s and Terraform on the Hetzner Cloud for the beginners

Meta-tag Keywords: terraform, kubernetes, k3s, hetzner
Author: Farid Ahmadian
Persona: everybody who would like to have a small and cheap but also functional Kubernetes cluster on the internet.

I always wanted to find an easy, independent, and low-cost solution to have my own container orchestration which empowers me to test lots of cloud technologies like Prometheus, Fluentd, and Traefik. Also, I was thinking I should do this with a standard approach in order to make that knowledge useful for my career path which is infrastructure as code.

In this tutorial, we are going to build our own one node low-cost Kubernetes cluster from the scratch, if you don't have any knowledge about any of the components of this article don't worry, I am trying to create a step by step brief guide which gives you some basic idea, we will not dive into details but we will create the big picture as fast as possible, and after having something meaningful we can continue to play and learn more.
I should mention that I prefer to create an infrastructure in the internet instead of my local machine to host my own website on top of that and be proud of it. I know this is not a good approach for a serious business but it is a good opportunity to create a playground and learn more.
After all, it is just a lab to experience some popular cloud technologies and doesn't suppose to use in a real production situation.

## Step 1: Provision a server with the help of Terraform

To create a new server we are going to use Terraform, according to Wikipedia, Terraform is an open-source infrastructure as code software tool created by HashiCorp. Users define and provision data center infrastructure using a declarative configuration language.
To use the terraform command I prefer to install `tfswitch` which empowers me to switch between different versions of terraform, if you wand to install terraform directly please install version 0.13.
Terraform using `Providers` to communicate with services like AWS, Cloudflare, ... and we are going to use `Hetzner Cloud Provider` because they are providing a decent and simple service with really low price which is fitting to our goal. 

In an empty folder, first we should create four files:

versions.tf
```
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}
```

variables.tf
```
variable "hcloud_token" {}

variable "private_ssh_key_path" {
  default = "~/.ssh/id_rsa"
}
```

main.tf
```
# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Add main ssh key
resource "hcloud_ssh_key" "default" {
  name       = "main ssh key"
  public_key = file("${var.private_ssh_key_path}.pub")
}

# Create a server
resource "hcloud_server" "node1" {
  name        = "node1"
  image       = "ubuntu-16.04"
  ssh_keys    = [hcloud_ssh_key.default.name]
  server_type = "cx11"
}
```

outputs.tf
```
output "public_ip4" {
  value = "${hcloud_server.node1.ipv4_address}"
}

output "status" {
  value = "${hcloud_server.node1.status}"
}
```

You may wondering what are these files, don't worry, the main.tf will add a ssh key and also a server in the hetzner Cloud, how did I find them out? by checking the provider documentation:
https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server

Now it is time for initialing the terraform provider and checking the health of our files, we can do that by the below commands:
‘‘‘
tfswitch
terraform init
terraform fmt
‘‘‘

If you didn't see any problem means you are ready to move to the next step, but if you like to learn more about terraform, please read this:

## Step 2: Configuring the platform

Ok, now we are ready to provision our server via code but still, in order to make that happen we should get help from a service provider which in our case is Hetzner cloud, the benefit of using Hetzner is avoiding facing with lots of complexity that may confuse us at the beginning, also alongside the providing a fair quality of service the monthly price of their servers could be as cheap as a Doner kebab!
please go to [https://www.hetzner.com/cloud] and sign up and verify your account and then create a new project.
Then go to your new project -> security tab -> API Tokens and generate a new one `Read & Write` permission level:



Then copy the generated token and put it into a new file in your folder like this:

terraform.tfvars
```
hcloud_token = "yourHetznerToken"
```

It is better to generate a dedicated ssh key for our lab without any passphrase, we can generate that by:

```
ssh-keygen -f ~/.ssh/myPersonalCloudLab 
```

lets add it to our `terraform.tfvars` file like:
```
hcloud_token = "yourHetznerToken"
private_ssh_key_path="~/.ssh/myPersonalCloudLab"
```

Ok, now you are ready to create your very first server, please run:
```
terraform plan
```

Here you can see an execution plan which will add two items, an ssh key, and a server, remember you can always see more detail about arguments by something like this:
```
terraform plan --help 
```
and now it time to make your dream real and create them on the Hetzner:
```
terraform apply
```

congratulation, now you are seeing your new server IP address and you can test it by:
```
ssh -i ~/.ssh/myPersonalCloudLab root@yourServerIP
```

It is time to move to the third and the last section of this article but in case that you are wondering what else you can put in our server configuration you can see the below examples and play with them ;)

```
 brew install jq 
```

```
export API_TOKEN=yourHetznerToken
```

https://docs.hetzner.cloud/#images
```
curl \
        -H "Authorization: Bearer $API_TOKEN" \
        'https://api.hetzner.cloud/v1/images' | jq ".images[].name"
```

https://docs.hetzner.cloud/#server-types-get-all-server-types
```
 curl \
        -H "Authorization: Bearer $API_TOKEN" \
        'https://api.hetzner.cloud/v1/server_types' | jq ".server_types[] | .name, .prices" | less
```

## Step 3: Installing Kubernetes on our server



# resources:
* https://tfswitch.warrensbox.com/
* https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code
* https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
* https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
* https://docs.hetzner.cloud/
* https://rancher.com/docs/k3s/latest/en/cluster-access/
