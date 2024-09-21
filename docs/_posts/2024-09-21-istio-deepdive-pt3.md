---
layout: post
title: Istio Advanced ⛵ Session 3 - Egress Gateway

tags: ["tech", "microservices", "service-mesh"]
mathjax: true
---

This is the third installment in my advanced Istio deep dive series, where we’ll be exploring another critical component of Istio: Egress. In this post, I’ll take a closer look at how services interact through the Egress gateway, using detailed logs to give you a clearer understanding of the process. Before we get started, be sure to check out the other topics covered in this series:

1. [Istio HelmCart](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
2. [Istio Ingress](https://yuyatinnefeld.com/2024-09-16-istio-deepdive-pt2/)
3. [Istio Egress](https://yuyatinnefeld.com/2024-09-21-istio-deepdive-pt3/)
4. [Istio Control plane](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
5. [Istio Data plane (1)](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)
6. [Istio Data plane (2)](https://yuyatinnefeld.com/2024-09-08-istio-deepdive-pt1/)

For this project, we're using the following GitHub repository: [DEMO EGRESS](https://github.com/yuyatinnefeld/istio/tree/main/istio/istio-deepdive)

## 🤔 What is Engress Gateway?
An Egress Gateway is a dedicated exit point in a service mesh used to manage outbound traffic leaving the mesh. It provides a controlled pathway through which all external traffic passes when leaving the mesh, ensuring security and traffic management.

## ⚙️ Setting Up the Istio Environment

```bash
# Install Istio will allow outbound traffic to any external service by default and enable access logging
istioctl install -y --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=ALLOW_ANY --set meshConfig.accessLogFile=/dev/stdout

# Install Kiali for monitoring
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/addons/kiali.yaml
kubectl port-forward svc/kiali 20001:20001 -n istio-system

# Create a demo application environment
kubectl create ns application
kubectl config set-context --current --namespace=application
kubectl label namespace application istio-injection=enabled
kubectl get ns application --show-labels

# Deploy sample applications
kubectl apply -f istio-deepdive/depl-sleep.yaml
kubectl apply -f istio-deepdive/depl-helloworld.yaml
```

## 🔔 Calling Internal and External Services

```bash
# Get the source pod for the sleep application
SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
```

### Call an internal service

```bash
TARGET_URL="dest-svc-v1.application.svc.cluster.local:7777"
while true; do kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI $TARGET_URL | grep  "HTTP/"; sleep 2; done;
```

```bash
HTTP/1.1 200 OK
```

### Call an external service

```bash
TARGET_URL=http://google.com
while true; do kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI $TARGET_URL | grep  "HTTP/"; sleep 2; done;
```

```bash
HTTP/1.1 200 OK
```

## ⚙️ Enabling REGISTRY_ONLY Mode

![Simple App](/images/post-20240921/blackholecluster.png)


In `REGISTRY_ONLY` mode, Istio only allows traffic to services that are registered in the service mesh. Traffic to any unregistered external service will be blocked, and routed to the `BlackHoleCluster`.

```bash
# Check the current outbound traffic mode
kubectl get cm istio -n istio-system -o jsonpath='{.data.mesh}' | grep mode

# Re-install Istio with REGISTRY_ONLY mode enabled
istioctl install -y --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY --set meshConfig.accessLogFile=/dev/stdout

# Verify that REGISTRY_ONLY mode is active
kubectl get cm istio -n istio-system -o jsonpath='{.data.mesh}' | grep mode
```

### Call an internal service
```bash
TARGET_URL="dest-svc-v1.application.svc.cluster.local:7777"
while true; do kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI $TARGET_URL | grep  "HTTP/"; sleep 2; done;
```

```bash
HTTP/1.1 200 OK
```

### Call an external service
```bash
TARGET_URL=http://google.com
while true; do kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI $TARGET_URL | grep  "HTTP/"; sleep 2; done;
```

```bash
HTTP/1.1 502 Bad Gateway
```

## ⚙️ ServiceEntry
![Simple App](/images/post-20240921/serviceentry.png)

A ServiceEntry allows Istio to treat external services (like third-party APIs) as if they are part of the service mesh. This enables internal services to discover and route traffic to external services.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: se-google
  namespace: application
spec:
  hosts:
  - google.com
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
EOF

kubectl get serviceentry -n application

```

### Call google.com
```bash
TARGET_URL=http://google.com
while true; do kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI $TARGET_URL | grep  "HTTP/"; sleep 2; done;
```

```bash
HTTP/1.1 200 OK
```

### Call github.com

```bash
# Call GitHub (HTTP/1.1 502 Bad Gateway - no ServiceEntry defined)
TARGET_URL=http://github.com/
while true; do kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI $TARGET_URL | grep  "HTTP/"; sleep 2; done;
```

```bash
HTTP/1.1 502 Bad Gateway
```

## 🤔 Why is a ServiceEntry Not Enough?

While a `ServiceEntry` enables access to and discovery of external services, it lacks the control, security, and traffic management needed for outbound traffic. For more fine-grained control, you need to deploy additional Istio components, like the Egress Gateway.

### Steps to Set Up an Egress Gateway
![Simple App](/images/post-20240921/egressgateway.png)

1. Create an Egress gateway

- `gw-egress-google` directs outbound HTTP traffic to `google.com` on port `80`.

```bash
# Check if the Egress Gateway pod is running
kubectl get pod -l istio=egressgateway -n istio-system

# Apply the egress gateway configuration for Google
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gw-egress-google
  namespace: application
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - google.com
EOF

```

2. Create a Distination Rule

- `dr-egress-google` manages traffic for Google’s services, which will be used in the VS configuration.

```bash
# Apply the Destination Rule and VirtualService for Google
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: dr-egress-google
  namespace: application
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: google
EOF
```

3. Configure a Virutal Service

- 3.1. Inside the `mesh`, traffic destined for google.com is first routed through the `istio-egressgateway.istio-system.svc.cluster.local`.

- 3.2. Once the traffic leaves `istio-egressgateway`, it is directed to `google.com` on port `80`.


```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: vs-google-via-egress-gw
spec:
  hosts:
  - google.com
  gateways:
  - gw-egress-google
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: google
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - gw-egress-google
      port: 80
    route:
    - destination:
        host: google.com
        port:
          number: 80
      weight: 100
EOF
```

Call Google via the Egress GW

```bash
TARGET_URL=http://google.com
while true; do kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI $TARGET_URL | grep  "HTTP/"; sleep 2; done;
```

Check Egress GW logs to verify traffic routing
```bash
kubectl logs -l istio=egressgateway -n istio-system
```

Example log entry:

```bash
[2024-09-21T10:00:43.708Z] "HEAD / HTTP/2" 301 - via_upstream - "-" 0 0 29 29 "10.244.0.66" "curl/8.10.1" "9cf4caf3-9faf-9689-bec3-8989898" "google.com" "142.250.184.206:80" outbound|80||google.com 10.244.0.58:45773 10.244.0.58:8080 10.244.0.66:57182 - -
```

- Sleep POD IP: `10.244.0.66`
- External IP of Google: `142.250.184.206:80`
- Egress Gateway IP: `10.244.0.58`
- Route Info: `outbound|80||google.com`

## 🧹 Clean up

```bash
istioctl uninstall --purge -y
kubectl delete -f istio-deepdive/egress
```

## ℹ️  Summary
In this post, we explored the fundamentals of managing egress traffic in Istio, from `outboundTrafficPolicy.mode` to using ServiceEntries and setting up an Egress Gateway for fine-grained control of outbound traffic. In the next post, we’ll take a deeper dive into the Istio Control Plane (Config ingestion layer, translation, serving layers) and the xDS API.

Stay tuned for more insights into Istio’s architecture!