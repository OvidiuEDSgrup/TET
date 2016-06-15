--***
CREATE procedure [dbo].[wIaSarcini] 
  @sesiune varchar(50), @parXML xml
as


declare @descriere varchar(200), @stare varchar(50), @utilizator varchar(30), @descrieres varchar(50), 
@tip varchar(2), @dataj datetime, @datas datetime, @codsesizare varchar(10), @cod varchar(15), @usr varchar(5)


select @descriere = isnull(@parXML.value('(/row/@f_descriere)[1]', 'varchar(200)'), ''),
	@dataj = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), ''),
	@datas = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), ''),
	@utilizator = isnull(@parXML.value('(/row/@f_utilizator)[1]', 'varchar(30)'), ''),
	@descrieres = isnull(@parXML.value('(/row/@f_descrieres)[1]', 'varchar(50)'), ''),
	@stare = isnull(@parXML.value('(/row/@f_stare)[1]', 'varchar(50)'), ''),
	@codsesizare = isnull(@parXML.value('(/row/@f_codsesizare)[1]', 'varchar(10)'), ''),
	@cod = isnull(@parXML.value('(/row/@cod)[1]', 'varchar(15)'), '')
	
set @descriere='%'+REPLACE(@descriere,' ','%')+'%'
set @utilizator= '%'+REPLACE(@utilizator,' ','%')+'%'
set @descrieres='%'+REPLACE(@descrieres,' ','%')+'%'
set @stare='%'+REPLACE(@stare,' ','%')+'%'
set @codsesizare='%'+REPLACE(@codsesizare,' ','%')+'%'

select @usr= valoare from (
		select cod,Cod_proprietate,valoare from proprietati where Tip='UTILIZATOR'  and cod like '%'+SUBSTRING(SUSER_NAME(),6,20)+'%' ) as p
			where p.cod_proprietate='PERSOANA'

select top 100
(case when Stare_sarcina in (0,1) then 'Nepreluata' when Stare_sarcina = 2 then 'In Lucru' else 'Finalizata' end) as stare,
rtrim(s.IDSarcina) as cod, convert(char(10),s.Data_sarcina,101) as data_sarcina, rtrim(s.Descriere_scurta) as Subiect, rtrim(s.Descriere) as descriere, 
ISNULL(rtrim(t.Denumire),'<intern>') as 'client', rtrim(i.descriere) as utilizator, i.Identificator as cod_angajat,
(case when Stare_sarcina in (0,1) then '#FF0000' when Stare_sarcina = 2 then '#000000' else '#00CC00' end) as culoare,
s.Ore_estimate as ore_estimate, Data_estimata as data_estimat, Termen_realizare as termen, Valoare_estimata as valoare,
Data_start as data_inceput, Data_stop as data_sfarsit, rtrim(Numar_contract) as contract,
(case when s.Tip_sarcina ='P' then 'Programare' when s.Tip_sarcina ='A' then 'Altele' when s.Tip_sarcina ='S' then 'Servicii'
when s.Tip_sarcina ='I' then 'Implementare' else 'Nelucrat' end) as tip,
s.Ore_realizate as ore_realizate,s.Ora_start, s.Ora_stop, rtrim(s.IDSesizare) as idsesizare
,(case  when s.Stare_sarcina < =1 then 1 when s.Stare_sarcina >= 3 then 3 else 2 end) as num_stare,
(case when Stare_sarcina >  2 then '1' else '0'end) as _nemodificabil,
s.Proiect as proiect

from sarcini s
left outer join terti t on t.Tert=s.IDC
left outer join infotert i on   I.Identificator=s.ID_user and i.Subunitate='C1' and i.tert='1'

where Descriere_scurta like @descrieres and s.Descriere like @descriere
and i.Descriere like @utilizator
--and s.ID_user = @usr
and s.IDSesizare like @codsesizare
and s.Data_sarcina between @dataj and (case when @datas<='01/01/1901' then '12/31/2999' else @datas end)
and s.IDSarcina like @cod + '%'
and (case when Stare_sarcina in (0,1) then 'Nepreluata' when Stare_sarcina = 2 then 'In Lucru' else 'Finalizata' end) like @stare

order by s.data_sarcina desc

for xml raw
