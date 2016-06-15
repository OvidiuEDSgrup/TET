--***
CREATE procedure [dbo].[wIaHartaTerti] @sesiune varchar(50), @parXML xml
as
begin
set transaction isolation level READ UNCOMMITTED
declare @filtruadresa varchar(100),@filtrulocalitate varchar(100)
set @filtruadresa = '%'+isnull(@parXML.value('(/row/@adresa)[1]', 'varchar(100)'), '')+'%'
set @filtrulocalitate = '%'+isnull(@parXML.value('(/row/@localitate)[1]', 'varchar(100)'), '')+'%'

select top 100
rtrim(t.denumire) as descriere,rtrim(t.adresa) as adresa,cx,cy,'0xFF0000' as culoare
from Harti h
inner join terti t on t.Tert=h.Cod
left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
where h.tip='T' 
and t.adresa like @filtruadresa
and isnull(l.oras, t.localitate) like @filtrulocalitate
for xml raw

/*
--pentru functia de refresh automat
select 5 as refresh for xml raw,root('Mesaje')
*/
end
