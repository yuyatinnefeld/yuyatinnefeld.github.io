---
layout: post
title: Istio Advanced ⛵ Session 1 - Under Stand Istio Componets

tags: ["tech", "microservices", "service-mesh"]
mathjax: true
---

Starting a new role has opened up a deeper dive into the world of Service Mesh, especially Istio. Recently, I found myself stumbling when a colleague asked, "What exactly gets installed with `istioctl install --set profile=demo -y`" or "How does the Ingress Gateway work? What's the difference between Istio Ingress and Kubernetes Ingress?" These questions motivated me to dive deeper into Istio and go beyond the basics.

To make this exploration more digestible, I’ve broken down Istio’s components into six sessions:

1. [Istio HelmCart](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
2. [Istio Ingress](https://yuyatinnefeld.com/2024-09-16-istio-deepdive-pt2/)
3. [Istio Egress](https://yuyatinnefeld.com/2024-09-21-istio-deepdive-pt3/)
4. [Istio Control plane](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
5. [Istio Data plane (1)](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
6. [Istio Data plane (2)](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)

## 🤔 Why Use Helm Instead of `istioctl install`?

In this guide, I'll focus on deploying Istio using Helm. While the `istioctl install` command is a quick way to install Istio, it may not be ideal for Infrastructure as Code (IaC) practices, especially when scaling or customizing configurations for different environments.

I thought I had a decent understanding of Istio components until I dug deeper. Using Istio seems straightforward, but mastering it is an entirely different challenge. This guide will help both you and me get a better grasp of the key components of Istio.

## 🚨 Installation Using `istioctl`

To install Istio with the demo profile using `istioctl`, run:

    istioctl install --set profile=demo -y

    ✔ Istio core installed: istio-base
    ✔ Istiod installed: istiod
    ✔ Egress gateways installed
    ✔ Ingress gateways installed
    ✔ Installation complete

These four steps can also be achieved by deploying Helm charts.

## ⚡️ Installation Using Helm

For this project, we're using the following GitHub repository:
- [ISTIO HELM](https://github.com/yuyatinnefeld/istio/tree/main/istio/istio-helm)

## 🛠️  1. istio-base
The `istio-base` chart installs the foundational resources required for Istio, including Custom Resource Definitions (CRDs) that define the various Istio components. It also sets up the necessary roles, service accounts, and basic configurations that other Istio components depend on.

Create the namespace and install the base components:

    kubectl create namespace istio-system
    helm install istio-base helm/base -n istio-system --set defaultRevision=default
    helm ls -n istio-system

The following components are installed

##### CustomResourceDefinitions (CRDs)
    authorizationpolicies.security.istio.io
    destinationrules.networking.istio.io
    envoyfilters.networking.istio.io
    gateways.networking.istio.io
    peerauthentications.security.istio.io
    proxyconfigs.networking.istio.io
    requestauthentications.security.istio.io
    serviceentries.networking.istio.io
    sidecars.networking.istio.io
    telemetries.telemetry.istio.io
    virtualservices.networking.istio.io
    wasmplugins.extensions.istio.io
    workloadentries.networking.istio.io
    workloadgroups.networking.istio.io
    ValidatingWebhookConfiguration
    istiod-default-validator

##### ClusterRole and ClusterRoleBinding
    multiple CRs and CRBs related to Istio

##### ServiceAccount
    istio-reader-service-account

##### ConfigMaps
    istio-ca-root-cert
    istio-gateway-status-leader
    istio-leader
    istio-namespace-controller-election
    kube-root-ca.crt


## 🛠️ 2. istiod
The `istiod` (isito-discovery) component is the control plane of Istio, responsible for managing the configuration of the service mesh, distributing certificates, and controlling the data plane proxies (Envoy). It handles the core functionality that enables Istio to operate.

Install the Istiod component:

    helm install istiod helm/istiod -n istio-system
    helm ls -n istio-system

##### ClusterRoles
    istio-reader-clusterrole-istio-system
    istiod-clusterrole-istio-system
    istiod-gateway-controller-istio-system

##### ClusterRoleBindings
    istio-reader-clusterrole-istio-system
    istiod-clusterrole-istio-system
    istiod-gateway-controller-istio-system

##### ValidatingWebhookConfiguration
    istio-validator-istio-system

##### MutatingWebhookConfiguration
    istio-sidecar-injector

##### PodDisruptionBudget
    istiod

##### RoleBindings
    istiod

##### Roles
    istiod

##### ServiceAccount
    istiod

##### ConfigMaps
    istio
    istio-sidecar-injector

##### Deployments
    istiod

##### Pods
    istiod-bc84dc94d-7k4bb

## 🛠️ 3. istio-egress and istio-ingress

The `istio-egress` component allows you to control and monitor outgoing traffic, applying policies and managing security for external communication.

The `istio-ingress` component allows you to control and secure incoming requests from external clients to services within the mesh.

Install the Istio Egress and Ingress Gateway:

    # egress
    helm install istio-egress helm/istio-egress -n istio-system
    # ingress
    helm install istio-ingress helm/istio-ingress -n istio-system
    # verify
    helm ls -n istio-system


##### Deployments
    istio-egressgateway
    istio-ingressgateway

##### Services
    istio-egressgateway
    istio-ingressgateway

##### Pods
    istio-egressgateway-c5f45ff98-w4rjb
    istio-ingressgateway-77bb45d49d-r77pw

##### ServiceAccounts
    istio-egressgateway-service-account
    istio-ingressgateway-service-account

##### RoleBindings
    istio-egressgateway-sds
    istio-ingressgateway-sds

##### Roles
    istio-egressgateway-sds
    istio-inressgateway-sds

##### PodDisruptionBudget
    istio-egressgateway
    istio-ingressgateway

## ℹ️ Summary

Deploying Istio with Helm gives you more control and flexibility compared to using istioctl, especially when managing your IaC. By understanding the core components—istio-base, istiod, istio-egress, and istio-ingress—you'll be better equipped to handle service mesh management in various environments.

In the next session, we’ll dive deeper into Istio’s Ingress Gateway. Stay tuned!