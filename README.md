# Task Overview

Cartline's catalog API is deployed locally but production-meaningful requests through its Kubernetes Service do not satisfy the availability contract. Operators also see misleading health behavior, inconsistent runtime configuration, and unreliable backend discovery during application initialization. These conditions can remove catalog traffic or cause unsafe workload handling during routine operations. A healthy solution must continue serving correctly after normal restart or promotion activity.

# Objectives

- API consumers should receive an available catalog response for the configured market.
- Platform health signals should accurately represent process and dependency availability.
- Customer traffic should reach a fully ready backend during routine operations.
- Operators should observe deployed runtime configuration consistently in logs and responses.
- Workload initialization should complete safely without premature failure handling.

# Helpful Tips

- Review object relationships and compare declared workload identity with discovered backends.
- Analyze events and conditions over the complete application initialization period.
- Consider whether every health signal represents the same kind of failure.
- Explore runtime logs alongside the configuration delivered to the running container.
- Think about API status codes as part of the client-facing health contract.

# How to Verify

- Run the provided reproduction check and observe it fail before remediation and pass afterward.
- Watch the workload converge until every desired replica is available for traffic.
- Exercise the Service path and observe the configured market in a successful catalog response.
- Inspect health responses and observe truthful process and dependency states.
- Perform a rolling restart and verify availability returns without excessive container restarts.
