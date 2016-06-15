--***
CREATE procedure wACLocm @sesiune varchar(50), @parXML XML
as
set transaction isolation level read uncommitted
if exists (select * from sysobjects where name='wACLocmSP' and type='P')      
begin
	exec wACLocmSP @sesiune, @parXML
	return 0
end
declare @searchText varchar(80), @userASiS varchar(10), @lista_lm bit,@faraRestrictiiProp int

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
	@faraRestrictiiProp=ISNULL(@parXML.value('(/row/@faraRestrictiiProp)[1]', 'int'), 0)
		-->daca se trimite =1 atunci sa se returneze toate locurile de munca, netinandu-se cont de locurile de munca din proprietati
set @searchText=REPLACE(@searchText, ' ', '%')

--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
/*Modificare pentru login utilizator sa */
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

select @lista_lm=dbo.f_arelmfiltru(@userASiS)

select top 100 rtrim(lm.Cod) as cod, rtrim(lm.Denumire) as denumire
from lm
	left join lmfiltrare l on lm.cod=l.cod and l.utilizator=@userASiS
where (lm.cod like replace(@searchText,' ','%')+'%' or lm.denumire like '%'+@searchText+'%')
and ((@lista_lm=0 or l.utilizator is not null) or @faraRestrictiiProp=1)
order by patindex(@searchText+'%',lm.cod) desc,rtrim(lm.cod)
for xml raw
