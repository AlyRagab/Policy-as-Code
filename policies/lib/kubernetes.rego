package lib.kubernetes

import future.keywords

default is_gatekeeper := false

# Detect if running in Gatekeeper
is_gatekeeper if {
	has_field(input, "review")
	has_field(input.review, "object")
}

# Normalize object reference
object = input if {
	not is_gatekeeper
}

object = input.review.object if {
	is_gatekeeper
}

# Format messages for Conftest or Gatekeeper
format(msg) = gatekeeper_format if {
	is_gatekeeper
	gatekeeper_format = {"msg": msg}
}

format(msg) = msg if {
	not is_gatekeeper
}

# Extract resource metadata
name = object.metadata.name
kind = object.kind

# Identify kinds
is_service if kind == "Service"
is_deployment if kind == "Deployment"
is_pod if kind == "Pod"

# Extract image name and tag
split_image(image) = [image_name, tag] if {
	parts := split(image, ":")
	count(parts) > 1
	tag := parts[count(parts) - 1]
	image_name := concat(":", array.slice(parts, 0, count(parts) - 1))
}

split_image(image) = [image, "latest"] if {
	not contains(image, ":")
}

# Extract containers and pods
pod_containers(pod) = all_containers if {
	keys := {"containers", "initContainers"}
	all_containers := [c | keys[k]; c := pod.spec[k][_]]
}

containers contains container if {
	pods[pod]
	all_containers := pod_containers(pod)
	container := all_containers[_]
}

containers contains container if {
	all_containers := pod_containers(object)
	container := all_containers[_]
}

pods contains pod if {
	is_deployment
	pod := object.spec.template
}

pods contains pod if {
	is_pod
	pod := object
}

# Extract volumes
volumes contains volume if {
	pods[pod]
	volume := pod.spec.volumes[_]
}

# Linux capabilities helpers
dropped_capability(container, cap) if {
	container.securityContext.capabilities.drop[_] == cap
}

added_capability(container, cap) if {
	container.securityContext.capabilities.add[_] == cap
}

# Field helpers
has_field(obj, field) if {
	obj[field]
}

get_field_value contains val if {
	not has_field(input.metadata, "name")
	val := "default-name"
}

get_field_value contains val if {
	has_field(input.metadata, "name")
	val := input.metadata.name
}

# Security context helpers
no_read_only_filesystem(c) if {
	not has_field(c, "securityContext")
} else if {
	has_field(c, "securityContext")
	not has_field(c.securityContext, "readOnlyRootFilesystem")
}

priviledge_escalation_allowed(c) if {
	has_field(c, "securityContext")
	c.securityContext.allowPrivilegeEscalation == true
}

missing_run_as_non_root(c) if {
	has_field(c, "securityContext")
	not has_field(c.securityContext, "runAsNonRoot")
}

low_uid(c) if {
	has_field(c, "securityContext")
	c.securityContext.runAsUser < 10000
}
