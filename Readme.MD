# Deploy Sitecore 10 into AWS EKS

This will guide through the steps required to get Sitecore provisioned in AWS EKS cluster. 

## Pre-Requisites

1. Enable AWS CLI and Configure
2. Install eksctl
3. Install Kubectl


## Setup Kubernetes Cluster

1. Create a new cluster with linux nodes for kubernetes orchestration

```PS
eksctl create cluster -f ./EKS/cluster.yaml --install-vpc-controllers
```

## Install nginx Ingress Controller

Ingress controller is used for mpping external access to the application running inside of the containers in kubernetes. Below steps will help install and configure nginx ingress controller.

1. Install Helm using chocololatey

```PS
choco install kubernetes-helm
```

2. Add the default chart repository to helm

```
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```

If default chart repository is already installed. Perform a update on the respository.

```
helm repo update
```

3. Add Bitnami chart repository to helm as we will be using bitnami nginx ingress controller.

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Search for nginx ingress controller in helm.

```
helm search repo nginx
```
4. Deploy bitnami nginx ingress controller

Default sitecore documentation uses a deprecated version of nginx ingress controller. bitnami nginx ingress controller is also compatible with the configuration files provided by sitecore.

```PS
helm install nginxingress bitnami/nginx-ingress-controller `
--set replicaCount=1 `
--set nodeSelector."beta\.kubernetes\.io/os"=linux `
--set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux `
--set-string controller.config.proxy-body-size=10m `
--set service.externalTrafficPolicy=Local `
```
5. Uninstall ingress controller

If there is a need to uninstall the ingress controller run the following command. this will also cleanup the deployment from kubernetes cluster.

```
helm uninstall <deployment-name>
```

## Deploy sitecore into kubernetes cluster

1. Prepare the secret files

Run `.\Init.ps1` to setup the required secrets. Please make sure to place the license file in c:\License folder or update the location in the script.

2. deploy secrets into kubernetes

```PS
kubectl apply -k ./k8s/secrets
```

3. Deploy external services (optional)

If external services are already configured skip this step and proceed to deploying sitecore.

```PS
kubectl apply -f ./k8s/external/

```PS

Use the below script to wait until the deployment of the external services to be completed.

```PS
kubectl wait --for=condition=Available deployments --all --timeout=900s
```
Check status of the pods using `kubectl get pods -o wide` make sure the external services are all in `Running` status.

Deploy and run the initialization jobs using below

```PS
kubectl apply -f ./k8s/init/
```

Wait for init jobs to finish using the below commands

```PS
kubectl wait --for=condition=Complete job.batch/solr-init --timeout=600s `
kubectl wait --for=condition=Complete job.batch/mssql-init --timeout=600s `
```
If the jobs fail to run, you can use the `kubectl describe pod <pod-name>` which should describe the events that have occurred and might shed some light on the issues.

4. Deploy sitecore and ingress configuration into the kubernetes cluster

```PS
kubectl apply -f ./k8s/ -f ./k8s/ingress-nginx/ingress.yaml
```

Wait for the deployments to be complete 
```PS
kubectl wait --for=condition=Available deployments --all --timeout=1800s
```

Make sure all the pods are in `running` state using `kubectl get pods -o wide` 

5. Setup DNS records

Use the below command to get the external ip address to the cluster to setup the DNS records. When using in AWS you will get a CNAME and can perform a nslookup to get the ip address.

```PS
kubectl get service -l app=nginx-ingress-controller
```

6. Setup Cloud watch

Add CloudWatchAgentServerPolicy policy to the IAM role attached to the instance IAM role in cluster.

Create a new namespace for cloud watch
```PS
kubectl apply -f ./k8s/cloud-watch/cloudwatch-namespace.yaml
```

Create a service account for cloudwatch agent
```PS
kubectl apply -f ./k8s/cloud-watch/cwagent-serviceaccount.yaml
```

push the config map into cloudwatch namespace
```PS
kubectl apply -f ./k8s/cloud-watch/cwagent-configmap.yaml
```

deploy the cloud watch agent
```
kubectl apply -f ./k8s/cloud-watch/cwagent-daemonset.yaml
```PS

Run the beow command to check the daemon set is installed correctly
```PS
kubectl get pods -n amazon-cloudwatch
```