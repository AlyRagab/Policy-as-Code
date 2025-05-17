package main

import data.lib.kubernetes
import future.keywords

# === Violation: Containers must define memory limits ===
violation contains msg if {
	kubernetes.containers[container]
	not container.resources.limits.memory
	msg := kubernetes.format(sprintf("%s in the %s %s does not have a memory limit set", [container.name, kubernetes.kind, kubernetes.name]))
}

# === Violation: Containers must define CPU limits ===
violation contains msg if {
	kubernetes.containers[container]
	not container.resources.limits.cpu
	msg := kubernetes.format(sprintf("%s in the %s %s does not have a CPU limit set", [container.name, kubernetes.kind, kubernetes.name]))
}
