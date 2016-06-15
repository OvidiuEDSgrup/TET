--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori ) */
CREATE procedure [dbo].[wIaDateBuget] @sesiune varchar(50), @parXML XML 
as


declare  @categorie varchar(25),@lm varchar(13),@an int,@can varchar(4)
set @categorie= isnull(@parXML.value('(/row/@codCat)[1]', 'varchar(25)'), '')	
set @lm= isnull(@parXML.value('(/row/@lm)[1]', 'varchar(13)'), '')	
set @can= isnull(@parXML.value('(/row/@an)[1]', 'int'), 1)	
if ISNUMERIC(@can)=1 and CONVERT(int,@can)>1920
	set @an=CONVERT(int,@can)
else
	set @an=YEAR(getdate())

declare @datajos datetime,@datasus datetime
set @datajos='01/01/'+ltrim(str(@an))
set @datasus='12/31/'+ltrim(str(@an))

select dbo.iaArboreTB(@categorie,'',@datajos,@datasus,@lm)
for xml path('Ierarhie'),root('Date')
