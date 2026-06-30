<!-- BEGIN_TF_DOCS -->
# Protected File Share Backup

* This deploys the module in its simplest form.

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9, < 2.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 2.4 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) | data source |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_recovery_vault_name"></a> [recovery\_vault\_name](#input\_recovery\_vault\_name) | recovery\_vault\_name: specify a recovery\_vault\_name for the Azure Recovery Services Vault. Upper/Lower case letters, numbers and hyphens. number of characters 2-50 | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_file_share_backup_policy"></a> [file\_share\_backup\_policy](#input\_file\_share\_backup\_policy) | A map objects for backup and retation options.<br><br>    - `name` - (Optional) The name of the private endpoint. One will be generated if not set.<br>    - `role_assignments` - (Optional) A map of role assignments to create on the <br><br>    - `backup` - (required) backup options.<br>        - `frequency` - (Required) Sets the backup frequency. Possible values are hourly, Daily and Weekly.<br>        - `time` - (required) Specify time in a 24 hour format HH:MM. "22:00"<br>        - `hour_interval` - (Optional) Interval in hour at which backup is triggered. Possible values are 4, 6, 8 and 12. This is used when frequency is hourly. 6<br>        - `hour_duration` -  (Optional) Duration of the backup window in hours. Possible values are between 4 and 24 This is used when frequency is hourly. 12<br>        - `weekdays` -  (Optional) The days of the week to perform backups on. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. This is used when frequency is Weekly. ["Tuesday", "Saturday"]<br>    - `backup_tier` - (Optional) The backup tier. Possible values are `snapshot` and `vault-standard`. Defaults to `snapshot`. When set to `vault-standard`, backups are stored in the Recovery Services vault. When set to `snapshot`, backups are stored as snapshots.<br>    - `snapshot_retention_in_days` - (Optional) The number of days to retain snapshots when `backup_tier` is `vault-standard`. Must be less than `retention_daily` count. Defaults to `0`.<br>    - `retention_daily` - (Optional)<br>      - `count` - <br>    - `retantion_weekly` -<br>      - `count` -<br>      - `weekdays` -<br>    - `retantion_monthly` -<br>      - `count` -  # (Required) The number of monthly backups to keep. Must be between 1 and 9999<br>      - `weekdays` - (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.<br>      - `weeks` -  # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.<br>      - `days` -  # (Optional) The days of the month to retain backups of. Must be between 1 and 31.<br>      - `include_last_days` -  # (Optional) Including the last day of the month, default to false.<br>    - `retantion_yearly` -<br>      - `months` - # (Required) The months of the year to retain backups of. Must be one of January, February, March, April, May, June, July, August, September, October, November and December.<br>      - `count` -  # (Required) The number of monthly backups to keep. Must be between 1 and 9999<br>      - `weekdays` - (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.<br>      - `weeks` -  # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.<br>      - `days` -  # (Optional) The days of the month to retain backups of. Must be between 1 and 31.<br>      - `include_last_days` -  # (Optional) Including the last day of the month, default to false.<br><br>    example:<br>      retentions = {<br>      rest1 = {<br>        backup = {<br>          frequency     = "hourly"<br>          time          = "22:00"<br>          hour\_interval = 6<br>          hour\_duration = 12<br>          # weekdays      = ["Tuesday", "Saturday"]<br>        }<br>        retention\_daily = 7<br>        retention\_weekly = {<br>          count    = 7<br>          weekdays = ["Monday", "Wednesday"]<br><br>        }<br>        retention\_monthly = {<br>          count = 5<br>          # weekdays =  ["Tuesday","Saturday"]<br>          # weeks = ["First","Third"]<br>          days = [3, 10, 20]<br>        }<br>        retention\_yearly = {<br>          count  = 5<br>          months = []<br>          # weekdays =  ["Tuesday","Saturday"]<br>          # weeks = ["First","Third"]<br>          days = [3, 10, 20]<br>        }<br><br>        }<br>      } | <pre>object({<br>    name     = string<br>    timezone = string<br><br>    frequency = string<br><br>    backup_tier                = optional(string, "snapshot")<br>    snapshot_retention_in_days = optional(number, 0)<br><br>    retention_daily = optional(number, null)<br><br>    backup = object({<br>      time = string<br>      hourly = optional(object({<br>        interval        = number<br>        start_time      = string<br>        window_duration = number<br>      }))<br>    })<br><br>    retention_weekly = optional(object({<br>      count    = optional(number, 7)<br>      weekdays = optional(list(string), [])<br>    }), {})<br><br>    retention_monthly = optional(object({<br>      count             = optional(number, 0)<br>      weekdays          = optional(list(string), [])<br>      weeks             = optional(list(string), [])<br>      days              = optional(list(number), [])<br>      include_last_days = optional(bool, false)<br>    }), {})<br><br>    retention_yearly = optional(object({<br>      count             = optional(number, 0)<br>      months            = optional(list(string), [])<br>      weekdays          = optional(list(string), [])<br>      weeks             = optional(list(string), [])<br>      days              = optional(list(number), [])<br>      include_last_days = optional(bool, false)<br>    }), {})<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource"></a> [resource](#output\_resource) | resource Id output |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | resource Id output |

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->