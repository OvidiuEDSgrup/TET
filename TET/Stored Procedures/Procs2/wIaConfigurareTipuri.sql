--***
create procedure wIaConfigurareTipuri @sesiune varchar(30), @parXML xml
as
  
--Declare @sesiune varchar(30), @parXML xml
--Set @sesiune = ''
--Set @parXML = '<row tipMacheta="C" codMeniu="N" />'

Declare @parTipMacheta varchar(2), @parCodMeniu varchar(20), @tip varchar(20)
  
Set @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]','varchar(2)')
Set @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]','varchar(20)')
set @tip = @parXML.value('(/row/@tip)[1]','varchar(2)') -- filtru aplicat cand vrem sa afisam un singur tip de document, util pentru taburi

declare @utilizator varchar(255),@limba varchar(50)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)

select @tip,
	rtrim(Tip) Tip,rtrim(dbo.wfTradu(@limba,Nume)) as Nume, rtrim(ProcDate) ProcDate, rtrim(ProcScriere) ProcScriere, rtrim(ProcStergere) ProcStergere, rtrim(ProcDatePoz) ProcDatePoz,
	rtrim(ProcScrierePoz) ProcScrierePoz, rtrim(ProcStergerePoz) ProcStergerePoz, rtrim(Fel) Fel, rtrim(NULLIF(ProcPopulare,'')) ProcPopulare,	rtrim(nullif(ProcInchidereMacheta,'')) ProcInchidereMacheta
from webConfigTipuri 
where --tipMacheta = @parTipMacheta and 
	Meniu = @parCodMeniu 
	--and (@tip is null or tip=@tip)
	--and ISNULL(subtip,'') = '' and ISNULL(tip,'') <> '' and Vizibil = 1
order by Ordine

-- atentie: momentan aceste configurari se citesc si in procedura wIaConfigurareTaburi.
-- cand sunt modificari se vor actualiza ambele, pana cand se vor unifica in o singura procedura.
select 
	rtrim(Tip) Tip,rtrim(dbo.wfTradu(@limba,Nume)) as Nume, rtrim(ProcDate) ProcDate, rtrim(ProcScriere) ProcScriere, rtrim(ProcStergere) ProcStergere, rtrim(ProcDatePoz) ProcDatePoz,
	rtrim(ProcScrierePoz) ProcScrierePoz, rtrim(ProcStergerePoz) ProcStergerePoz, rtrim(Fel) Fel, rtrim(NULLIF(ProcPopulare,'')) ProcPopulare,	rtrim(nullif(ProcInchidereMacheta,'')) ProcInchidereMacheta
from webConfigTipuri 
where --tipMacheta = @parTipMacheta and 
	Meniu = @parCodMeniu and (@tip is null or tip=@tip)
	and ISNULL(subtip,'') = '' and ISNULL(tip,'') <> '' and Vizibil = 1
order by Ordine
for xml raw

--Testare 
--exec wIaConfigurareTipuri '','<row tipMacheta="D"  codMeniu="DO"/>'
--exec wIaConfigurareTipuri '','<row tipMacheta="C"  codMeniu="N"/>'
  
  
