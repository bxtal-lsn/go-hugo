---
title: "Billing Pipeline AIM to Sonwin Monthly Billing Job"
weight: 10
---
# Billing Pipeline AIM to Sonwin Monthly Billing Job
## Where
Runs as scheduled job in SQL Server Agent in DW server  
Job name: `Insert from AIM to SONLINC EVNTSEII`

## What

Executes main stored procedure exec `sonwin_main_execute_meter_readings_from_aim_to_sonwin`

Reads data from AIM

inserts into `[dbo].[sonwin_billing_readings_temp]`  
inserts from `[dbo].[sonwin_billing_readings_temp]` to `[Sonlinc].[EVNTSEII]`  
Updates `[Sonlinc].[EVNTSEII]`  
inserts into archive table `[dbo].[sonwin_billing_readings_archive]`  
inserts data into `[dbo].[sonwin_billing_missing_meters]`  

This executes sub stored procedures:  
- sonwin_get_meter_readings_framleidsla_1
- sonwin_meter_readings_create_tables;
- sonwin_get_meter_readings_nytsla_1;
- sonwin_get_meter_readings_nytsla_2;
- sonwin_get_meter_readings_nytsla_3;
- sonwin_get_meter_readings_framleidsla_1;
- sonwin_get_meter_readings_framleidsla_2;
- sonwin_get_meter_readings_framleidsla_3;
- sonwin_insert_meter_readings_from_dw_to_billing;
- sonwin_update_meter_readings_mwh;
- sonwin_insert_meter_readings_into_archive;
- sonwin_insert_into_missing_meters_table;

Inserts into `[dbo].[sonwin_billing_readings_temp]` on DW

Inserts and updates `[Sonlinc].[EVNTSEII]` on AfregnDB

Inserts into `[dbo].[sonwin_billing_readings_archive]` on DW

Inserts into `[dbo].[sonwin_billing_missing_meters]` on DW

## When
3rd of each month at 07:00 am

