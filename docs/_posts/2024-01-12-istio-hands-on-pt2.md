---
layout: post
title: Istio Mastery ⛵ Session 2 - Visualizing Service Mesh

tags: ["tech", "microservices"]
mathjax: true
---

Welcome to Istio Hands-On Pt 2! 

Building on the foundation of Part 1, we're excited to take you further into the exciting world of Istio with Kiali! If you haven't yet, make sure to check out the earlier session on setting up your Istio environment ([link](https://yuyatinnefeld.com/2024-01-10-istio-hands-on-pt1)). Today, we'll master the Kiali dashboard, uncovering the hidden dynamics of your service mesh and gaining invaluable insights into its health and performance.


## Create a Secret for Kiali Loggin
To enhance security, create a Kiali logging secret. Currently, Kiali uses built-in credentials (username: admin, password: admin), which are not recommended for production environments. ([offical site](https://istio.io/v1.3/docs/tasks/telemetry/kiali))

#### Create secret variables
```bash
KIALI_USERNAME=$(read -p 'Kiali Username: ' uval && echo -n $uval | base64)
KIALI_PASSPHRASE=$(read -sp 'Kiali Passphrase: ' pval && echo -n $pval | base64)
NAMESPACE=istio-system
```

#### Configure secret variables
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $KIALI_USERNAME
  passphrase: $KIALI_PASSPHRASE
EOF
```

## Install Kiali
To unlock the full power of Kiali's dashboard and monitoring capabilities, you'll need to have Prometheus installed. It fuels Kiali with the essential metrics it needs to display network traffic and service health.

Install Prometheus

```bash
ISTIO_HOME=$(ls | grep istio)
kubectl apply -f ${ISTIO_HOME}/samples/addons/prometheus.yaml
kubectl get pod -n istio-system | grep prometheus
kubectl get svc -n istio-system  | grep prometheus

# verify prometheus server
kubectl port-forward svc/prometheus -n istio-system 9090
open http://localhost:9090
```

Install Kiali
```bash
kubectl apply -f ${ISTIO_HOME}/samples/addons/kiali.yaml
kubectl rollout status deployment/kiali -n istio-system
kubectl get svc -n istio-system  | grep kiali
```

## Start Kiali Dashboard
![Kiali Dashboard Browser](/images/post-20240112/kiali-dashboard.png)

Launch Kiali with a Single Command and Access the Kiali Dashboard. You'll be greeted by a login prompt. Remember to use your own credentials for production environments.

#### Open Kiali Dashboard
```bash
# option 1
kubectl port-forward svc/kiali 20001:20001 -n istio-system

## option 2
istioctl dashboard kiali
```

## Kiali Architecture
![Kiali Architecture](/images/post-20240112/kiali-architecture.png)

Envision Kiali as the command center overseeing your service mesh. Comprising two essential components, it boasts a backend written  in Go and single-page application (SPA) frontend services constructed with Patternfly, React, Typescript, and Redux. Kiali relies on various external services, including Prometheus, Kube API, Istiod, and components furnished by the container application platform and Istio, seamlessly integrating them to provide a comprehensive and robust management solution for your service mesh.


## Create Traffics
To truly appreciate Kiali's power, create some dummy traffic! Call the frontend app that interacts with your backend services. As traffic flows, watch Kiali update in real-time, illustrating the connections and performance metrics.

```bash
SERVICE_NAME="frontend-service"
SERVICE_PORT="5000"

# verify
kubectl get svc -n default | grep $SERVICE_NAME

# port forwarding
kubectl port-forward svc/$SERVICE_NAME $SERVICE_PORT

# visit the frontend app
while sleep 5; do curl "http://localhost:$SERVICE_PORT"; done
```

## Kiali Dashboard
![Kiali graph](/images/post-20240112/kiali-graph.png)

Kiali's Graph shows a vibrant visualization of your mesh traffic, weaving real-time data with Istio configuration. See service talk, spot issues instantly, and zoom in with multiple views: services, workloads, or applications. It's like a live network detective story, guiding you to performance insights and troubleshooting wins. Ditch the confusion, embrace the clarity – Kiali's Graph empowers you to master your mesh.

## Conclusion
In this session, we've explored the capabilities of Kiali in visualizing the service mesh. With Kiali, you gain real-time insights into your microservices architecture, enabling you to monitor network traffic, identify issues, and optimize performance. As we continue our Istio journey, stay tuned for the next article, where we delve into Istio gateway and ingress, further enhancing our mastery of traffic management and control within the service mesh. Happy exploring!