EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
GO 
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
GO
EXEC sp_dropserver
    @server = N'ExcelServer',
    @droplogins='droplogins'
    
EXEC sp_addlinkedserver
    @server = 'ExcelServer',
    @srvproduct = 'Excel', 
    @provider = 'Microsoft.ACE.OLEDB.12.0',
    @datasrc = 'd:\BAZA_DATE_ASIS\EXCEL\IMPORT\testimport.xlsx',
    @provstr = 'Excel 12.0;IMEX=1;HDR=YES;'
    
    SELECT * --into testimportexcel
    from opendatasource('Microsoft.ACE.OLEDB.12.0',
'Data Source=d:\BAZA_DATE_ASIS\EXCEL\IMPORT\testimport.xlsx;Extended Properties=Excel 12.0')...[Sheet1$]