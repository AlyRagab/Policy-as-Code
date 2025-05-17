package workloads.volume_mounts

import data.lib.kubernetes
import future.keywords

# Prevent mounting the Docker socket
violation contains msg if {
	kubernetes.volumes[volume]
	volume.hostpath.path == "/var/run/docker.sock"
	msg := kubernetes.format(sprintf("The %s %s is mounting the Docker socket", [kubernetes.kind, kubernetes.name]))
}

# Prevent sharing hostIPC
violation contains msg if {
	kubernetes.pods[pod]
	pod.spec.hostIPC == true
	msg := kubernetes.format(sprintf("The %s %s is sharing the host IPC namespace", [kubernetes.kind, kubernetes.name]))
}

# Prevent sharing hostPID
violation contains msg if {
	kubernetes.pods[pod]
	pod.spec.hostPID == true
	msg := kubernetes.format(sprintf("The %s %s is sharing the host PID namespace", [kubernetes.kind, kubernetes.name]))
}

# Prevent sharing hostNetwork
violation contains msg if {
	kubernetes.pods[pod]
	pod.spec.hostNetwork == true
	msg := kubernetes.format(sprintf("The %s %s is connected to the host network", [kubernetes.kind, kubernetes.name]))
}

# Prevent use of hostAliases
violation contains msg if {
	kubernetes.pods[pod]
	pod.spec.hostAliases
	msg := kubernetes.format(sprintf("The %s %s is managing host aliases", [kubernetes.kind, kubernetes.name]))
}
