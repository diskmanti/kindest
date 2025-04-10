# kindest

1. AWS MSK Topics/ACLs

Managing Topics and ACL for AWS MSK is done using CRDs provider by the Strimzi Operator. Strimzi provides 2 CRDs specific foe this kind of operator: *KafkaTopic* and *KafkaUser*. This [yaml manifest](./tenants/backend-team/kafka.yaml) shows how the CR can be created. The KafkaTopic is very straghtforward. It creates a topic with the  same name as the CR and the configuration that is defined under spec. The KafkaUser CR is more complicated. The intresting part, the one where access is defined is located under **.sepc.authorization.acls[]. Here we define what operation we required, on thich topic and if the operation if permitted or not.

2. Flux Multitenancy and Alerting

Flus is bootstrapped on the cluster using the official cli:

```bash
export GITHUB_TOKEN=$(gh auth token)
flux check --pre

flux bootstrap github \
  --token-auth \
  --owner=diskmanti \
  --repository=kindest\
  --branch=main \
  --path=clusters/main \
  --personal
```

After a succesfull FluxCD installation a mofification is needed to segregate and isolate resources using namesapaces and RBAC. The modification is a [kustomization.yml](./clusters/main/flux-system/kustomization.yml) file. 
This customised configuration provides:

- Deny cross-namespace access to Flux custom resources, thus ensuring that a tenant can’t use another tenant’s sources or subscribe to their events.
- Deny accesses to Kustomize remote bases, thus ensuring all resources refer to local files, meaning only the Flux Sources can affect the cluster-state.
- All Kustomizations and HelmReleases which don’t have spec.serviceAccountName specified, will use the default account from the tenant’s namespace. Tenants have to specify a service account in their Flux resources to be able to deploy workloads in their namespaces as the default account has no permissions.
- The flux-system Kustomization is set to reconcile under a service account with cluster-admin role, allowing platform admins to configure cluster-wide resources and provision the tenant’s namespaces, service accounts and RBAC.

Now Flux is able manage *Tenants*. Each Tenant is given access to one or more namespaces and they can deploy whatever they required for their workload.

Tenants are created and managed by CusterAdmins. The manifests that describe a Tenant are available under the [tenants](./tenants/) folder.
In this example we have tenanat **frontend-team** with full access to namespaces blue and green. And tenanat backend-team with access only to namespace red.

Alerting is configured using the CRDs provided by FluxCD, namely: Provider and Alert. The manifests are available [here](./infrastructure/alerting).
Alerts are defined so that they fire when an event is created for HelmReleases or Kustomizations.

3. AWS RDS

The **[rds-controller](https://github.com/aws-controllers-k8s/rds-controller)** has been deployed on the cluster. This is the official operator from AWS to manage RDS instances.
When this operator is deployed it offers a list of CRDs they can be consumed by users:

 - dbclusterparametergroups                        
 - dbclusters                                   
 - dbclustersnapshots                          
 - dbinstances                                    
 - dbparametergroups                           
 - dbproxies                                        
 - dbsnapshots                                  
 - dbsubnetgroups                                
 - globalclusters

 Using the above CRDs users are capable of provisioning their RDS instances and use them. Below is an example manifest of such instance:

 ```yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
metadata:
  name: "${RDS_INSTANCE_NAME}"
spec:
  allocatedStorage: 20
  dbInstanceClass: db.t4g.micro
  dbInstanceIdentifier: "${RDS_INSTANCE_NAME}"
  engine: postgres
  engineVersion: "14"
  masterUsername: "postgres"
  masterUserPassword:
    namespace: default
    name: "${RDS_INSTANCE_NAME}-password"
    key: password
 ```