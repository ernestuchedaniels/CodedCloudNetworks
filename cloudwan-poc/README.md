# Cloud WAN + TGW Hybrid Backbone POC

## Architecture Overview

This POC demonstrates a **hybrid backbone architecture** combining:
- **AWS Cloud WAN** - Global network overlay with segment isolation
- **AWS Transit Gateway** - Regional network hub per region
- **Route Table Separation** - Prevents route leakage between backbones

## Route Table Architecture

### The Problem: Route Leakage
When using a single TGW route table for both VPC association and Cloud WAN export, routes leak between backbones causing routing loops.

### The Solution: 3 Route Tables Per Segment

```
┌─────────────────────────────────────────────────────────────────┐
│                    Transit Gateway (us-east-1)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │  pe-spoke-rt     │  │ pe-cw-export-rt  │  │ pe-peer-     │  │
│  │                  │  │                  │  │ export-rt    │  │
│  │ Purpose:         │  │ Purpose:         │  │              │  │
│  │ Workload routing │  │ Cloud WAN export │  │ Purpose:     │  │
│  │                  │  │                  │  │ TGW peering  │  │
│  │ Receives:        │  │ Receives:        │  │ export       │  │
│  │ ✅ VPC routes    │  │ ✅ VPC routes    │  │              │  │
│  │ ✅ Cloud WAN     │  │ ❌ Cloud WAN     │  │ Receives:    │  │
│  │ ✅ TGW peering   │  │ ❌ TGW peering   │  │ ✅ VPC routes│  │
│  │                  │  │                  │  │ ❌ Cloud WAN │  │
│  │ Used by:         │  │ Used by:         │  │ ❌ TGW peer  │  │
│  │ VPC attachments  │  │ Cloud WAN attach │  │              │  │
│  │ (association)    │  │                  │  │ Used by:     │  │
│  │                  │  │                  │  │ TGW peering  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │  npe-spoke-rt    │  │ npe-cw-export-rt │  │ npe-peer-    │  │
│  │  (same pattern)  │  │  (same pattern)  │  │ export-rt    │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Propagation Flow

### VPC Attachment Propagation
```
                    ┌─────────────┐
                    │  VPC (PE)   │
                    │ 10.1.0.0/16 │
                    └──────┬──────┘
                           │
                    Attaches to TGW
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ pe-spoke-rt   │  │pe-cw-export-rt│  │pe-peer-export │
│               │  │               │  │      -rt      │
│ Associate ✅  │  │ Propagate ✅  │  │ Propagate ✅  │
│ Propagate ✅  │  │               │  │               │
└───────────────┘  └───────┬───────┘  └───────────────┘
                           │
                           │ Attached to
                           ▼
                   ┌───────────────┐
                   │  Cloud WAN    │
                   │  PE Segment   │
                   └───────────────┘
```

### Cloud WAN Propagation (Prevents Leakage)
```
┌───────────────────────────────────────────────────────────┐
│              Cloud WAN PE Segment                         │
│  (Learns: 10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16, etc)   │
└───────────────────┬───────────────────────────────────────┘
                    │
            TGW Peering Attachment
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
┌───────────┐ ┌─────────┐ ┌─────────┐
│pe-spoke-rt│ │pe-cw-   │ │pe-peer- │
│           │ │export-rt│ │export-rt│
│Propagate✅│ │         │ │         │
│           │ │Block ❌ │ │Block ❌ │
└───────────┘ └─────────┘ └─────────┘
     │
     │ Workloads can reach
     ▼ remote via Cloud WAN
┌──────────┐
│   VPC    │
│ Workload │
└──────────┘
```

## Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud WAN                             │
│                     (Global Network Overlay)                     │
│                                                                   │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │   PE Segment     │              │   NPE Segment    │         │
│  │   (Isolated)     │              │   (Isolated)     │         │
│  └────────┬─────────┘              └────────┬─────────┘         │
└───────────┼──────────────────────────────────┼──────────────────┘
            │                                  │
    ┌───────┴────────┬─────────────────────────┴────────┬─────────┐
    │                │                                   │         │
    ▼                ▼                                   ▼         ▼
┌────────┐      ┌────────┐                         ┌────────┐ ┌────────┐
│  TGW   │      │  TGW   │                         │  TGW   │ │  TGW   │
│us-east │      │us-west │                         │eu-west │ │ap-se-1 │
└───┬────┘      └───┬────┘                         └───┬────┘ └───┬────┘
    │               │                                  │          │
┌───┴───┐       ┌───┴───┐                          ┌───┴───┐  ┌───┴───┐
│ PE VPC│       │ PE VPC│                          │ PE VPC│  │ PE VPC│
│10.1.0 │       │10.2.0 │                          │10.3.0 │  │10.4.0 │
└───────┘       └───────┘                          └───────┘  └───────┘
┌───────┐       ┌───────┐                          ┌───────┐  ┌───────┐
│NPE VPC│       │NPE VPC│                          │NPE VPC│  │NPE VPC│
│10.1.16│       │10.2.16│                          │10.3.16│  │10.4.16│
└───────┘       └───────┘                          └───────┘  └───────┘
```

## Key Features

✅ **No Route Leakage** - Separate route tables prevent circular propagation  
✅ **Segment Isolation** - PE and NPE remain isolated end-to-end  
✅ **Dual Backbone** - Workloads can use both Cloud WAN and TGW peering  
✅ **Scalable** - Easy to add new regions and segments  
✅ **Production Ready** - Follows AWS best practices  

## Deployment

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- AWS credentials with appropriate permissions

### Deploy
```bash
cd cloudwan-poc
terraform init
terraform plan
terraform apply
```

### Verify
```bash
# Check TGW route tables
aws ec2 describe-transit-gateway-route-tables \
  --filters "Name=tag:Name,Values=pe-spoke-us-east-1"

# Check Cloud WAN learned routes
aws networkmanager get-network-routes \
  --global-network-id <id> \
  --core-network-id <id> \
  --route-table-identifier segment=pe,region=us-east-1
```

## Documentation

- [Route Leakage Prevention Architecture](./ROUTE_LEAKAGE_PREVENTION.md) - Detailed explanation
- [Terraform Modules](./modules/) - Module documentation

## Regions

- **us-east-1** (10.1.0.0/16 PE, 10.1.16.0/20 NPE)
- **us-west-2** (10.2.0.0/16 PE, 10.2.16.0/20 NPE)
- **eu-west-1** (10.3.0.0/16 PE, 10.3.16.0/20 NPE)
- **ap-southeast-1** (10.4.0.0/16 PE, 10.4.16.0/20 NPE)

## Cost Considerations

- Cloud WAN: ~$0.05/GB inter-region data transfer
- TGW: ~$0.02/hour per attachment + $0.02/GB
- VPC: Standard AWS VPC pricing
- EC2: t3.micro test instances

## Cleanup

```bash
terraform destroy
```

## License

MIT
