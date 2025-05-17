# Kubernetes Gatekeeper Policies

This directory contains Open Policy Agent (OPA) Gatekeeper policies for Kubernetes. These policies help enforce security, compliance, and best practices in your Kubernetes cluster.

## Constraint Templates vs Constraints

### Constraint Templates
- Located in the `templates/` directory
- Define the policy logic using Rego (OPA's policy language)
- Create Custom Resource Definitions (CRDs) for the constraints
- Define the schema for constraint parameters
- Are reusable across multiple constraints

### Constraints
- Located in the `constraints/` directory
- Are instances of constraint templates
- Define the scope (which resources to check)
- Specify the parameters for the policy
- Define the enforcement action (deny, warn, etc.)

## Available Policies

### 1. Allowed Repositories (k8sallowedrepos)
**Template**: `templates/k8sallowedrepos.yaml`
**Constraint**: `constraints/allowed-repositories.yaml`

Enforces that container images can only be pulled from allowed repositories. This helps prevent the use of untrusted or unauthorized container registries.

**Parameters**:
- `repos`: List of allowed container registry URLs
- `excludedNamespaces`: Namespaces to exclude from this policy

### 2. Required Resource Limits (k8srequiredresourcelimits)
**Template**: `templates/k8srequiredresourcelimits.yaml`
**Constraint**: `constraints/required-resource-limits.yaml`

Ensures that containers have specified resource limits set. This helps prevent resource exhaustion and ensures fair resource allocation.

**Parameters**:
- `limits`: Array of required resource types (e.g., "memory")

**Scope**:
- Pods
- Deployments
- StatefulSets
- DaemonSets
- Jobs
- CronJobs

### 3. Required Network Policy (k8srequirednetworkpolicy)
**Template**: `templates/k8srequirednetworkpolicy.yaml`
**Constraint**: `constraints/required-network-policy.yaml`

Enforces that namespaces have required labels for network policy management. This helps ensure proper network isolation and security.

**Parameters**:
- `labels`: Array of required label keys

**Scope**:
- Namespaces

### 4. Required Security Context (k8srequiredsecuritycontext)
**Template**: `templates/k8srequiredsecuritycontext.yaml`
**Constraint**: `constraints/required-security-context.yaml`

Enforces security context settings for containers. This helps ensure containers run with appropriate security settings.

**Parameters**:
- `runAsNonRoot`: Whether containers must run as non-root
- `allowPrivilegeEscalation`: Whether containers can escalate privileges

**Scope**:
- Pods
- Deployments
- StatefulSets
- DaemonSets
- Jobs
- CronJobs

## Usage

1. Apply the constraint templates:
```bash
kubectl apply -f kubernetes-gatekeeper/templates/
```

2. Apply the constraints:
```bash
kubectl apply -f kubernetes-gatekeeper/constraints/
```

## Policy Enforcement

All policies are configured with `enforcementAction: deny` by default, which means they will prevent the creation or modification of resources that violate the policies. The `kube-system` namespace is excluded from all policies to ensure system components can function properly.

## Testing Policies

You can test the policies by attempting to create resources that violate them. For example:

1. Try creating a pod with an image from a non-allowed repository
2. Try creating a pod without memory limits
3. Try creating a namespace without the required network-policy label
4. Try creating a pod without the required security context settings

The policies will prevent these operations and provide clear error messages about what needs to be fixed.

## Prerequisites

- Kubernetes cluster (v1.16+)
- Gatekeeper installed in your cluster
- kubectl configured to communicate with your cluster

## Installation

1. Install Gatekeeper in your cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

2. Apply all policies:
```bash
kubectl apply -f kubernetes-gatekeeper/
```

## Policies

### 1. Allowed Repositories

**Constraint Template:** `K8sAllowedRepos`

**Constraint:** `allowed-repositories`

**Description:**  
This policy ensures that only images from specified repositories are allowed. It applies to Pods, Deployments, StatefulSets, DaemonSets, Jobs, and CronJobs in all namespaces except `kube-system`.

**Example Constraint:**
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-repositories
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet", "DaemonSet"]
      - apiGroups: ["batch"]
        kinds: ["Job", "CronJob"]
    namespaceSelector:
      matchExpressions:
        - key: kubernetes.io/metadata.name
          operator: NotIn
          values:
            - kube-system
  parameters:
    repos:
      - "4444444444.dkr.ecr.me-south-1.amazonaws.com"
      - "docker.io/library"
      - "quay.io"
      - "registry.k8s.io"
      - "gcr.io"
```

**Installation:**
```sh
kubectl apply -f kubernetes-gatekeeper/templates/k8sallowedrepos.yaml
kubectl apply -f kubernetes-gatekeeper/constraints/allowed-repositories.yaml
```

**Testing:**
- Create a Pod in a non-`kube-system` namespace with an image from a disallowed repository. It should be denied.
- Create a Pod in the `kube-system` namespace with an image from a disallowed repository. It should be allowed.

### 2. Resource Limits

**Constraint Template:** `K8sRequiredResourceLimits`

**Description:**  
This policy ensures that all containers have CPU and memory limits defined.

**Example Constraint:**
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredResourceLimits
metadata:
  name: required-resource-limits
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    cpu: "500m"
    memory: "512Mi"
```

**Installation:**
```sh
kubectl apply -f kubernetes-gatekeeper/templates/k8srequiredresourcelimits.yaml
kubectl apply -f kubernetes-gatekeeper/constraints/required-resource-limits.yaml
```

### 3. Network Policy

**Constraint Template:** `K8sRequiredNetworkPolicy`

**Description:**  
This policy ensures that all namespaces have a NetworkPolicy defined.

**Example Constraint:**
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredNetworkPolicy
metadata:
  name: required-network-policy
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels:
      - key: "network-policy"
        allowedRegex: "^(enabled|required)$"
```

**Installation:**
```sh
kubectl apply -f kubernetes-gatekeeper/templates/k8srequirednetworkpolicy.yaml
kubectl apply -f kubernetes-gatekeeper/constraints/required-network-policy.yaml
```

### 4. Security Context

**Constraint Template:** `K8sRequiredSecurityContext`

**Description:**  
This policy ensures that all containers run as non-root users and have privilege escalation disabled.

**Example Constraint:**
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredSecurityContext
metadata:
  name: required-security-context
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    runAsNonRoot: true
    allowPrivilegeEscalation: false
```

**Installation:**
```sh
kubectl apply -f kubernetes-gatekeeper/templates/k8srequiredsecuritycontext.yaml
kubectl apply -f kubernetes-gatekeeper/constraints/required-security-context.yaml
```

## Available Policies

### 1. Container Registry Policy (`container-registry.yaml`)
Enforces the use of approved container registries.

**Features:**
- Restricts container images to specific registries
- Currently allows:
  - ECR: `4444444444.dkr.ecr.me-south-1.amazonaws.com`
  - Docker Hub: `docker.io/library`
  - Quay.io: `quay.io`

**Applies to:**
- Pods
- Deployments
- StatefulSets
- DaemonSets
- Jobs
- CronJobs

### 2. Resource Limits Policy (`resource-limits.yaml`)
Ensures proper resource management for all workloads.

**Features:**
- Enforces CPU and memory limits
- Enforces CPU and memory requests
- Prevents resource exhaustion

**Applies to:**
- Pods
- Deployments
- StatefulSets
- DaemonSets
- Jobs
- CronJobs

### 3. Network Policy (`network-policy.yaml`)
Enforces network security requirements.

**Features:**
- Requires network policy labels
- Requires network policy annotations
- Ensures proper network isolation

**Applies to:**
- Namespaces

### 4. Security Context (`security-context.yaml`)
Enforces security best practices for containers.

**Features:**
- Requires non-root users
- Disables privilege escalation
- Drops all capabilities
- Enhances container security

**Applies to:**
- Pods
- Deployments
- StatefulSets
- DaemonSets

### 5. Labels and Annotations (`labels-annotations.yaml`)
Enforces Kubernetes recommended labels and annotations.

**Features:**
- Requires standard Kubernetes labels
- Enforces label format using regex
- Improves resource organization and management

**Required Labels:**
- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/version`
- `app.kubernetes.io/component`
- `app.kubernetes.io/part-of`
- `app.kubernetes.io/managed-by`

**Applies to:**
- Pods
- Services
- Namespaces
- Deployments
- StatefulSets
- DaemonSets

## Usage Examples

### Example 1: Basic Deployment with All Policies Satisfied

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  labels:
    app.kubernetes.io/name: example-app
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: frontend
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  template:
    spec:
      containers:
      - name: app
        image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/example-app:1.0.0
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
```

### Example 2: StatefulSet with Multiple Containers

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
  labels:
    app.kubernetes.io/name: postgres
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "14.5"
    app.kubernetes.io/component: database
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  serviceName: postgres
  replicas: 3
  template:
    spec:
      containers:
      - name: postgres
        image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/postgres:14.5
        resources:
          limits:
            cpu: "1000m"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "512Mi"
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
      - name: metrics-exporter
        image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/postgres-exporter:latest
        resources:
          limits:
            cpu: "200m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
```

### Example 3: CronJob with Init Container

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
  labels:
    app.kubernetes.io/name: backup
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: backup
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          initContainers:
          - name: init-backup
            image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/backup-init:1.0.0
            resources:
              limits:
                cpu: "200m"
                memory: "256Mi"
              requests:
                cpu: "100m"
                memory: "128Mi"
            securityContext:
              runAsNonRoot: true
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
          containers:
          - name: backup
            image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/backup:1.0.0
            resources:
              limits:
                cpu: "500m"
                memory: "512Mi"
              requests:
                cpu: "200m"
                memory: "256Mi"
            securityContext:
              runAsNonRoot: true
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                - ALL
```

### Example 4: Namespace with Network Policy

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-app
  labels:
    app.kubernetes.io/name: secure-app
    app.kubernetes.io/instance: prod
    network-policy: enabled
  annotations:
    network-policy/type: "restricted"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Example 5: Service with Required Labels

```yaml
apiVersion: v1
kind: Service
metadata:
  name: example-service
  labels:
    app.kubernetes.io/name: example-service
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  selector:
    app.kubernetes.io/name: example-app
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

### Example 6: DaemonSet for Logging Agent

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
  labels:
    app.kubernetes.io/name: logging-agent
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: logging
    app.kubernetes.io/part-of: monitoring
    app.kubernetes.io/managed-by: helm
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: logging-agent
  template:
    metadata:
      labels:
        app.kubernetes.io/name: logging-agent
    spec:
      containers:
      - name: fluentd
        image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/fluentd:1.0.0
        resources:
          limits:
            cpu: "200m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### Example 7: Job with ConfigMap and Secret

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: job-config
  labels:
    app.kubernetes.io/name: job-config
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: config
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
data:
  config.yaml: |
    environment: production
    logLevel: info
---
apiVersion: v1
kind: Secret
metadata:
  name: job-secret
  labels:
    app.kubernetes.io/name: job-secret
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: secret
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
type: Opaque
data:
  api-key: base64encodedkey
---
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processor
  labels:
    app.kubernetes.io/name: data-processor
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: processor
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  template:
    spec:
      containers:
      - name: processor
        image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/data-processor:1.0.0
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
        env:
        - name: CONFIG_FILE
          value: /etc/config/config.yaml
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: job-secret
              key: api-key
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: job-config
      restartPolicy: Never
```

### Example 8: PersistentVolumeClaim with Storage Class

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  labels:
    app.kubernetes.io/name: data-pvc
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: storage
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp2
```

### Example 9: HorizontalPodAutoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: example-hpa
  labels:
    app.kubernetes.io/name: example-hpa
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: autoscaling
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: example-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Example 10: Ingress with TLS

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  labels:
    app.kubernetes.io/name: example-ingress
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: ingress
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

### Example 11: PodDisruptionBudget with ServiceAccount

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: example-pdb
  labels:
    app.kubernetes.io/name: example-pdb
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: availability
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: example-app
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: example-sa
  labels:
    app.kubernetes.io/name: example-sa
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: security
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
```

### Example 12: Role and RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  labels:
    app.kubernetes.io/name: pod-reader
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: rbac
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  labels:
    app.kubernetes.io/name: read-pods
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: rbac
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
subjects:
- kind: ServiceAccount
  name: example-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Example 13: PodSecurityPolicy

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  labels:
    app.kubernetes.io/name: restricted-psp
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: security
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  privileged: false
  seLinux:
    rule: RunAsAny
  runAsUser:
    rule: MustRunAsNonRoot
  fsGroup:
    rule: MustRunAs
    ranges:
    - min: 1
      max: 65535
  volumes:
  - 'configMap'
  - 'emptyDir'
  - 'projected'
  - 'secret'
  - 'downwardAPI'
  - 'persistentVolumeClaim'
```

### Example 14: ResourceQuota and LimitRange

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  labels:
    app.kubernetes.io/name: compute-resources
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: quota
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 4Gi
    limits.cpu: "8"
    limits.memory: 8Gi
---
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  labels:
    app.kubernetes.io/name: resource-limits
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: limits
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 200m
      memory: 256Mi
    type: Container
```

### Example 15: PriorityClass and Pod Priority

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
  labels:
    app.kubernetes.io/name: high-priority
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: scheduling
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
value: 1000000
globalDefault: false
description: "This priority class should be used for high priority pods only."
---
apiVersion: v1
kind: Pod
metadata:
  name: high-priority-pod
  labels:
    app.kubernetes.io/name: high-priority-pod
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: app
    app.kubernetes.io/part-of: example
    app.kubernetes.io/managed-by: helm
spec:
  priorityClassName: high-priority
  containers:
  - name: app
    image: 4444444444.dkr.ecr.me-south-1.amazonaws.com/example-app:1.0.0
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "200m"
        memory: "256Mi"
    securityContext:
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

## Troubleshooting

### Common Issues

1. **Policy Violations**
   - Check the Gatekeeper audit logs:
   ```bash
   kubectl logs -n gatekeeper-system -l control-plane=controller-manager
   ```

2. **Policy Not Applied**
   - Verify Gatekeeper installation:
   ```bash
   kubectl get pods -n gatekeeper-system
   ```
   - Check constraint status:
   ```bash
   kubectl get constraints
   ```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details. 