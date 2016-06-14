declare @p2 xml
set @p2=convert(xml,N'')
exec wIauStructuraRapoarte @sesiune='984DA29425836',@parXML=@p2
go
declare @p2 xml
set @p2=convert(xml,N'<row path="/CG/Contabilitate/Balanta contabila"/>')
exec wReportParam @sesiune='984DA29425836',@parXML=@p2