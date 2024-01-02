---
layout: post
title: Istio Mastery ⛵ Session 0 - Microservices Deployment

tags: ["tech", "microservices"]
mathjax: true
---

Welcome to the Istio Hands-On series! 

The target audience for this blog comprises users who are already familiar with microservices, service mesh, and want to learn Istio. If these concepts are new to you, I recommend reading my introductory blog on microservices and Istio. If you are unfamiliar with these topics, I recommend reading my blog article on <a href="https://yuyatinnefeld.com/2023-10-31-service-mesh/" target="_blank"><b>microservices and service mesh</b></a> beforehand. In these sessions, I'll guide you through the step-by-step implementation of Istio for your microservices. To make it more digestible, I've divided the implementation process into five sessions:

1. Setup Environment
2. Kiali Dashboard
3. Traffic Management
4. Security
5. Observability

In our inaugural session, Part 0, we'll start by deploying microservices without Istio, and then we'll delve into the process with Istio injection in the second session. While Istio provides a sample microservices project (bookstore), I've taken the initiative to create a simple microsoft architecture application. This will allow us not only to understand the basics but also to make adjustments to the application later.

For the official Istio sample project, you can refer to: <a href="https://github.com/istio/istio/tree/master/samples/bookinfo/platform/kube" target="_blank"><b>this link</b></a>

## Microservices Architecture
![Sample Microservices Architecture](/images/post-20240101/microservice-sample.png)

#### Application Overview
- 1 x Frontend App (Python Flask) with v1
- 1 x Reviews BFF (Golang) with v1, v2, v3
- 1 x Payment BFF (Golang) with v1, v2, v3
- 1 x Details BFF (Java) with v1, v2, v3

In a single Kubernetes cluster, we deploy a few services: frontend and BFF (backend-for-frontend) services (details, reviews, payment). The frontend service is configured with a LoadBalancer type to enable user interaction with the application. The other BFF services use ClusterIP as the service type. Additionally, we leverage an Ingress Controller to define paths and ingress rules.

## Push Docker Images into Dockerhub

For detailed information about the application, visit <a href="https://github.com/yuyatinnefeld/istio/tree/main/microservices/app" target="_blank"><b>this repository</b></a>. We'll push four Docker images into the official Docker registry, Docker Hub, to use them in the Kubernetes cluster later. We'll push three different versions of BFF images for canary deployment and later for Istio.

- [Payment App Image](https://hub.docker.com/repository/docker/yuyatinnefeld/microservice-payment-app/general)
- [Reviews App Image](https://hub.docker.com/repository/docker/yuyatinnefeld/microservice-reviews-app/general)
- [Details App Image](https://hub.docker.com/repository/docker/yuyatinnefeld/microservice-details-app/general)
- [Frontend App Image](https://hub.docker.com/repository/docker/yuyatinnefeld/microservice-frontend-app/general)

## Deploy microservices to kubernetes cluster

After pushing the images, we'll deploy the microservice applications. See the guide: [link](https://github.com/yuyatinnefeld/istio/tree/main/microservices/deploy/no-service-mesh)

## Start Minikube Cluster
```bash
minikube start --memory=8192 --cpus=4 --driver=hyperkit
```

## Deploy Microservices into Kubernetes Cluster
```bash
# deploy microservices with v1
kubectl apply -f microservices/deploy/no-service-mesh/apps-v1
# verfiy the services with v1
kubectl port-forward svc/frontend-service 5000

# update the services with v2
kubectl apply -f microservices/deploy/no-service-mesh/apps-v2
# verfiy the services with v2
kubectl port-forward svc/frontend-service 5000

# update the services with v3
kubectl apply -f microservices/deploy/no-service-mesh/apps-v3
# verfiy the services with v3
kubectl port-forward svc/frontend-service 5000
```

## Deploy Kubernetes Ingress Controller and Ingress Rules

```bash
# enable minikube ingress controller to use ./k8s-ingress/ingress.yaml
minikube addons enable ingress

# verify the ingress controller
kubectl get pods -n ingress-nginx | grep ingress-nginx-controller

# deploy ingress rules
kubectl apply -f microservices/deploy/no-service-mesh/k8s-ingress/ingress.yaml

# wait and verify the ingress received the cluster IP
kubectl get ingress --watch

# update DNS for Local Domain Access
echo -e "$(minikube ip)\testing-yuya.com" | sudo tee -a /etc/hosts
```

## Verify Applications

```bash
curl 'http://testing-yuya.com'
curl -X GET 'http://testing-yuya.com/details' -H 'Content-Type: application/json'
curl -X GET 'http://testing-yuya.com/payment' -H 'Content-Type: application/json'
curl -X GET 'http://testing-yuya.com/reviews' -H 'Content-Type: application/json'
```

## Conclusion
In the current stage of our exploration, we have developed a microservices application that sets the stage for integration with Service Mesh through Istio in the upcoming session. One significant drawback of microservices without a service mesh is the complexity associated with deployment, canary deployment, and A/B testing. These tasks become challenging as traditional setups lack the straightforward ability to distribute traffic in specific percentages. Additionally, there may be instances where deploying redundant pods in parallel is necessary, followed by manual elimination at a later stage.

In the next article, we will delve into the installation of Istio and explore the utilization of sidecar injection from Istio. This will equip us with the tools needed to overcome the challenges posed by microservices deployments without a service mesh.

Happy coding!

