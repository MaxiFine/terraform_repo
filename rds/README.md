# RDS Module

This module creates a Multi-AZ MySQL RDS instance for the ECS web application.

## Features

- **Multi-AZ Deployment**: Provides high availability and automatic failover
- **Security**: Deployed in private subnets with security group allowing access only from ECS tasks
- **Secrets Management**: Database credentials stored securely in AWS Secrets Manager
- **Backup & Monitoring**: Automated backups with configurable retention period
- **Encryption**: Storage encryption enabled by default
- **Auto Scaling Storage**: Automatic storage scaling up to defined maximum
- **Parameter Groups**: Custom parameter groups for database tuning
- **CloudWatch Logs**: Optional database log exports to CloudWatch

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   ECS Tasks     │────│   RDS Multi-AZ  │
│ (Private Subnet)│    │ (Private Subnet)│
└─────────────────┘    └─────────────────┘
         │                       │
         │              ┌─────────────────┐
         └──────────────│ Secrets Manager │
                        │  (Credentials)  │
                        └─────────────────┘
```

## Resources Created

1. **DB Subnet Group**: Groups private subnets for RDS deployment
2. **Security Group**: Allows database access only from ECS security group
3. **RDS Instance**: Multi-AZ MySQL database with encryption
4. **Random Password**: Secure password generation
5. **Secrets Manager**: Secure credential storage
6. **Parameter Group**: Custom database parameters
7. **CloudWatch Log Groups**: Database log exports (optional)
8. **IAM Role**: Enhanced monitoring (optional)

## Configuration

### Default Configuration
- **Engine**: MySQL 8.0
- **Instance Class**: db.t3.micro
- **Storage**: 20GB (auto-scales to 100GB)
- **Multi-AZ**: Enabled
- **Backup Retention**: 7 days
- **Encryption**: Enabled

### Customization
You can customize the RDS instance by modifying variables in the root `variables.tf`:

```hcl
# Example custom configuration
db_engine = "postgres"
db_engine_version = "14.9"
db_instance_class = "db.t3.small"
db_allocated_storage = 50
db_multi_az = true
```

## Security

1. **Network Security**: 
   - Deployed in private subnets only
   - Security group allows access only from ECS tasks on database port

2. **Encryption**:
   - Storage encryption enabled by default
   - Credentials stored in AWS Secrets Manager

3. **Access Control**:
   - Master credentials generated randomly
   - No public accessibility
   - IAM integration for enhanced monitoring

## Connectivity from ECS

ECS tasks can connect to the database using:

```bash
# Get credentials from Secrets Manager
aws secretsmanager get-secret-value --secret-id webapp-db-credentials

# Connect from ECS task
mysql -h <rds-endpoint> -u admin -p webapp
```

## Monitoring

1. **CloudWatch Metrics**: Automatic RDS metrics
2. **Enhanced Monitoring**: Optional detailed metrics
3. **Performance Insights**: Optional query performance monitoring
4. **CloudWatch Logs**: Database error, general, and slow query logs

## Backup & Recovery

1. **Automated Backups**: Daily backups with 7-day retention
2. **Multi-AZ**: Automatic failover to standby instance
3. **Point-in-Time Recovery**: Restore to any point within backup retention
4. **Final Snapshot**: Created before deletion (configurable)

## Outputs

The module provides these outputs for use by other modules:

- `db_instance_endpoint`: Database connection endpoint
- `db_instance_port`: Database port
- `db_credentials_secret_arn`: Secrets Manager ARN for credentials
- `db_security_group_id`: Database security group ID
- `db_connection_info`: Complete connection information (sensitive)

## Cost Optimization

- Uses `db.t3.micro` for development (lowest cost)
- Storage auto-scaling prevents over-provisioning
- Configurable backup retention
- Can disable deletion protection for development environments

## Production Considerations

For production deployments, consider:

1. **Instance Size**: Upgrade to `db.t3.small` or larger
2. **Storage**: Increase allocated storage based on needs
3. **Backup Retention**: Increase to 14-30 days
4. **Deletion Protection**: Enable for production
5. **Enhanced Monitoring**: Enable for performance insights
6. **Multi-AZ**: Keep enabled for high availability
7. **Parameter Tuning**: Customize database parameters for workload

# Check RDS status
aws rds describe-db-instances --db-instance-identifier webapp-db

# Get database credentials
aws secretsmanager get-secret-value --secret-id webapp-db-credentials

# Connect from ECS task
aws ecs execute-command --cluster nginx-web-cluster --task <task-id> --container nginx --interactive --command "/bin/bash"
