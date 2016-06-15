--***
create procedure wIaConfigurareFiltre @sesiune varchar(30), @parXML xml
as
  
--Declare @sesiune varchar(30), @parXML xml
--Set @sesiune = ''
--Set @parXML = '<row tipMacheta="C" codMeniu="N" Tip="N"/>'

Declare @parTipMacheta varchar(2), @parCodMeniu varchar(20), @parTip varchar(2)
  
Set @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]','varchar(2)')
Set @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]','varchar(20)')
Set @parTip = @parXML.value('(/row/@Tip)[1]','varchar(2)')

declare @utilizator varchar(255),@limba varchar(50)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)

select dbo.wfTradu(@limba,Descriere) as Descriere, dbo.wfTradu(@limba,Prompt1) as Prompt1, DataField1, 
dbo.wfTradu(@limba,Prompt2) as Prompt2, DataField2, Interval 
from webConfigFiltre 
where Meniu = @parCodMeniu and /*La cataloage doar meniul conteaza, nu si tipul*/(Tip = @parTip OR @parTipMacheta in ('C','H','GT')) and Vizibil = 1
order by Ordine
for xml raw

--Testare 
--exec wIaConfigurareFiltre '','<row tipMacheta="C" codMeniu="N" Tip="N" />'
  
