
 declare @sursa nvarchar(max),@server nvarchar(max)
 ,@sql nvarchar(max)='set fmtonly off; wIaPozdoc @sesiune,@parxml;', @par nvarchar(max)='@sesiune varchar(25), @parXML xml',
 @parx xml='<row subunitate="1" tip="AP" numar="9430281" data="2012-10-29"/>'
 
set @sql=
'set @sql=replace(@sql,''@sursa'',@sursa)
set @sql=replace(@sql,''@server'',@server)
set @sql=replace(@sql,''@server'',@server)'+CHAR(10)+CHAR(13)+@sql
exec sp_executesql @s,@p,@sesiune=@ses,@parxml=@p

SELECT * INTO #tbl_test FROM
    OPENROWSET(
        'SQLNCLI',
        'Server=(local);trusted_connection=yes',
        'set fmtonly off exec db_test.dbo.xml_test') AS tbl_test;
        
        