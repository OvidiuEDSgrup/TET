--***
/****** Object:  StoredProcedure [dbo].[wUAIaCentre]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAIaGrAbonati]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @utilizator char(10), @userASiS varchar(20),@filtrustrada varchar(20),@filtrulocalitate varchar(30),
		@filtruLm varchar(30),@filtruZona varchar(30)

select 
	@filtruLm = replace(isnull(@parXML.value('(/row/@filtruLm)[1]','varchar(30)'),'%'),' ','%')
	
---------
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------

select rtrim(g.Grupa) as grupa,rtrim(g.Denumire) as denumire,g.Export_detaliat as detaliat,rtrim(g.Cont) as cont,
	rtrim(g.Loc_de_munca) as lm,rtrim(d.Denumire) as denlm,(case when g.Export_detaliat=0 then 'NU' else 'DA' end) as dendetaliat
from grabonat g
	left outer join lm d on g.loc_de_munca=d.cod
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and g.loc_de_munca=lu.cod
where (@lista_lm=0 or lu.cod is not null)	
for xml raw
--select * from infocontracte
