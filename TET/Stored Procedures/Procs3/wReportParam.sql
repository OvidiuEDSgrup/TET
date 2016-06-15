--***
create procedure wReportParam @sesiune varchar(50), @parXML xml output
as

begin try

declare @eroare varchar(1000), @bdrep varchar(100), @xml xml, @path varchar(2000), @fara_luare_date int
select @bdrep=rtrim(val_alfanumerica) from par where tip_parametru='AR' and parametru='REPSRVBAZ'

set @bdrep=(case when isnull(@bdrep,'') = '' then 'ReportServer' else @bdrep end)

if not exists (select 1 from sys.databases where name=@bdrep)
begin
	set @eroare='Baza de date pentru Reporting ("'+@bdrep+'") nu se afla pe server!'
	raiserror(@eroare,16,1)
end

/*Daca se extrage un raport de contabilitate vom fi atenti sa rulam generarea notelor contabile aferente documentelor necontate deja*/
select	@path=isnull(@parXML.value('(/row/@path)[1]', 'varchar(255)'), ''),
		@fara_luare_date=isnull(@parXML.value('(/row/@fara_luare_date)[1]', 'int'), 0)

declare @comanda nvarchar(4000)

set @comanda=
'
select @xml = convert(xml,parameter) 
from ['+@bdrep+']..catalog
where path=@path
'
exec sp_executesql @statement=@comanda, @params=N'@path as varchar(2000), @xml as xml output', @path=@path, @xml=@xml output

set @parXML=@xml

if @fara_luare_date=0
	select @xml as par
	for xml raw
	
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wReportParam linia '+convert(varchar(20),ERROR_LINE())+')'
			
	raiserror(@eroare,16,1)
end catch
