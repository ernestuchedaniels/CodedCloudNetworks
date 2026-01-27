# AWS Cloud WAN Migration POC - TGW Peering to Cloud WAN

## Overview

This POC demonstrates a production-ready migration path from AWS Transit Gateway (TGW) inter-region peering to AWS Cloud WAN. The architecture supports gradual, zero-downtime migration while maintaining end-to-end network segmentation between Production (PE) and Non-Production (NPE) environments.

## Current Architecture Status

### Phase 1: TGW Peering (Current - Validated ✅)
- Full mesh TGW peering across 4 regions
- PE and NPE environments completely isolated
- Static routes for cross-region connectivity
- Bidirectional connectivity validated across all regions

### Phase 2: Cloud WAN Integration (Deployed - Ready for Migration)
- Cloud WAN global network deployed with PE/NPE segments
- TGW-to-Cloud WAN peering established in each region
- Migration framework in place with per-VPC control flags
- Ready for atomic region migration

## Network Topology

### Multi-Region Architecture

**Regions:**
- us-east-1 (PE: 10.1.0.0/16, NPE: 10.101.0.0/16)
- us-west-2 (PE: 10.2.0.0/16, NPE: 10.102.0.0/16)
- eu-west-1 (PE: 10.3.0.0/16, NPE: 10.103.0.0/16)
- ap-southeast-1 (PE: 10.4.0.0/16, NPE: 10.104.0.0/16)

### Per-Region TGW Route Table Design

Each region has **5 route tables** for complete isolation:

**PE Environment:**
- `pe-spoke-rt` - VPC attachments associated here, receives local + remote routes
- `pe-cw-export-rt` - Exports only local PE routes to Cloud WAN PE segment

**NPE Environment:**
- `npe-spoke-rt` - VPC attachments associated here, receives local + remote routes
- `npe-cw-export-rt` - Exports only local NPE routes to Cloud WAN NPE segment

**Shared:**
- `peer-ingress-rt` - All peering attachments associated here, routes to local VPCs

**Note:** There is no separate `peer-export-rt`. The spoke route tables serve dual purpose - they handle both VPC workload routing AND act as the source for TGW peering routes (since they already contain all necessary routes).

### Route Flow Architecture

**Outbound (VPC → Remote Region):**
1. VPC route table → TGW (or Cloud WAN during migration)
2. VPC attachment associated with spoke_rt
3. spoke_rt has static route: `10.4.0.0/16 → peering-attachment-id`
4. Traffic exits via peering attachment to remote region TGW
5. Remote TGW receives traffic on peering attachment
6. **Peering attachment is associated with peer_ingress_rt**
7. peer_ingress_rt has static route: `10.4.0.0/16 → vpc-attachment-id`
8. Traffic forwarded to VPC attachment → Remote VPC

**Inbound (Remote Region → VPC):**
1. Remote VPC → Remote TGW spoke_rt
2. Remote spoke_rt has static route: `10.2.0.0/16 → peering-attachment-id`
3. Traffic exits via peering attachment to local region TGW
4. Local TGW receives traffic on peering attachment
5. **Peering attachment is associated with peer_ingress_rt**
6. peer_ingress_rt has static route: `10.2.0.0/16 → vpc-attachment-id`
7. Traffic forwarded to VPC attachment → Local VPC

**Key Insight:** The peer_ingress_rt acts as the "landing zone" for all inter-region traffic. When a peering attachment receives traffic from a remote region, the TGW consults the peer_ingress_rt (because that's what the peering attachment is associated with) to determine where to forward the traffic. The static routes in peer_ingress_rt point to the local VPC attachments, completing the path.

## Key Design Decisions

### 1. Separate peer_ingress_rt for Peering Attachments
**Why:** Peering attachments need different routing behavior than VPC attachments. By associating all peering attachments with a dedicated route table, we can:
- Control inbound traffic from remote regions independently
- Add static routes to local VPCs without affecting outbound routing
- Maintain clean separation between ingress and egress routing

**How it works:**
- All 6 peering attachments (3 per region in full mesh) are associated with peer_ingress_rt
- When traffic arrives from a remote region via peering, TGW consults peer_ingress_rt
- peer_ingress_rt contains static routes pointing to local VPC attachments
- Example: `10.4.0.0/16 → vpc-attachment-04f8e2983a85f87fd`
- This allows the peering attachment to deliver traffic to the correct local VPC

### 2. Static Routes Instead of Propagation
**Why:** Static routes provide:
- Explicit control over routing paths
- No risk of route leakage between segments
- Predictable routing behavior during migration
- Easy troubleshooting and validation

### 3. Spoke Route Table Reuse for Peering Export
**Why:** The spoke_rt already has all necessary routes (local VPCs + remote destinations). Rather than duplicating routes, we use the spoke_rt as the peer_export_rt, simplifying management.

### 4. VPC Attachment Association to spoke_rt
**Why:** VPC attachments must be associated with spoke_rt (not peer_ingress_rt) because:
- Outbound traffic from VPCs needs to consult spoke_rt for routing decisions
- spoke_rt contains both local VPC routes and remote peering routes
- This enables VPCs to reach both local and remote destinations

## Migration Strategy

### Atomic Region Migration (Recommended)

To avoid asymmetric routing with stateful firewalls, migrate entire regions atomically:

**Migration Control:**
- `pe_use_cloudwan` - Boolean flag per region to switch PE VPCs to Cloud WAN
- `npe_use_cloudwan` - Boolean flag per region to switch NPE VPCs to Cloud WAN

**Migration Sequence:**
1. Migrate us-west-2 (both PE and NPE simultaneously)
2. Validate connectivity for 24-48 hours
3. Migrate us-east-1
4. Migrate eu-west-1
5. Migrate ap-southeast-1
6. Decommission TGW peering

**Why Atomic Region Migration:**
- Prevents asymmetric routing (forward via Cloud WAN, return via TGW)
- Maintains stateful firewall compatibility
- Simplifies rollback (single flag flip)
- Clear migration boundaries

### Symmetric Routing Guarantee

When a region is migrated:
- All traffic TO that region uses TGW-CW peering bridge
- All traffic FROM that region uses TGW-CW peering bridge
- Non-migrated regions continue using TGW peering
- No asymmetric flows occur

## Validated Connectivity

### PE Environment (Production)
- ✅ us-west-2 ↔ ap-southeast-1 (160ms, 0% loss)
- ✅ us-west-2 ↔ us-east-1 (56ms, 0% loss)
- ✅ us-west-2 ↔ eu-west-1 (117ms, 0% loss)
- ✅ eu-west-1 ↔ us-west-2 (116ms, 0% loss)

### NPE Environment (Non-Production)
- ✅ us-west-2 ↔ eu-west-1 (118ms, 0% loss)

### Segmentation Validation
- ✅ PE cannot reach NPE (complete isolation)
- ✅ NPE cannot reach PE (complete isolation)
- ✅ TTL=252 confirms TGW hop traversal

## Infrastructure Components

### Modules

**tgw** - Creates regional TGW with 7 route tables per region
**tgw-peering** - Establishes full mesh peering and static routes
**tgw-routing** - Manages VPC attachment associations and propagations
**tgw-cloudwan-integration** - Creates TGW-to-Cloud WAN peering per region
**cloudwan** - Deploys global Cloud WAN with PE/NPE segments
**vpc** - Creates VPCs with dual-attachment (TGW + Cloud WAN)
**migration** - (Future) Orchestrates migration workflow

### Key Resources Per Region

- 1 Transit Gateway
- 5 TGW Route Tables (pe-spoke, pe-cw-export, npe-spoke, npe-cw-export, peer-ingress)
- 6 TGW Peering Attachments (full mesh to 3 other regions)
- 1 TGW-to-Cloud WAN Peering Attachment
- 2 VPCs (PE + NPE)
- 2 VPC-to-TGW Attachments
- 2 VPC-to-Cloud WAN Attachments
- 2 EC2 Test Instances

## Deployment

### Prerequisites
- AWS CLI configured with credentials
- Terraform >= 1.0
- 4 AWS regions enabled in account

### Deploy Infrastructure

```bash
cd cloudwan-poc
terraform init
terraform plan
terraform apply
```

### Validate TGW Peering

```bash
# SSH to test instance
ssh ec2-user@<public-ip>

# Test cross-region connectivity
ping <remote-region-private-ip>
```

### Migrate to Cloud WAN

```bash
# Edit terraform.tfvars
pe_use_cloudwan = true   # Migrate PE
npe_use_cloudwan = true  # Migrate NPE

terraform apply
```

## Troubleshooting

### Connectivity Issues

**Check VPC Route Tables:**
Verify routes point to TGW (pre-migration) or Cloud WAN (post-migration)

**Check TGW Routes:**
Verify static routes exist in spoke_rt and peer_ingress_rt

**Check Peering Associations:**
Verify peering attachments are associated with peer_ingress_rt

**Check VPC Associations:**
Verify VPC attachments are associated with spoke_rt

### Asymmetric Routing

If experiencing asymmetric routing during migration:
- Verify entire region migrated atomically (both PE and NPE)
- Check that non-migrated regions still use TGW peering
- Validate firewall logs for symmetric flows

## Cost Optimization

**Current (TGW Peering):**
- TGW attachments: ~$0.05/hour per attachment × 16 attachments = $0.80/hour
- TGW peering: ~$0.05/hour per peering × 6 peerings = $0.30/hour
- Data transfer: ~$0.02/GB inter-region
- **Total: ~$1.10/hour + data transfer**

**Post-Migration (Cloud WAN):**
- Cloud WAN attachments: ~$0.05/hour per attachment × 8 attachments = $0.40/hour
- Cloud WAN data transfer: ~$0.05/GB inter-region
- **Total: ~$0.40/hour + data transfer**

**Savings: ~64% reduction in fixed costs**

## Security Considerations

- All traffic remains within AWS backbone
- PE/NPE segmentation enforced at TGW and Cloud WAN layers
- Security groups control instance-level access
- NACLs provide subnet-level filtering
- No internet gateway in attachment subnets

## Limitations

- Maximum 5,000 routes per TGW route table
- Maximum 50 TGW peering attachments per TGW
- Cloud WAN supports up to 20 segments
- VPC can attach to only 1 TGW per region

## Future Enhancements

- Automated migration orchestration module
- Route validation testing framework
- CloudWatch dashboards for migration monitoring
- Automated rollback on connectivity failure
- Multi-account support with RAM sharing

## References

- [AWS Cloud WAN Documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/)
- [AWS Transit Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [TGW to Cloud WAN Migration Patterns](https://aws.amazon.com/blogs/networking-and-content-delivery/aws-cloud-wan-and-aws-transit-gateway-migration-and-interoperability-patterns/)

## Architecture Diagrams

For detailed architecture diagrams including:
- Multi-region topology
- Per-region TGW route table architecture
- Traffic flow sequences
- Route table isolation model
- Migration state transitions

See [architecture-diagram.md](./architecture-diagram.md)

## License

MIT
