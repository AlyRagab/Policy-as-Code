package workloads.security_context

import data.lib.kubernetes
import future.keywords

# Containers must not run in privileged mode
violation contains msg if {
	kubernetes.containers[container]
	container.securityContext.privileged == true
	msg := kubernetes.format(sprintf("%s in the %s %s is privileged", [container.name, kubernetes.kind, kubernetes.name]))
}

# Containers must not add CAP_SYS_ADMIN
violation contains msg if {
	kubernetes.containers[container]
	kubernetes.added_capability(container, "CAP_SYS_ADMIN")
	msg := kubernetes.format(sprintf("%s in the %s %s has SYS_ADMIN capabilities", [container.name, kubernetes.kind, kubernetes.name]))
}

# Containers must run as UID >= 10000
violation contains msg if {
	kubernetes.containers[container]
	container.securityContext.runAsUser < 10000
	msg := kubernetes.format(sprintf("%s in the %s %s is running as UID less than 10000", [container.name, kubernetes.kind, kubernetes.name]))
}

# Containers should set runAsNonRoot = true
warn contains msg if {
	kubernetes.containers[container]
	not container.securityContext.runAsNonRoot == true
	msg := kubernetes.format(sprintf("%s in the %s %s is not explicitly set to run as non-root", [container.name, kubernetes.kind, kubernetes.name]))
}

# Containers should not allow privilege escalation
warn contains msg if {
	kubernetes.containers[container]
	kubernetes.priviledge_escalation_allowed(container)
	msg := kubernetes.format(sprintf("%s in the %s %s allows privilege escalation", [container.name, kubernetes.kind, kubernetes.name]))
}

# Containers should drop all Linux capabilities
warn contains msg if {
	kubernetes.containers[container]
	not kubernetes.dropped_capability(container, "all")
	msg := kubernetes.format(sprintf("%s in the %s %s doesn't drop all capabilities", [container.name, kubernetes.kind, kubernetes.name]))
}

# Containers should use read-only root filesystem
warn contains msg if {
	kubernetes.containers[container]
	kubernetes.no_read_only_filesystem(container)
	msg := kubernetes.format(sprintf("%s in the %s %s is not using a read-only root filesystem", [container.name, kubernetes.kind, kubernetes.name]))
}
