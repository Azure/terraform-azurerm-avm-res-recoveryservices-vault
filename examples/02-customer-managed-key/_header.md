# Customer-Managed Key Example

This example deploys a Recovery Services Vault encrypted with a customer-managed key stored in Azure Key Vault.

## What this example shows

- Creating and wiring a customer-managed key for vault encryption
- Using both system-assigned and user-assigned managed identities
- Passing the Key Vault and identity references the vault needs for CMK access
- A secure pattern for vaults that must use customer-controlled encryption material

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
