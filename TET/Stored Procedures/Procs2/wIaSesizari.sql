--***
CREATE procedure  [dbo].[wIaSesizari] 

 @sesiune varchar(50), @parXML xml
as
declare @descriere varchar(200),@stare varchar(10), @utilizator varchar(30), @descrieres varchar(50),
		@client varchar(50), @dataj datetime, @datas datetime, @tip varchar(10), @cod varchar(10) , @cod_ses varchar(15), @distrib varchar(10),
		@meniu varchar(2)


select 
	@descriere = rtrim(isnull(@parXML.value('(/row/@f_descriere)[1]', 'varchar(200)'), '')),
	@utilizator = rtrim(isnull(@parXML.value('(/row/@f_utilizator)[1]', 'varchar(30)'), '')),
	@descrieres = rtrim(isnull(@parXML.value('(/row/@f_descrieres)[1]', 'varchar(50)'), '')),
	@client = rtrim(isnull(@parXML.value('(/row/@f_client)[1]', 'varchar(50)'), '')),
	@dataj = rtrim(isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '')),
	@datas = rtrim(isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '')),
	@tip =rtrim(isnull(@parXML.value('(/row/@f_tip)[1]', 'varchar(10)'), '')),
	@cod =rtrim(isnull(@parXML.value('(/row/@f_cod)[1]', 'varchar(10)'), '')),
	@stare =rtrim(isnull(@parXML.value('(/row/@f_stare)[1]', 'varchar(10)'), '')),
	@cod_ses =rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(14)'), '')),
	@meniu =rtrim(isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''))
	
set @descriere='%'+REPLACE(@descriere,' ','%')+'%'
set @utilizator= '%'+REPLACE(@utilizator,' ','%')+'%'
set @descrieres='%'+REPLACE(@descrieres,' ','%')+'%'
set @client = '%'+REPLACE(@client,' ','%')+'%'
set @stare = '%'+REPLACE(@stare,' ','%')+'%'
set @tip = '%'+REPLACE(@tip,' ','%')+'%'
set @cod = '%'+REPLACE(@cod,' ','%')+'%'

select 
	@distrib = valoare from proprietati where tip = 'UTILIZATOR' and  cod_proprietate = 'DISTRIBUITOR' and cod like '%'+SUBSTRING(SUSER_NAME(),6,20)+'%'


select top 100 
convert(char(10),s.Data_postarii,101) as data_postarii,
s.cod as cod,s.descrieres as descrieres , ISNULL(t.Denumire,'') as tert,
 (select denumire from terti where tert = s.Client  )as client, s.Utilizator as utilizator, s.Descriere as descriere, 
S.Raspuns as raspuns, (case when s.Tip_sesizare = 'A' then 'Asistenta' when s.tip_sesizare = 'D' then 'Dezvoltare'  when s.tip_sesizare = 'V' then 'Viciu' when s.tip_sesizare='S' then 'Serviciu' end) as tip_interpretat,
 s.tip_sesizare as tip,s.Observatii_validare as observatii,
(case when s.Stare = 'F' then '#00CC00' when s.stare = 'L' then '#000F00' when s.Stare = 'N'then '#FF0000' end) as culoare,
(case when s.Stare = 'F' then 'Finalizata' when s.stare = 'L' then 'In Lucru' when s.Stare = 'N'then 'Nepreluata' end) as stare
,(case when s.stare = 'F' then '1' else '0'end) as _nemodificabil,
s.Aplicatie as aplicatie,s.Sistem as sistem, (case  when s.stare ='L' then 2 when s.stare='F' then 3 else 1 end) as num_stare,
i.descriere as contact 


from sesizari s
left outer join terti t on t.Tert=s.IDC 
left outer join infotert i on t.Tert = i.tert and i.Subunitate='C1'  and s.Persoana_contact = i.Identificator


where t.Tert like 
(case when @meniu = 'SC' then @distrib else '%' end) and
s.descrieres like @descrieres and s.Descriere like @descriere 
and s.utilizator like @utilizator
and  (select denumire from terti where tert = s.Client  )like @client
and s.Cod like @cod
and s.Data_postarii between @dataj and (case when @datas<='01/01/1901' then '12/31/2999' else @datas end)
and (case when s.Tip_sesizare = 'A' then 'Asistenta' when s.tip_sesizare = 'D' then 'Dezvoltare'
when s.tip_sesizare = 'V' then 'Viciu' when s.tip_sesizare='S' then 'Serviciu' end)like @tip
and s.Cod like @cod_ses + '%'
and (case when s.Stare = 'F' then 'Finalizata' when s.stare = 'L' then 'In Lucru' when s.Stare = 'N'then 'Nepreluata' end) like @stare
for xml raw
