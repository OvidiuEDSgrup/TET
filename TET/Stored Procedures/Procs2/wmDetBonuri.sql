--***
create procedure wmDetBonuri @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDetBonuriSP' and type='P')
begin
	exec wmDetBonuriSP @sesiune, @parXML 
	return -1
end

declare @datacasa varchar(30),@data char(10),@lm varchar(10),@indexsep int, @utilizator varchar(50)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

select	@datacasa=@parXML.value('(/row/@wmIaBonuri.cod)[1]','varchar(30)'),
		@indexsep=charindex('|',@datacasa),
		@data=LEFT(@datacasa,@indexsep-1),
		@lm=SUBSTRING(@datacasa,@indexsep+1,100)

select top 100 ltrim(str(bp.Numar_bon)) as cod, 
'Bonul: '+ltrim(str(bp.Numar_bon)) as denumire,
ltrim(str(count(*)))+' '+(case when count(*)=1 then 'pozitie' else 'pozitii' end)+', valoare '+
	ltrim(convert(varchar(20),convert(money,sum(convert(decimal(15,2), bp.Total)),1)))+' lei' as info
from bp
where tip='21' and data=convert(datetime,@data,103) and Loc_de_munca=@lm
group by bp.Numar_bon
order by bp.numar_bon desc
for xml raw

select 'Bonuri din :'+@data as titlu,'wmAfiseazaBon' as detalii,0 as areSearch
for xml raw,Root('Mesaje')
