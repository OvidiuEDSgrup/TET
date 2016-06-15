
create procedure [dbo].[wACStariContracte] @sesiune varchar(50), @parXML xml
as
declare @tip varchar(20)

set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')

select distinct stare as cod, denumire 
from StariContracte
where (@tip='' or tipContract = @tip)
for xml raw

