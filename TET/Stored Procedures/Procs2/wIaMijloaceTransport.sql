--***
CREATE procedure wIaMijloaceTransport @sesiune varchar(40), @parXML xml
as
declare @returnValue int
if exists(select * from sysobjects where name='wIaMijloaceTransportSP' and type='P')      
begin
	exec @returnValue = wIaMijloaceTransportSP @sesiune,@parXML
	return @returnValue 
end

declare @Tert varchar(20)
set @Tert = @parXML.value('(/row/@tert)[1]', 'varchar(20)')

select rtrim(numarul_mijlocului) as idMasina, (case when p.Valoare=numarul_mijlocului then 1 else 0 end) as ordine
from masinexp 
left outer join proprietati p on p.tip='TERT' and p.cod=furnizor and p.cod_proprietate='UltMasina'
where Furnizor=@Tert
order by ordine desc, Numarul_mijlocului
for xml raw

--select * from masinexp
--select * from proprietati where tip='TERT'
