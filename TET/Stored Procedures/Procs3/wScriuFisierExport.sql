
Create procedure wScriuFisierExport @sesiune varchar(50), @parXML xml
as

begin try
	declare @eroare varchar(5000), @fisier varchar(255), @meniu varchar(20), @database varchar(50), @doc xml
		,@mesaj varchar(5000)
		
	select @mesaj=''

	set @fisier = isnull(@parXML.value('(/*/@fisier)[1]','varchar(255)'),'')
	set @meniu = isnull(@parXML.value('(/*/@meniu)[1]','varchar(20)'),'')
	set @database = isnull(@parXML.value('(/*/@database)[1]','varchar(50)'),'')

	begin
		declare @cale varchar(2000), @comanda varchar(max), @nranterior int, @sfComanda varchar(max)
		select @cale='/parametri', @sfComanda=''

		if object_id('tempdb..#temp_tip') is not null drop table #temp_tip
		create table #temp_tip(meniu varchar(200), tip varchar(200), subtip varchar(200), sursa varchar(200))
		--> extragere nivele ierarhice configurari si aducere la acelasi nivel:
		select @comanda='
		declare @var xml
		select @var='''+convert(varchar(max),@parXML)+'''

		if object_id(''tempdb..#temp_tip'') is null
			create table #temp_tip(meniu varchar(200), tip varchar(200), subtip varchar(200), sursa varchar(200))

		insert into #temp_tip (meniu, tip, subtip, sursa)
		select
		t.c.value(''@meniu'',''varchar(20)'') meniu,t.c.value(''@tip_m'',''varchar(20)'') tip, t.c.value(''@subtip_m'',''varchar(20)'') subtip, t.c.value(''@sursa'',''varchar(20)'') sursa
		from @var.nodes('''

		select @nranterior=-1
		while  (select count(1) from #temp_tip)>@nranterior
		begin
			select @nranterior=(select count(1) from #temp_tip)
			exec (@comanda+@cale+''') t(c)'+@sfComanda)
			select @cale = @cale + '/row'
			--select @sfComanda=' where isnull(t.c.value(''@vizibil'',''bit''),1)=1'
		end
		
		declare @export table(ID int identity(1,1), meniu varchar(20),tip varchar(2),subtip varchar(2), rezultat xml, sursa varchar(200), tipmacheta varchar(200), areTipNecompletat int default 0)
		
		insert into @export(meniu, tip, subtip, rezultat, sursa, tipmacheta)
		select tt.meniu as meniu, isnull(tt.tip,'') as tip, isnull(tt.subtip,'') as subtip, '' as rezultat, sursa, m.tipmacheta
		from #temp_tip tt left join webconfigmeniu m on tt.meniu=m.meniu
			where sursa='webconfigmeniu' or exists (select 1 from webconfigtipuri t where tt.meniu=t.meniu and isnull(tt.tip,'')=isnull(t.tip,'') and isnull(t.subtip,'')=isnull(tt.subtip,''))
		group by tt.meniu, isnull(tt.tip,''), isnull(tt.subtip,''), sursa, m.tipmacheta
		--> identificare webconfigtab-uri care fac parte din configurarile de exportat:
		declare @webconfigtaburi table (meniusursa varchar(200), tipsursa varchar(200), meniunou varchar(200), tipnou varchar(200), tipmachetanoua varchar(20))

		insert into  @webconfigtaburi(meniusursa, tipsursa, meniunou, tipnou, tipmachetanoua)
		select a.meniusursa, a.tipsursa, a.meniunou, a.tipnou, max(a.tipmachetanoua)
		from @export t inner join webconfigtaburi a on t.meniu=a.meniusursa and t.tip=a.tipsursa and t.subtip=''
		group by a.meniusursa, a.tipsursa, a.meniunou, a.tipnou
		
		declare @cate int, @cateant int
		select @cate=isnull((select count(1) from @webconfigtaburi),0), @cateant=0

		while @cate>@cateant
		begin
			select @cateant=@cate
			insert into @webconfigtaburi
			select a.meniusursa, a.tipsursa, a.meniunou, a.tipnou, isnull(w.tipmacheta,'')
			from @webconfigtaburi t
				inner join webconfigtaburi a on t.meniunou=a.meniusursa and t.tipnou=a.tipsursa
					and not exists (select 1 from @webconfigtaburi r where r.meniusursa=a.meniusursa and r.tipsursa=a.tipsursa and r.meniunou=a.meniunou and r.tipnou=a.tipnou)
				left join webconfigmeniu w on w.meniu=a.meniunou
			select @cate=count(1) from webconfigtaburi
		end
		
		select @eroare='Pentru export este necesar ca tipul meniului si tipul tabului sa fie aceleasi!'+char(10)+char(10)
			+'Meniul "'+t.meniu+'" cu tipul "'+t.tip+'" are tipmacheta="'+t.tipmacheta+'",'+char(10)
			+'dar ca tab pentru meniul "'+w.meniusursa+'" si tipul "'+w.tipsursa+'" are tip macheta "'+w.tipmachetanoua+'"!'+char(10)+char(10)
			 from @webconfigtaburi w 
			inner join
			@export t on t.meniu=w.meniunou and t.tip=w.tipnou and (t.tipmacheta<>w.tipmachetanoua and t.tipmacheta not in ('D','E') and w.tipmachetanoua not in ('D','E'))
			where w.tipmachetanoua<>'pozdoc' and w.tipmachetanoua<>'F'
		if @eroare is not null raiserror(@eroare,16,1)
		
		--> adaugare in export a tipurilor suplimentare cerute de webconfigtab-uri:
		insert into @export(meniu, tip, subtip, rezultat, sursa, tipmacheta)
		select t.meniunou, isnull(t.tipnou,''), isnull(ti.subtip,''), '', 'webConfigTaburi', max(isnull(t.tipmachetanoua,'D'))
		from @webconfigtaburi t inner join webconfigtipuri ti on t.meniunou=ti.meniu and
			(case when isnull(t.tipmachetanoua,'')='C' and isnull(ti.tip,'')='' then '' else isnull(t.tipnou,'') end)=isnull(ti.tip,'')
		where not exists (select 1 from @export e where t.meniunou=e.meniu and isnull(t.tipnou,'')=isnull(e.tip,''))
		group by t.meniunou, t.tipnou, ti.subtip
		
		--> pregatire mesaj cu lista de cataloage cerute de ACA:
		select @mesaj=@mesaj+char(10)+m.meniu+' ("'+max(rtrim(m.nume))+'")'
			from webconfigmeniu m inner join webconfigtipuri t on m.meniu=t.meniu
		where
			--> filtrarea pe autocomplete cu adaugare:
			exists (select 1 from webconfigform f inner join @export e on f.tipobiect='ACA' and f.meniu=e.meniu and f.detalii.value('(row/@meniu_deschis)[1]', 'varchar(500)')=m.meniu)
			and not exists (select 1 from @export e where t.meniu=e.meniu and isnull(t.tip,'')=isnull(e.tip,''))
		group by m.meniu
		
		if len(@mesaj)>0
			select @mesaj='Meniuri necesare pentru obiectele de tip autocomplete de adaugare:'+@mesaj
		
		update e set areTipNecompletat=1
		from @export e
		where exists (select 1 from @export e1 where e1.meniu=e.meniu and isnull(e1.tip,'')='')

		if object_id('tempdb..#temp_tip') is not null drop table #temp_tip

		declare @linie_curenta int, @max int
		select @linie_curenta = 1, @max = (select count(1) from @export)
		
		--> exportul de pozitie document nu functioneaza corect; nu e permis in aceasta situatie:
		select @eroare='Nu este permis exportul de pozitii document fara a se exporta si tipul parinte!'+char(10)+char(10)
			+'meniu="'+t.meniu+'", tip="'+t.tip+'", subtip="'+t.subtip+'"'
			 from @export t
			where t.tipmacheta='D' and t.subtip<>'' and t.subtip=t.tip
				and not exists (select 1 from @export e where e.meniu=t.meniu and e.subtip='')
		if @eroare is not null raiserror(@eroare,16,1)
		
		--> compunerea xml-urilor finale de configurari; se creeaza pt fiecare linie din @export, la final creandu-se unul singur care le contine:
		while @linie_curenta <= @max
		begin
			update e set rezultat = 
			(select * from webconfigmeniu wt
			where isnull(wt.Meniu,'')=isnull((select Meniu from @export where ID=@linie_curenta),'')
			for xml raw('meniuri'))
			from @export e
			where ID=@linie_curenta and e.sursa='webConfigMeniu'

			update e set rezultat = x.x
--			select 
			from @export e
			cross apply (select (select max(wt.Meniu) Meniu, max(wt.Tip) Tip, max(isnull(wt.Subtip,'')) Subtip, max(Ordine) Ordine, max(Nume) Nume, max(Descriere) Descriere,
				max(TextAdaugare) TextAdaugare, max(TextModificare) TextModificare, max(ProcDate) ProcDate, max(ProcScriere) ProcScriere,
				max(ProcStergere) ProcStergere, max(ProcDatePoz) ProcDatePoz, max(ProcScrierePoz) ProcScrierePoz, max(ProcStergerePoz) ProcStergerePoz,
				max(convert(int,Vizibil)) Vizibil, max(Fel) Fel, max(procPopulare) procPopulare, max(tasta) tasta,
				max(ProcInchidereMacheta) ProcInchidereMacheta,
				max(e1.sursa) sursa,		--> luare configurari asociate fiecaror tipuri/subtipuri:
				(select max(Meniu) Meniu, max(Tip) Tip, max(isnull(Subtip,'')) Subtip, max(Ordine) Ordine, max(Nume) Nume, max(TipObiect) TipObiect,
						max(DataField) DataField, max(LabelField) LabelField, max(Latime) Latime, max(convert(int,Vizibil)) Vizibil,
						max(convert(int,Modificabil)) Modificabil, max(ProcSQL) ProcSQL, max(ListaValori) ListaValori, max(ListaEtichete) ListaEtichete,
						max(Initializare) Initializare, max(Prompt) Prompt, max(Procesare) Procesare, max(Tooltip) Tooltip, max(formula) formula
						,convert(xml,max(convert(varchar(max),form.detalii)))
							--> max nu merge pe xml, nici group by; facem varchar, max si inapoi xml sa nu se altereze caracterele mai speciale
					from webconfigform form
					where form.meniu=max(wt.meniu) and
						(case	when max(isnull(e1.tipmacheta,''))='C' and (max(e1.areTipNecompletat)=0 or isnull(form.tip,'')=isnull(form.meniu,'')) and isnull(wt.tip,'')=''
								then '' else isnull(form.tip,'') end)=max(isnull(wt.tip,''))	-->	case-ul complicat , care se repeta pt aproape fiecare tabela din care se iau configurari,
															-->	se datoreaza "haosului cataloagelor" (=completarea/necompletarea tipului in configurari pentru machetele de cataloage meniu=tip)
						and isnull(form.subtip,'')=max(isnull(wt.subtip,''))
					group by meniu, tip, isnull(subtip,''), datafield
					order by tip, subtip, ordine for xml auto, type) formuri,
				(select max(Meniu) Meniu, max(Tip) Tip, max(Ordine) Ordine, max(convert(int,Vizibil)) Vizibil, max(TipObiect) TipObiect, max(Descriere) Descriere,
						max(Prompt1) Prompt1, max(DataField1) DataField1, max(convert(int,Interval)) Interval, max(Prompt2) Prompt2, max(DataField2) DataField2
					from webconfigfiltre filtre where filtre.meniu=max(wt.meniu) and max(isnull(wt.subtip,''))='' and
						(replace(isnull(filtre.meniu,''),max(e1.tipmacheta)+'_','')=isnull(filtre.tip,'') and max(isnull(wt.tip,''))=''
							and not exists (select 1 from webconfigtipuri t where t.meniu=filtre.meniu and isnull(t.tip,'')=isnull(filtre.tip,'') and isnull(t.subtip,'')='')
							or
						(case	when max(e1.tipmacheta)='C'
								then '' else isnull(filtre.tip,'') end)=max(isnull(wt.tip,'')))
					group by meniu, tip, datafield1
					order by tip, ordine for xml auto, type) filtre,
				(select max(Meniu) Meniu, max(Tip) Tip, max(Subtip) Subtip, max(convert(int,InPozitii)) InPozitii, max(NumeCol) NumeCol, max(DataField) DataField,
						max(TipObiect) TipObiect, max(Latime) Latime, max(Ordine) Ordine, max(convert(int,Vizibil)) Vizibil,
						max(convert(int,modificabil)) modificabil, max(formula) formula
					from webconfiggrid grid where grid.meniu=max(wt.meniu) and 
						--isnull(grid.tip,'')=max(isnull(wt.tip,'')) 
						(case when max(isnull(e1.tipmacheta,''))='C' and (max(e1.areTipNecompletat)=0 or isnull(grid.tip,'')=isnull(grid.meniu,'')) and isnull(wt.tip,'')='' then '' else isnull(grid.tip,'') end)=max(isnull(wt.tip,''))
						and isnull(grid.subtip,'')=max(isnull(wt.subtip,''))
					group by meniu, tip, subtip, datafield, inpozitii
					order by tip, inpozitii, subtip, ordine for xml auto, type) griduri,
				(select max(MeniuSursa) MeniuSursa, max(TipSursa) TipSursa, max(NumeTab) NumeTab, max(Icoana) Icoana, max(TipMachetaNoua) TipMachetaNoua,
						max(MeniuNou) MeniuNou, max(TipNou) TipNou, max(ProcPopulare) ProcPopulare, max(Ordine) Ordine, max(convert(int,Vizibil)) Vizibil
						from webconfigtaburi tab where tab.meniusursa=max(wt.meniu) and 
						--isnull(tab.tipsursa,'')=max(isnull(wt.tip,''))
						(case when max(isnull(e1.tipmacheta,''))='C' and max(e1.areTipNecompletat)=0 and isnull(wt.tip,'')='' then '' else isnull(tab.tipsursa,'') end)=max(isnull(wt.tip,''))
						and max(isnull(wt.subtip,''))=''
					group by meniusursa, tipsursa, numetab
					order by ordine
					for xml auto, type) taburi,
				--> webconfigformmobile:
				(select max(Identificator) Identificator, max(convert(decimal(15,4),Ordine)) Ordine, max(Nume) Nume, max(TipObiect) TipObiect, max(DataField) DataField,
						max(LabelField) LabelField, max(ProcSQL) ProcSQL, max(ListaValori) ListaValori, max(ListaEtichete) ListaEtichete,
						max(Initializare) Initializare, max(Prompt) Prompt, max(convert(int,Vizibil)) Vizibil, max(convert(int,Modificabil)) Modificabil
					from webconfigformmobile webconfigformmobile where webconfigformmobile.identificator=max(wt.meniu) and
						max(isnull(e1.tipmacheta,''))='M'
						/*(case	when max(isnull(e1.tipmacheta,''))='C' and (max(e1.areTipNecompletat)=0 or isnull(form.tip,'')=isnull(form.meniu,'')) and isnull(wt.tip,'')=''
								then '' else isnull(form.tip,'') end)=max(isnull(wt.tip,''))	-->	case-ul complicat , care se repeta pt aproape fiecare tabela din care se iau configurari,
															-->	se datoreaza "haosului cataloagelor" (=completarea/necompletarea tipului in configurari pentru machetele de cataloage meniu=tip)
						and isnull(form.subtip,'')=max(isnull(wt.subtip,''))*/
					group by identificator, datafield
					order by ordine for xml auto, type) formmobile
			from webconfigtipuri wt
				inner join @export e1 on wt.meniu=e1.meniu 
					and isnull(wt.tip,'')=(case when isnull(e1.tipmacheta,'')='C' and e1.areTipNecompletat=0 and isnull(wt.tip,'')='' then '' else e1.tip end)
					and isnull(wt.subtip,'')=e1.subtip and e1.id=@linie_curenta
			where isnull(wt.Meniu,'')=isnull((select Meniu from @export where ID=@linie_curenta),'')
				and isnull(wt.tip,'')=isnull((case when isnull(e1.tipmacheta,'')='C' and e1.areTipNecompletat=0 and isnull(wt.tip,'')='' then '' else (select Tip from @export where ID=@linie_curenta) end),'')
				and isnull(wt.Subtip,'')=isnull((select Subtip from @export where ID=@linie_curenta),'')
				and ID=@linie_curenta and e1.sursa in ('webConfigTipuri','webConfigTaburi')	
			group by wt.meniu, wt.tip, isnull(wt.subtip,'')
			for xml raw('tipuri')) as x) x
			where ID=@linie_curenta and e.sursa in ('webConfigTipuri','webConfigTaburi')

			set @linie_curenta = @linie_curenta + 1
		end

		select @doc = (select rezultat.query('/*') from @export for xml path(''), root('machete'))
	end
--test	select @doc doc for xml path('')

	-- #####################################################################
	-- #								EXPORT							   #
	-- #####################################################################

	delete tabelXML where sesiune=@sesiune
	insert into tabelXML(sesiune, date) select @sesiune, @doc

	declare @cmdShellCommand varchar(3000), @caleform varchar(1000)
	select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)
		from par where tip_parametru='AR' and parametru='caleform'
	set @cmdShellCommand = 'bcp "select replace(convert(varchar(max),date),''>'',''>''+char(10)) from ' + @database + '.dbo.tabelXML where sesiune='''+rtrim(@sesiune)+'''" queryout '+@caleform + @fisier + '.xml -c -T -r \n -S ' + convert(varchar(1000),serverproperty('ServerName'))
			--> adaugat enter-uri in xml pentru debug ca era mult prea urat intr-o singura linie
	exec xp_cmdshell @cmdShellCommand
	
	SELECT @fisier + '.xml' AS fisier, 'wTipFormular' AS numeProcedura
		FOR XML raw, root('Mesaje')

	if len(@mesaj)>0
	select 'Notificare' titluMesaj, @mesaj textMesaj for xml raw, root('Mesaje')
	
	delete tabelXML where sesiune=@sesiune
	if object_id('tempdb..#myvar') is not null drop table #myvar
end try

begin catch
	set @eroare = error_message() + ' (wScriuFisierExport)'
	raiserror(@eroare, 11, 1)
end catch
