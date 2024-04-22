# Introduction
This reproduces an issue where using the synchronous `.Open()` method to open a `SqlConnection` using `Authentication=ActiveDirectoryManagedIdentity`
take an increasingly large time when multiple connections are started in parallel.

# Results

| async | threads | totalMilliseconds |
|-------|---------|-------------------|
| False |       1 |          2,584.46 |
| False |       2 |          2,787.73 |
| False |       4 |          4,301.57 |
| False |       8 |         10,845.30 |
| False |      16 |         13,047.61 |
| False |      32 |         26,729.01 |
|  True |       1 |          2,020.73 |
|  True |       2 |          2,098.92 |
|  True |       4 |          2,208.14 |
|  True |       8 |          2,176.08 |
|  True |      16 |          2,230.75 |
|  True |      32 |          2,384.87 |

# Running the Repro

Because I wasn't able to test Managed Identity auth locally, this requires that a SQL database and app service be deployed to Azure.
This can be done using the `./Deploy.ps1` command:

```ps
./Deploy.ps1 -SubscriptionId my-subscription-guid
```

The issue only affects newly opened connections, so we need to restart the app service and record the first results to get accurate numbers.
This is automated in the `./Collect.ps1` command:
```ps
./Collect.ps1 -SubscriptionId my-subscription-guid
```
