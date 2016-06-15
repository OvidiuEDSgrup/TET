
Create procedure wOPImportMachete @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(500), @date xml

begin try
	declare @iDoc int, @iPar int
	select @date = (select date from tabelXML where sesiune=@sesiune)

	declare @scriereMeniuri table(ID int, Meniu varchar(20), Nume varchar(30), MeniuParinte varchar(20), Icoana varchar(50), 
	TipMacheta varchar(5), NrOrdine decimal(7,2), Componenta varchar(100), Semnatura varchar(100), Detalii xml, Vizibil bit,
	publicabil int, Existent varchar(2), Suprascriere bit, Selectare bit)

	declare @scriereTipuri table(ID int, Meniu varchar(20), Tip varchar(2), Subtip varchar(2), Ordine int, Nume varchar(50),
	Descriere varchar(500), TextAdaugare varchar(60), TextModificare varchar(60), ProcDate varchar(60), ProcScriere varchar(60), ProcStergere varchar(60),
	ProcDatePoz varchar(60), ProcScrierePoz varchar(60), ProcStergerePoz varchar(60), Vizibil bit, Fel varchar(1), ProcPopulare varchar(60), tasta varchar(20),
	publicabil int, ProcInchidereMacheta varchar(60), detalii xml, Existent varchar(2), Suprascriere bit, Selectare bit)

	declare @scriereFormuri table(ID int, Meniu varchar(20), Tip varchar(2), Subtip varchar(2), Ordine int, Nume varchar(50), TipObiect varchar(50), 
	DataField varchar(50), LabelField varchar(50), Latime int, Vizibil bit, Modificabil bit, ProcSQL varchar(50), ListaValori varchar(100), ListaEtichete varchar(600),
	Initializare varchar(50), Prompt varchar(50), Procesare varchar(50), Tooltip varchar(500), formula varchar(8000), detalii xml)

	declare @scriereGrid table(ID int, Meniu varchar(20), Tip varchar(2), Subtip varchar(2), InPozitii bit, NumeCol varchar(50), DataField varchar(50),
	TipObiect varchar(50), Latime int, Ordine int, Vizibil bit, modificabil bit, formula varchar(8000), detalii xml)

	declare @scriereFiltre table(ID int, Meniu varchar(20), Tip varchar(2), Ordine int, Vizibil bit, TipObiect varchar(50), Descriere varchar(50), 
	Prompt1 varchar(20), DataField1 varchar(100), Interval bit, Prompt2 varchar(20), DataField2 varchar(100), detalii xml)
	
	declare @scrieretaburi table(ID int, MeniuSursa varchar(50),	TipSursa varchar(50), NumeTab varchar(100), Icoana varchar(500),
	TipMachetaNoua varchar(20), MeniuNou varchar(20), TipNou varchar(20), ProcPopulare varchar(100), Ordine smallint, Vizibil bit, detalii xml)
	
	declare @scriereFormuriMobile table(ID int, Identificator varchar(50), Ordine float, Nume varchar(2000), TipObiect varchar(100), DataField varchar(2000),
			 LabelField varchar(2000), ProcSQL varchar(2000), ListaValori varchar(2000), ListaEtichete varchar(2000), Initializare varchar(2000),
			 Prompt varchar(2000), Vizibil bit, Modificabil bit)
		
	declare @alt_nume varchar(1000), @alt_meniu varchar(1000), @alt_tip varchar(1000)
	select	@alt_nume=isnull(@parXML.value('(/parametri/@alt_nume)[1]','varchar(1000)'),''),
		@alt_meniu=isnull(@parXML.value('(/parametri/@alt_meniu)[1]','varchar(1000)'),''),
		@alt_tip=isnull(@parXML.value('(/parametri/@alt_tip)[1]','varchar(1000)'),'')
		
	
	EXEC sp_xml_preparedocument @iPar OUTPUT, @parXML
	
	insert into @scriereMeniuri
	select row_number() over(order by t.c.value('@s_meniu','varchar(20)')) as ID,
	t.c.value('@s_meniu','varchar(20)') Meniu, t.c.value('@s_nume','varchar(30)') Nume, t.c.value('@s_meniuparinte','varchar(20)') MeniuParinte,
	t.c.value('@s_icoana','varchar(20)') Icoana, t.c.value('@s_tipmacheta','varchar(5)') TipMacheta, t.c.value('@s_nrordine','decimal(7,2)') NrOrdine,
	t.c.value('@s_componenta','varchar(100)') Componenta, t.c.value('@s_semnatura','varchar(100)') Semnatura, t.c.query('detalii/row') Detalii,
	t.c.value('@s_vizibil','bit') Vizibil,  t.c.value('@s_publicabil','int') publicabil,
	t.c.value('@s_existent','varchar(2)') Existent, t.c.value('@s_suprascriere','bit') Suprascriere, t.c.value('@s_selectare','bit') Selectare
	from @parXML.nodes('/parametri/DateGrid/meniuri') t(c)
	
	insert into @scriereTipuri
		select row_number() over(order by Meniu) as ID,
				Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, ProcPopulare, tasta, publicabil, ProcInchidereMacheta, detalii, Existent, Suprascriere, Selectare
			from OPENXML(@iPar, '/parametri/DateGrid/tipuri')
			with(
					Meniu varchar(20) '@s_meniu'
					,Tip varchar(2) '@s_tip'
					,Subtip varchar(2) '@s_subtip'
					,Ordine int '@s_ordine'
					,Nume varchar(50) '@s_nume'
					,Descriere varchar(500) '@s_descriere'
					,TextAdaugare varchar(60) '@s_textadaugare'
					,TextModificare varchar(60) '@s_textmodificare'
					,ProcDate varchar(60) '@s_procdate'
					,ProcScriere varchar(60) '@s_procscriere'
					,ProcStergere varchar(60) '@s_procstergere'
					,ProcDatePoz varchar(60) '@s_procdatepoz'
					,ProcScrierePoz varchar(60) '@s_procscrierepoz'
					,ProcStergerePoz varchar(60)'@s_procstergerepoz'
					,Vizibil bit '@s_vizibil'
					,Fel varchar(1) '@s_fel'
					,ProcPopulare varchar(60) '@s_procpopulare'
					,tasta varchar(60) '@s_tasta'
					,publicabil int '@s_publicabil'
					,ProcInchidereMacheta varchar(60) '@s_procinchideremacheta'
					,detalii xml 'detalii'
					,Existent varchar(2) '@s_existent'
					,Suprascriere bit '@s_suprascriere'
					,Selectare bit '@s_selectare'
				)
	begin try exec sp_xml_removedocument @iPar
	end try begin catch end catch

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @date
	if isnull(@date.value('count(/row/machete/tipuri/taburi)','int'),0)<>0
	insert into @scriereTaburi
		select row_number() over(order by meniuNou) as ID,
				MeniuSursa, TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, ProcPopulare, Ordine, Vizibil, detalii
			from OPENXML(@iDoc, '/row/machete/tipuri/taburi/tab')
			with(
				MeniuSursa varchar(20)
				,TipSursa varchar(20)
				,NumeTab varchar(2000)
				,Icoana varchar(2000)
				,TipMachetaNoua varchar(2000)
				,MeniuNou varchar(20)
				,TipNou varchar(20)
				,ProcPopulare varchar(2000)
				,Ordine decimal(17,2)
				,Vizibil bit
				,detalii  xml './*'
			)
	
	update t set selectare=1
	from @scriereTipuri t
	where exists (select 1 from @scriereTaburi a inner join @scrieretipuri s on s.meniu=a.meniusursa and s.tip=a.tipsursa and s.selectare=1 and a.meniunou=t.meniu and a.tipnou=t.tip
			and a.meniusursa<>a.meniunou and a.tipsursa<>a.tipnou)
	--> pana aici s-a stabilit integral care meniuri,tipuri, subtipuri (incluzant taburile) se vor importa !!!

	if isnull(@date.value('count(/row/machete/tipuri/formuri)','int'),0)<>0
	begin
		insert into @scriereFormuri
		select row_number() over(order by Ordine) as ID,
				Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula, detalii
			from OPENXML(@iDoc, '/row/machete/tipuri/formuri/form')
			with(
				Meniu varchar(20)
				,Tip varchar(2)
				,Subtip varchar(2)
				,Ordine int
				,Nume varchar(50)
				,TipObiect varchar(50)
				,DataField varchar(50)
				,LabelField varchar(50)
				,Latime int
				,Vizibil bit
				,Modificabil bit
				,ProcSQL varchar(50)
				,ListaValori varchar(100)
				,ListaEtichete varchar(600)
				,Initializare varchar(50)
				,Prompt varchar(50)
				,Procesare varchar(50)
				,Tooltip varchar(500)
				,formula varchar(500)
				,detalii  xml './*'
				)
	end

	if isnull(@date.value('count(/row/machete/tipuri/griduri)','int'),0)<>0
	begin
		insert into @scriereGrid
		select row_number() over(order by Ordine) as ID,
				Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, modificabil, formula, detalii
			from OPENXML(@iDoc, '/row/machete/tipuri/griduri/grid')
			with(
				 Meniu varchar(20)
				 ,Tip varchar(2)
				 ,Subtip varchar(2)
				 ,InPozitii bit
				 ,NumeCol varchar(50)
				 ,DataField varchar(50)
				 ,TipObiect varchar(50)
				 ,Latime int
				 ,Ordine int
				 ,Vizibil bit
				 ,modificabil bit
				 ,formula varchar(8000)
				 ,detalii  xml './*'
				)
	end

	if isnull(@date.value('count(/row/machete/tipuri/filtre)','int'),0)<>0
	begin
		insert into @scriereFiltre
		select row_number() over(order by Ordine) as ID,
			Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2, detalii
		from OPENXML(@iDoc, '/row/machete/tipuri/filtre/filtre')
			with(
			Meniu varchar(20)
			,Tip varchar(2)
			,Ordine int
			,Vizibil bit
			,TipObiect varchar(50)
			,Descriere varchar(50)
			,Prompt1 varchar(20)
			,DataField1 varchar(100)
			,Interval bit
			,Prompt2 varchar(20)
			,DataField2 varchar(100)
			,detalii  xml './*'
				)
	end
	
	if isnull(@date.value('count(/row/machete/tipuri/formmobile)','int'),0)<>0
	begin
		insert into @scriereFormuriMobile
		select row_number() over(order by Ordine) as ID,
				Identificator, Ordine, isnull(Nume,''), TipObiect, DataField, isnull(LabelField,''), isnull(ProcSQL,''),
				isnull(ListaValori,''), isnull(ListaEtichete,''), isnull(Initializare,''), isnull(Prompt,''), Vizibil, Modificabil
			from OPENXML(@iDoc, '/row/machete/tipuri/formmobile/webconfigformmobile')
			with(
			Identificator varchar(50)
			,Ordine float
			,Nume varchar(2000)
			,TipObiect varchar(100)
			,DataField varchar(2000)
			,LabelField varchar(2000)
			,ProcSQL varchar(2000)
			,ListaValori varchar(2000)
			,ListaEtichete varchar(2000)
			,Initializare varchar(2000)
			,Prompt varchar(2000)
			,Vizibil bit
			,Modificabil bit
			 )
	end
			 
	begin try	exec sp_xml_removedocument @iDoc
	end try begin catch end catch
	
	if len(@alt_meniu)>0	-->tratez inlocuirea codului de meniului si/sau a tipului, care va determina crearea unei dubluri a configurarilor initiale care se importa
	begin
		declare @o_meniu varchar(1000), @o_tip varchar(1000)
		select @o_meniu=isnull(@parXML.value('(/parametri/@old_meniu)[1]','varchar(1000)'),'')
				,@o_tip=isnull(@parXML.value('(/parametri/@old_tip)[1]','varchar(1000)'),'')
		if @o_meniu is null or @o_meniu=''
			select @o_meniu=isnull(@parxml.value('(/parametri/DateGrid/meniuri[(./@s_selectare)="1"]/@s_meniu)[1]','varchar(1000)'),''),
					@o_tip=isnull(@parxml.value('(/parametri/DateGrid/tipuri[(./@s_selectare)="1"]/@s_tip)[1]','varchar(1000)'),'')
		
		if @o_meniu<>@alt_meniu
		begin
			declare @meniuNouInexistent bit	--> meniul "nou" se va insera daca tipul nou nu e specificat sau daca nu exista in webconfigmeniu
				set @meniuNouInexistent=0
			if not exists (select 1 from webconfigmeniu m where m.meniu=@alt_meniu)
				set @meniuNouInexistent=1
			update s set s.Meniu=@alt_meniu,
				s.Nume=(case when @alt_tip='' and (@alt_nume<>'' or @meniuNouInexistent=1) then @alt_nume else s.Nume end)
			from @scriereMeniuri s where s.meniu=@o_meniu and (@alt_tip='' or @meniuNouInexistent=1)
		end
		
		--if @o_tip<>@alt_tip
		update s set s.Meniu=@alt_meniu,
				s.tip=(case when @alt_tip='' then s.tip else @alt_tip end),
				s.Nume=(case when @alt_tip<>'' and @alt_nume<>'' and (isnull(s.subtip,'')='') then @alt_nume else s.Nume end)
			from @scriereTipuri s where s.meniu=@o_meniu
				and (--@o_tip='' and (isnull(s.tip,'')='' or isnull(s.tip,'')=@o_meniu)
					@alt_tip=''
					or @o_tip=s.tip)
		
		update s set s.Meniu=@alt_meniu,
				s.tip=(case when @alt_tip='' then s.tip else @alt_tip end)
			from @scriereFiltre s where s.meniu=@o_meniu
				and (@alt_tip=''
					or @o_tip=s.tip)
					
		update s set s.Meniu=@alt_meniu,
				s.tip=(case when @alt_tip='' then s.tip else @alt_tip end)
			from @scriereFormuri s where s.meniu=@o_meniu
				and (@alt_tip=''
					or @o_tip=s.tip)

		update s set s.Meniu=@alt_meniu,
				s.tip=(case when @alt_tip='' then s.tip else @alt_tip end)
			from @scriereGrid s where s.meniu=@o_meniu
				and (@alt_tip=''
					or @o_tip=s.tip)
		
		update s set s.MeniuSursa=@alt_meniu,
				s.TipSursa=(case when @alt_tip='' then s.TipSursa else @alt_tip end)
			from @scrieretaburi s where s.MeniuSursa=@o_meniu
				and (@alt_tip=''
					or @o_tip=s.TipSursa)
		
		update s set s.MeniuNou=@alt_meniu,
				s.TipNou=(case when @alt_tip='' then s.TipNou else @alt_tip end)
			from @scrieretaburi s where s.MeniuNou=@o_meniu
				and (@alt_tip=''
					or @o_tip=s.TipNou)
		
		update s set s.identificator=@alt_meniu
			from @scriereFormuriMobile s where s.identificator=@o_meniu

	end
	--#################################################################################################################
	--#												SCRIERE MENIURI													  #
	--#################################################################################################################

	begin
		
		delete m
		from webconfigmeniu m inner join @scriereMeniuri s on m.meniu=s.meniu
		where s.selectare=1 and s.Suprascriere=1

		insert into webConfigMeniu(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil)
		select Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil
			from @scriereMeniuri s
			where (s.selectare=1 and not exists (select 1 from webconfigmeniu m where m.meniu=s.meniu))

	end

		
	--#################################################################################################################
	--#												SCRIERE TIPURI													  #
	--#################################################################################################################
	
	begin
		
		delete m
		from webconfigtipuri m inner join @scriereTipuri t on m.meniu=t.meniu and isnull(m.tip,'')=isnull(t.tip,'') and isnull(m.subtip,'')=isnull(t.subtip,'')
		where t.selectare=1 and t.Suprascriere=1

		insert into webConfigTipuri(Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, 
					ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare, tasta, ProcInchidereMacheta, Detalii)
		select Meniu, isnull(Tip,''), isnull(Subtip,''), isnull(Ordine,0), Nume, Descriere, TextAdaugare, TextModificare, ProcDate, 
				ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare, tasta, ProcInchidereMacheta, Detalii
			from @scriereTipuri t
			where (t.selectare=1 and not exists (select 1 from webConfigTipuri m where m.meniu=t.meniu and isnull(m.tip,'')=isnull(t.tip,'') and isnull(m.subtip,'')=isnull(t.subtip,'')))
	end
	
	--#################################################################################################################
	--#												SCRIERE TABURI													  #
	--#################################################################################################################

	begin
		delete m
		from webconfigtaburi m inner join @scriereTipuri t on m.meniusursa=t.meniu and isnull(m.tipsursa,'')=isnull(t.tip,'') and isnull(t.subtip,'')=''
		where t.selectare=1 and t.Suprascriere=1

		insert into webConfigTaburi(MeniuSursa,	TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, ProcPopulare, Ordine, Vizibil, detalii)
		select MeniuSursa,	TipSursa, NumeTab, Icoana, TipMachetaNoua, MeniuNou, TipNou, t.ProcPopulare, t.Ordine, t.Vizibil, t.detalii
			from @scriereTaburi t
			where exists (select 1 from @scriereTipuri s where t.meniusursa=s.meniu and isnull(t.tipsursa,'')=isnull(s.tip,'') and isnull(s.subtip,'')='' and s.selectare=1) and
				not exists (select 1 from webConfigtaburi m where m.meniusursa=t.meniusursa and isnull(m.tipsursa,'')=isnull(t.tipsursa,'')
						and m.meniunou=t.meniunou and isnull(m.tipnou,'')=isnull(t.tipnou,''))
	end
	
	--#################################################################################################################
	--#												SCRIERE FORMURI													  #
	--#################################################################################################################
	
	begin
		
		delete m
		from webConfigForm m
			inner join @scriereTipuri t on m.meniu=t.meniu and isnull(m.tip,'')=isnull(t.tip,'') and isnull(m.subtip,'')=isnull(t.subtip,'')
		where t.selectare=1 and t.Suprascriere=1

		insert into webConfigForm(Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, 
			Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, formula, Detalii)
		select f.Meniu, isnull(f.Tip,''), isnull(f.Subtip,''), max(f.Ordine), max(f.Nume), max(f.TipObiect), isnull(f.DataField,''), max(f.LabelField), max(f.Latime), 
			max(convert(int,f.Vizibil)), max(convert(int,f.Modificabil)), max(f.ProcSQL), max(f.ListaValori), max(f.ListaEtichete), max(f.Initializare), max(f.Prompt), max(f.Procesare),
			max(f.Tooltip), max(f.formula), max(convert(varchar(max),f.Detalii))
		from @scriereFormuri f
		where exists (select 1 from @scriereTipuri t where f.meniu=t.meniu and isnull(f.tip,'')=isnull(t.tip,'') and isnull(f.subtip,'')=isnull(t.subtip,'') and t.selectare=1) and
			not exists (select 1 from webConfigform m
			where m.meniu=f.meniu and isnull(m.tip,'')=isnull(f.tip,'') and isnull(m.subtip,'')=isnull(f.subtip,'') and isnull(m.datafield,'')=isnull(f.datafield,''))
		group by f.meniu, f.tip, f.subtip, f.datafield
	end
	
	--#################################################################################################################
	--#												SCRIERE GRIDURI													  #
	--#################################################################################################################

	begin
		
		delete m
		from webConfigGrid m
			inner join @scriereTipuri t on m.meniu=t.meniu and isnull(m.tip,'')=isnull(t.tip,'') and isnull(m.subtip,'')=isnull(t.subtip,'')
		where t.selectare=1 and t.Suprascriere=1

		insert into webConfigGrid(Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, Modificabil, formula, Detalii)
		select	g.Meniu, isnull(g.Tip,''), isnull(g.Subtip,''), g.InPozitii, max(g.NumeCol), isnull(g.DataField,''), max(g.TipObiect), max(g.Latime), max(isnull(g.Ordine,1)), max(convert(int,g.Vizibil)), 
				max(convert(int,g.Modificabil)), max(g.formula), max(convert(varchar(max),g.Detalii))
		from @scriereGrid g
		where exists (select 1 from @scriereTipuri t where g.meniu=t.meniu and isnull(g.tip,'')=isnull(t.tip,'') and isnull(g.subtip,'')=isnull(t.subtip,'') and t.selectare=1) and
			not exists(select 1 from webconfiggrid w where g.meniu=w.meniu and isnull(g.tip,'')=isnull(w.tip,'') and isnull(g.subtip,'')=isnull(w.subtip,'')
						and isnull(g.datafield,'')=isnull(w.datafield,'') and isnull(g.InPozitii,0)=isnull(w.InPozitii,0))
		group by g.meniu, g.tip, g.subtip, g.datafield, g.inpozitii
	end

	----#################################################################################################################
	----#												SCRIERE FILTRE													#
	----#################################################################################################################
	
	begin
		delete m
		from webConfigFiltre m
			left join @scrieremeniuri w on w.meniu=m.meniu
			left join webconfigmeniu ww on ww.meniu=m.meniu
			inner join @scriereTipuri t on m.meniu=t.meniu and (isnull(m.tip,'')=isnull(t.tip,'') or isnull(w.tipmacheta,ww.tipmacheta)='C' and isnull(t.tip,'')='' and isnull(m.tip,'')=isnull(m.meniu,''))
				and isnull(t.subtip,'')=''
		where t.selectare=1 and t.Suprascriere=1

		insert into webConfigFiltre(Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2, Detalii)
		select	f.Meniu, f.Tip, max(f.Ordine), max(convert(int,f.Vizibil)), max(f.TipObiect), max(f.Descriere), max(f.Prompt1), max(isnull(f.DataField1,'')),
			max(convert(int,f.Interval)), max(f.Prompt2), max(f.DataField2), max(convert(varchar(max),f.Detalii))
		from @scriereFiltre f
			left join @scrieremeniuri w on w.meniu=f.meniu
			left join webconfigmeniu ww on ww.meniu=f.meniu
		where exists (select 1 from @scriereTipuri t where f.meniu=t.meniu and (isnull(f.tip,'')=isnull(t.tip,'') or (isnull(w.tipmacheta,ww.tipmacheta)='C' or isnull(w.tipmacheta,ww.tipmacheta) is null)
				and isnull(t.tip,'')='' and isnull(f.tip,'')=left(isnull(f.meniu,''),2)) and isnull(t.subtip,'')='' and t.selectare=1) and
			not exists (select 1 from webconfigfiltre w where f.meniu=w.meniu and isnull(f.tip,'')=isnull(w.tip,'') and isnull(f.DataField1,'')=isnull(w.DataField1,''))
		group by f.meniu, f.tip, f.DataField1
	end
	
	--#################################################################################################################
	--#											SCRIERE FORMURI MOBILE												  #
	--#################################################################################################################
	
	begin
		
		delete m
		from webConfigFormMobile m
			inner join @scriereTipuri t on m.identificator=t.meniu
		where t.selectare=1 and t.Suprascriere=1

		insert into webConfigFormMobile(Identificator, Ordine, Nume, TipObiect, DataField, LabelField, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Vizibil, Modificabil)
		select Identificator, Ordine, Nume, TipObiect, DataField, LabelField, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Vizibil, Modificabil
		from @scriereFormuriMobile f
		where exists (select 1 from @scriereTipuri t where f.identificator=t.meniu and t.selectare=1) and
			not exists (select 1 from webConfigFormMobile m
			where m.identificator=f.identificator and isnull(m.datafield,'')=isnull(f.datafield,''))
	end
	--test	
	delete tabelXML where sesiune=@sesiune
end try

begin catch
	set @mesaj = error_message() + ' (wOPImportMachete)'
	raiserror(@mesaj, 11, 1)
end catch
