--***
/* citeste si returneaza taburile configurate pentru o macheta */
create procedure wIaConfigurareTaburi @sesiune varchar(30), @parXML xml
as

-- mitz: ce nu e facut, si va trebui
-- 1. citire drepturi
-- 2. configurari icoane - optional
-- in frame, determinare label la machete tip poz. doc. deschise din alt poz.doc.
-- formulare


--Declare @sesiune varchar(30), @parXML xml
--Set @sesiune = ''
--Set @parXML = '<row tipMacheta="C" codMeniu="N" />'

declare @tip varchar(20), @codMeniu varchar(20)

-- citesc meniul din care este apelata functia...
select	@codMeniu = @parXML.value('(/row/@codmeniu)[1]','varchar(20)'),
		@tip = ISNULL(@parXML.value('(/row/@tip)[1]','varchar(20)'),'')

declare @utilizator varchar(255),@limba varchar(50)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @limba= dbo.wfProprietateUtilizator('LIMBA',@utilizator)

select wTab.NumeTab as tab, (case wTab.TipMachetaNoua when 'pozdoc' then 'pd' /*in frame astept tipmacheta=pd la pozitii document*/ else wTab.TipMachetaNoua end) as tipmacheta, 
	wTab.MeniuNou as codmeniu, wTab.TipNou as tip, wTab.ProcPopulare as procpopulare,
	-- mitz: acest select trebuie intretinut si in procedura wIaConfigurareTipuri pana la unificarea lor.
	isnull((select Tip tip, dbo.wfTradu(@limba,Nume) as nume, dbo.wfTradu(@limba,Descriere) as descriere, rtrim(ProcDate) procdate, RTRIM(ProcStergere) procstergere, 
	rtrim(ProcScriere) procscriere, procdatepoz procdatepoz, ProcScrierePoz procscrierepoz, ProcStergerePoz procstergerepoz, 
	Fel fel, rtrim(procPopulare) procpopulare,
	RTRIM(TextAdaugare) TextAdaugare, rtrim(TextModificare) TextModificare
	from webConfigTipuri wTip
	where -- la tipMacheta de tip pozdoc, citim tipurile tot din tip D
/*	wTip.tipMacheta = (case wTab.TipMachetaNoua 
							when 'pozdoc' then 'D' /*tab de tip pozitie document*/
							when 'pd' then 'D' /*tab de tip pozitie document*/
							when 'E' then 'D' /*tab de tip document fara filtru pe data*/ 
							when 'F' then 'C' /*tab de tip form - momentan citeste configurari ca si pentru editarea unei linii din macheta tip Catalog*/ 
							else wTab.TipMachetaNoua end) 
	and*/ ISNULL(wTab.MeniuNou,'') = isnull(wTip.Meniu,'') and ISNULL(wTab.TipNou,'') = ISNULL(wTip.Tip,'')
	and ISNULL(subtip,'') = '' /*and Vizibil = 1 -- dezactivat pt. ca la citirea la cataloage, vizibil=0 pentru linia care descrie macheta; altfel apare o linie goala in combo detalieri*/
	order by Ordine
	for xml raw('macheta'), type
	),'') configurari
from webConfigTaburi wTab
where wTab.MeniuSursa = @codMeniu and isnull(wTab.TipSursa,'') = @tip
and wTab.Vizibil = 1
order by wTab.Ordine
for xml raw

--Testare 
/*

exec wIaConfigurareTaburi '','<row codmeniu="DO" tip="RM"  />'
exec wIaConfigurareTaburi '','<row codmeniu="DO"  />'

select * from webconfigtaburi 



*/
  
  
