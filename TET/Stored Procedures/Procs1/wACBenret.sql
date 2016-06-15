--***
Create procedure wACBenret @sesiune varchar(50), @parXML XML
as

declare @Subtipret int
Set @Subtipret=dbo.iauParL('PS','SUBTIPRET')

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(cod_beneficiar) as cod, (case when @Subtipret=1 then rtrim(b.denumire) else 
(case when a.tip_retinere='1' then 'Debite externe' when a.tip_retinere='2' then 'Rate' when a.tip_retinere='3' then 'Debite interne' 
when a.tip_retinere='4' then 'CAR cont curent' when a.tip_retinere='5' then 'Pensii facultative' else '' end) end) as info,  
rtrim(denumire_beneficiar) as denumire
from benret a
left outer join tipret b on a.tip_retinere=b.Subtip
where (cod_beneficiar like @searchText+'%' or denumire_beneficiar like '%'+@searchText+'%')
order by cod_beneficiar
for xml raw
