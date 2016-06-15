--***
/****** Object:  StoredProcedure [dbo].[wUAIaCentre]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAIaCentre] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @utilizator char(10), @userASiS varchar(20)

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select	rtrim(a.centru) as centru,rtrim(a.denumire_centru) as dencentru,
		isnull(RTRIM(b.oras),'') +' Jud '+isnull(RTRIM(b.cod_judet),'')as denlocalitate,
		RTRIM(a.localitate) as localitate,rtrim(a.loc_de_munca) as lm,rtrim(d.denumire) as denlm
from centre a
	left outer join localitati b on a.localitate=b.cod_oras 
	left outer join judete c on b.cod_judet=c.cod_judet 
	left outer join lm d on a.loc_de_munca=d.cod
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
where (@lista_lm=0 or lu.cod is not null)	
for xml raw
