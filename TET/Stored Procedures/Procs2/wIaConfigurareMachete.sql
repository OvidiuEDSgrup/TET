--***
create procedure wIaConfigurareMachete (@sesiune varchar(50), @parXML xml)
as

declare @eroare varchar(max)
select @eroare=''
begin try
	declare @f_meniu varchar(200), @f_nume varchar(200), @f_publicabil varchar(2), @doc xml,
			@f_vizibil varchar(2), @f_tipmacheta varchar(20), @f_tip varchar(10), @f_subtip varchar(10), @f_fel varchar(10), @f_procedura varchar(2000),
			@f_sitaburi varchar(20)
				--> parametri "@nec_" determina modul de filtrare: daca filtrul asociat contine doar spatii se vor aduce doar datele pt care campul corespunzator este necompletat, altfel se filtreaza cu like
			,@nec_meniu bit, @nec_nume bit, @nec_tipmacheta bit, @nec_tip bit, @nec_subtip bit, @nec_fel bit
			,@expandare varchar(20)	--> da/nu/nivel expandare (0->n)
			,@faraierarhie varchar(20)

	select	@f_meniu=isnull(@parXML.value('(/*/@f_meniu)[1]','varchar(200)'),''),
			@f_nume=isnull(@parXML.value('(/*/@f_nume)[1]','varchar(200)'),''),
			@f_tipmacheta=isnull(@parXML.value('(/*/@f_tipmacheta)[1]','varchar(20)'),''),
			@f_tip=isnull(@parXML.value('(/*/@f_tip)[1]','varchar(10)'),''),
			@f_subtip=isnull(@parXML.value('(/*/@f_subtip)[1]','varchar(10)'),''),
			@f_fel=isnull(@parXML.value('(/*/@f_fel)[1]','varchar(10)'),''),
			--@f_publicabil=isnull(@parXML.value('(/*/@f_publicabil)[1]','varchar(2)'),''),
			@f_vizibil=isnull(@parXML.value('(/*/@f_vizibil)[1]','varchar(2)'),''),
			@f_procedura=isnull(@parXML.value('(/*/@f_procedura)[1]','varchar(2000)'),''),
			@f_sitaburi=isnull(@parXML.value('(/*/@f_sitaburi)[1]','varchar(2000)'),'')
			,@expandare=@parXML.value('(/*/@f_expandare)[1]','varchar(20)')
			,@faraierarhie=isnull(@parxml.value('(/*/@f_faraierarhie)[1]','varchar(20)'),'0')

	select	@nec_meniu=(case when rtrim(@f_meniu)='' and @parXML.value('string-length(/*[1]/@f_meniu)', 'int')>0 then 1 else 0 end),
			@nec_nume=(case when rtrim(@f_nume)='' and @parXML.value('string-length(/*[1]/@f_nume)', 'int')>0 then 1 else 0 end),
			@nec_tipmacheta=(case when rtrim(@f_tipmacheta)='' and @parXML.value('string-length(/*[1]/@f_tipmacheta)', 'int')>0 then 1 else 0 end),
			@nec_tip=(case when rtrim(@f_tip)='' and @parXML.value('string-length(/*[1]/@f_tip)', 'int')>0 then 1 else 0 end),
			@nec_subtip=(case when rtrim(@f_subtip)='' and @parXML.value('string-length(/*[1]/@f_subtip)', 'int')>0 then 1 else 0 end),
			@nec_fel=(case when rtrim(@f_fel)='' and @parXML.value('string-length(/*[1]/@f_fel)', 'int')>0 then 1 else 0 end)
	
	select @f_vizibil = (case when @f_vizibil in ('da','1') then '1' when @f_vizibil in ('nu','0') then '0' else '' end)
	select @f_publicabil = (case when @f_publicabil in ('da','1') then '1' when @f_publicabil in ('nu','0') then '0' else '' end)
	select @expandare=(case when @expandare is null then null when @expandare='Da' then 1000 when @expandare='Nu' then 0 else @expandare end)


	if object_id('tempdb..#myvar') is not null drop table #myvar
	;with myvar(nivel, id, idparinte, meniu,nume,nrordine, tip_macheta, vizibil, icoana)--, publicabil)
	as			--> id si idparinte: recursivitatea nu se poate face doar pe baza lui meniu (si meniuparinte) daca e sa punem si tip si subtip
	(
		select 1 nivel, wm.Meniu id, wm.MeniuParinte idparinte, wm.Meniu,wm.Nume,wm.NrOrdine, wm.tipmacheta, wm.vizibil, wm.icoana--, wm.publicabil
		from webconfigmeniu wm where isnull(wm.MeniuParinte,'')='' and rtrim(isnull(wm.meniu,''))<>''
			--test:	and wm.Meniu='documente'
		union ALL
		select m.nivel+1 nivel, wm.Meniu id, wm.MeniuParinte idparinte, wm.Meniu,wm.Nume,wm.NrOrdine, wm.tipmacheta, wm.vizibil, wm.icoana--, wm.publicabil
		from myvar m
			inner join webconfigmeniu wm on m.Meniu=wm.MeniuParinte and m.meniu<>wm.Meniu
				--and m.meniu='Mobile' and rtrim(wm.meniuparinte)<>''
			--test:				where m.nivel<>1 or wm.Meniu='ad'
	)
	select nivel, convert(varchar(100),id) id, convert(varchar(100),idparinte) idparinte, meniu, convert(varchar(200),nume) nume,nrordine, 
	tip_macheta, convert(varchar(50),'') fel_m, convert(varchar(50),'') tip_m, convert(varchar(50),'') subtip_m, vizibil, icoana,
	--publicabil, 
	convert(xml,null) xmlu, 1 confirmat_filtre_ambi, 1 confirmat_filtre_sus, convert(varchar(50),'webConfigMeniu') sursa,
	convert(varchar(10),null) as _expandat, '#000000' culoare
	into #myvar from myvar order by nivel, nrordine, Meniu

	insert into #myvar(id, idparinte, meniu,nume, nrordine, tip_macheta, nivel, fel_m, tip_m, subtip_m, vizibil, icoana,
	--publicabil, 
	xmlu, confirmat_filtre_ambi, confirmat_filtre_sus, sursa, culoare)
	select rtrim(t.meniu)+
		(case when m.tip_macheta='C' and t.meniu=t.tip and t.fel='O' then '' else '|'+rtrim(t.tip) end),
		t.meniu, t.meniu, t.nume, ordine, m.tip_macheta, m.nivel+1, t.fel, t.tip, t.subtip, t.Vizibil, '',-- t.publicabil, 
		null, 1, 1, 'webConfigTipuri', '#000000'
	from webconfigtipuri t inner join #myvar m on t.Meniu=m.Meniu and isnull(t.Subtip,'')=''
	union all
	select rtrim(t.meniu)+'|'+rtrim(t.tip)+'|'+rtrim(t.subtip), rtrim(t.meniu)+(case when m.tip_macheta='C' and 1=0/*(t.meniu=t.tip or len(t.meniu)>2) and t.fel not in ('O','R')*/ then '' else '|'+rtrim(t.tip) end), t.meniu, t.nume, ordine,
			m.tip_macheta, m.nivel+2, t.fel, t.tip, t.subtip, t.Vizibil, '',-- t.publicabil, 
			null, 1, 1, 'webConfigTipuri', '#000000'
	from webconfigtipuri t inner join #myvar m on t.Meniu=m.Meniu and isnull(t.Subtip,'')<>''
	order by fel, ordine
--	/*
	--> completare ierarhie pentru acele subtipuri care nu au tip parinte (vezi DO & AD):
	insert into #myvar(id, idparinte, meniu,nume, nrordine, tip_macheta, nivel, fel_m, tip_m, subtip_m, vizibil, icoana,
	xmlu, confirmat_filtre_ambi, confirmat_filtre_sus, sursa, culoare)
	--select idparinte, meniu, meniu, '<'+meniu+'>', nrordine, tip_macheta, nivel-1, '' fel_m, '' tip_m, '' subtip_m, vizibil, icoana, xmlu, confirmat_filtre_ambi, confirmat_filtre_sus, sursa, culoare
	select max(idparinte), meniu, meniu, '{'+meniu+' '+tip_m+'}', max(nrordine), max(tip_macheta), min(nivel)-1, '' fel_m, tip_m, '' subtip_m, 0 vizibil, '' icoana, '' xmlu, max(confirmat_filtre_ambi), max(confirmat_filtre_sus),
			'webConfigTipuri' sursa, '' culoare
	from #myvar w where isnull(w.subtip_m,'')<>'' and
		not exists (select 1 from #myvar t where t.meniu=w.meniu and (/*isnull(t.tip_m,'')='' or*/ t.tip_m=w.tip_m) and isnull(t.subtip_m,'')='' and sursa='webConfigTipuri')
	group by meniu, tip_m
--*/
--
--> completari cu tipuri de machete "pierdute" (poate pe viitor sa se faca sa apara orice linie din webconfig-uri ratacita):
--> webconfigtipuri fara "reprezentanta" in webconfigmeniuri (poate se regasesc in webconfigtaburi sau nicaieri):
	insert into #myvar(id, idparinte, meniu,nume, nrordine, tip_macheta, nivel, fel_m, tip_m, subtip_m, vizibil, icoana,
	--publicabil, 
	xmlu, confirmat_filtre_ambi, confirmat_filtre_sus, sursa, culoare)
	select rtrim(t.meniu) meniu
		--,(case when m.tip_macheta='C' and t.meniu=t.tip and t.fel='O' then '' else '|'+rtrim(t.tip) end)
		,'<tipuriFaraMeniuri>', meniu, t.nume, ordine, '' tip_macheta, 2, t.fel, t.tip, t.subtip, t.Vizibil, '',-- t.publicabil, 
		null, 1, 1, 'webConfigMeniu', '#000000'
	from webconfigtipuri t
	where --not exists (select 1 from webconfigtaburi a where a.meniunou=t.meniu and a.tipnou=t.tip) and
		not exists (select 1 from webconfigmeniu m where m.meniu=t.meniu-- and m.meniuparinte<>'<tipuriFaraMeniuri>'
		)
	union all	--> meniuri fara parinte, dar care exista in webconfigmeniu:
	select rtrim(m.meniu) meniu, m.meniuparinte, m.meniu, m.nume, nrordine, tipmacheta, 2, '' fel, '' tip, '' subtip, m.vizibil,'', null, 1 ,1, 'webConfigMeniu', '#000000'
	from webconfigmeniu m where not exists (select 1 from webconfigmeniu w where m.meniuparinte=w.meniu) and isnull(m.MeniuParinte,'')<>''
	union all
	select rtrim(m.meniuparinte) meniu, '', m.meniuparinte, '<fara parinte>', -1 nrordine, '' tipmacheta, 1, '' fel, '' tip, '' subtip, 0 vizibil,'', null, 1 ,1, 'webConfigMeniu', '#000000'
	from webconfigmeniu m where not exists (select 1 from webconfigmeniu w where m.meniuparinte=w.meniu) and isnull(m.MeniuParinte,'')<>'' group by m.meniuparinte

	if not exists (select 1 from #myvar where meniu='<tipuriFaraMeniuri>')
		and exists (select 1 from #myvar where idparinte='<tipuriFaraMeniuri>')
	insert into #myvar(id, idparinte, meniu,nume, nrordine, tip_macheta, nivel, fel_m, tip_m, subtip_m, vizibil, icoana,
	--publicabil, 
	xmlu, confirmat_filtre_ambi, confirmat_filtre_sus, sursa, culoare)
	select '<tipuriFaraMeniuri>','','<tipuriFaraMeniuri>','<tipuriFaraMeniuri>', -1, '', 1, '', '', '', 0,'',null,1,1,'webConfigMeniu', '#000000'
		
	declare @utilizator varchar(50)
	select @utilizator=dbo.fiautilizator(@sesiune)
--	select date from tabelxml where sesiune=@utilizator+'_expmachete'
	
	delete m		--> cum se face aici? cand vizbil=1 sa aduca doar cele cu vizbil=1 si pt vizibil=0 sa aduca cu tot cu parinti?
	from #myvar m
	where not(
			@f_vizibil='' or vizibil=@f_vizibil
		)
		--select * from #myvar

--> se pregateste xml dinamic pentru aplicarea succesiva a filtrarilor; complicatia rezulta din motivele urmatoare:
	--> filtrarile nu se pot aplica in ierarhie simplu, trebuie sa se tina cont de meniuri parinte si meniuri fii; de asemenea,
	-->		filtrarile nu se pot aplica simultan (exemplu: filtrare pe denumire 'Intrari/Iesiri' si tip 'RM' nu ar afisa nimic deoarece nu exista linia care sa satisfaca ambele conditii)
	-->		=> filtrele si eliminarea liniilor care nu corespund trebuie aplicate succesiv
	--> singurul fragment care difera e conditia, locul ei in cod fiind semnalat prin "[[de_inlocuit]]"
		
	declare @comanda varchar(max)
	select @comanda='
--> se marcheaza inregistrarile care nu se incadreaza in filtarea introdusa:
	update m set confirmat_filtre_ambi=0
	from #myvar m
	where not(
		[[de_inlocuit]]
		)

	update m set culoare=''#0000FF''
	from #myvar m where confirmat_filtre_ambi=1
'+(case when @faraierarhie<>'1' then '	
--> liniile cu superiori marcati sunt la randul lor marcate (pana cand se parcurge toata partea inferioara a ierarhiei):
	declare @nrconfirmate int, @nrconfirmate_ant int
	select @nrconfirmate_ant=0, @nrconfirmate=count(1) from #myvar where confirmat_filtre_ambi=1
	while (@nrconfirmate<>@nrconfirmate_ant)
	begin
		update m set m.confirmat_filtre_ambi=1--, culoare=''#000000''
			from #myvar m
			where m.confirmat_filtre_ambi=0 and exists (select 1 from #myvar v where v.id=m.idparinte and v.confirmat_filtre_ambi=1)
		select @nrconfirmate_ant=@nrconfirmate
		select @nrconfirmate=count(1) from #myvar where confirmat_filtre_ambi=1
	end

--> liniile cu subalterni marcati sunt la randul lor marcate (pana cand se parcurge toata partea superioara a ierarhiei):
	select @nrconfirmate_ant=0, @nrconfirmate=count(1) from #myvar where confirmat_filtre_ambi=1
	while (@nrconfirmate<>@nrconfirmate_ant)
	begin
		update m set m.confirmat_filtre_ambi=1--, culoare=''#000000''
			from #myvar m
			where m.confirmat_filtre_ambi=0 and exists (select 1 from #myvar v where m.id=v.idparinte and v.confirmat_filtre_ambi=1)
		select @nrconfirmate_ant=@nrconfirmate
		select @nrconfirmate=count(1) from #myvar where confirmat_filtre_ambi=1
	end
' else '' end)+'

--> se elimina inregistrarile care nu se incadreaza in filtrare:
	delete #myvar where confirmat_filtre_ambi=0'
	declare @de_inlocuit varchar(max)
--> se aplica filtrarile succesive, folosind sql dinamic de mai sus:
	declare @comanda2 varchar(max)	--> sa nu "stric" comanda originala deoarece inlocuirea lui [[de_inlocuit]] e cam ireversibila
	--> denumire (de meniu sau tipuri)
	if len(@f_nume)>0 or @nec_nume>0
	begin
		select @de_inlocuit=''
/*		select @f_meniu=(case when @f_meniu='' then '%' else @f_meniu end)
		if @f_sitaburi<>'2'
			select @de_inlocuit=(case when @nec_meniu=1 then 'rtrim(isnull(m.meniu,''''))=''''' else 'isnull(m.meniu,'''') like '''+@f_meniu+'''' end)
		if @f_sitaburi='1' select @de_inlocuit=@de_inlocuit+' or '
		if @f_sitaburi in ('1','2') select @de_inlocuit=@de_inlocuit+'
		exists (select 1 from webconfigtaburi t where t.meniusursa=m.meniu and t.tipsursa=m.tip_m and isnull(m.subtip_m,'''')=''''
				and isnull(t.meniunou,'''') like '''+@f_meniu+''')'
*/				
		select @f_nume='%'+replace(@f_nume,' ','%')+'%'
		if @f_sitaburi<>'2'
			select @de_inlocuit=(case when @nec_nume=1 then 'rtrim(isnull(m.nume,''''))=''''' else 'isnull(m.nume,'''') like '''+@f_nume+'''' end)
		if @f_sitaburi='1' select @de_inlocuit=@de_inlocuit+' or '
		if @f_sitaburi in ('1','2') select @de_inlocuit=@de_inlocuit+'
		exists (select 1 from webconfigtaburi t where t.meniusursa=m.meniu and t.tipsursa=m.tip_m and isnull(m.subtip_m,'''')=''''
				and isnull(t.numetab,'''') like '''+@f_nume+''')'
		set @comanda2=replace(@comanda,'[[de_inlocuit]]',@de_inlocuit)
		exec (@comanda2)
	end

	if len(@f_procedura)>0
	begin
		select @f_procedura=''''+@f_procedura+''''
		select @de_inlocuit=
			(case when @f_sitaburi='2' then '' else 
				'exists (select 1 from webconfigtipuri t where t.meniu=m.meniu and isnull(t.tip,'''')=isnull(m.tip_m,'''') and isnull(t.subtip,'''')=isnull(m.subtip_m,'''') and
				(isnull(t.ProcDate,'''') like '+@f_procedura+'
					or isnull(t.ProcScriere,'''') like '+@f_procedura+'
					or isnull(t.ProcStergere,'''') like '+@f_procedura+'
					or isnull(t.ProcDatePoz,'''') like '+@f_procedura+'
					or isnull(t.ProcScrierePoz,'''') like '+@f_procedura+'
					or isnull(t.ProcStergerePoz,'''') like '+@f_procedura+'
					or isnull(t.procPopulare,'''') like '+@f_procedura+'
					or isnull(t.ProcInchidereMacheta,'''') like '+@f_procedura+'))
				' end)
			+(case when @f_sitaburi='1' then 'or ' else '' end)
			+ (case when @f_sitaburi in ('1','2') then 'exists (select 1 from webconfigtaburi t where t.meniusursa=m.meniu and t.tipsursa=m.tip_m and isnull(m.subtip_m,'''')=''''
				and isnull(t.procpopulare,'''') like '+@f_procedura+')' else '' end)
		set @comanda2=replace(@comanda,'[[de_inlocuit]]',@de_inlocuit)
		exec(@comanda2)
		--test	select @comanda2 for xml path('')
	end
	
	--> cod meniu
	if len(@f_meniu)>0 or @nec_meniu>0
	begin
		select @de_inlocuit=''
		select @f_meniu=(case when @f_meniu='' then '%' else @f_meniu end)
		if @f_sitaburi<>'2'
			select @de_inlocuit=(case when @nec_meniu=1 then 'rtrim(isnull(m.meniu,''''))=''''' else 'isnull(m.meniu,'''') like '''+@f_meniu+'''' end)
		if @f_sitaburi='1' select @de_inlocuit=@de_inlocuit+' or '
		if @f_sitaburi in ('1','2') select @de_inlocuit=@de_inlocuit+'
		exists (select 1 from webconfigtaburi t where t.meniusursa=m.meniu and t.tipsursa=m.tip_m and isnull(m.subtip_m,'''')=''''
				and isnull(t.meniunou,'''') like '''+@f_meniu+''')'
		set @comanda2=replace(@comanda,'[[de_inlocuit]]',@de_inlocuit)
		exec (@comanda2)
	end
	--> cod tip
	if len(@f_tip)>0 or @nec_tip>0
	begin
		select @de_inlocuit=''
		select @f_tip=(case when @f_tip='' then '%' else @f_tip end)
		if @f_sitaburi<>'2'
			select @de_inlocuit=(case when @nec_tip=1 then 'rtrim(isnull(m.tip_m,''''))=''''' else 'isnull(m.tip_m,'''') like '''+@f_tip+'''' end)
		if @f_sitaburi='1' select @de_inlocuit=@de_inlocuit+' or '
		if @f_sitaburi in ('1','2') select @de_inlocuit=@de_inlocuit+'
		exists (select 1 from webconfigtaburi t where t.meniusursa=m.meniu and t.tipsursa=m.tip_m and isnull(m.subtip_m,'''')=''''
				and isnull(t.tipnou,'''') like '''+@f_tip+''')'
		set @comanda2=replace(@comanda,'[[de_inlocuit]]',@de_inlocuit)
		exec (@comanda2)
	end
	--> cod subtip
	if len(@f_subtip)>0 or @nec_subtip>0
	begin
		select @de_inlocuit=(case when @nec_subtip=1 then 'rtrim(isnull(m.subtip_m,''''))=''''' else 'isnull(m.subtip_m,'''') like '''+@f_subtip+'''' end)
		set @comanda2=replace(@comanda,'[[de_inlocuit]]',@de_inlocuit)
		exec (@comanda2)
	end
	--> cod tip macheta
	if len(@f_tipmacheta)>0 or @nec_tipmacheta>0
	begin
		select @de_inlocuit=''
		select @f_tip=(case when @f_tipmacheta='' then '%' else @f_tipmacheta end)
		if @f_sitaburi<>'2'
			select @de_inlocuit=(case when @nec_tipmacheta=1 then 'rtrim(isnull(m.tip_macheta,''''))=''''' else 'isnull(m.tip_macheta,'''') like '''+@f_tipmacheta+'''' end)
		if @f_sitaburi='1' select @de_inlocuit=@de_inlocuit+' or '
		if @f_sitaburi in ('1','2') select @de_inlocuit=@de_inlocuit+'
		exists (select 1 from webconfigtaburi t where t.meniusursa=m.meniu and t.tipsursa=m.tip_m and isnull(m.subtip_m,'''')=''''
				and isnull(t.tipmachetanoua,'''') like '''+@f_tipmacheta+''')'
		set @comanda2=replace(@comanda,'[[de_inlocuit]]',@de_inlocuit)
		exec (@comanda2)
	end
	--> cod fel
	if len(@f_fel)>0 or @nec_fel>0
	begin
		select @de_inlocuit=(case when @nec_fel=1 then 'rtrim(isnull(m.fel_m,''''))=''''' else 'isnull(m.fel_m,'''') like '''+@f_fel+'''' end)
		set @comanda2=replace(@comanda,'[[de_inlocuit]]',@de_inlocuit)
		exec (@comanda2)
	end
	
--	delete #myvar where confirmat_filtre_sus=0
	declare @nivel int
	select @nivel=max(nivel) from #myvar

	declare @nrmyvar int, @_expandat varchar(20)
	select @nrmyvar=count(1) from #myvar
	select @_expandat=(case when @expandare is null and @nrmyvar<=50 then 'Da' else @expandare end)	--> daca nu s-a optat pt expandare, cand nr randuri<=50 se va expanda automat

--> se formeaza documentul xml final ierarhizat:
	declare @comanda_str varchar(max), 
		@recursiva varchar(max),	--> secventa de cod care ar trebui apelata recursiv pentru a apela ierarhia
		@iterativa varchar(max),	--> secventa de cod formata din @recursiva care va forma ierarhia
		@conditie varchar(max)		--> partea de conditie si legatura din @recursiva care trebuie inlocuita pentru primul pas
	select @expandare=(case when @expandare is null and @nrmyvar<=50 then 1000 when @expandare is not null then @expandare else 0 end)	--> daca nu s-a optat pt expandare, cand nr randuri<=50 se va expanda automat
	select @conditie='from #myvar mvr2 where nivel=@nivel and rtrim(mvr2.idparinte)=rtrim(mvr1.id) order by (case when id like idparinte+''%'' then 0 else 1 end), nrordine for xml raw, type'
	select @recursiva='(select '+case when @faraierarhie<>'1' then '' else 'top 100 ' end+'
					meniu,nume, nrordine, tip_macheta, nivel, fel_m, tip_m, subtip_m, vizibil, icoana, rtrim(idparinte) parinte,
					(case tip_macheta	when "C" then "Catalog (C)"
										when "D" then "Document (D)"
										when "E" then "Catalog doc (E)"
										when "G" then "Grafic TB (G)"
										when "GT" then "Grafic Gantt (GT)"
										when "O" then "Operatie (O)"
										when "H" then "Harta (H)"
										when "M" then "Mobil (M)"
										else tip_macheta
					end) tip_macheta_,
					(case fel_m	when "O" then "Operatie (O)"
									when "R" then "Raport (R)"
					end) fel_,
				(case when vizibil=1 then "Da" when vizibil=0 then "Nu" else "" end) vizibil_,
				 sursa, (case when '+@expandare+'<nivel then "Nu" else "Da" end) _expandat,
				 culoare
						,'''' xmlu
					 '+@conditie+')
'	/*	'''' xmlu e locul in care se va repeta @recursiva, cu replace
		[mvr<x>] din @conditie e alias-ul pentru diferitele "etaje" din tabela, se completeaza pentru fiecare etaj mai jos
	*/
						
	--> completarea cu string delimiters:
	select @recursiva=replace(@recursiva,'"','''')

	--> primul pas; conditia trebuie inlocuita deoarece nu exista nivel parinte de legatura
	select @iterativa=
	'select '+
			replace(@recursiva
					,@conditie
					,'from #myvar mvr1 where '+case when @faraierarhie<>'1' then 'nivel=1' else '1=1' end +' for xml raw, type')
		+'
		for xml path(''Ierarhie''), root(''Date'')'

	select @iterativa=replace(@iterativa,''''' xmlu',replace(@recursiva, '@nivel','2'))

	--> completarea in continuare a @iterativa merge la fel pentru toate nivelele:
	declare @i_nivel int
	select @i_nivel=3	--, @nivel=5
if @faraierarhie<>'1'
	while @nivel>=@i_nivel
	begin
		select @iterativa=replace(@iterativa,''''' xmlu',
			replace(
			replace(
				replace(@recursiva, '@nivel',convert(varchar(20),@i_nivel))	--> nivelul creste
				,'mvr2','mvr'+convert(varchar(20),@i_nivel))	--> completarea legaturilor ierarhice intre nivele
			,'mvr1','mvr'+convert(varchar(20),@i_nivel-1))
			)
		select @i_nivel=@i_nivel+1
	end
	
	exec (@iterativa)
end try

begin catch
	set @eroare = error_message() + ' (wIaConfigurareMachete)'
end catch

if object_id('tempdb..#myvar') is not null drop table #myvar
if len(@eroare)>0 raiserror(@eroare, 11, 1)
