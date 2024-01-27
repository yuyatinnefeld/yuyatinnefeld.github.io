---
layout: post
title: Istio Mastery ⛵ Session 4 - Security

tags: ["tech", "microservices"]
mathjax: true
---

Welcome to Istio Hands-On Pt 4! 

Building on the foundation of Part 1, we're excited to take you further into the exciting world of Istio Security! If you haven't yet, make sure to check out the earlier session on setting up your Istio environment.

Below, you'll find the table of contents detailing the Istio hands-on lab, organized into five informative sessions:

1. [Setup Istio Environment](https://yuyatinnefeld.com/2024-01-10-istio-hands-on-pt1/)
2. [Kiali Dashboard](https://yuyatinnefeld.com/2024-01-12-istio-hands-on-pt2/)
3. [Traffic Management](https://yuyatinnefeld.com/2024-01-17-istio-hands-on-pt3/)
4. [Security](https://yuyatinnefeld.com/2024-01-27-istio-hands-on-pt4/)
5. Observability

Today, we'll master the following topics:

- [Authentication](#authentication)
- [Authorization](#authorization)
- [Certificate Management](#certificate-management)

For this project, we are utilizing a sample microservice project, and you can find it [here](https://github.com/yuyatinnefeld/istio).

## Setup Environment and Deploy a Sample App
```bash
# Start the cluster and Setup Istio environment
bash ./istio-install.sh

# Deploy microservices
kubectl apply -f microservices/deploy/service-mesh/apps

# Check the deployment
kubectl port-forward svc/frontend-service 5000

# Set a new namespace
export NAMESPACE="foo"

# Create a new namespace
kubectl create ns $NAMESPACE

# Deploy a sample app
kubectl apply -f <(istioctl kube-inject -f microservices/deploy/service-mesh/sample/httpbin.yaml) -n $NAMESPACE

# Verify
kubectl rollout status deployment/httpbin -n $NAMESPACE
```

## Security in Depth (SID)
Security in Depth (SID) involves employing a comprehensive approach to safeguarding assets through multiple layers of security. Within this framework, Istio Service Mesh Sidecar and ingress/egress proxies serve as Policy Enforcement Points, ensuring that certificates, keys, authentication, authorization, and secure naming policies are consistently communicated to the proxies. It is essential to note that security checks are implemented at every point in the network, emphasizing the significance of securing not only the entry point but also all components throughout the system.

## Authentication {#authentication}
Istio provides two authentication mechanisms for enhanced security: <b>Peer Authentication</b> using mTLS and <b>Request Authentication</b> leveraging JWT. Additionally, it supports integration with OpenID Connect providers such as ORY Hydra, Keycloak, Firebase, and Google.

- Mutual TLS (mTSL) focuses on the secure exchange of digital certificates to ensure mutual <b>authentication between services</b> 

- JSON Web Tokens (JWT) provide a means of securely transmitting claims and identity information, commonly used for <b>authentication between end-users and services</b>. 

### mTLS
 In a typical TLS handshake, only the server is authenticated to the client using a digital certificate. However, in mutual TLS, both the client and the server authenticate each other through the exchange of digital certificates. This bidirectional authentication enhances the overall security of the communication by verifying the identities of both parties, mitigating the risk of unauthorized access.

Istio does indeed automate the management and implementation of mTLS. `istiod` is responsible for handling the control plane functionalities, including the automatic configuration and enforcement of mTLS authentication between services. 

#### Workload-specific policy
A workload-specific policy refers to a set of rules and configurations tailored to a specific application or service within a computing environment. 

Example: An e-commerce application may have a workload-specific policy dictating how customer data is handled, specifying encryption requirements, access controls, and communication protocols unique to that service.

#### Fetch the frontend app
```bash
# Curl frontend app via httpbin
kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://frontend-service.default:5000" -s -o /dev/null -w "%{http_code}\n"
```

You will receive a status code `200`, indicating that we could fetch our way into the default namespace to the apps from the 'foo' namespace.

#### Deploy the Workload Policy 
```bash
kubectl apply -f istio/security/authn-workload.yaml
```

Now you cannot fetch the `frontend-app` via httpbin because of workload-specific policy, but we can still fetch other apps like `payment-app`, `reviews-app`.

```bash
# Curl frontend app via httpbin (we will receive 000 as an error)
kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://frontend-service.default:5000" -s -o /dev/null -w "%{http_code}\n"

# Curl another apps via httpbin (we will receive 200)
kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://payment-service.default:8888" -s -o /dev/null -w "%{http_code}\n"

kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://reviews-service.default:9999" -s -o /dev/null -w "%{http_code}\n"
```

#### Namespace-wide policy
A namespace-wide policy encompasses rules and configurations that are applied uniformly across a specific namespace in a computing environment.

Example: In a Kubernetes cluster, a namespace-wide policy could enforce resource quotas, network policies, and access controls applicable to all services within that namespace.

#### Deploy the Namespace Policy 
```bash
kubectl apply -f istio/security/authn-namespace.yaml

# Curl frontend app via httpbin (we will receive 000 as an error)
kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://frontend-service.default:5000" -s -o /dev/null -w "%{http_code}\n"

kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://payment-service.default:8888" -s -o /dev/null -w "%{http_code}\n"

kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://reviews-service.default:9999" -s -o /dev/null -w "%{http_code}\n"
```

Now we cannot access another apps from the `default` namespace.

#### Mesh-wide policy
A mesh-wide policy refers to a set of rules and configurations applied across the entire service mesh infrastructure.

Example: A mesh-wide policy might enforce a consistent authentication mechanism, traffic routing rules, or telemetry settings across all services within an Istio service mesh.
 
### JWT (Json Web Token)
JWT is used to convey information about the identity and additional metadata and consists of three parts: a header, a payload, and a signature. The header and payload are Base64-encoded JSON objects, and the signature is used to verify the integrity of the token.

JWT is often used where a user is issued a token upon successful login. This token is then sent with subsequent requests, allowing the server to validate the user's identity witout needing to reauthenticate with every request. JWTs are stateless and enable the creation of secure and scalable authentication systems.

## Authorization {#authorization}
authorization in Istio provides a flexible approach to access control for inbound traffic. we can control which service can reach which service, which is referred to as east-west traffic using authorization configuration. Authorization policies provide 3 actions `CUSTOM`, `ALLOW`, `DENY`. we can also manage that the application can only use only `GET`, `UPDAGE`, `POST` or `DELETE` calls

Step 1: At first, we would like to deny that any application can access our microservices.

```bash
kubectl apply -f istio/security/authz-allow-noting.yaml

# verify (recieve 403 error)
kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://frontend-service.default:5000" -s -o /dev/null -w "%{http_code}\n"
```

After a few seconds, the message `RBAC: Access Denied` is displayed in the browser.

Step 2: We will allow accessing the frontend app now.

```bash
kubectl apply -f istio/security/authz-allow-frontend.yaml

# verify (recieve 200)
kubectl exec -it "$(kubectl get pod -l app=httpbin -n $NAMESPACE -o jsonpath={.items..metadata.name})" -c istio-proxy -n $NAMESPACE -- curl "http://frontend-service.default:5000" -s -o /dev/null -w "%{http_code}\n"

# cannot fetch 3 backend apps
kubectl port-forward svc/frontend-service 5000
```

Result
```bash
"FRONTEND API: 1.0.0 - DETAILS API: {'status': 'error', 'message': 'data cannot be serialized'}, PAYMENT API: {'status': 'error', 'message': 'data cannot be serialized'}, REVIEWS API: {'status': 'error', 'message': 'data cannot be serialized'}"
```

Step 3: We will allow accessing that the frontend app can access reviews app.

```bash
kubectl apply -f istio/security/authz-allow-reviews.yaml

# can fetch the reviews app now
kubectl port-forward svc/frontend-service 5000
```

Result
```bash
"FRONTEND API: 1.0.0 - DETAILS API: {'status': 'error', 'message': 'data cannot be serialized'}, PAYMENT API: {'status': 'error', 'message': 'data cannot be serialized'}, REVIEWS API: {'app': 'reviews', 'version': '3.0.0', 'language': 'go'}"
```

Step 4: Allow Frontend App Access to Payment and Details App

```bash
kubectl apply -f istio/security/authz-allow-details.yaml
kubectl apply -f istio/security/authz-allow-payment.yaml
```

Result
```bash
"FRONTEND API: 1.0.0 - DETAILS API: {'app': 'details', 'version': '3.0.0', 'language': 'java'}, PAYMENT API: {'app': 'payment', 'version': '1.0.0', 'language': 'golang'}, REVIEWS API: {'app': 'reviews', 'version': '3.0.0', 'language': 'go'}"
```

## Certificate Management {#certificate-management}
If you want to read more about how CA works, see the article that offers a deep dive on how CA and PKI works: [here](https://securityboulevard.com/2020/08/what-is-a-certificate-authority-ca-and-what-do-they-do/).

Here, my plan is to explore the integration of Istio and HashiCorp Vault more extensively in an upcoming blog post, detailing how to effectively use Vault CA in conjunction with Istio.

#### Cleaning Up Old Environment
```bash
# clean up
kubectl delete namespace istio-system
istioctl uninstall --purge
kubectl delete kubectl apply -f microservices/deploy/service-mesh/apps
```

#### Generate Certificates and Keys
```bash
cd istio/security/certs
# Generate the root certificate and key
make -f Makefile.selfsigned.mk root-ca

# Generate the intermediate certificate and key
make -f Makefile.selfsigned.mk cluster1-cacerts
```

#### Store Secret in Istio for Istio CA
```bash
kubectl create namespace istio-system

kubectl create secret generic cacerts -n istio-system \
      --from-file=cluster1/ca-cert.pem \
      --from-file=cluster1/ca-key.pem \
      --from-file=cluster1/root-cert.pem \
      --from-file=cluster1/cert-chain.pem
```

#### Deploying Istio, Apps, and Policies
```bash
# Deploy Istio
istioctl install --set profile=demo -y

# Deploy Apps
kubectl create ns foo
kubectl label namespace foo istio-injection=enabled
kubectl apply -f <(istioctl kube-inject -f microservices/deploy/service-mesh/sample/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f microservices/deploy/service-mesh/sample/sleep.yaml) -n foo

# Deploy Policy
kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
```
#### Verifying the Certificates

```bash
# Change the workspace directory
cd istio/security

sleep 10; kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt

# Create 4 files based on istio/security/httpbin-proxy-cert.txt
proxy-cert-1.pem
proxy-cert-2.pem
proxy-cert-3.pem
proxy-cert-4.pem

# Create a temporary directory
mkdir tmp

# Create compare files
openssl x509 -in certs/cluster1/root-cert.pem -text -noout > tmp/root-cert.crt.txt
openssl x509 -in ./proxy-cert-3.pem -text -noout > tmp/pod-root-cert.crt.txt

# Verify the results
diff -s tmp/root-cert.crt.txt tmp/pod-root-cert.crt.txt
```

Result
```bash
...
Files tmp/root-cert.crt.txt and tmp/pod-root-cert.crt.txt are identical
```

## Conclusion

In this session, we delved into the intricacies of Istio Security, exploring key aspects such as Authentication, Authorization, and Certificate Management. These fundamental components play a pivotal role in ensuring the robustness and integrity of your microservices architecture within an Istio Service Mesh.

- **Authentication:** Istio offers two powerful authentication mechanisms – Peer Authentication using mutual TLS (mTLS) and Request Authentication with JSON Web Tokens (JWT). The bidirectional authentication provided by mTLS enhances overall communication security, while JWTs offer a versatile means of transmitting identity information securely.

- **Authorization:** Istio's flexible approach to access control empowers you to govern inbound traffic with precision. By implementing authorization policies, you can control which services can communicate with each other and even specify the allowed HTTP methods, providing granular control over your microservices interactions.

- **Certificate Management:** Understanding the principles of Certificate Authorities (CAs) and Public Key Infrastructure (PKI) is essential for securing communications within your Istio Service Mesh. We walked through the generation of certificates, their storage in Istio, and the verification of these certificates, ensuring a secure foundation for your microservices.

As you progress through each session of our Istio Hands-On series, you're not only mastering the tools but also gaining insights into best practices for securing your microservices architecture. Stay tuned for our next session, where we explore Observability within Istio.

Happy coding and sailing through the seas of microservices with Istio! 🚀
