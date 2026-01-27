# AWS Cloud WAN Migration Architecture Diagrams

## High-Level Multi-Region Topology

```mermaid
graph TB
    subgraph CloudWAN["AWS Cloud WAN (Global)"]
        PE_SEG["PE Segment<br/>10.1-4.0.0/16"]
        NPE_SEG["NPE Segment<br/>10.101-104.0.0/16"]
    end
    
    subgraph USE1["us-east-1"]
        TGW_USE1["TGW<br/>5 Route Tables"]
        VPC_PE_USE1["PE VPC<br/>10.1.0.0/16"]
        VPC_NPE_USE1["NPE VPC<br/>10.101.0.0/16"]
    end
    
    subgraph USW2["us-west-2"]
        TGW_USW2["TGW<br/>5 Route Tables"]
        VPC_PE_USW2["PE VPC<br/>10.2.0.0/16"]
        VPC_NPE_USW2["NPE VPC<br/>10.102.0.0/16"]
    end
    
    subgraph EUW1["eu-west-1"]
        TGW_EUW1["TGW<br/>5 Route Tables"]
        VPC_PE_EUW1["PE VPC<br/>10.3.0.0/16"]
        VPC_NPE_EUW1["NPE VPC<br/>10.103.0.0/16"]
    end
    
    subgraph APSE1["ap-southeast-1"]
        TGW_APSE1["TGW<br/>5 Route Tables"]
        VPC_PE_APSE1["PE VPC<br/>10.4.0.0/16"]
        VPC_NPE_APSE1["NPE VPC<br/>10.104.0.0/16"]
    end
    
    PE_SEG -.TGW-CW Peering.-> TGW_USE1
    PE_SEG -.TGW-CW Peering.-> TGW_USW2
    PE_SEG -.TGW-CW Peering.-> TGW_EUW1
    PE_SEG -.TGW-CW Peering.-> TGW_APSE1
    
    NPE_SEG -.TGW-CW Peering.-> TGW_USE1
    NPE_SEG -.TGW-CW Peering.-> TGW_USW2
    NPE_SEG -.TGW-CW Peering.-> TGW_EUW1
    NPE_SEG -.TGW-CW Peering.-> TGW_APSE1
    
    TGW_USE1 <-->|TGW Peering| TGW_USW2
    TGW_USE1 <-->|TGW Peering| TGW_EUW1
    TGW_USE1 <-->|TGW Peering| TGW_APSE1
    TGW_USW2 <-->|TGW Peering| TGW_EUW1
    TGW_USW2 <-->|TGW Peering| TGW_APSE1
    TGW_EUW1 <-->|TGW Peering| TGW_APSE1
    
    TGW_USE1 --> VPC_PE_USE1
    TGW_USE1 --> VPC_NPE_USE1
    TGW_USW2 --> VPC_PE_USW2
    TGW_USW2 --> VPC_NPE_USW2
    TGW_EUW1 --> VPC_PE_EUW1
    TGW_EUW1 --> VPC_NPE_EUW1
    TGW_APSE1 --> VPC_PE_APSE1
    TGW_APSE1 --> VPC_NPE_APSE1
```

## Per-Region TGW Route Table Architecture

```mermaid
graph TB
    subgraph TGW["Transit Gateway (Example: us-west-2)"]
        subgraph PE_RTs["PE Route Tables"]
            PE_SPOKE["pe-spoke-rt<br/>━━━━━━━━━━━━━━<br/>Associated:<br/>• PE VPC attachment<br/><br/>Static Routes:<br/>• 10.2.0.0/16 → local VPC<br/>• 10.1.0.0/16 → peering<br/>• 10.3.0.0/16 → peering<br/>• 10.4.0.0/16 → peering"]
            PE_CW["pe-cw-export-rt<br/>━━━━━━━━━━━━━━<br/>Propagated:<br/>• PE VPC attachment<br/><br/>Purpose:<br/>Export ONLY local<br/>PE routes to<br/>Cloud WAN PE segment<br/><br/>Blocks:<br/>• Cloud WAN routes<br/>• TGW peer routes"]
        end
        
        subgraph NPE_RTs["NPE Route Tables"]
            NPE_SPOKE["npe-spoke-rt<br/>━━━━━━━━━━━━━━<br/>Associated:<br/>• NPE VPC attachment<br/><br/>Static Routes:<br/>• 10.102.0.0/16 → local VPC<br/>• 10.101.0.0/16 → peering<br/>• 10.103.0.0/16 → peering<br/>• 10.104.0.0/16 → peering"]
            NPE_CW["npe-cw-export-rt<br/>━━━━━━━━━━━━━━<br/>Propagated:<br/>• NPE VPC attachment<br/><br/>Purpose:<br/>Export ONLY local<br/>NPE routes to<br/>Cloud WAN NPE segment<br/><br/>Blocks:<br/>• Cloud WAN routes<br/>• TGW peer routes"]
        end
        
        PEER_INGRESS["peer-ingress-rt<br/>━━━━━━━━━━━━━━━━━━━━━━━━━━<br/>Associated:<br/>• Peering to us-east-1<br/>• Peering to eu-west-1<br/>• Peering to ap-southeast-1<br/><br/>Static Routes:<br/>• 10.2.0.0/16 → PE VPC attachment<br/>• 10.102.0.0/16 → NPE VPC attachment<br/><br/>Purpose:<br/>Landing zone for inter-region traffic"]
    end
```

## Traffic Flow: us-west-2 PE → ap-southeast-1 PE

```mermaid
sequenceDiagram
    participant SRC as Source VPC<br/>(us-west-2 PE)<br/>10.2.2.74
    participant SRC_TGW as us-west-2 TGW<br/>VPC Attachment
    participant SRC_RT as us-west-2<br/>pe-spoke-rt
    participant PEER as TGW Peering<br/>Connection
    participant DST_RT as ap-southeast-1<br/>peer-ingress-rt
    participant DST_TGW as ap-southeast-1 TGW<br/>VPC Attachment
    participant DST as Destination VPC<br/>(ap-southeast-1 PE)<br/>10.4.2.86
    
    SRC->>SRC_TGW: Ping 10.4.2.86<br/>VPC RT: 10.0.0.0/13 → TGW
    Note over SRC_TGW: VPC attachment associated<br/>with pe-spoke-rt
    SRC_TGW->>SRC_RT: Consult route table
    Note over SRC_RT: Static route:<br/>10.4.0.0/16 → peering attachment
    SRC_RT->>PEER: Forward to peering
    PEER->>DST_RT: Traffic arrives at remote TGW
    Note over DST_RT: Peering attachment associated<br/>with peer-ingress-rt
    Note over DST_RT: Static route:<br/>10.4.0.0/16 → VPC attachment
    DST_RT->>DST_TGW: Forward to VPC attachment
    DST_TGW->>DST: Deliver to VPC
    Note over DST: Ping received<br/>TTL=252, 160ms
    
    DST-->>DST_TGW: Reply
    DST_TGW-->>DST_RT: Consult pe-spoke-rt
    DST_RT-->>PEER: 10.2.0.0/16 → peering
    PEER-->>SRC_RT: Arrives at peer-ingress-rt
    SRC_RT-->>SRC_TGW: 10.2.0.0/16 → VPC attachment
    SRC_TGW-->>SRC: Reply delivered
```

## Route Table Isolation Model

```mermaid
graph LR
    subgraph VPC_OUT["Outbound from VPC"]
        VPC1["VPC"] --> SPOKE["spoke-rt<br/>━━━━━━━━<br/>Local VPC routes<br/>+ Remote peering routes<br/>+ Cloud WAN routes"]
    end
    
    subgraph EXPORT["Export to Cloud WAN"]
        VPC2["VPC"] -.propagate.-> CW_EXPORT["cw-export-rt<br/>━━━━━━━━<br/>ONLY local VPC routes<br/><br/>Blocks:<br/>• Remote routes<br/>• Peering routes"]
        CW_EXPORT --> CLOUDWAN["Cloud WAN<br/>Segment"]
    end
    
    subgraph INGRESS["Inbound from Peering"]
        PEERING["Peering<br/>Attachment"] --> PEER_IN["peer-ingress-rt<br/>━━━━━━━━<br/>Static routes to<br/>local VPC attachments"]
        PEER_IN --> VPC3["VPC"]
    end
    
    style SPOKE fill:#e1f5ff
    style CW_EXPORT fill:#fff4e1
    style PEER_IN fill:#f0e1ff
```

## Migration States

```mermaid
stateDiagram-v2
    [*] --> TGW_Only: Initial State
    
    state TGW_Only {
        [*] --> AllRegionsTGW
        AllRegionsTGW: All VPCs route via TGW peering
        AllRegionsTGW: PE/NPE isolated
    }
    
    TGW_Only --> Hybrid: Migrate Region 1
    
    state Hybrid {
        [*] --> MixedState
        MixedState: Region 1 uses Cloud WAN
        MixedState: Regions 2-4 use TGW peering
        MixedState: TGW-CW peering bridges traffic
    }
    
    Hybrid --> CloudWAN_Only: Migrate All Regions
    
    state CloudWAN_Only {
        [*] --> AllRegionsCloudWAN
        AllRegionsCloudWAN: All VPCs route via Cloud WAN
        AllRegionsCloudWAN: PE/NPE isolated
        AllRegionsCloudWAN: TGW peering decommissioned
    }
    
    CloudWAN_Only --> [*]
```
