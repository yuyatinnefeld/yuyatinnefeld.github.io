---
layout: post
title: Kubernetes Debugging - Tips and Best Practices

tags: ["tech", "microservices"]
mathjax: true
---
Welcome to the comprehensive guide on Kubernetes debugging. Recently, I found myself immersed in lengthy debugging sessions due to typos in Kubernetes configurations, prompting the realization of the need for a structured approach. In this post, we'll explore the intricate world of Kubernetes troubleshooting, offering insights into best practices and strategies. By mastering these techniques, you'll save valuable time and ensure smoother operations across your varied tasks and projects. Let's dive in!

## Debugging Overview
Before delving into Kubernetes troubleshooting, let's discuss the fundamental process of debugging. It's a systematic approach that demands analytical thinking, problem-solving skills, and collaboration with team members. Here's a concise overview:

1. <b>Understanding the Issue: </b>Start by gathering information about the symptoms, including error messages and unexpected behavior.

2. <b>Reproducing the Problem: </b>Reproduce the issue to isolate its root cause and test potential solutions effectively.

3. <b>Prioritizing Debug Issues: </b> Prioritize debugging efforts based on the severity and impact of the issue on the system and users.

4. <b>Isolating the Root Cause: </b>Employ a process of elimination to isolate the underlying cause of the problem.

5. <b>Collaboration with Co-workers:</b> Embrace teamwork by collaborating with various team members, including developers, testers, and system administrators.

6. <b>Testing Solutions: </b>Develop and test potential solutions once the root cause is identified.

7. <b>Documentation: </b>Document the debugging process, including steps taken, findings, and implemented solutions, for future reference and knowledge sharing.

With a solid understanding of the general debugging process, we're now equipped to dive into Kubernetes debugging and troubleshooting.

## Visual Guide on Troubleshooting
<div class="aspect-ratio aspect-ratio--5x7"><a href="https://static.learnk8s.io/dac10c60ec5d2fe6bd3d3f8736cf0ce0.pdf"><img src="https://static.learnk8s.io/fae60444184ca7bd8c3698d866c24617.png" class="aspect-ratio--object" alt="A visual guide on troubleshooting Kubernetes deployments"></a></div>

You can also refer to the diagram provided by Daniele Polencic on the Learnk8s platform ([link](https://learnk8s.io/troubleshooting-deployments)). In this blog, debugging and troubleshooting are explained thoroughly, offering beginners step-by-step guidance.

## Check List

| NR  | Check Items | Description |
| --- | --- | --- |
| 1 | Gather Info | Collect info about cluster, nodes, pods, services. |
| 2 | YAML | Ensure the YAML manifest is valid and error-free. |
| 3 | Docker Image | Verify the correctness and functionality of Docker images. |
| 4 | Service Accessibility | Use `kubectl port-forward` to access services and validate connectivity. |
| 5 | Log Inspection | Inspect pod logs for error messages and anomalies with `kubectl log`. |
| 6 | Container Execution | Execute commands within containers for debugging |
| 7 | Container Debugging | Utilize `kubectl debug` for interactive troubleshooting |
| 8 | Health Check Configuration | Configure liveness and readiness probes to monitor container health. |
| 9 | Network Configuration | Check network configuration, firewall settings, and ensure correct connections. |
| 10 | Access Control Resolution | Resolve access issues for users and services, including permissions, policies, and TLS configurations. |

## Gather Info
Before diving into debugging, it's beneficial to gather information about the cluster, nodes, pods, services, and other relevant components.

```bash
# Check k8s cluster health
kubectl get componentstatus

# Check k8s nodes
kubectl get nodes

# Check pods
kubectl get pods  -o wide

# List all events
kubectl describe pod $POD | grep -A 8 "Events:"

# Better option
kubectl get events --field-selector involvedObject.kind=Pod | grep pod/frontend
```

##### Pods can have startup and runtime errors

Startup errors include:
- ImagePullBackoff
- ImageInspectError
- ErrImagePull
- ErrImageNeverPull
- RegistryUnavailable
- InvalidImageName

Runtime errors include:
- CrashLoopBackOff
- RunContainerError
- KillContainerError
- VerifyNonRootError
- RunInitContainerError
- CreatePodSandboxError
- ConfigPodSandboxError
- KillPodSandboxError
- SetupNetworkError
- TeardownNetworkError

## Ensure Kubernetes YAML manifest is correct
Before proceeding with any further actions, it's essential to ensure the validity of the Kubernetes manifest file af first. Occasionally, errors such as incorrect key or value names, or indentation issues, can render YAML-formatted code invalid. To verify the correctness of the manifest, you can employ the `--dry-run=client` flag, which allows you to perform a syntax check without actually applying the configuration changes to the cluster. This preemptive step helps prevent potential deployment failures and ensures smooth execution of subsequent actions.

```bash
kubectl create -f reviews.yaml --dry-run=client 
error: error parsing reviews.yaml: error converting YAML to JSON: yaml: line 10: mapping values are not allowed in this context
```

These tools assist in ensuring the correctness and validity of your Kubernetes YAML files, enhancing the reliability of your configurations:

- [validkube](https://validkube.com/)
- [yamllint](https://www.yamllint.com/)

## Check the Docker Image
When deploying applications in Kubernetes, ensuring the correctness of Docker images and service configurations is paramount. Let's walk through the process of validating these components within the Kubernetes environment.

1. Review Kubernetes YAML File
Begin by inspecting the Kubernetes YAML file to identify the Docker image and associated port number specified for the service. Here's an example snippet:

```bash
apiVersion: v1
kind: Service
...
  ports:
    - port: 9999
      targetPort: 9999
---
...
    spec:
      serviceAccountName: reviews-sa
      containers:
        - name: reviews-app
          image: yuyatinnefeld/microservice-reviews-app:1.0.0
```

2. Execute Docker Run
To validate the Docker image's functionality, execute the docker run command, mapping the container port to a local port:

```bash
docker run -p 9999:9999  yuyatinnefeld/microservice-reviews-app:1.0.0

curl localhost:9999
```

## Execute Port Forwarding
By following these steps, you can effectively verify the correctness of Docker images and ensure the availability of associated services within the Kubernetes cluster.

```bash
SVC=$(kubectl get svc -l service=frontend -o jsonpath="{.items[0].metadata.name}")
POD=$(kubectl get pod -l app=frontend-app -o jsonpath="{.items[0].metadata.name}")

# Check pod
kubectl port-forward pod/$POD 5555:5000
curl localhost:5555

# Check service
kubectl port-forward svc/$SVC 5000
curl localhost:5000
```

## Examining Pod Logs
Pod logs provide valuable insights into the behavior of applications running within Kubernetes pods. You can retrieve these logs using the kubectl logs command:

```bash
POD=$(kubectl get pod -l app=frontend-app -o jsonpath="{.items[0].metadata.name}")
kubectl logs $POD
```

By inspecting pod logs, you can identify errors, warnings, or other messages that help pinpoint issues within your application.

## Container Exec
In some cases, you may need to execute commands directly within a container to further investigate issues. Kubernetes provides the exec command for this purpose:

Using `exec -it`, you can run an interactive shell within the container, allowing you to execute commands and explore its environment.

However, it's essential to note that not all containers may contain the necessary tools for debugging. Attempting to run commands like ps or top within a container may result in errors if these tools are not installed:

```bash
kubectl exec -it $POD -- sh

# Error: Container doesn't contain 'ps' tool
kubectl exec -it $POD -- ps

# Error: Container doesn't contain 'top' tool
kubectl exec -it $POD -- top
```

A preferable alternative is `kubectl debug`. With this option, there's no need to manipulate the original pod. Instead, an ephemeral container is utilized for debugging purposes, ensuring that the original container remains untouched.

## Debug with Ephemeral Containers
Ephemeral containers are useful for interactive troubleshooting when `kubectl exec` is insufficient because a container has crashed or a container image doesn't include debugging utilities, such as with distroless images.

#### Deploying the Sample Application
Let's deploy a sample application to demonstrate debugging scenarios:


```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: server
data:
  server.js: |
    const http = require('http');
    const server = http.createServer((req, res) => {
      res.statusCode = 200;
      res.end('hello sample app!\n');
    });
    server.listen(8080, '0.0.0.0', () => console.log('Server running'));
---
apiVersion: v1
kind: Pod
metadata:
  name: sample-app
spec:
  containers:
    - name: sample-app
      image: gcr.io/distroless/nodejs:16
      ports: [ { name: http, containerPort: 8080 } ]
      args: [ "/app/server.js" ]
      volumeMounts: [ { mountPath: /app, name: server } ]
  volumes:
    - name: server
      configMap:
        name: server
EOF
```

#### Accessing the Sample App
Attempt to access the sample app, which may result in an error due to the absence of a shell within the Distroless container.

```bash
kubectl exec sample-app -it -- sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH: unknown
command terminated with exit code 126
```

#### Using Curl Image to Call the App

```bash
POD="sample-app"

kubectl debug $POD -it --image=curlimages/curl -- curl localhost:8080
> Defaulting debug container name to debugger-wj662.
> hello sample app!
```

#### Copying Sample App and Debugging from Sidecar Container
Create a copy of the `sample-app` and add a new Alpine container named `debug-sample-app` for debugging:

```bash
kubectl debug $POD -it --image=alpine --share-processes --copy-to debug-sample-app -- sh
```

Inspect the processes and files within the container:

```bash
ps x

PID=8
ls -l /proc/$PID/root/app

cat /proc/$PID/root/app/server.js
```

#### Cleaning Up the Debug Apps
```bash
kubectl delete pod debug-sample-app
```

## Configuring Health Checks for Kubernetes Pods
Ensuring the health and availability of containers running in Kubernetes is paramount for maintaining the reliability of your applications. 

It's crucial to configure both liveness and readiness probes in your Kubernetes deployment manifests. Without proper configuration, your containers may face issues such as endless restart loops or being prematurely included in service pools.

### Defining a Liveness Probe
The `livenessProbe` monitors the health of a container and determines if it should be restarted. It's essential to include this probe to ensure that unhealthy containers are automatically restarted.


```bash
spec:
  containers:
  ...
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
```

To verify the configuration, check the result using the following command:
```bash
POD="frontend-v1-65db68c8b-8vbjg"
kubectl describe $POD | grep -i liveness
```

### Defining a Readiness Probe
The `readinessProbe` checks if a container is ready to receive traffic. This probe ensures that only healthy containers are included in the service pool to avoid serving traffic to unhealthy instances.

```bash
spec:
  containers:
  ...
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 10
```

To verify the configuration, check the result using the following command:
```bash
POD="frontend-v1-65db68c8b-8vbjg"
kubectl describe $POD | grep -i readiness
```

## Conclusion
As Kubernetes continues to evolve and grow in popularity, mastering these debugging techniques becomes increasingly essential for maintaining the reliability and performance of microservices. With the knowledge gained from this blog post, readers are well-equipped to tackle the challenges of debugging in Kubernetes confidently.

I hope that the insights shared here empower you to overcome obstacles, optimize your Kubernetes deployments, and embark on a journey of continuous improvement in your containerized environments. Happy debugging!

Happy debugging and trouble shooting! 🚀