CREATE procedure [dbo].[yso_ExportView2Excel] @numeView varchar(50),@numefisier varchar(50),@numeMacheta varchar(50)
as
/*
exec yso_ExportView2Excel 'YSO_Venituri','Venituri.xlsx','BlankVenituri.xlsx'
exec master..xp_cmdshell 'del C:\Users\Beni\OneDrive\EDS\beni.xlsx' 
go
*/
--create new file from blank template
DECLARE @sql NVARCHAR(MAX)
SET @SQL = N'EXEC xp_cmdshell ''del C:\Users\Beni\OneDrive\EDS\Exportat\'+@numefisier+''''

PRINT @SQL
EXEC(@SQL)

SET @SQL = N'EXEC xp_cmdshell ''copy C:\Users\Beni\OneDrive\EDS\Blank\'+@numeMacheta+' C:\Users\Beni\OneDrive\EDS\Exportat\'+@numefisier+''''

PRINT @SQL
EXEC(@SQL)


SET @SQL = N'INSERT INTO OPENDATASOURCE( ''Microsoft.ACE.OLEDB.12.0'',''Data Source=C:\Users\Beni\OneDrive\EDS\Exportat\'+@numefisier
	+';Extended properties=Excel 8.0'')...Sheet1$'
+ ' SELECT * FROM '+@numeView + ' order by Data desc'

PRINT @SQL
EXEC(@SQL)


/*
INSERT INTO OPENDATASOURCE( 'Microsoft.ACE.OLEDB.12.0',
       'Data Source=C:\Users\Beni\OneDrive\EDS\beni.xlsx; 
        Extended properties=Excel 8.0')...Sheet1$
SELECT * FROM ExportFisier 

--select
select * from OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\Users\Beni\OneDrive\EDS\beni.xlsx', Sheet1$)
*/