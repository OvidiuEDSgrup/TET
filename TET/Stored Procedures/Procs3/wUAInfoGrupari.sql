create PROCEDURE [dbo].[wUAInfoGrupari]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @codabonat varchar(30),@filtrucontract varchar(30),@filtrudenabonat varchar(30)  
select @codabonat=isnull(@parXML.value('(/row/@codabonat)[1]', 'varchar(30)'), '')  

select rtrim(z.Denumire_zona) as denzona,rtrim(cc.Denumire_centru) as dencentru,rtrim(g.Denumire) as dengrupa,
RTRIM(lm.Denumire) as denlm
from abonati a left outer join Zone z on a.zona=z.zona
left outer join Centre cc on a.Centru=cc.Centru
left outer join Grabonat g on a.Grupa=g.Grupa
left outer join lm on a.Loc_de_munca=lm.Cod  
where a.abonat=@codabonat
order by a.denumire
for xml raw
