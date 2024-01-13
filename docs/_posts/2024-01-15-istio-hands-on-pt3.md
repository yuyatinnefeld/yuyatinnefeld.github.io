---
layout: post
title: Istio Mastery ⛵ Session 3 - Traffic Management

tags: ["tech", "microservices"]
mathjax: true
---

Welcome to Istio Hands-On Pt 3! 

Building on the foundation of Part 1, we're excited to take you further into the exciting world of Istio Traffic Management! If you haven't yet, make sure to check out the earlier session on setting up your Istio environment ([link](https://yuyatinnefeld.com/2024-01-10-istio-hands-on-pt1)). Today, we'll master the following topics:

- Gateways
- Virtual Service
- Destination Rules
- Fault Injection
- Timeouts
- Retries
- Circuit Breaker
- A/B Testing

For this project, we are utilizing a sample microservice project, and you can find it at the following <a href="https://github.com/yuyatinnefeld/istio/tree/main" target="_blank"><b>link</b></a>.

## Gateways
![Kiali graph](/images/post-20240115/istio-gateway.png)

A Gateway is like a traffic controller for a service mesh. It sits at the edge, managing incoming and outgoing connections. Think of it as a set of instructions for how to handle different types of connections—what ports to use, what kind of rules to follow, and other details like how to configure the load balancer.

First, we deploy ingress rules to specify which path corresponds to each service. These rules essentially tell the system which service should be called when a specific path is accessed. Afterward, we deploy a gateway manifest, which is a set of instructions that defines the domain hosts we'll be using to access the microservices website.

In simpler terms, it's like setting up road signs. The ingress rules are like signposts that guide traffic to the right service based on the path taken, and the gateway manifest is like a big sign at the entrance, stating which domains are allowed to access our microservices website.

#### Deploy Ingress Rules
```bash
# check svc
kubectl get svc -n istio-system | grep istio-ingressgateway

# deploy ingress
kubectl apply -f microservices/deploy/service-mesh/istio/gateway/istio-ingress.yaml

# verify
kubectl get ingress -A
```

#### Deploy Gateway
```bash
# deploy gateway
kubectl apply -f microservices/deploy/service-mesh/istio/gateway/istio-gateway.yaml

# verify
kubectl get gateway -A
```

#### Access Microservice Site
```bash
# setup environment variables
export INGRESS_HOST=$(minikube ip)

export INGRESS_PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

echo http://$INGRESS_HOST:$INGRESS_PORT/

# update local DNS
sudo echo -e "$(minikube ip)\tmicroservices-yuya.com" | sudo tee -a /etc/hosts

# open the website (example)
open http://192.168.64.66:31586
open http://192.168.64.66:31586/details
open http://192.168.64.66:31586/payment
open http://192.168.64.66:31586/reviews


open http://microservices-yuya.com:31586
open http://microservices-yuya.com:31586/details
open http://microservices-yuya.com:31586/payment
open http://microservices-yuya.com:31586/reviews
```

## Virtual Services



## Conclusion
x