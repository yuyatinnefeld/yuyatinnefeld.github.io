---
layout: post
title: Istio Advanced ⛵ Session 2 - Ingress Gateway

tags: ["tech", "microservices", "service-mesh"]
mathjax: true
---

Welcome to the second post in my advanced Istio deep dive series! This time, we’ll be focusing on a crucial aspect of Istio: Ingress. In this post, I'll delve into how services communicate through the Ingress gateway, with detailed logs to provide deeper insight into the process. Before we dive in, feel free to explore the other topics covered in this series:

1. [Istio HelmCart](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
2. [Istio Ingress](https://yuyatinnefeld.com/2024-09-16-istio-deepdive-pt2/)
3. [Istio Egress](https://yuyatinnefeld.com/2024-09-21-istio-deepdive-pt3/)
4. [Istio Control plane](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
5. [Istio Data plane (1)](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
6. [Istio Data plane (2)](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)

Before diving deep into Istio Gateways, ingress, and routing, I want to clarify the differences between Kubernetes Ingress controllers and their variations, specifically focusing on the Istio Ingress and NGINX Ingress. In this post, I'll compare how both ingress models are structured and operate without delving into the pros and cons of each. The focus will be on the technical architecture and how these services function in practice. To demonstrate this, I’ll deploy a demo application and showcase the differences between Istio’s ingress controller and the NGINX ingress controller. Additionally, I'll provide a brief overview of key Kubernetes components such as Pods, Endpoints, and Services.

For this project, we're using the following GitHub repository: [DEMO INGRESS](https://github.com/yuyatinnefeld/istio/tree/main/istio/istio-deepdive)

## 🚀 Create Demo App

We will deploy a demo application in the `application` namespace and create hello-world apps.

![Simple App](/images/post-20240916/simple-app.png)


    # create the target application namespace
    kubectl create namespace application && kubectl config set-context --current --namespace=application

    # deploy the target application
    kubectl apply -f istio-deepdive/depl-helloworld.yaml


## 👀 Inspecting Service Metadata
When a user sends a request to the external ClusterIP (`http://192.168.76.2:30001`), the Kubernetes cluster maps this to the corresponding service IP (`10.108.78.105`) and routes the traffic to the correct Pod through its endpoints (`10.244.0.10:5678`). Let’s break down the components involved:

##### External ClusterIP
The `minikube service <service-name> --url` command creates a tunnel to expose services externally.

- ClusterIP: `192.168.76.2`

```bash
minikube -n application service dest-svc-v1 --url
curl http://192.168.76.2:30001
```

##### Service IP / Internal ClusterIP
Service IPs are accessible only within the cluster unless exposed via NodePort or LoadBalancer.

- Service Internal IP: `10.108.78.105`

```bash
kubectl get svc -l app=hw-v1 -owide
```

##### Endpoints
When a Service selects a set of Pods (based on labels like app=hw-v1), their Pod IP addresses are registered as endpoints for the Service.

- Endpoints of App 1: `10.244.0.10:5678,10.244.0.11:5678`

```bash
kubectl get endpoints -l app=hw-v1 -owide
```

##### POD
Pods are the fundamental units running your application, each with its own IP

- Pod IP of App 1: `10.244.0.11, 10.244.0.10`

```bash
kubectl get pod -l app=hw-v1  -owide
```

## 🚀 Create IngressController

We will now deploy the Kubernetes NGINX IngressController to expose services through DNS endpoints (e.g., http://yuya.example.com) and handle different paths such as `/v1` and `/v2`.

![Ingress Nginx overview](/images/post-20240916/ingress-nginx.png)

    # enable the Ingress Controller
    minikube addons enable ingress

    # deploy the Ingress rules
    kubectl apply -f istio-deepdive/ingress/nginx-ingress.yaml


## 👀 Check Detailed Flow
##### 1. User Initiates Request: 
The user makes HTTP requests to `http://yuya.example.com/v1` simulating traffic to different versions of the application.

    CLUSTER_IP=$(minikube ip)
    curl --resolve "yuya.example.com:80:$CLUSTER_IP" -i http://yuya.example.com/v1


##### 2. DNS Resolution: 
The DNS resolves the hostname to the IP address of the service.

    kubectl get -n ingress-nginx svc ingress-nginx-controller

##### 3. LoadBalancer Routes the Request to the Ingress Controller: 
The LoadBalancer forwards the request to the IngressController, which applies ingress rules.

    kubectl get -n ingress-nginx pod -l app.kubernetes.io/component=controller

    kubectl get ingress -o jsonpath='{.items[0].status}'

Example response:

```json
{
  "loadBalancer": {
    "ingress": [
      {
        "ip": "192.168.76.2"
      }
    ]
  }
}
```

##### 4. Ingress Controller Processes the Request:
The Ingress Controller checks the defined Ingress rules and routes the request based on the domain or path. For example, traffic to `/v1` is routed to the correct service endpoint (e.g., `10.244.0.10:5678`).

    NGINX_CONTROLLER=$(kubectl get -n ingress-nginx pod -l app.kubernetes.io/component=controller -ojsonpath='{.items[0].metadata.name}')
    kubectl logs $NGINX_CONTROLLER -n ingress-nginx

Example log entry:

```bash
192.168.76.1 - - [15/Sep/2024:08:52:37 +0000] "GET /v1 HTTP/1.1" 200 33 "-" "curl/7.81.0" 82 0.001 [application-dest-svc-v1-http-v1] [] 10.244.0.10:5678 33 0.000 200 5b0de41158eb9e86c19b0fc0174e4450
```

##### 5. Service Routes the Request to the Target Pod: 
The service associated with the Ingress forwards the request to one of its pods based on the pod selector.

    POD=$(kubectl get pod -l app=hw-v1 -ojsonpath='{.items[].metadata.name}')
    kubectl debug $POD -it --image=busybox -- cat /etc/resolv.conf

Example response:

    Defaulting debug container name to debugger-j6zks.
    nameserver 10.96.0.10
    search application.svc.cluster.local svc.cluster.local cluster.local
    options ndots:5

The service `dest-svc-v1` resolves to the cluster IP (svc IP) `10.108.78.105`

    kubectl debug $POD -it --image=busybox -- /bin/sh


Inside the shell:

```bash
  / # nslookup dest-svc-v1
  Server:         10.96.0.10
  Address:        10.96.0.10:53

  Name:   dest-svc-v1.application.svc.cluster.local
  Address: 10.108.78.105
```

##### 6. DNS Query Validation: 
You can check the DNS query and responses, including both IPv4 (A) and IPv6 (AAAA) queries, using CoreDNS logs. Both should return NOERROR, meaning DNS queries are successful.

    kubectl get pod $POD -o jsonpath='{.status.podIP}'
    kubectl logs --namespace=kube-system -l k8s-app=kube-dns --tail 100 | grep dest-svc-v1.application.svc.cluster

Example log entry:
```bash
[INFO] 10.244.0.10:54152 - 19147 "A IN dest-svc-v1.application.svc.cluster.local. udp 59 false 512" NOERROR qr,aa,rd 116 0.000088042s
[INFO] 10.244.0.10:54152 - 36587 "AAAA IN dest-svc-v1.application.svc.cluster.local. udp 59 false 512" NOERROR qr,aa,rd 152 0.000044833s
```

## 🧹 Clean Up
Delete IngressController and Ingress rules

    kubectl delete -f istio-deepdive/ingress/nginx-ingress.yaml
    minikube addons disable ingress

## 🚀 Create Istio Ingress Gateway

For simplicity, we won't use VirtualService or DestinationRule this time and create only Ingress and Gateway 

![Ingress Nginx overview](/images/post-20240916/ingress-istio.png)

```bash
# install and inject istio
istioctl install --set profile=demo -y
kubectl label namespace application istio-injection=enabled

# deploy ingress rule
kubectl apply -f istio-deepdive/ingress/istio-ingress.yaml
kubectl get ingress -A

# deploy
kubectl apply -f istio-deepdive/ingress/istio-gateway.yaml
kubectl get gateway -A

# restart target apps
kubectl delete -f istio-deepdive/depl-helloworld.yaml
kubectl apply -f istio-deepdive/depl-helloworld.yaml
```


## 👀 Istio Gateway Flow Overview

##### 1. User Initiates Request: 
Users can now call the external ClusterIP (http://192.168.76.2) with the Ingress port (e.g., 30736).

```bash
# retrive ingressgateway http TCP port (e.g. 30154)
export INGRESS_PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

# verfiy
curl http://$CLUSTER_IP:$INGRESS_PORT/v1
curl -s -HHost:yuya.example.com http://$CLUSTER_IP:$INGRESS_PORT/v1
```

##### 2. DNS Resolution: 
The DNS resolves the hostname to the IP address of the service.

    kubectl get svc -n istio-system istio-ingressgateway

##### 3. LoadBalancer Routes the Request to the Ingress Gateway: 
The LoadBalancer forwards the request to the Istio Gateway pod, where the ingress rules are applied.

    kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.spec.type}'

##### 4. Ingress Controller Processes the Request: 
The Istio Gateway applies ingress rules and routes traffic to the correct endpoint. For example, traffic to /v1 is routed to the correct service endpoint (e.g., `10.244.0.10:5678`).

```bash
# check logs 
ISTIO_INGRESS_GW=$(kubectl get -n istio-system pod -l app=istio-ingressgateway -ojsonpath='{.items[0].metadata.name}')
kubectl logs $ISTIO_INGRESS_GW -n istio-system
```

Example log entry:
```bash
[2024-09-15T12:35:56.471Z] "GET /v1 HTTP/1.1" 200 - via_upstream - "-" 0 33 0 0 "10.244.0.1" "curl/7.81.0" "3170f1cf-61ea-9166-b63c-35273a31e6f5" "yuya.example.com" "10.244.0.10:5678" outbound|7777||dest-svc-v1.application.svc.cluster.local 10.244.0.8:52522 10.244.0.8:8080 10.244.0.1:6131 - -
```

check the istio-ingressgateway Pod IP:

    kubectl get pod -o wide --all-namespaces | grep 10.244.0.8

- Hostname: `yuya.example.com`
- A unique request ID or trace ID: `3170f1cf-61ea-9166-b63c-35273a31e6f5`
- The destination IP and port of the service Endpoints: `10.244.0.10:5678`
- Outbound to dest-svc-v1 in the application namespace with the specified port 7777: `outbound|7777||dest-svc-v1.application.svc.cluster.local`
- Source Pod IP (istio-ingressgateway): `10.244.0.8`

##### 5. Service Routes the Request to the Target Pod: 

The service follows a similar path to the NGINX Ingress setup.

##### 6. DNS Query Validation: 

You can see a very similar structured log of the istio-ingressgateway in the envoy container

```bash
# check pod IP and DNS logs
POD=$(kubectl get pod -l app=hw-v1 -ojsonpath='{.items[].metadata.name}')
kubectl get pod $POD -o jsonpath='{.status.podIP}'
kubectl logs -c istio-proxy $POD
```

Example log entry:
```bash
[2024-09-15T12:35:56.471Z] "GET /v1 HTTP/1.1" 200 - via_upstream - "-" 0 33 0 0 "10.244.0.1" "curl/7.81.0" "3170f1cf-61ea-9166-b63c-35273a31e6f5" "yuya.example.com" "10.244.0.10:5678" inbound|5678|| 127.0.0.6:42109 10.244.0.10:5678 10.244.0.1:0 outbound_.7777_._.dest-svc-v1.application.svc.cluster.local default

```
- Hostname: `yuya.example.com`
- A unique request ID or trace ID: `3170f1cf-61ea-9166-b63c-35273a31e6f5`
- The destination IP and port of the service Endpoints: `10.244.0.10:5678`
- Inbound from dest-svc-v1 in the application namespace with the specified port 5678: `inbound|5678||`
- Envoy / Istio Proxy IP: `127.0.0.6:42109` 
- Client ip with the cluster `10.244.0.1:0` 
- Outbond Routing from the target service: `outbound_.7777_._.dest-svc-v1.application.svc.cluster.local default`


## 🛠 Debugging with istioctl proxy-config
One of Istio's most powerful features is its ability to provide deep insights into network traffic and proxy configurations using the istioctl command-line tool. These commands can significantly help identify misconfigurations, routing errors, or any networking anomalies within your Istio service mesh.

    istioctl proxy-config cluster $POD -n application

    istioctl proxy-config listener $POD -n application

    istioctl proxy-config route $POD -n application

    istioctl proxy-config all $POD -n application

## 🧹 Clean up

    istioctl uninstall --purge -y
    kubectl delete -f istio-deepdive/ingress

## ℹ️  Summary
I hope that by now, you have a clearer understanding of how ingress traffic is routed within a Kubernetes cluster. Through deploying demo applications, tracing network flows, and using istioctl to debug configurations, I aimed to equip you with the tools and techniques necessary to manage ingress controllers more effectively in your Kubernetes environment.

In my next post, I’ll dive deeper into Istio by exploring how the Egress Gateway functions. This will provide even more control and visibility into your microservices and their outbound traffic.

Stay tuned for that deep dive!