
Create procedure wOPImportMachete_p @sesiune varchar(50), @parXML xml
as

declare @meniuXML xml, @tipuriXML xml, @selSelectare varchar(1), @selSuprascriere bit

select	@selSelectare= isnull(@parXML.value('(/*/@selSelectare)[1]','varchar(1)'),''),
		@selSuprascriere = isnull(@parXML.value('(/*/@selSuprascriere)[1]','bit'),'')

if isnull(@parXML.value('count(/row/machete/meniuri)','int'),0)<>0
begin
		select @meniuXML =
		(select
		 t.c.value('@Meniu','varchar(20)') s_meniu, t.c.value('@Nume','varchar(30)') s_nume, t.c.value('@MeniuParinte','varchar(20)') s_meniuparinte,
		 t.c.value('@Icoana','varchar(50)') s_icoana, t.c.value('@TipMacheta','varchar(5)') s_tipmacheta,
		 t.c.value('@NrOrdine','decimal(7,2)') s_nrordine,  t.c.value('@Componenta','varchar(100)') s_componenta,
		 t.c.value('@Semnatura','varchar(100)') s_semnatura, t.c.query('/*/*/*/detalii'),
		 t.c.value('@vizibil','bit') s_vizibil, t.c.value('@publicabil','int') s_publicabil, 'webConfigMeniuri' s_sursa,
		 case when m.meniu is not null then 'Da' else 'Nu' end s_existent, 
		 (case when m.meniu is null then 0 else @selSuprascriere end) s_suprascriere,
		 (case	when @selSelectare='T' or
					@selSelectare='E' and m.meniu is not null or
					@selSelectare='I' and m.meniu is null  then 1 else 0 end)
			s_selectare
		from @parXML.nodes('/row/machete/meniuri') t(c)
			left join webConfigMeniu m
				on isnull(Meniu,'')=isnull(t.c.value('@Meniu','varchar(20)'),'')
		for xml raw('meniuri'),type)
end

if isnull(@parXML.value('count(/row/machete/tipuri)','int'),0)<>0
begin
	select @tipuriXML = 
		(select
		 t.c.value('@Meniu','varchar(20)') s_meniu, t.c.value('@Tip','varchar(2)') s_tip, t.c.value('@Subtip','varchar(2)') s_subtip,
		 t.c.value('@Ordine','int') s_ordine, t.c.value('@Nume','varchar(50)') s_nume, t.c.value('@Descriere','varchar(500)') s_descriere,
		 t.c.value('@TextAdaugare','varchar(60)') s_textadaugare, t.c.value('@TextModificare','varchar(60)') s_textmodificare,
		 t.c.value('@ProcDate','varchar(60)') s_procdate, t.c.value('@ProcScriere','varchar(60)') s_procscriere, t.c.value('@ProcStergere','varchar(60)') s_procstergere,
		 t.c.value('@ProcDatePoz','varchar(60)') s_procdatepoz, t.c.value('@ProcScrierePoz','varchar(60)') s_procscrierepoz, 
		 t.c.value('@ProcStergerePoz','varchar(60)') s_procstergerepoz, t.c.value('@Vizibil','bit') s_vizibil, t.c.value('@Fel','varchar(1)') s_fel,
		 t.c.value('@procPopulare','varchar(60)') s_procpopulare, t.c.value('@tasta','varchar(20)') s_tasta, t.c.value('@publicabil','int') s_publicabil,
		 t.c.value('@ProcInchidereMacheta','varchar(60)') s_procinchideremacheta, t.c.query('/*/*/*/detalii'), t.c.value('@sursa','varchar(200)') s_sursa,
		 case when w.meniu is not null then 'Da' else 'Nu' end s_existent, 
		 (case when w.meniu is null then 0 else @selSuprascriere end) s_suprascriere, 
		 (case	when @selSelectare='T' or
					@selSelectare='E' and w.meniu is not null or
					@selSelectare='I' and w.meniu is null  then 1 else 0 end)
			s_selectare
		from @parXML.nodes('/row/machete/tipuri') t(c)
			left join webconfigtipuri w
				on isnull(w.Meniu,'')=isnull(t.c.value('@Meniu','varchar(20)'),'')
				and isnull(w.Tip,'')=isnull(t.c.value('@Tip','varchar(2)'),'')
				and isnull(w.Subtip,'')=isnull(t.c.value('@Subtip','varchar(2)'),'')
		for xml raw('tipuri'),type)
end

delete tabelXML where sesiune=@sesiune
	insert into tabelXML(sesiune, date) values(@sesiune, @parXML)

--> initializare meniu si tip de inlocuit pt optiunea de inlocuire:
declare @old_meniu varchar(200), @old_tip varchar(200)
select @old_meniu=@meniuXML.value('(meniuri/@s_meniu)[1]','varchar(200)')
select @old_tip=@tipuriXML.value('((tipuri)[@s_meniu=sql:variable("@old_meniu")]/@s_tip)[1]','varchar(200)')
select 
'In campurile "nou" de mai jos se pot specifica alta denumire, meniu si/sau tip pentru datele importate.
In campurile "vechi" se specifica pentru ce meniu si/sau ce tip se va modifica.
Atentie! Eventualele submeniuri si taburi ale meniului "vechi" modificat raman neafectate!'
	as specificatie,
	@old_meniu as old_meniu,
	@old_tip as old_tip	
	for xml raw

select 	@meniuXML, @tipuriXML for xml path('DateGrid'),root('Mesaje')
