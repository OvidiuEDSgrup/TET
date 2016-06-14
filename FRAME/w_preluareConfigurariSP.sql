/**	
	Sript de preluare setari din configurarile standard de Ria
*/
/*
--***
if exists (select 1 from sysobjects where name='wPreluareConfigurari')
	drop procedure wPreluareConfigurari
GO
--***
create procedure wPreluareConfigurari (
	@tipMacheta varchar(20)=null, @meniu varchar(20)=null	--> cele doua filtre nu au efect (deocamdata)
	)
as*/
/* probleme netratate la populare:
trebuie candva recreati index-ii pt. tabelele in care se face insert 
la webConfigMeniu, scriptul presupune ca folderele Documente Cataloage si Operatii au ID 1,2,3
*/

declare @webConfigTmp table (tipMacheta varchar(2), meniu varchar(2), exista bit)

begin tran 
begin try

	insert into @webConfigTmp(tipMacheta, meniu, exista)
	select distinct TipMacheta, Meniu, 
	isnull( (select top 1 1 from webConfigMeniu w where w.TipMacheta = STD.TipMacheta
		and w.Meniu = STD.Meniu) , 0) as "exista"
	from webConfigSTDMeniu STD /*where (@tipMacheta is null or std.tipMacheta=@tipMacheta)
			and (@meniu is null or std.meniu=@meniu)*/
	order by STD.TipMacheta ASC, STD.Meniu 

	INSERT INTO webConfigForm(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, 
		DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, 
		Initializare, Prompt, Procesare, Tooltip)
	select 
		IdUtilizator, STD.TipMacheta, STD.Meniu, Tip, Subtip, Ordine, Nume, TipObiect, Datafield, LabelField, 
		Latime, (case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou", Modificabil,
		ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip
	from webConfigSTDForm STD
		inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
	where not exists ( select 1 from webConfigForm w where
			( w.IdUtilizator = STD.IdUtilizator or w.IdUtilizator is null and STD.IdUtilizator is null )
			and ( w.TipMacheta = STD.TipMacheta or w.TipMacheta is null and STD.TipMacheta is null )
			and ( w.Meniu = STD.Meniu or w.Meniu is null and STD.Meniu is null )
			and ( w.Tip = STD.Tip or w.Tip is null and STD.Tip is null )
			and ( w.Subtip = STD.Subtip or w.Subtip is null and STD.Subtip is null )
			and ( w.Datafield = STD.Datafield or w.Datafield is null and STD.Datafield is null )
		)

	INSERT INTO webConfigFiltre(IdUtilizator, TipMacheta, Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2)
	select 
		IdUtilizator, STD.TipMacheta, STD.Meniu, Tip, Ordine, 
		(case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou", TipObiect, 
		Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2
	from webConfigSTDFiltre STD
		inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
	where not exists ( select 1 from webConfigFiltre w where
			( w.IdUtilizator = STD.IdUtilizator or w.IdUtilizator is null and STD.IdUtilizator is null )
			and ( w.TipMacheta = STD.TipMacheta or w.TipMacheta is null and STD.TipMacheta is null )
			and ( w.Meniu = STD.Meniu or w.Meniu is null and STD.Meniu is null )
			and ( w.Tip = STD.Tip or w.Tip is null and STD.Tip is null )
			and ( w.DataField1 = STD.DataField1 or w.DataField1 is null and STD.DataField1 is null )
		)

	INSERT INTO webConfigGrid(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, formula)
	select
		IdUtilizator, STD.TipMacheta, STD.Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, 
		(case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou", STD.formula
	from webConfigSTDGrid STD
		inner join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
	where not exists ( select 1 from webConfigGrid w where
			isnull(w.IdUtilizator,'') = isnull(STD.IdUtilizator,'')
			and isnull(w.TipMacheta,'') = isnull(STD.TipMacheta,'') 
			and isnull(w.Meniu,'') = isnull(STD.Meniu,'') 
			and isnull(w.Tip,'') = isnull(STD.Tip,'') 
			and isnull(w.Subtip,'') = isnull(STD.Subtip ,'') 
			and isnull(w.DataField,'') = isnull(STD.DataField ,'')
			and isnull(w.InPozitii,'') = isnull(STD.InPozitii ,'')
		)

		--> ce facem cu webConfigTaburi si webConfigTipuri? posibila recursivitate a lui webConfigTaburi complica destul de mult eventuala filtrare pe @tipMacheta
	INSERT INTO webConfigTipuri(IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, Descriere, 
		TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, 
		ProcStergerePoz, Vizibil,Fel, procPopulare)
	select	IdUtilizator, std.TipMacheta, std.Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare,
		TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, 
		/* std.vizibil, tmp.exista, */(case when tmp.exista = 1 then 0 else STD.Vizibil end) as "vizibilNou"
		,Fel, procPopulare
	from webConfigSTDTipuri STD left join @webConfigTmp tmp on tmp.TipMacheta = STD.TipMacheta and tmp.Meniu = STD.Meniu
	where not exists (select 1 from webConfigTipuri w where 
			isnull(w.IdUtilizator,'') = isnull(STD.IdUtilizator,'') 
			and isnull(w.TipMacheta,'') = isnull(STD.TipMacheta,'') 
			and isnull(w.Meniu,'') = isnull(STD.Meniu,'') 
			and isnull(w.Tip,'') = isnull(STD.Tip,'') 
			and isnull(w.Subtip,'') = isnull(STD.Subtip ,'') )
		and (tmp.meniu is not null or
			exists (select 1 from webconfigSTDtaburi wt where wt.MeniuSursa = STD.Meniu and wt.TipSursa = STD.Tip
			or wt.MeniuNou = STD.Meniu and wt.TipNou = STD.Tip))

	INSERT INTO webConfigACRapoarte(caleraport, ordine, expresie,proceduraAC)
	select	caleraport, ordine, expresie,proceduraAC
	from webConfigSTDACRapoarte STD
	where not exists (select 1 from webConfigACRapoarte w where 
			isnull(w.caleraport,'') = isnull(STD.caleraport,'') 
			and isnull(w.ordine,'') = isnull(STD.ordine,'') 
			and isnull(w.expresie,'') = isnull(STD.expresie,'') 
			and isnull(w.proceduraAC,'') = isnull(STD.proceduraAC,''))

	INSERT INTO webConfigTaburi(MeniuSursa, TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, ProcPopulare, Ordine, Vizibil)
	select MeniuSursa, TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, std.ProcPopulare, std.Ordine, std.Vizibil
	from webConfigSTDTaburi STD
	where exists (select 1 from webConfigTipuri tmp where tmp.meniu = STD.MeniuSursa and tmp.tip = STD.TipSursa)
		and exists (select 1 from webConfigTipuri n where n.meniu = STD.MeniuNou and n.tip = STD.TipNou)
		and not exists ( select 1 from webConfigTaburi w where
			( isnull(w.meniusursa,'') = isnull(STD.meniusursa,'') or w.MeniuSursa is null and STD.meniusursa is null )
			and ( isnull(w.TipSursa,'') = isnull(STD.TipSursa,'') or w.TipSursa is null and STD.TipSursa is null )
			and ( isnull(w.NumeTab,'') = isnull(STD.NumeTab,'') or w.NumeTab is null and STD.NumeTab is null )
			)

	/* 
	e bine ca insertul in webConfigMeniu sa se faca ultimul, pt. ca daca sunt erori la restul tabelelor, 
	sa nu se populeze meniul pana ce se rezolva problema 
	insertul presupune ca folderele Documente , Cataloage, Operatii au id 1, 2, respectiv 3
	*/
	INSERT INTO webConfigMeniu (id, Nume, idParinte, Icoana, Meniu, Modul, TipMacheta)
	select id, Nume, idParinte, Icoana, Meniu, Modul, TipMacheta
	from 
		webConfigSTDMeniu STD
	where not exists ( select 1 from webConfigMeniu w where
			ISNULL(w.Meniu,'') = ISNULL(STD.Meniu,'')
			and ISNULL(w.TipMacheta,'') = ISNULL(STD.TipMacheta,'')
			)
		and not exists ( select 1 from webConfigMeniu w where
			ISNULL(w.id,'') = ISNULL(STD.id,'')
			and ISNULL(w.idParinte,'') = ISNULL(STD.idParinte,'')
			and ISNULL(w.nume,'') = ISNULL(STD.Nume,'')
			)
commit tran
end try
begin catch 
rollback tran
declare @msgEroare varchar(max)

set @msgEroare = error_message()

raiserror(@msgeroare, 11,1)

end catch