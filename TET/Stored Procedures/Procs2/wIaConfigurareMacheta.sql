--***
create procedure wIaConfigurareMacheta @sesiune varchar(30), @parXML xml
as
Declare @parTipMacheta varchar(2), @parCodMeniu varchar(20), @parInDetaliere int, @parTipDetaliere varchar(20),@parTip varchar(2),@parSubtip varchar(2)
  
Set @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]','varchar(2)')
Set @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]','varchar(20)')
Set @parTipDetaliere = isnull(@parXML.value('(/row/@TipDetaliere)[1]','varchar(20)'), ISNULL(@parXML.value('(/row/@tip)[1]','varchar(20)'),''))
Set @parSubtip = isnull(@parXML.value('(/row/@subtip)[1]','varchar(2)'),'')

declare @utilizator varchar(255),@limba varchar(50), @existaTip bit
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)

--> daca nu exista tipul si suntem pe un catalog se va considera ca este cazul special al catalogului cu tip necompletat (vezi si conditia din ultimul select):
select @existaTip=0
if exists (select 1 from webconfigtipuri t where t.meniu=@parCodMeniu and @parTipDetaliere=isnull(t.tip,''))
	select @existaTip=1

select dbo.wfTradu(@limba,w.Nume) as Nume, dbo.wfTradu(@limba,w.Descriere) as Descriere, rtrim(w.ProcDate) ProcDate, RTRIM(w.ProcStergere) ProcStergere, 
	rtrim(w.ProcScriere) ProcScriere, RTRIM(w.TextAdaugare) TextAdaugare, rtrim(w.TextModificare) TextModificare, 
	(case when ((w.fel='O' or isnull(m.TipMacheta,'')='O')  and isnull(w.procPopulare,'')='') then 'wPopulareOperatie' else rtrim(w.procPopulare) end ) ProcPopulare,
	(case when @parTipMacheta='O' and Ordine>30 then Ordine else null end) as RequestTimeout
from webConfigTipuri w 
left join webconfigmeniu m on w.meniu=m.meniu
where --tipMacheta = @parTipMacheta and 
	w.Meniu = @parCodMeniu 
	--AND isnull(w.Tip, '') = @parTipDetaliere
	and (m.TipMacheta='C' and @existaTip=0 or ISNULL(w.tip,'') = @parTipDetaliere)
	AND (@parSubtip = '' OR isnull(w.Subtip,'') = @parSubtip)
for xml raw

--Testare 
-- exec wIaConfigurareMacheta '','<row tipMacheta="C"  codMeniu="T"/>'
-- exec wIaConfigurareMacheta '','<row tipMacheta="C"  codMeniu="T" TipDetaliere="PC" />'
-- exec wIaConfigurareMacheta '','<row tipMacheta="D"  codMeniu="BK" />'
-- exec wIaConfigurareMacheta '','<row tipMacheta="D"  codMeniu="CO" TipDetaliere="BK"  subtip="ST" />'
-- exec wIaConfigurareMacheta '','<row tipMacheta="O"  codMeniu="SD"/>'

-- select * from webConfigTipuri where tipmacheta='C' and meniu='T'
-- select * from webConfigTipuri where tipmacheta='D' and meniu='DO' and tip='rm'
-- select * from webConfigTipuri where tipmacheta='D' and meniu='co' 
-- select * from webConfigTipuri where tipmacheta='O' and meniu='RF' 

