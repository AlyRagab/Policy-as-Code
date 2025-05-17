package images

import data.lib.kubernetes

approved_registries := {"4444444444.dkr.ecr.me-south-1"}

# Violation: Image must include a tag
violation contains msg if {
    c1 := kubernetes.containers[_]
    not contains(c1.image, ":")
    msg := kubernetes.format(sprintf(
        "%s in the %s %s does not specify a container image tag (%s)",
        [c1.name, kubernetes.kind, kubernetes.name, c1.image]
    ))
}

# Violation: Use of 'latest' tag is discouraged
violation contains msg if {
    c2 := kubernetes.containers[_]
    parts := kubernetes.split_image(c2.image)
    count(parts) == 2
    parts[1] == "latest"
    msg := kubernetes.format(sprintf(
        "%s in the %s %s uses an image with the 'latest' tag (%s)",
        [c2.name, kubernetes.kind, kubernetes.name, c2.image]
    ))
}

# Violation: Image must be from an approved registry
violation contains msg if {
    c3 := kubernetes.containers[_]
    not approved_registry(c3.image)
    msg := kubernetes.format(sprintf(
        "The image '%v' in %s/%s is not from an approved registry",
        [c3.image, kubernetes.kind, kubernetes.name]
    ))
}

# Helper: Registry approval check
approved_registry(image) if {
    p1 := approved_registries[_]
    startswith(image, p1)
}
