--***
create procedure wIaConfigurareAntet @sesiune varchar(30), @parXML xml
as
  
--Declare @sesiune varchar(30), @parXML xml
--Set @sesiune = ''
--Set @parXML = '<row tipMacheta="D"  codMeniu="DO" Tip="RM"/>'

Declare @parTipMacheta varchar(20), @parCodMeniu varchar(20), @parTip varchar(20)
  
Set @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]','varchar(20)')
Set @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]','varchar(20)')
Set @parTip = @parXML.value('(/row/@Tip)[1]','varchar(20)')
 
declare @utilizator varchar(255),@limba varchar(50)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)

select	case when TipObiect='ACA' then 'AC' else rtrim(TipObiect) end as TipObiect, 
		dbo.wfTradu(@limba,
		rtrim(f.Nume)) as Nume, 
		dbo.wfTradu(@limba,rtrim(f.Tooltip)) as Tooltip, 
		rtrim(f.DataField) DataField, 
		rtrim(f.LabelField) LabelField, 
		f.Latime Latime, 
		rtrim(f.ProcSQL) ProcSQL, 
		rtrim(f.ListaValori) ListaValori, 
		rtrim(f.ListaEtichete) ListaEtichete, 
		rtrim(f.Initializare) Initializare, 
		dbo.wfTradu(@limba,rtrim(f.Prompt)) as Prompt, 
		f.Modificabil Modificabil,
		case when TipObiect='ACA' then detalii end detalii
from webConfigForm f --left join webconfigmeniu m on f.meniu=m.meniu
where f.Meniu = @parCodMeniu and f.Tip = @parTip and ISNULL(f.subtip,'')=''
	--and (m.meniu is null or (case when m.tipMacheta = @parTipMacheta)
and f.Vizibil = 1
order by Ordine
for xml raw
