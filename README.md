# Kubelini aka "Kubernetes the hard way the easy way"

### TLDR
If you want to just get going, head over to:

[How to Run](../master/HOWTO.md)


### Work in progress! 
This repo is not finished in any way

### Background
As an excerise for learning the ins and outs of Kubernetes, I decided to create an Ansible-based deployment of Kelsey Hightower's "Kubernetes the hard way" (https://github.com/kelseyhightower/kubernetes-the-hard-way).

Kubelini does not match "Kubernetes the hard way" 100%, there are slight differences in networking and some of the PKI stuff (see below). However, most of the components are configured as identical as possible to the original.
EDIT: This is not completely true anymore.

### What gets deployed
Kubelini deploys Kubernetes (choice of version is up to you) with Docker 1.13 and Weavenet or Flannel. Most (if not all) testing is done with Flannel.

### Prerequisites
- Kubelini uses Amazon S3 to distribute certain files (certificates and dynamicly generated config files). Replacing the S3 part with cifs or a similar backend should be fairly easy if s3 is a big no-no for you.
- Kubelini expects a set of already running nodes, and has only been tested with Ubuntu 16.04.
- It is expected that networking is alredy configured: full access between the hosts in the cluster, and ssh access from the Ansible control node to all hosts. Kubelini does _not_ require setting up custom routes, as it uses overlay networking (cni) for pod communication.
- You need Ansible. Kubelini was tested with Ansible 2.5.5.
- Target nodes need to satisfy the standard Ansible prereqs - which is essentially python and ssh
- You ned an inventory containing 1 or more nodes in a group called "kubernetes_master". These hosts will get etcd/apiserver and other "master" workloads installed.
- You also need a host group called "kubernetes_worker", which should contain 1 or more hosts where actual pods will get scheduled.

### Differences from "Kubernetes the hard way"
1. Certificates: Both Kubernetes and etcd relies on PKI, so there's a lot of certs flying aronud. In "Kubernetes the hard way", a single certificate containing all cluster node ip addresses is used with Kubernetes. Kubelini on the other hand, generates a uniqe cert per node. This allows for scaling out the cluster later, without having to re-issue certificates for every node.
2. ~~Self-signed kubelet certs: "Kubernetes the hard way" uses a new feature in kubelets where a kubelet can auto-generate its own certificate. These auto-generated certificates have some naming issues, so Kubelini uses the per-node certificates described above. This is implemented by first starting the kubelet in "registration mode", and then replacing the certs before restarting. I haven't been able to find a combination of kubelet params that allow this done in any other way (but I'm not giving up on it just yet).~~
3. Networking: "Kubernetes the hard way" uses kubenet, while Kubelini uses cni (weavenet or flannel). The primary reason for this is that by using an overlay we don't have to configure routes on each host or in the network's router. CNI plugins take care of all that. Implementing other cni-based plugins instead shouldn't be too hard.
4. Ip-based communication between apiserver and kubelets: Kubelini explicitly sets the `--kubelet-preferred-address` flag to InternalIP, making sure that apiserver doesn't try and resolve the hostname of nodes when communicating with them. This should increase the robustness of commands like `kubectl log` and `kubectl exec`.
5. Doesn't assume GCE. You can run Kubelini anywhere. The only opinionated piece is the s3 bucket used for exchanging files. That said, the only cloud provider tests is the "aws" one, which you can enable using config variables.
6. Supports running the apiserver in a pod. This is maybe the biggest difference between "Kubernetes the hard way" and most "Kubernetes Distributions". Kubelini simply allows you to choose whether to run the Apiserver as a regular service using systemd or in a pod using the "pod-manifest-folder" functionality of Kubelet. So you get to choose!

### Cloud support
Kubernetes has a special setting, `cloud-provider` which is required in some cases, such as when using the `cluster-autoscaler` for scaling a cluster up and down dynamically. Unfortunately the cloud-provider flag is not well documented, but kubelini makes a best-effort attempt of supporting it thru the `kubelet_cloud_provider`/`apiserver_cloud_provider` variables. Make sure your nodes are set up with roles providing sufficient permissions if using it.

Also note that when the cloud-provider flag is used with AWS, cluster nodes will no longer use `inventory_hostname` for node names, but the AWS-generated "internal dns name" instead. Kubelini will by default inject the node label `ansible/inventory-hostname` containing the value of `inventory_hostname`.

### Things you need to do after running site.yml
Nothing, you should end up with a fully functioning Kubernetes cluster. You can test stuff for example by running: `kubectl run netutils --image=trondhindenes/netutils -t -i` and test that you're able to resolve addresses on the internet by using `dig www.google.com` (this also tests the kube-dns addon).

### Using kubectl locally against your cluster
After kubelini has been set up, grab the ca.pem cert and the admin.pem and admin-key.pem from the s3 bucket you've used.
Also make sure you have kubectl locally in path. Then run (make sure to replace the `kubernetes_cluster_address` variable):

```
kubectl config set-cluster kubelini \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://<kubernetes_cluster_address>:6443

kubectl config set-credentials kubelini \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true
kubectl config set-context kubelini \
  --cluster=kubelini \
  --user=kubelini
kubectl config use-context kubelini
```

You can also use the generated 'admin.kubeconfig', which will be generated at `s3://<bucket>/<clusterid>/admin/admin.kubeconfig`

### Ansible implementation
Kubelini attempts to not use anything "special" in terms of Ansible functionality. The roles included should be very easy to integrate into an existing Ansible setup, and there's no special "bootstrap script". Simply run `ansible-playbook prep_cluster.yml` for the cluster/master setup, and `ansible-playbook site.yml` to configure workers as you're used to. The `ansible.cfg` file just points to the local role dir and is really not needed if you don't want it - just make sure your global ansible config somehow is able to "resolve" the roles in this repo. Same goes for the inventory file (`hosts`).

It's worth noting that the inventory group names _are_ referenced a few places inside roles (to figure out the first cluster node ip, etc). If you want to use other group names, then you should do a search+replace in all roles.

All variables can be controlled using group_vars/all.yml. Also, be sure to create / fill inn the following variables in the file `secrets/secrets.yml`:   
- `aws_access_key_id`
- `aws_secret_access_key`
Alternatively, you can make sure your instances (if running in AWS) have roles which provide them access to the configured S3 bucket. In that case, just don't configure these variables.

### TODO
- Implement better change tracking. Many of the tasks currently rely on simple `if file exists` logic, and could be made more robust.
- Smoother kubernetes api interaction: For now we just fire stuff at kubernetes using kubectl. A "native" Kubernetes module for Ansible is being developed, so watch this space!
- Implement encryption of secrets
