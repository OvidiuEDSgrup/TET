--***
/****** Object:  StoredProcedure [dbo].[wUAIaCentre]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAIaInfoContracte] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @utilizator char(10), @userASiS varchar(20),@filtruInfo varchar(20),@filtrulocalitate varchar(30),
		@filtruLm varchar(30),@filtruZona varchar(30)

select 
	@filtruInfo = replace(isnull(@parXML.value('(/row/@filtruInfo)[1]','varchar(30)'),'%'),' ','%'),
	@filtruLm = replace(isnull(@parXML.value('(/row/@filtruLm)[1]','varchar(30)'),'%'),' ','%')	

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select	rtrim(a.Cod) as cod,rtrim(a.Descriere) as descriere,
		rtrim(a.loc_de_munca) as lm,rtrim(d.denumire) as denLm,RTRIM(Info1)as info1,rtrim(Info2) as info2,
		RTRIM(Info3)as info3
		
from infocontracte a
		left outer join lm d on a.loc_de_munca=d.cod
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod
where (@lista_lm=0 or lu.cod is not null)	
  and (a.Descriere like '%'+@filtruInfo+'%' or a.Cod like @filtruInfo+'%' or @filtruInfo='')
  and (d.Denumire like '%'+@filtrulm+'%' or a.Loc_de_munca like @filtruLm+'%' or @filtruLm='')
 for xml raw
--select * from sp_help infocontracte
