--***
create procedure wOPPopulareConfigurari(@sesiune varchar(50)=null,
		@parXML xml=null,
		@publicabil int=1,	--> daca sa se genereze populare configurari pentru: 2=meniu din @parxml, 1=publicabile, 0=nepublicabile, null,-1 = toate
		@faraSTD int=0,		--> @faraSTD>0  = sa se genereze populare configurari fara std-uri intermediare
								--> @faraSTD=2 sa genereze populare cu verificare pe indecsi (completari la configurari existente)
		@meniuri varchar(max)=null,	--> lista de meniuri, cu virgula ca separator (exemplu: ",CFGMACHETE,DO,"); daca lista e completata @publicabil nu mai are efect
		@caleDestinatie varchar(max)=null,	--> unde se salveaza popularea generata
		@fisier varchar(max)=null	--> numele fisierului de populare
		)
as
declare @eroare varchar(max)
select @eroare=''
begin try

	if not exists (select 1 from sys.objects o 
		inner join sys.columns c on o.object_id=c.object_id
		and o.name='webconfigmeniu' and c.name='publicabil')
		set @publicabil=-1
	if @sesiune is null set @sesiune=suser_name()
	declare @sitaburi bit
	
	if @parXML is not null
	begin
		select	@publicabil=@parXML.value('(*/@publicabil)[1]','int'),
				@faraSTD=isnull(@parXML.value('(*/@farastd)[1]','int'),0),
				@sitaburi=isnull(@parXML.value('(*/@sitaburi)[1]','int'),1),
				@fisier='populare'+@sesiune+'.sql.txt'
--		select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)
			
		select @caleDestinatie=
				rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)
			from par where tip_parametru='AR' and parametru='caleform'
	end
	select @publicabil=isnull(@publicabil,-1)
	
	--> se genereaza populare doar pentru meniul din @parxml daca @publicabil = 2 = "Meniul selectat"
	if @publicabil=2
		set @meniuri=','+@parxml.value('(*/@meniu)[1]','varchar(100)')+','
		
	declare @rez varchar(max), 
			@webconfigmeniu varchar(max), @webconfiggrid varchar(max), @webconfigfiltre varchar(max), 
			@webConfigForm varchar(max), @webConfigTipuri varchar(max), @webConfigTaburi varchar(max),
			@grup varchar(max), @linie varchar(max),
			@numarator int, @limita int, @Meniu varchar(20), @vizibil int, @tip varchar(20)

	--select @publicabil=0
	--select @meniuri=',C_LS,'--,@Meniu=506--, @vizibil=1, @tip='TE'	--> Grija: aplicarea filtrului @tip strica luarea recursiva a configurarilor pe webconfigtaburi !!!!!
	--> determin obiectele publicabile
	if object_id('tempdb..#meniuri') is not null drop table #meniuri

	create table #meniuri (meniu varchar(20))
	--/*
	--> publicare obiecte publicabile; se iau meniurile parinti:
	--> dinamic pt a se putea folosi usor procedura si pe alte baze de date:
	if @meniuri is null-- and @publicabil is not null
	begin
		declare @comanda_str varchar(max)
		select @comanda_str='
		--if @publicabil=1 and exists (select 1 from webconfigmeniu w where meniuparinte='''' and publicabil is null)
		declare @eroare varchar(max), @publicabil bit
		select @publicabil='+convert(varchar(10),@publicabil)+'
		'+(case when @publicabil<>4 then '' else	--> aceasta eroare ar trebui sa apara daca exista meniuri nesetate (ca publicabilitate), pt @publicabil=1; trebuie?
		'select top 1 @eroare=''Exista cel putin un meniu-folder cu publicarea nedecisa (''+meniu+'')''
			from webconfigmeniu w where meniuparinte='''' and publicabil is null and meniu<>''''
		if len(@eroare)>0 raiserror(@eroare,16,1)' end) +'

		insert into #meniuri(meniu)
		select meniu
		from webconfigmeniu w where meniuparinte is not null and meniuparinte='''' '+(case when @publicabil=-1 then '' else 'and isnull(w.publicabil,0)=@publicabil' end)+'
			and isnull(meniu,'''')<>''''
		group by meniu
		--union all select ''''
		order by 1
		'
		--test	select @comanda_str for xml path('')
		exec (@comanda_str)
		--test	select @comanda_str for xml path('')
	end

	--*/
	--/*
	--> publicare cand e specificata o lista de meniuri:
	if (@meniuri is not null)
	insert into #meniuri(meniu)
	select meniu from webconfigmeniu w where charindex(','+rtrim(w.meniu)+',',@meniuri)>0
		order by 1

	--select * from #meniuri
	--> completare cu meniuri inferioare:
	declare @nr int, @nranterior int
	select @nr=count(1) from #meniuri
	select @nranterior=0
	while @nr>@nranterior
	begin
		select @nranterior=@nr
		insert into #meniuri(meniu)
		select meniu from webconfigmeniu m where exists (select 1 from #meniuri w where w.meniu=m.meniuparinte)
			and not exists (select 1 from #meniuri w where w.meniu=m.meniu)
		order by 1
		select @nr=count(1) from #meniuri
	end

	--> elimin meniuri dubioase (space, null) care NU AR TREBUI SA EXISTE:
	delete m from #meniuri m where rtrim(isnull(m.meniu,''))=''
	--/*
	create table #taburi(meniu varchar(100))
	;with x (meniu, dinmeniu)
	as
	(
		select meniu, 1 from #meniuri union all
		select convert(varchar(20),t.meniunou) meniu, 0
			from webconfigtaburi t inner join x on t.meniusursa=x.meniu and x.meniu<>t.meniunou
			where not exists (select 1 from #meniuri w where w.meniu=t.meniunou)
	)
	insert into #taburi(meniu)
	select meniu
	from x where dinmeniu=0
	group by x.meniu
	order by meniu
	
	--> daca exista tab-uri externe configurarilor exportate folosite de configurarile respective fie se vor exporta de asmenea fie se va afisa un mesaj cu lista lor:
	if (select count(1) from #taburi)>0
		if @sitaburi=1
			insert into #meniuri(meniu) select meniu from #taburi
		else
		begin
			declare @mesaj varchar(max)
			select @mesaj='Urmatoarele meniuri sunt folosite ca tab in configurarile pentru care s-a generat popularea dar NU SUNT INCLUSE in populare:'+char(10)
			select @mesaj=@mesaj+char(10)+rtrim(t.meniu)+' ('+isnull(max(m.nume),max(a.nume))+')' from
				#taburi t
					outer apply( select rtrim(nume) nume from webconfigmeniu m where m.meniu=t.meniu) m
					outer apply( select rtrim(m.numetab) nume from webconfigtaburi m where m.meniunou=t.meniu) a
			group by t.meniu
			
			select 'Notificare' titluMesaj, @mesaj textMesaj for xml raw, root('Mesaje')
		end

	--> mai elimin o data meniuri dubioase (space, null) care NU AR TREBUI SA EXISTE:
	delete m from #meniuri m where rtrim(isnull(m.meniu,''))=''
	--*/
	declare @sirmeniuri varchar(max)
	select @sirmeniuri=','
	select @sirmeniuri=@sirmeniuri+meniu+',' from #meniuri m
	--> cateva explicatii despre script:
	select @rez=
'--	Script generat automat pentru popularea tabelelor de configurari in ASiSRia in '+convert(varchar(20),getdate(),103)+'
'+(case when @publicabil=1 and @meniuri is null and @faraSTD=0 then '	--------- populare standard (toate meniurile publicabile, cu intermediere prin std) --------'+char(10)
		else '' 
		end)
	+(case when @meniuri is not null then '--		pentru '+convert(varchar(20),(select count(1) from #meniuri))+' meniuri selectate '+char(10) else '' end)
	+(case when @faraSTD=0 then '--		trece prin tabele intermediare STD (va trebui rulat si Frame/Populare/w_preluareConfigurari.sql pentru instalare)'+char(10)
		when @faraSTD=2 then '--		insereaza conditionat (completare configurari fara stergere) direct in tabelele de configurari'+char(10)
		when @faraSTD=1 then '--		DACA se activeaza codul din "if"-ul de mai jos: insereaza neconditionat (cu stergerea in prealabil a meniurilor de inserat) direct in tabelele de configurari:'+char(10)
	end)
	+'
'
	--> o mica asigurare impotriva popularii accidentale cu configurari specifice pe bd de dezvoltare de pe dev; daca se vrea neaparat popularea se va comenta conditia:
	--> stergere in prealabil (by default nu ruleaza, daca e nevoie se va activa la instalare de catre implementator; valabil doar pt @farastd>0 altfel nu are sens):
		--> tabela #instaleaza e comutator pentru rulare sau nerulare a popularii:
	if @farastd>0 select @rez=@rez+
		(case when @farastd>0 then 'if object_id(''tempdb..#instaleaza'') is not null drop table #instaleaza'+char(10) else '' end)
			--> daca se instaleaza cu verificarea existentei liniei de inserat (@farastd=2) #instaleaza exista by default deoarece e cel mai probabil ca se doreste instalarea
		+'
		----- daca se doreste instalarea pe bd "ghita" se va comenta secventa urmatoare (intregul "if"):
		if db_name()=''ghita'' and @@servername=''aswdev''
		begin
			raiserror(''Nu este permisa instalarea de configurari specifice pe baza de date de dezvoltare pentru a preveni alterarea machetelor generale! (Daca nu exista riscul specificat se va comenta eroarea curenta din script-ul de populare)'',16,1)
			return
		end
		'
		+(case when @farastd='2' then 'create table #instaleaza(pretext int)'+char(10) else '' end)
		+'
		if 1=0		---- pentru instalare NECONDITIONATA cu STERGEREA CONFIGURARILOR ANTERIOARE ale meniurilor de instalat trebuie setat "if"-ul pe true si rulat intregul script
		begin'+char(10)
			--> daca se instaleaza fara verificarea existentei liniei de inserat (@farastd=1) #instaleaza exista doar daca se face stergerea datelor in prealabil
			-->		deoarece altfel sunt sanse mari de eroare; in aceasta situatie se instaleaza cu stergerea configurarilor anterioare
			+(case when @farastd='1' then 
'				create table #instaleaza(pretext int)'+char(10) else '' end)+
'			delete w from webconfigmeniu w where NOT(charindex('',''+w.meniu+'','','''+@sirmeniuri+''')=0)
			delete w from webconfiggrid w where NOT(charindex('',''+w.meniu+'','','''+@sirmeniuri+''')=0)
			delete w from webconfigfiltre w where NOT(charindex('',''+w.meniu+'','','''+@sirmeniuri+''')=0)
			delete w from webconfigtipuri w where NOT(charindex('',''+w.meniu+'','','''+@sirmeniuri+''')=0)
			delete w from webconfigform w where NOT(charindex('',''+w.meniu+'','','''+@sirmeniuri+''')=0)
			delete w from webconfigtaburi w where NOT(charindex('',''+w.meniusursa+'','','''+@sirmeniuri+''')=0)
		end
		'
	--select @rez='-- create table #stergere(pretext int)'
	--> re-creare tabele std
	else
	select @rez=@rez+'
	Set nocount on
	begin try drop table [dbo].[webConfigSTDFiltre] end try begin catch end catch
	'+'GO
	begin try drop table [dbo].[webConfigSTDForm] end try begin catch end catch
	'+'GO
	begin try drop table [dbo].[webConfigSTDGrid] end try begin catch end catch
	'+'GO
	begin try drop table [dbo].[webConfigSTDMeniu] end try begin catch end catch
	'+'GO
	begin try drop table [dbo].[webConfigSTDTaburi] end try begin catch end catch
	'+'GO
	begin try drop table [dbo].[webConfigSTDTipuri] end try begin catch end catch
	'+'GO

	CREATE TABLE webConfigSTDMeniu(
		Meniu varchar(20) not null,
		Nume varchar(30) null,
		MeniuParinte varchar(20) null,
		Icoana varchar(50) null,
		TipMacheta varchar(5) null,
		NrOrdine decimal(7,2),
		Componenta varchar(100),
		Semnatura varchar(100),
		Detalii xml default null,
		vizibil bit not null default 0
	)

	CREATE TABLE webConfigSTDGrid(
		Meniu varchar(20) NOT NULL,
		Tip varchar(20) NULL,
		Subtip varchar(20) NULL,
		InPozitii bit NOT NULL,
		NumeCol varchar(50) NULL,
		DataField varchar(50) NULL,
		TipObiect varchar(50) NULL,
		Latime int NULL,
		Ordine int NULL,
		Vizibil bit NULL,
		modificabil bit NULL,
		formula varchar(8000) NULL
	)

	CREATE TABLE webConfigSTDFiltre(
		Meniu varchar(20) NOT NULL,
		Tip varchar(20) NOT NULL,
		Ordine int NULL,
		Vizibil bit NOT NULL,
		TipObiect varchar(50) NULL,
		Descriere varchar(50) NULL,
		Prompt1 varchar(20) NULL,
		DataField1 varchar(100) NULL,
		Interval bit NULL,
		Prompt2 varchar(20) NULL,
		DataField2 varchar(100) NULL
	)

	CREATE TABLE webConfigSTDTipuri(
		Meniu varchar(20) NOT NULL,
		Tip varchar(20) NULL,
		Subtip varchar(20) NULL,
		Ordine int NULL,
		Nume varchar(50) NULL,
		Descriere varchar(500) NULL,
		TextAdaugare varchar(60) NULL,
		TextModificare varchar(60) NULL,
		ProcDate varchar(60) NULL,
		ProcScriere varchar(60) NULL,
		ProcStergere varchar(60) NULL,
		ProcDatePoz varchar(60) NULL,
		ProcScrierePoz varchar(60) NULL,
		ProcStergerePoz varchar(60) NULL,
		Vizibil bit NULL,
		Fel varchar(1) NULL,
		procPopulare varchar(60) NULL,
		tasta varchar(20) NULL,
		ProcInchidereMacheta varchar(60) null
	)

	CREATE TABLE webConfigSTDForm(
		Meniu varchar(20) NOT NULL,
		Tip varchar(20) NULL,
		Subtip varchar(20) NULL,
		Ordine int NULL,
		Nume varchar(50) NULL,
		TipObiect varchar(50) NULL,
		DataField varchar(50) NULL,
		LabelField varchar(50) NULL,
		Latime int NULL,
		Vizibil bit NULL,
		Modificabil bit NULL,
		ProcSQL varchar(50) NULL,
		ListaValori varchar(100) NULL,
		ListaEtichete varchar(600) NULL,
		Initializare varchar(50) NULL,
		Prompt varchar(50) NULL,
		Procesare varchar(50) NULL,
		Tooltip varchar(500) NULL,
		formula varchar(max) NULL,
		detalii xml
	)

	CREATE TABLE webConfigSTDTaburi(
		MeniuSursa varchar(50) NOT NULL,
		TipSursa varchar(50) NOT NULL,
		NumeTab varchar(100) NOT NULL,
		Icoana varchar(500) NULL,
		TipMachetaNoua varchar(20) NULL,
		MeniuNou varchar(20) NULL,
		TipNou varchar(20) NULL,
		ProcPopulare varchar(100) NULL,
		Ordine smallint NULL,
		Vizibil bit NULL
		)
	'
	--> populare propriu-zisa
	--> deoarece sql server nu se descurca prea bine cu concatenarile de string-uri mari aplic "divide et impera": 
		--> fiecare linie de cod o creez in variabila @linie;
		--> apoi concatenez cate 100 (@limita) de linii in @webconfig[ceva] si le adaug GO sa mearga mai rapid rularea script-ului final generat;
		--> le concatenez in @grup pt fiecare tabela de configurari;
		--> codul complet ajunge in @rez
	--------------------------------------------------	webConfigSTDMeniu	--------------------------------------------------
	select @limita=100
	select	@numarator=@limita,@grup='', @webConfigmeniu=''
	select	@grup=@grup+char(13)+char(13)
	select	@linie=min(
				char(13)+'union all select '''+convert(varchar(20),m.Meniu)+''','''+isnull(Nume,'')+''','+isnull(''''+convert(varchar(20),MeniuParinte)+'''','null')+','''+
					isnull(Icoana,'')+''','''+isnull(m.TipMacheta,'')+''','+--isnull(m.Meniu,'')+''','''+isnull(Modul,'')+''''
					isnull(''''+convert(varchar(20),m.NrOrdine)+'''','null')+','''+m.componenta+''','''+m.semnatura+''','+isnull(''''+convert(varchar(max),m.detalii)+'''','null')+','+convert(varchar(20),m.vizibil)
					--> conditia de inserare fara eroare in cazul in care configurarile exista deja:
				+(case when @faraSTD=2 then'
					where not exists (select 1 from webconfigSTDmeniu w where w.meniu='''+convert(varchar(100),m.Meniu)+''')' else '' end)
				),
			@webconfigmeniu=(case when @numarator<@limita then @webconfigmeniu else @webConfigmeniu+@grup end)
			,@grup=(case when @numarator<@limita then @grup else 
					char(13)+'GO'+char(13)
					+(case when @farastd=0 then '' else 'if object_id(''tempdb..#instaleaza'') is not null'+char(13) end)
					+'insert into webconfigSTDmeniu(Meniu, Nume, MeniuParinte, Icoana, TipMacheta, NrOrdine, Componenta, Semnatura, Detalii, vizibil
								)'		--id,Nume,idParinte,Icoana,TipMacheta,Meniu,Modul
					+char(13)+'select top 0 null, null,null,null,null,null,null,null,null,null'
			end)+@linie
			,@numarator=(case when @numarator<@limita then @numarator+1 else 0 end)
	from webconfigmeniu m inner join #meniuri w on w.meniu=isnull(m.meniu,'')
			where m.meniuParinte is not null and m.meniu is not null or
				m.meniuParinte is null and exists (select 1 from webconfigmeniu m1 inner join #meniuri w1 on w1.meniu=isnull(m1.meniu,'')
					and m1.meniuparinte is not null and m.meniu=m1.meniuparinte and m1.meniu is not null)
			group by isnull(m.meniu,'')
	select @rez=@rez+@webconfigmeniu+@grup

	--------------------------------------------------	webConfigSTDGrid	--------------------------------------------------
	select	@numarator=@limita,@grup='', @webConfigGrid=''
	select @grup=char(13)+char(13)
	select @linie=min(
			char(13)+'union all select '''+isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(w.Subtip,'')+''','''+
						convert(varchar(1),w.InPozitii)+''','''+w.NumeCol+''','''+w.DataField+''','''+isnull(w.TipObiect,'')+''','''+convert(varchar(10),w.Latime)+''','''+convert(varchar(10),isnull(w.Ordine,0))+''','''+
						convert(varchar(10),w.Vizibil)+''','''+convert(varchar(max),isnull(w.formula,''))+''','+convert(varchar(1),isnull(w.modificabil,0))
					--> conditia de inserare fara eroare in cazul in care configurarile exista deja:
				+(case when @faraSTD=2 then'
				where not exists (select 1 from webconfigSTDgrid w
					where w.meniu='''+convert(varchar(100),w.Meniu)+'''
					and w.tip='''+convert(varchar(100),w.tip)+'''
					and isnull(w.subtip,'''')='''+convert(varchar(100),isnull(w.subtip,''))+'''
					and w.datafield='''+convert(varchar(100),w.datafield)+'''
					and w.inpozitii='''+convert(varchar(100),w.inpozitii)+'''
					and isnull(w.ordine,0)='''+convert(varchar(100),isnull(w.ordine,0))+''')'
					else '' end)
				),
			@webconfiggrid=(case when @numarator<@limita then @webconfiggrid else @webConfiggrid+@grup end)
			,@grup=(case when @numarator<@limita then @grup else 
					char(13)+'GO'+char(13)
					+(case when @farastd=0 then '' else 'if object_id(''tempdb..#instaleaza'') is not null'+char(13) end)
					+'insert into webconfigSTDgrid (Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, formula, modificabil) '
					+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null'
			end)+@linie
			,@numarator=(case when @numarator<@limita then @numarator+1 else 0 end)
	from webConfigGrid w inner join #meniuri m on w.meniu=m.meniu
		where w.latime is not null and rtrim(w.meniu)<>''
			and (@vizibil is null or w.Vizibil=@vizibil)
			and (@tip is null or w.Tip=@tip)
		group by isnull(w.Meniu,''), isnull(w.Tip,''), isnull(w.Subtip,''), isnull(w.DataField,''), isnull(w.InPozitii,''), isnull(w.Ordine,'')
	select @rez=@rez+@webConfiggrid+@grup
	
	--------------------------------------------------	webConfigSTDFiltre	--------------------------------------------------
	select	@numarator=@limita,@grup='', @webconfigfiltre=''
	select @grup=@grup+char(13)+char(13)
	select @linie=min(
			char(13)+'union all select '''+
			isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(convert(varchar(10),w.Ordine),'')+''','''+convert(varchar(1),w.Vizibil)+''','''+
			isnull(w.TipObiect,'')+''','''+replace(isnull(w.Descriere,''),'''','''''')+''','''+replace(isnull(w.Prompt1,''),'''','''''')+''','''+isnull(w.DataField1,'')+''','''+
			convert(varchar(10),isnull(w.Interval,0))+''','''+isnull(w.Prompt2,'')+''','''+isnull(w.DataField2,'')+''''
				--> conditia de inserare fara eroare in cazul in care configurarile exista deja:
				+(case when @faraSTD=2 then'
				where not exists (select 1 from webconfigSTDfiltre w
					where isnull(w.meniu,'''')='''+convert(varchar(100),w.Meniu)+'''
					and isnull(w.tip,'''')='''+convert(varchar(100),w.tip)+'''
					and isnull(w.datafield1,'''')='''+convert(varchar(100),w.datafield1)+''')'
					else '' end)
			),
		@webconfigfiltre=(case when @numarator<@limita then @webconfigfiltre else @webconfigfiltre+@grup end)
		,@grup=(case when @numarator<@limita then @grup else 
			char(13)+'GO'+char(13)+
				+(case when @farastd=0 then '' else 'if object_id(''tempdb..#instaleaza'') is not null'+char(13) end)
			+'insert into webconfigSTDfiltre (Meniu, Tip, Ordine, Vizibil, TipObiect, Descriere, Prompt1, DataField1, Interval, Prompt2, DataField2) '
			+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null'
		end)+@linie
		,@numarator=(case when @numarator<@limita then @numarator+1 else 0 end)
	from webConfigFiltre w inner join #meniuri m on w.meniu=m.meniu
		where (@vizibil is null or w.Vizibil=@vizibil)
			and (@tip is null or w.Tip=@tip)
		group by isnull(w.Meniu,''), isnull(w.Tip,''), isnull(w.DataField1,'')
	select @rez=@rez+@webConfigfiltre+@grup

	--------------------------------------------------	webConfigSTDTipuri	--------------------------------------------------
	select	@numarator=@limita,@grup='', @webConfigTipuri=''
	select	@grup=@grup+char(13)+char(13)
	select	@linie=min(
				char(13)+'union all select '''+
				isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(w.Subtip,'')+''','''+isnull(convert(varchar(10),w.Ordine),'0')+''','''+isnull(w.Nume,'')+''','''+
				isnull(replace(w.Descriere,'''',''''''),'')+''','''+isnull(w.TextAdaugare,'')+''','''+isnull(w.TextModificare,'')+''','''+isnull(w.ProcDate,'')+''','''+isnull(w.ProcScriere,'')+''','''+isnull(w.ProcStergere,'')+''','''+
				isnull(w.ProcDatePoz,'')+''','''+isnull(w.ProcScrierePoz,'')+''','''+isnull(w.ProcStergerePoz,'')+''','''+isnull(convert(varchar(2),w.Vizibil),'0')+''','''+isnull(w.Fel,'')+''','''+rtrim(isnull(w.procPopulare,''))+''','+
				rtrim(isnull(''''+w.tasta+'''','null'))+','+rtrim(isnull(''''+w.ProcInchidereMacheta+'''','null'))+''
	--			, tasta, ProcInchidereMacheta
				--> conditia de inserare fara eroare in cazul in care configurarile exista deja:
						+(case when @faraSTD=2 then'
						where not exists (select 1 from webconfigSTDtipuri w
							where w.meniu='''+convert(varchar(100),w.Meniu)+'''
							and w.tip='''+convert(varchar(100),w.tip)+'''
							and isnull(w.subtip,'''')='''+convert(varchar(100),isnull(w.subtip,''))+'''
							and isnull(w.ordine,0)='''+convert(varchar(100),isnull(w.ordine,0))+''')'
							else '' end)
				),
		@webConfigTipuri=(case when @numarator<@limita then @webConfigTipuri else @webConfigTipuri+@grup end)
		,@grup=(case when @numarator<@limita then @grup else
			char(13)+'GO'+char(13)
			+(case when @farastd=0 then '' else 'if object_id(''tempdb..#instaleaza'') is not null'+char(13) end)
			+'insert into webconfigSTDtipuri (Meniu, Tip, Subtip, Ordine, Nume, Descriere, TextAdaugare, TextModificare, ProcDate, ProcScriere, ProcStergere, ProcDatePoz, ProcScrierePoz, ProcStergerePoz, Vizibil, Fel, procPopulare, tasta, ProcInchidereMacheta)'
			+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
		end)+@linie
		,@numarator=(case when @numarator<@limita then @numarator+1 else 0 end)
	from webConfigTipuri w inner join #meniuri m on w.meniu=m.meniu
		where rtrim(w.meniu)<>'' and (@vizibil is null or w.Vizibil=@vizibil)
			and (@tip is null or w.Tip=@tip)
		group by isnull(w.Meniu,''), isnull(w.Tip,''), isnull(w.Subtip,''), isnull(w.Ordine,'')
	select @rez=@rez+@webConfigTipuri+@grup
	--------------------------------------------------	webConfigSTDForm	--------------------------------------------------
	select	@numarator=@limita,@grup='', @webConfigForm=''
	select	@grup=@grup+char(13)+char(13)
	--select	@grup=@grup+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'
	select	@linie=min(
			char(13)+
	--		'insert into dbo.webconfigSTDform (IdUtilizator, TipMacheta, Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip)'+
	--		char(13)+
			' union all select '''+
			--'values ('''+
			isnull(w.Meniu,'')+''','''+isnull(w.Tip,'')+''','''+isnull(w.Subtip,'')+''','''+isnull(convert(varchar(10),w.Ordine),'')+''','''+
			isnull(replace(w.Nume,'''',''''''),'')+''','''+isnull(w.TipObiect,'')+''','''+isnull(w.DataField,'')+''','''+isnull(w.LabelField,'')+''','''+isnull(convert(varchar(10),w.Latime),'')+''','''+
			convert(varchar(1),isnull(w.Vizibil,0))+''','''+convert(varchar(1),isnull(w.Modificabil,0))+''','''+isnull(w.ProcSQL,'')+''','''+isnull(w.ListaValori,'')+''','''+isnull(w.ListaEtichete,'')+
			''','''+isnull(w.Initializare,'')+''','''+isnull(replace(w.Prompt,'''',''''''),'')+''','''+isnull(w.Procesare,'')+''','''+isnull(w.Tooltip,'')+''','''+isnull(w.formula,'')+
			--''','''+isnull(replace(convert(varchar(max),w.detalii),'''',''''''),'')
			''','''+isnull(case when w.TipObiect='ACA' then convert(varchar(max),w.detalii) else '' end,'')
		+''''
			--> conditia de inserare fara eroare in cazul in care configurarile exista deja:
			+(case when @faraSTD=2 then'
			where not exists (select 1 from webconfigSTDform w
				where w.meniu='''+convert(varchar(100),w.Meniu)+'''
				and w.tip='''+convert(varchar(100),w.tip)+'''
				and isnull(w.subtip,'''')='''+convert(varchar(100),isnull(w.subtip,''))+'''
				and isnull(w.datafield,'''')='''+convert(varchar(100),isnull(w.datafield,''))+''')'
				else '' end)
		)--+')'	+char(13)+'GO'
		,@webConfigForm=(case when @numarator<@limita then @webConfigForm else @webConfigForm+@grup end),
		--@grup=(case when @numarator<@limita then @grup else '' end)+@linie
		@grup=	(case when @numarator<@limita then @grup else 
						char(13)+'GO'+char(13)
						+(case when @farastd=0 then '' else 'if object_id(''tempdb..#instaleaza'') is not null'+char(13) end)
						+'insert into dbo.webconfigSTDform (Meniu, Tip, Subtip, Ordine, Nume, TipObiect, DataField, LabelField, Latime, Vizibil, Modificabil,
						ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Procesare, Tooltip, Formula, detalii)'
					+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null'--	''
				end)+@linie
		,@numarator=(case when @numarator<@limita then @numarator+1 else 0 end)
	from webConfigForm w inner join #meniuri m on w.meniu=m.meniu
		where rtrim(w.meniu)<>'' and (@vizibil is null or w.Vizibil=@vizibil)
			and (@tip is null or w.Tip=@tip)
		group by isnull(w.Meniu,''), isnull(w.Tip,''), isnull(w.Subtip,''), isnull(w.DataField,'')
	select @rez=@rez+@webConfigForm+@grup
	--------------------------------------------------	webConfigSTDTaburi	--------------------------------------------------
	select	@numarator=@limita, @grup='', @webConfigTaburi=''
	select	@grup=@grup+char(13)+char(13)
	select	@linie=min(
			char(13)+'union all select '''+
			isnull(w.MeniuSursa,'')+''','''+isnull(w.TipSursa,'')+''','''+isnull(w.NumeTab,'')+''','''+isnull(w.Icoana,'')+''','''+isnull(w.TipMachetaNoua,'')+''','''+isnull(w.MeniuNou,'')+''','''+isnull(w.TipNou,'')+''','''+
			isnull(w.ProcPopulare,'')+''','''+isnull(convert(varchar(10),w.Ordine),'')+''','''+isnull(convert(varchar(10),w.Vizibil),'')+''''
			--> conditia de inserare fara eroare in cazul in care configurarile exista deja:
			+(case when @faraSTD=2 then'
			where not exists (select 1 from webconfigSTDTaburi w
				where w.Meniusursa='''+convert(varchar(100),w.Meniusursa)+'''
				and w.tipsursa='''+convert(varchar(100),w.TipSursa)+'''
				and isnull(w.numetab,'''')='''+convert(varchar(100),isnull(w.NumeTab,''))+''')'
				else '' end)
		),
		@webConfigTaburi=(case when @numarator<@limita then @webConfigTaburi else @webConfigTaburi+@grup end)
		,@grup=(case when @numarator<@limita then @grup else 
					char(13)+'GO'+char(13)
					+(case when @farastd=0 then '' else 'if object_id(''tempdb..#instaleaza'') is not null'+char(13) end)
					+'insert into webconfigSTDtaburi (MeniuSursa,TipSursa,NumeTab,icoana,TipMachetaNoua,MeniuNou,TipNou,ProcPopulare,Ordine,Vizibil)'
					+char(13)+'select top 0 null,null,null,null,null,null,null,null,null,null'
				end)+@linie
		,@numarator=(case when @numarator<@limita then @numarator+1 else 0 end)
	from webConfigTaburi w inner join #meniuri m on w.meniusursa=m.meniu
		where (@vizibil is null or w.Vizibil=@vizibil)
			and (@tip is null or w.TipMachetaNoua=@tip)
		group by isnull(w.MeniuSursa,''), isnull(w.TipSursa,''), isnull(w.NumeTab,'')
	select @rez=@rez+@webConfigTaburi+@grup+(case when @farastd=0 then '' else char(10)+char(10)+char(10)+'if object_id(''tempdb..#instaleaza'') is not null drop table #instaleaza' end)
	--*/
	--/*
	select @rez=
		replace(
			replace(
				replace(@rez,'<','''+char(60)+''')
			,'>','''+char(62)+''')
		,'&','''+char(38)+''')
	--*/		
	if charindex ('<',@rez)>0 or charindex ('>',@rez)>0	--> invechit, daca nu apar alte caractere care sunt in conflict cu xml ar trebui sa fie suficiente cele trei replace-uri de mai sus
		select 'Grija mare!!! Trebuie inlocuite: "&lt;" cu "<", "&gt;" cu ">" si "&amp;" cu "&"!'

	if (@faraSTD>0)
	begin
		select @rez=replace(@rez,'webconfigstdMeniu','webconfigMeniu')
		select @rez=replace(@rez,'webconfigstdTipuri','webconfigTipuri')
		select @rez=replace(@rez,'webconfigstdGrid','webconfigGrid')
		select @rez=replace(@rez,'webconfigstdFiltre','webconfigFiltre')
		select @rez=replace(@rez,'webconfigstdForm','webconfigForm')
		select @rez=replace(@rez,'webconfigstdTaburi','webconfigTaburi')
	end

	--select @rez=replace(replace(@rez,'<','mmmmmic'),'>','mmmmmare')
	if @caleDestinatie is null select @rez for xml path('')
	else
	begin
		if @fisier is null raiserror('Nu se cunoaste denumirea fisierului (parametrul "@fisier")!',16,1)
		delete tabelXML where sesiune=@sesiune
		insert into tabelXML(sesiune, date) select @sesiune, @rez
		
		declare @cmdShellCommand varchar(3000)
		--set @cmdShellCommand = 'bcp "select replace(convert(varchar(max),date),''>'',''>''+char(10)) from ' + @database + '.dbo.tabelXML where sesiune='''+rtrim(@sesiune)+'''" queryout '+@caleform + @fisier + '.xml -c -T -r \n -S ' + convert(varchar(1000),serverproperty('ServerName'))
					--> adaugat enter-uri in xml pentru debug ca era mult prea urat intr-o singura linie
		set @cmdShellCommand = 'bcp "select convert(varchar(max),date) from ' + db_name() + '.dbo.tabelXML where sesiune='''+rtrim(@sesiune)+'''" queryout '+@caleDestinatie+@fisier + ' -c -T -r \n -S ' + convert(varchar(1000),serverproperty('ServerName'))
		exec xp_cmdshell @cmdShellCommand
		
		if @parXML is not null
		SELECT @fisier AS fisier, 'wTipFormular' AS numeProcedura
			FOR XML raw, root('Mesaje')

		delete tabelXML where sesiune=@sesiune
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wOPPopulareConfigurari '+convert(varchar(20),ERROR_LINE())+')'
end catch


if object_id('tempdb..#meniuri') is not null drop table #meniuri
	
if len(@eroare)>0 raiserror(@eroare, 16,1)
