exec sp_configure
go
exec sp_configure 'Ole Automation Procedures', 1
-- Configuration option 'Ole Automation Procedures' changed from 0 to 1. Run the RECONFIGURE statement to install.
go
reconfigure
go