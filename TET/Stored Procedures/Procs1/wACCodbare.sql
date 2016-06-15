--***
create procedure wACCodbare @sesiune varchar(50), @parXML XML
as
if exists (select 1 from sys.objects where name='wACCodbareSP' and type='P')  
begin
	exec wACCodbareSP @sesiune, @parXML
	return
end

declare @cod varchar(20), @searchText varchar(20)
select	--@searchText=@parXML.value('(/row/@searchText)[1]','varchar(20)'),
		@cod=isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),'')

select top 100 
RTRIM(cod_de_bare) as cod,
RTRIM(cod_de_bare) as denumire
from codbare
where codbare.Cod_produs=@cod
union all
select 'GENERARE',
'Generare cod de bare nou'

for xml raw
