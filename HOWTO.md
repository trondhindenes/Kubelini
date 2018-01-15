# HOWTO

### Stuff you need:
- An s3 bucket
- S3 credentials
- A couple of vms running Ubuntu 16.04. You should make sure there's no firewall stopping traffic on any port between the nodes.
- Ansible 2.3.x or newer

### Configure things:
Group vars: in `groups_vars/all.yml`, make sure you've configed the following:   

`kubernetes_cluster_address`: This should be the address of a load balancer in front of your master nodes (should forward port 6443 to 6443 on the master nodes). If you don't have one, you can set this variable to the ip of any of the master nodes.   

`s3_sync_bucket`: The name of the s3 bucket you want to use for exchanging certificates.

The rest of the settings in `groups_vars/all.yml` should have "sane defaults" and you're not required to change them.

Variables in `secrets/secrets.yml`:   
This file _must_ contain two variables:
`aws_access_key_id` and `aws_secret_access_key`. Put in the credentials of an iam user with read and write access to the S3 bucket configued in `s3_sync_bucket`.

### Inventory
Replace the contents of the `hosts` file with your own values. If you want to use the example playbooks you should change the group names, only the targets.

The hosts file should look something like this:
```
[all]
[all:vars]
ansible_user=ubuntu
ansible_password=SoMuchPassword
ansible_become_pass=SoMuchPassword
become=true

[kubernetes_master]
kubelini1 ansible_host=10.245.22.17
kubelini2 ansible_host=10.245.22.89

[kubernetes_worker]
kubelini3 ansible_host=10.245.22.53
kubelini4 ansible_host=10.245.22.78
```
Note that Kubelini uses these group names, so if you use others you should use Ansible's modules for adding hosts to these groups dynamically.

### Run it
If you have a completely fresh set of nodes here's how you get a cluster up and running.
1. Configure the cluster masters by running:
`ansible-playbook -i hosts prep_cluster.yml`. This will set up the required services on the masters (etcd, kube-apiserver and so on), and generate a ca cert which will be uploaded to the s3 bucket.   
You should now be able to log on to one of the master servers and issue `kubectl --namespace kube-system get serviceaccount`, which should list a couple of serviceaccounts.
Note that Kubelini will "reset" if you make changes to the master hosts, such as adding or removing them. Re-running the `prep_cluster.yml` playbook should be safe as long as you target the same hosts as on the initial run.

2. You can now run the `worker` playbook:   
`ansible-playbook -i hosts site.yml`. This will configure kubernetes on your worker nodes. The worker nodes will each get a weave-net pod as they come online. After this step, you'll be able to list your nodes by typing `kubectl get nodes`. All your nodes should now show up as "ready". The `site.yml` is idempodent, and supports adding Kubernetes workers dynamically. You can run `site.yml` against all your workers, or use ansible's `--limit-hosts` parameter to run it against a single node. Each node will pull down the required CA cert and self-generate the necessary certs.

3. Blow it all away:   
run `ansible-playbook -i hosts reset.yml` to wipe all the things.

