# Policy-as-Code
Open Policy Agent - Gatekeeper

This repository contains Open Policy Agent (OPA) policies for enforcing Kubernetes security and compliance best practices. The rules are structured using Rego and intended to be run using tools like Conftest or OPA Gatekeeper.


# Rules Summary

```sh
| Policy File                       | Rule Description                                        | Enforcement         |
| --------------------------------- | ------------------------------------------------------- | ------------------- |
| `workloads/resource-limits.rego`  | Enforce memory limits on containers                     | Violation           |
| `workloads/security-context.rego` | Block privileged containers, UID < 10000                | Violation           |
| `workloads/security-context.rego` | Enforce `runAsNonRoot: true`, drop all capabilities     | Warning             |
| `workloads/security-context.rego` | Disallow `CAP_SYS_ADMIN` capability                     | Violation           |
| `workloads/security-context.rego` | Enforce `readOnlyRootFilesystem`                        | Warning             |
| `workloads/security-context.rego` | Disallow privilege escalation                           | Warning             |
| `workloads/volume-mounts.rego`    | Disallow Docker socket mounts                           | Violation           |
| `workloads/volume-mounts.rego`    | Disallow hostIPC, hostPID, hostNetwork, and hostAliases | Violation           |
| `images/image-validation.rego`    | Block use of untagged images and `:latest`              | Violation / Warning |
| `images/image-validation.rego`    | Restrict allowed registries (e.g., AWS/GCP ECR only)    | Violation           |
```

## Prerequisites

To get started, install the following tools:
  - [Conftest](https://github.com/open-policy-agent/conftest)
  - [OPA CLI](https://www.openpolicyagent.org/docs/latest/#running-opa)
  - [Helm](https://helm.sh/)

## Running Conftest Locally

- Test Kubernetes manifests:

```sh
conftest test deployment.yaml --policy ./policies
```

- Test Kubernetes Helm Chart:

To test a Helm chart using Conftest, you first need to render the chart as Kubernetes manifests using Helm’s template command

```sh
helm template testapp ./charts/testapp > rendered.yaml
conftest test rendered.yaml --policy ./policies
```

## Gatekeeper Integration

We can integrate these policies with Kubernetes using OPA Gatekeeper. Wrap rules inside ConstraintTemplates and Constraints

Example ConstraintTemplate:

```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredmemlimit
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredMemLimit
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredmemlimit

        violation[{
          "msg": msg,
          "details": {"container": container.name}
        }] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.memory
          msg := sprintf("Container %s must set memory limit", [container.name])
        }
```

## List of Policies in this repo:

- A policy to prevent deploying containers without a memory limit set
- A policy to prevent adding the CAP_SYS_ADMIN Linux capability
- A policy to prevent deploying privileged containers within a pod
- A policy to require user IDs (runAsUser) greater than or equal to 10000
- A policy to ensure containers drop all Linux capabilities
- A policy to enforce usage of readOnlyRootFilesystem: true
- A policy to block privilege escalation in containers
- A policy to ensure containers set runAsNonRoot: true
- A policy to prevent the use of hostIPC, hostNetwork, hostPID, and hostAliases
- A policy to prevent mounting the Docker socket (/var/run/docker.sock)
- A policy to ensure all container images have explicit tags
- A policy to block use of container images tagged with latest
- A policy to restrict image pulls to approved registries (e.g., AWS/GCP Registry)


## References:
- [Open Policy Agent](https://www.openpolicyagent.org/)
- [Conftest](https://www.conftest.dev/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [KubeSec](https://kubesec.io/)

