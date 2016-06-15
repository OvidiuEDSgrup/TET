--***
Create procedure wIaConfigurareInput @sesiune varchar(30), @parXML xml
as
  
--Declare @sesiune varchar(30), @parXML xml
--Set @sesiune = ''
--Set @parXML = '<row tipMacheta="D" codMeniu="DO" Tip="RM" subtip=" />'

-- update webconfigform set formula='Number(row.@cantitate)*10' where tip='rm' and subtip='rm' and DataField='@pvaluta'
-- update webconfigform set formula='Number(row.@pvaluta)/10' where tip='rm' and subtip='rm' and DataField='@cantitate'
-- update webconfigform set formula='String(Number(row.@cantitate)+Number(row.@cantitate))' where tip='rm' and subtip='rm' and DataField='@barcod'

Declare @parTipMacheta varchar(2), @parCodMeniu varchar(20), @parTip varchar(2)
  
Set @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]','varchar(2)')
Set @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]','varchar(20)')
Set @parTip = isnull(@parXML.value('(/row/@Tip)[1]','varchar(2)'),'')

declare @utilizator varchar(255),@limba varchar(50)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)

select	case when TipObiect='ACA' then 'AC' else rtrim(TipObiect) end as TipObiect, 
		rtrim(subtip) as subtip, 
		rtrim(dbo.wfTradu(@limba,Nume)) as Nume, 
		RTRIM(DataField) AS DataField, 
		RTRIM(LabelField) AS LabelField, 
		Latime, 
		rtrim(ProcSQL) ProcSQL, 
		RTRIM(ListaValori) AS ListaValori, 
		RTRIM(ListaEtichete) as ListaEtichete, 
		rtrim(dbo.wfTradu(@limba,Prompt)) as Prompt, 
		RTRIM(Initializare) as Initializare, 
		Modificabil, 
		RTRIM(formula) as formula,
		case when TipObiect='ACA' then detalii end detalii
from webConfigForm
where --tipMacheta = @parTipMacheta and 
	Meniu = @parCodMeniu and isnull(Tip,'') = @parTip 
and isnull(subtip,'') <> '' and Vizibil = 1
order by subtip, Ordine
for xml raw

--Testare 
-- exec wIaConfigurareInput '','<row tipMacheta="D"  codMeniu="DO" Tip="RM"/>'
  
