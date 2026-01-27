data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_networkmanager_global_network" "main" {
  description = "CloudWAN POC Global Network"

  tags = {
    Name        = "cloudwan-poc-global"
    Environment = "poc"
  }
}

data "aws_networkmanager_core_network_policy_document" "main" {
  core_network_configuration {
    asn_ranges = ["65001-65100"]

    dynamic "edge_locations" {
      for_each = var.regions
      content {
        location = edge_locations.key
        asn      = edge_locations.value.asn
      }
    }
  }

  dynamic "segments" {
    for_each = var.segments
    content {
      name                          = segments.key
      description                   = segments.value.description
      require_attachment_acceptance = segments.value.require_attachment_acceptance
      isolate_attachments           = segments.value.isolate_attachments
      edge_locations                = keys(var.regions)
    }
  }



  dynamic "attachment_policies" {
    for_each = var.segments
    iterator = segment
    content {
      rule_number     = (index(keys(var.segments), segment.key) + 1) * 100
      condition_logic = "or"

      conditions {
        type     = "tag-value"
        operator = "equals"
        key      = "Environment"
        value    = segment.key
      }

      action {
        association_method = "constant"
        segment            = segment.key
        require_acceptance = segment.value.require_attachment_acceptance
      }
    }
  }

  # REMOVED: segment_actions with share_with=["*"] causes PE/NPE route leakage
  # Each segment is isolated by default - no cross-segment sharing needed
  # Intra-segment routing happens automatically within each segment
}

resource "aws_networkmanager_core_network" "main" {
  global_network_id  = aws_networkmanager_global_network.main.id
  description        = "CloudWAN POC Core Network"
  create_base_policy = false
  base_policy_document = data.aws_networkmanager_core_network_policy_document.main.json

  tags = {
    Name        = "cloudwan-poc-core"
    Environment = "poc"
  }
}

resource "aws_networkmanager_core_network_policy_attachment" "main" {
  core_network_id = aws_networkmanager_core_network.main.id
  policy_document = data.aws_networkmanager_core_network_policy_document.main.json
}
