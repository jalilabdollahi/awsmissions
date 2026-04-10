# Solution

```bash
# Edit the local mission artifact first
$EDITOR service-discovery.json
# This edited file applies to: --name service-b.local

# Then apply the fix
aws servicediscovery create-private-dns-namespace --name service-b.local --vpc vpc-12345678
```
