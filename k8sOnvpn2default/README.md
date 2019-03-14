# Google Compute Engine VPN Example

This example joins a new Kubernetes Cluster and new network with default network on GCP via VPN.

Steps:
1. Adding network
2. Adding ssh and icmp rules
3. Create gateways
4. Reserve static ips
5. Create forwarding rules for both vpn gateways
6. Create tunnels
7. Create static routes
8. Create instance
9. Create kubernetes cluster

See this [example](https://cloud.google.com/compute/docs/vpn) for more 
information.

Run this example using 

```
terraform apply 
```
