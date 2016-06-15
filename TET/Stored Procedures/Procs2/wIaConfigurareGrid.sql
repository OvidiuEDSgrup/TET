--***
create procedure wIaConfigurareGrid @sesiune varchar(30), @parXML xml
as
  
--Declare @sesiune varchar(30), @parXML xml
--Set @sesiune = ''
--Set @parXML = '<row tipMacheta="C" codMeniu="N" Tip="N" />'

declare @utilizator varchar(255),@limba varchar(50)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)

Declare @parTipMacheta varchar(20), @parCodMeniu varchar(20)
  
Set @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]','varchar(20)')
Set @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]','varchar(20)')

select dbo.wfTradu(@limba,g.numecol) as numecol, g.datafield, g.TipObiect, g.latime
from webConfigGrid g inner join webconfigmeniu m on g.meniu=m.meniu
where m.tipMacheta = @parTipMacheta and g.Meniu = @parCodMeniu 
and isnull(g.Tip,'')=''
--and (subtip = @parsubtip or (@parsubtip is null and subtip is null))
and g.Vizibil = 1
order by Ordine
for xml raw

--Testare 
-- exec wIaConfigurareGrid '','<row tipMacheta="C" codMeniu="N" Tip="N"/>'
  
