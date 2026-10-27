# Azure three tier (free tier sizes)

A web server behind a Standard load balancer with one public IP, and a PostgreSQL database, sized for the Azure free services: a Standard_B1s virtual machine with a 30 GB disk and a Burstable B1ms database server with 32 GB storage. No NAT gateway, Bastion, VPN, Application Gateway or Log Analytics.

The database firewall has no rules, so nothing can connect until you add your own address or a private endpoint.
