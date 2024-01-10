---
layout: post
title: Istio Mastery ⛵ Session 1 - Setup Istio Environment

tags: ["tech", "microservices"]
mathjax: true
---

Welcome to Istio Hands-On Pt 1!

If you haven't read part 0 of the Istio Hands-On blog, please check it out [here](https://yuyatinnefeld.com/2024-01-02-istio-hands-on-pt0).

In these sessions, we'll learn how to install `istioctl` and configure an Istio mesh. There are various opportunities to install and configure the Istio mesh; you can refer to the official documentation [here](https://istio.io/latest/docs/setup/install/). This article provides a minimal overview of Istio setup. If you are interested in a deeper understanding of the topic, you can find a wealth of useful information in the Istio documentation.

## Install and Enable Istioctl
Firstly, we need to install the `istioctl` command line tool, offering rich customization of the Istio control plane and sidecars for the Istio data plane. `istioctl` includes user input validation to prevent installation errors and customization options to override any configuration aspect.

```bash
# Install istioctl
$ curl -L https://istio.io/downloadIstio | sh -

# Verify the ctl version
ISTIOCTL_VERSION=$(ls | grep istio)
echo $ISTIOCTL_VERSION

# Set up the working directory path
export PATH="$PATH:$(pwd)/$ISTIOCTL_VERSION/bin"

# Verify the istioctl version
istioctl version
```

## Install Istio Configuration Profiles
Additional Istio configuration profiles can be installed in a cluster by specifying the profile name on the command line. For example, the following command installs the demo profile:


```bash
# Install Istio profile
istioctl install --set profile=demo -y

# Verify the installation results
istioctl verify-install

# Verify all Istio components
kubectl get all -n istio-system
```

## Create a Namespace and enable istio injection

```bash
# Enable istio-injection for the default namespace
kubectl label namespace default istio-injection=enabled
kubectl get ns default --show-labels
kubectl get namespace -L istio-injection
```

## Deploy microservices
```bash
# Deploy microservices
kubectl apply -f microservices/deploy/service-mesh/apps

# Check the side-car proxy
istioctl analyze

# Check if all pods have a sidecar proxy (envoy)
kubectl get pod

# Port forwarding
kubectl port-forward svc/frontend-service 5000

# Call the frontend multiple times and verify whether the BFF API version varies.
curl 'http://localhost:5000'
```

## Conclusion
In this session, we have successfully developed microservices with Istio injection. All services now have an envoy proxy. In the next article, we will explore Istio gateway and ingress. Following this setup, we will configure traffic management features such as A/B testing and canary deployment through virtual services and destination rules.