# Hands on: How to setup a personal cloud lab

Provisioning a minimal Kubernetes cluster with the help of K3s and Terraform on the Hetzner Cloud for the beginners

##### Meta-tag Keywords: terraform, kubernetes, k3s, Infrastructure as code, containers orchestration hetzner
##### Author: Farid Ahmadian
##### Persona: software and devops engineers

In the new era of enormous internet services development, we are hearing the "microservice" term too many times, basically, unlike monolith application we are creating lots of individual maintainable and testable mini-applications which are empowering us to create a scalable service. This new era brought with itself new needs that between them, infrastructure as a code and containers orchestration are two big ones, here I don't want to explain these words but we are going to get down to business and create a simple example to get some real ideas about them.

I always wanted to find an easy, independent, and low-cost solution to have my own container orchestration which, empowers me to test lots of cloud technologies like Prometheus, Fluentd, Traefik, ..., Also, I was thinking I should do this with a standard approach in order to make that knowledge useful for my career path which in this case is infrastructure as code.

In this tutorial, we are going to build our own one node low-cost Kubernetes cluster from the scratch, if you don't have any knowledge about any of the components don't worry, I am trying to create a step by step brief guide which gives you some basic ideas, we will not dive into details but we will create the big picture as fast as possible, and after having something meaningful we can continue to play and learn more.
After all, it is just a lab to experience some popular technologies and is not supposed to be use in a real production situation.

## Step 1: Provision of a server with the help of Terraform

To create a new server we are going to use Terraform, Terraform is an open-source infrastructure as code software tool created by HashiCorp. Users define and provision data center infrastructure using a declarative configuration language.
To use the terraform command I prefer to install `tfswitch` which empowers me to switch between different versions of terraform, if you want to install terraform directly please install version 0.13.
Terraform using `Providers` to communicate with services like AWS, Cloudflare, ... and we are going to use `Hetzner Cloud Provider` because they are providing a decent and simple service with a really low price which is fitting our goal. 

Let's start our journey, in an empty folder, first, we should create four files:

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

You may wonder what are these files, don't worry, the main.tf will add a ssh key and also a server in the hetzner Cloud, you may think how did I find out about them? by checking the provider documentation:
https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server

Now it is time for initializing the terraform provider and checking the correct format of the files, we can do that by the below commands inside of our folder:
‘‘‘
tfswitch
terraform init
terraform fmt
‘‘‘

If you didn't see any problem it means you are ready to move to the next step, but if you like to learn more about terraform, please read this:
https://kubernetes.io/docs/tutorials/

## Step 2: Configuring the platform

Ok, now we are ready to provision our server via code but still, in order to make that happen we should get help from a cloud service provider which in our case is Hetzner cloud, the benefit of Hetzner is that it avoids lots of complexity that may confuse us at the beginning, also alongside providing a fair quality the monthly price of their servers could be as cheap as a Doner kebab!
please go to [https://www.hetzner.com/cloud] and sign up and verify your account and then create a new project.
Then go to your new project -> Security tab -> API Tokens and generate a new one with `Read & Write` permission level:

![ScreenShot](https://raw.github.com/pesarkhobeee/myPersonalCloudLab/master/screenshots/token.png)

Then copy the generated token and put it into a new file in your folder like this:

terraform.tfvars
```
hcloud_token = "yourHetznerToken"
```

It is better to generate a dedicated ssh key for our lab without any passphrase, we can generate that by:

```
ssh-keygen -f ~/.ssh/myPersonalCloudLab 
```

lets define it to our `terraform.tfvars` file like this:
```
hcloud_token = "yourHetznerToken"
private_ssh_key_path="~/.ssh/myPersonalCloudLab"
```

Now you are ready to create your very first server, please run:
```
terraform plan
```

Here you can see an execution plan which will add two items, an ssh key, and a server, remember you can always see more detail about arguments by a command like this:
```
terraform plan --help 
```
and now it time to make your dream real and create them on the Hetzner:
```
terraform apply
```

Wonderfull, we created our server with the help of terraform, it is time to move to the third and the last section of this article but in case you are wondering what else you can put in your server configuration values you can see the below examples and play with them ;)

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

Nowadays the most popular container orchestration tool is Kubernetes which was developed originally in Google, to learn it usually they are suggesting using a local program name `minikube` but it is not designed for running on the servers, instead, we are going to use `k3s` project, K3s is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.

Remember that we are using Terraform to manage our infrastructure, it is good for provisioning but about configuration management usually, people are suggesting using something like 'Ansible' alongside the terraform, luckily the installation process of `k3s` is very simple and we can manage it easily via Terraform itself, for this purpose, please change node1 in the `main.tf` like this:

```
# Create a server
resource "hcloud_server" "node1" {
  name        = "node1"
  image       = "ubuntu-16.04"
  ssh_keys    = [hcloud_ssh_key.default.name]
  server_type = "cx11"

  connection {
    type = "ssh"
    user        = "root"
    private_key = file(var.private_ssh_key_path)
    host = self.ipv4_address
    agent       = "true"
  } 

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | sh -",
    ]
  }

}

```

As you can see we added two new sections, connection and remote-exec and the whole idea is to connect automatically to our server and install k3s on that, provisioner and connection blocks are considered only during the "create" action, therefore we have to destroy our server and rebuild it:

```
terraform destroy
terraform apply
```

![ScreenShot](https://raw.github.com/pesarkhobeee/myPersonalCloudLab/master/screenshots/result.png)

Nice, it seems like we are almost done, we have k3s on our server, in order to work with our Kubernetes cluster we should use the `kubectl` command, you can follow [this|https://kubernetes.io/docs/tasks/tools/install-kubectl/] official documentation to install that command on your os. 
After installing it we should download our k3s config file and change the server ip address:
```
scp -i ~/.ssh/myPersonalCloudLab root@yourServerIP:/etc/rancher/k3s/k3s.yaml . 
sed -i.backUp 's,127.0.0.1,yourServerIP,g' k3s.yaml
export KUBECONFIG=$PWD/k3s.yaml 
```

Now you should be able to see one node via `kubectl` command:
```
kubectl get node 
```

Congratulations, we have our Kubernetes and we can be proud that we created it via terraform, we learned a lot and it is time to learn more by playing with Kubernetes commands.
If you like to deploy a weblog system on you Kubernetes you can look to my GitHub repository which I already created the whole chain of having wordpress on k3s:
https://github.com/pesarkhobeee/wp-k3s

Hope you find this article as a beneficial first step of getting familiar with Infrastructure as code and containers orchestration concepts :)


# resources:
* https://tfswitch.warrensbox.com/
* https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code
* https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
* https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
* https://docs.hetzner.cloud/
* https://rancher.com/docs/k3s/latest/en/cluster-access/
