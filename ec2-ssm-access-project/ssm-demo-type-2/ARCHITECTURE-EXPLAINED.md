# SSM Private Instance Access - Architecture Components Explained

This document breaks down every component in this solution and explains **why** each one is necessary.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Region (eu-west-1)                  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                VPC (10.0.0.0/16)                          │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────┐    │ │
│  │  │  Private Subnet (10.0.1.0/24)                   │    │ │
│  │  │                                                  │    │ │
│  │  │  ┌──────────────────────────────────┐           │    │ │
│  │  │  │  EC2 Instance (t3.micro)        │           │    │ │
│  │  │  │  • No Public IP                  │           │    │ │
│  │  │  │  • IAM Instance Profile          │◄──────┐   │    │ │
│  │  │  │  • SSM Agent Running             │       │   │    │ │
│  │  │  │  • Security Group (HTTPS out)    │       │   │    │ │
│  │  │  └──────────────┬───────────────────┘       │   │    │ │
│  │  │                 │ HTTPS (443)               │   │    │ │
│  │  │                 ▼                            │   │    │ │
│  │  │  ┌──────────────────────────────────┐       │   │    │ │
│  │  │  │  VPC Endpoints (Interface)       │       │   │    │ │
│  │  │  │  ┌────────────────────────────┐  │       │   │    │ │
│  │  │  │  │ com.amazonaws.eu-west-1.   │  │       │   │    │ │
│  │  │  │  │ • ssm                      │◄─┼───────┘   │    │ │
│  │  │  │  │ • ssmmessages              │  │           │    │ │
│  │  │  │  │ • ec2messages              │  │           │    │ │
│  │  │  │  └────────────────────────────┘  │           │    │ │
│  │  │  │  • Private DNS Enabled           │           │    │ │
│  │  │  │  • Security Group (HTTPS in)     │           │    │ │
│  │  │  └──────────────┬───────────────────┘           │    │ │
│  │  └─────────────────┼───────────────────────────────┘    │ │
│  │                    │ Private Link                       │ │
│  └────────────────────┼────────────────────────────────────┘ │
│                       │                                       │
│                       ▼                                       │
│              ┌─────────────────────┐                         │
│              │  AWS SSM Service    │                         │
│              └─────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
                       ▲
                       │ AWS API Call
                       │
              ┌─────────────────────┐
              │  Your Computer      │
              │  aws ssm start-     │
              │  session            │
              └─────────────────────┘
```

---

## 📦 Component Breakdown

### 1. **VPC (Virtual Private Cloud)**

**File:** `main.tf`
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

**Purpose:** 
- Creates an isolated network in AWS where your resources live
- Think of it as your own private data center in the cloud

**Why It's Needed:**
- Without a VPC, you can't create EC2 instances or subnets
- `enable_dns_hostnames = true` → Allows VPC endpoints to have DNS names
- `enable_dns_support = true` → Enables DNS resolution within the VPC

**What Would Break Without It:**
- ❌ Nothing else can be created - VPC is the foundation

---

### 2. **Private Subnet**

**File:** `main.tf`
```hcl
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false
}
```

**Purpose:**
- A subsection of the VPC where the EC2 instance lives
- `map_public_ip_on_launch = false` → Instances here get NO public IP

**Why It's Needed:**
- Organizes the VPC into smaller networks
- `private` means no direct internet access - perfect for secure workloads

**What Would Break Without It:**
- ❌ Can't launch EC2 instance (needs a subnet)
- ❌ Can't associate VPC endpoints (need a subnet)

---

### 3. **Route Table**

**File:** `main.tf`
```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

**Purpose:**
- Defines where network traffic can go from the subnet
- This one has **no routes** (no internet gateway, no NAT) - completely isolated

**Why It's Needed:**
- Every subnet needs a route table (explicit or implicit)
- Proves the instance truly has no internet access path

**What Would Break Without It:**
- ⚠️ Subnet would use VPC's default route table (still works, but less explicit)

---

### 4. **EC2 Instance**

**File:** `main.tf`
```hcl
resource "aws_instance" "private_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.ssm_instance_sg.id]
}
```

**Purpose:**
- The actual Linux server you'll connect to
- Uses Ubuntu 22.04 which has SSM agent pre-installed

**Why It's Needed:**
- This is what you're trying to access! The target server.

**Critical Properties:**
- `iam_instance_profile` → Gives the instance permission to talk to SSM service
- `vpc_security_group_ids` → Allows outbound HTTPS to VPC endpoints
- `subnet_id` → Places it in the private subnet (no public IP)

**What Would Break Without It:**
- ❌ Nothing to connect to - this is the whole point!

---

### 5. **IAM Role (for EC2 Instance)**

**File:** `ssm-configs.tf`
```hcl
resource "aws_iam_role" "ssm_role" {
  name = "SSM-Role-For-PrivateInstance"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
```

**Purpose:**
- Defines **who** can use this role (answer: EC2 service)
- Like a job title that says "EC2 instances can do certain things"

**Why It's Needed:**
- AWS requires roles to grant permissions to instances
- The `assume_role_policy` lets EC2 service "wear" this role

**What Would Break Without It:**
- ❌ Instance profile can't be created (needs a role)
- ❌ Instance has no identity - SSM service won't trust it

---

### 6. **IAM Policy Attachment**

**File:** `ssm-configs.tf`
```hcl
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

**Purpose:**
- Attaches AWS's managed policy to the role
- This policy grants permissions to:
  - Register with SSM service
  - Send heartbeat signals
  - Receive commands from Session Manager
  - Upload logs to CloudWatch (optional)

**Why It's Needed:**
- Without this, the role exists but has **zero permissions**
- SSM agent couldn't authenticate or communicate with SSM service

**What Would Break Without It:**
- ❌ Instance won't appear in SSM Fleet Manager
- ❌ SSM agent logs: "AccessDeniedException"
- ❌ Can't start sessions - instance not registered

---

### 7. **IAM Instance Profile**

**File:** `ssm-configs.tf`
```hcl
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSM-Instance-Profile"
  role = aws_iam_role.ssm_role.name
}
```

**Purpose:**
- The **bridge** between IAM roles and EC2 instances
- EC2 instances can't directly use roles - they need an instance profile wrapper

**Why It's Needed:**
- AWS quirk: Roles are for services, Instance Profiles attach to instances
- Think of it as the "ID badge holder" that attaches the role to the instance

**What Would Break Without It:**
- ❌ Can't attach role to EC2 instance
- ❌ Instance has no credentials to call AWS APIs

---

### 8. **Security Group (EC2 Instance)**

**File:** `main.tf`
```hcl
resource "aws_security_group" "ssm_instance_sg" {
  name        = "ssm-instance-sg"
  vpc_id      = aws_vpc.main.id

  # Allow HTTPS outbound to VPC CIDR (for VPC endpoints)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound (for system updates, internet access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Purpose:**
- Firewall rules for the EC2 instance
- Controls what traffic can **leave** the instance

**Why It's Needed:**
- **First egress rule:** Instance can reach VPC endpoints on port 443 (HTTPS)
- **Second egress rule:** Instance can download updates, packages, etc.

**What Would Break Without It:**
- ❌ Instance can't reach VPC endpoints (network blocked)
- ❌ SSM agent can't communicate - no connection to SSM service
- ❌ No `apt update` or package installs possible

---

### 9. **VPC Endpoints (3 Total)**

**File:** `vpc-endpoint.tf`
```hcl
# Endpoint 1: SSM Service
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

# Endpoint 2: SSM Messages (for Session Manager sessions)
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}

# Endpoint 3: EC2 Messages (for SSM agent communication)
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true
}
```

**Purpose:**
- Private "tunnels" into AWS services without using the internet
- Creates network interfaces (ENIs) inside your VPC

**Why ALL THREE Are Needed:**

| Endpoint | Purpose | What Breaks Without It |
|----------|---------|------------------------|
| **ssm** | Instance registration, heartbeats | ❌ Instance never registers with SSM |
| **ssmmessages** | Session Manager data channel | ❌ Can't establish sessions, no terminal I/O |
| **ec2messages** | SSM agent commands, updates | ❌ Agent can't receive commands |

**Critical Properties:**
- `vpc_endpoint_type = "Interface"` → Creates ENIs with private IPs in your subnet
- `private_dns_enabled = true` → Makes `ssm.eu-west-1.amazonaws.com` resolve to private IP
- `subnet_ids` → Places endpoints in the private subnet (same as instance)

**What Would Break Without Them:**
- ❌ **Total failure** - Instance can't reach SSM service at all
- ❌ SSM agent logs: "RequestTimeout" or "Connection refused"

---

### 10. **Security Group (VPC Endpoints)**

**File:** `vpc-endpoint.tf`
```hcl
resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "ssm-endpoint-sg"
  vpc_id      = aws_vpc.main.id

  # Allow HTTPS inbound from VPC CIDR (from EC2 instances)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Purpose:**
- Firewall rules for the VPC endpoints
- Controls what traffic can **reach** the endpoints

**Why It's Needed:**
- **Ingress rule:** Allows instances (10.0.0.0/16) to send HTTPS to endpoints
- Without this, packets from EC2 → VPC endpoints would be dropped

**What Would Break Without It:**
- ❌ VPC endpoints block traffic from instances
- ❌ SSM agent can't connect - firewall blocks packets
- ❌ Even with correct IAM and endpoints, network is blocked

---

## 🔄 How Components Work Together

### Startup Sequence (When Instance Launches):

```
1. EC2 Instance boots up
   └─> SSM Agent starts automatically (pre-installed in Ubuntu 22.04)

2. SSM Agent needs to register with SSM Service
   └─> Looks up DNS: ssm.eu-west-1.amazonaws.com
       └─> private_dns_enabled=true makes it resolve to VPC endpoint IP (10.0.1.x)

3. Agent tries to connect to VPC endpoint on port 443
   └─> ssm_instance_sg allows egress HTTPS to 10.0.0.0/16 ✅
   └─> ssm_endpoint_sg allows ingress HTTPS from 10.0.0.0/16 ✅
   └─> Packet reaches VPC endpoint

4. VPC endpoint forwards request to AWS SSM Service
   └─> Agent authenticates using IAM instance profile credentials
   └─> AmazonSSMManagedInstanceCore policy grants permission ✅

5. SSM Service accepts registration
   └─> Instance appears in Fleet Manager as "Online"

6. You run: aws ssm start-session
   └─> SSM Service routes session through ssmmessages endpoint
   └─> Agent receives session request via ec2messages endpoint
   └─> Bidirectional tunnel established 🎉
```

### Data Flow During Active Session:

```
Your Terminal
    ↓ (TLS encrypted)
AWS SSM Service (public)
    ↓ (AWS PrivateLink)
VPC Endpoint: ssmmessages
    ↓ (private network)
EC2 Instance
    ↓ (runs command)
Shell Output
    ↑ (flows back the same path)
Your Terminal
```

---

## 🎯 The "Why" Summary

| Component | Role | Analogy |
|-----------|------|---------|
| **VPC** | Network boundary | Your house |
| **Subnet** | Isolated zone | A locked room in the house |
| **EC2 Instance** | The server | Your computer in the room |
| **IAM Role** | Permission set | Job description |
| **Instance Profile** | Credential mechanism | ID badge |
| **Instance Security Group** | Outbound firewall | "Who can I call?" |
| **VPC Endpoints** | Private service gateway | Secret tunnel to AWS HQ |
| **Endpoint Security Group** | Inbound firewall | "Who can enter the tunnel?" |
| **SSM Agent** | Communication software | Phone app on the computer |
| **Route Table** | Traffic director | "No roads lead out" (isolation) |

---

## ❌ Common Misconfigurations

### ❌ Missing Instance Profile
```hcl
# WRONG - Instance has no credentials
resource "aws_instance" "private_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private.id
  # iam_instance_profile is MISSING ❌
}
```
**Result:** Instance can't authenticate with SSM - never registers.

---

### ❌ Missing Security Group on Instance
```hcl
# WRONG - Instance has no network permissions
resource "aws_instance" "private_instance" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.private.id
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  # vpc_security_group_ids is MISSING ❌
}
```
**Result:** Default SG has no egress to VPC endpoints - network blocked.

---

### ❌ Missing ssmmessages Endpoint
```hcl
# WRONG - Only created ssm endpoint, not ssmmessages
resource "aws_vpc_endpoint" "ssm" { ... }
# Missing: aws_vpc_endpoint.ssmmessages ❌
# Missing: aws_vpc_endpoint.ec2messages ❌
```
**Result:** Instance registers but you can't start sessions.

---

### ❌ Forgot private_dns_enabled
```hcl
# WRONG - DNS won't resolve to private IP
resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.eu-west-1.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private.id]
  # private_dns_enabled is MISSING ❌
}
```
**Result:** Agent tries to reach public internet (fails in private subnet).

---

## 🧪 Testing Component Dependencies

Want to prove what breaks? Try these experiments:

```powershell
# Deploy full solution
terraform apply

# Test 1: Remove instance profile
terraform destroy -target=aws_iam_instance_profile.ssm_instance_profile
# Result: Instance stops appearing in SSM Fleet Manager

# Test 2: Remove ssmmessages endpoint
terraform destroy -target=aws_vpc_endpoint.ssmmessages
# Result: Can't start sessions (instance still registers)

# Test 3: Remove security group from instance
# Edit main.tf, remove vpc_security_group_ids line
terraform apply
# Result: Instance can't reach endpoints (network blocked)
```

---

## 📚 AWS Documentation References

- **VPC Endpoints:** https://docs.aws.amazon.com/vpc/latest/privatelink/
- **Systems Manager Prerequisites:** https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-prereqs.html
- **IAM Roles for EC2:** https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
- **Session Manager:** https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html

---

**Key Takeaway:** Every component is essential. Remove any one piece and SSM access breaks. This is why the configuration has exactly these pieces - no more, no less. ✅
