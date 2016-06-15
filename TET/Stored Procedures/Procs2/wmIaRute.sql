--***
create procedure wmIaRute @sesiune varchar(50), @parXML xml as  
set transaction isolation level READ UNCOMMITTED  
if exists(select * from sysobjects where name='wmIaRuteSP' and type='P')  
begin
	exec wmIaRuteSP @sesiune, @parXML   
	return 0
end

declare @utilizator varchar(20)
exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator output
if @utilizator is null 
	return -1

declare @areFiltruRuta int
if exists(select * from proprietati pr where pr.tip='UTILIZATOR' and pr.cod_proprietate='RUTA' and pr.Cod=@utilizator and pr.valoare<>'')
	set @areFiltruRuta=1
else
	set @areFiltruRuta=0

select rtrim(r.cod) as ruta, rtrim(r.denumire) as denumire
from ruteliv r
left outer join proprietati pr on pr.tip='UTILIZATOR' and pr.cod_proprietate='RUTA' and pr.cod=@utilizator
where (@areFiltruRuta=0 or pr.valoare=r.Cod)
order by r.cod
for xml raw

select 'wmIaTerti' as detalii,1 as areSearch, 1 toateAtr
for xml raw,Root('Mesaje')  
