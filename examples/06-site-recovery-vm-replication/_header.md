# Site Recovery VM Replication Example

This example demonstrates cross-region Azure Site Recovery replication for Windows virtual machines using a pair of Recovery Services Vault deployments and the Site Recovery resources required to connect them.

## What this example shows

- Creating source and target resource groups, networks, and vaults for a full ASR topology
- Configuring Site Recovery fabrics, protection containers, container mapping, and network mapping
- Creating source VMs and enabling replication to a secondary region
- A working replicated VM configuration that defaults the target VM size to a source-compatible SKU to avoid ASR disk-controller compatibility failures

## Notes Before You Run It

- This is the heaviest example in the repository and can take a long time to apply
- The example currently focuses on reliable OS-disk replication for the protected VMs
- You need permissions to create Recovery Services, networking, storage, compute, and role assignment resources in both regions
