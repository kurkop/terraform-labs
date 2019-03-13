# Google Compute Engine VPN Example

This example joins two GCE networks via VPN.

Steps:
1. Adding networks
2. Adding ssh and icmp rules
3. Create gateways
4. Reserve static ips
5. Create forwarding rules for both vpn gateways
6. Create tunnels
7. Create static routes
8. Create instances

See this [example](https://cloud.google.com/compute/docs/vpn) for more 
information.

Run this example using 

```
terraform apply 
```
