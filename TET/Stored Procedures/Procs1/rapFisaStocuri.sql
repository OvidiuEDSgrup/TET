--***
create procedure rapFisaStocuri(@sesiune varchar(50)=null,	-->	parametrul sesiune nu va avea efect pana ce nu-l vom trimite catre ftert
	@dDataJos datetime, @dDataSus datetime,@cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cCont varchar(40),
	@TipStocuri varchar(20), @den varchar(20), @gr_cod varchar(20), 
	@tip_pret varchar(1)=0,	-->	0=stoc, 1=amanuntul, 2=pe tip gestiune, 3=vanzare
	@tiprap varchar(20),		--> = D=depozit, T=custodie, F=folosinta
	@ordonare varchar(20)=0,	--> @ordonare=1 ordonare alfabetica pe nume produs, =0 ordonare pe cod produs
	@comanda varchar(200)=null,
	@categpret int=null,
	@locatie varchar(30)=null,
	@lot varchar(2000)=null,
	@furnizor_nomenclator varchar(20)=null,
	@furnizor varchar(20)=null,
	@detalii bit=0,
	@sicoduri bit=1,
	@grupGestiuni varchar(50)=null,
	@nivel1 varchar(2)=null, @nivel2 varchar(2)=null, @nivel3 varchar(2)=null, @nivel4 varchar(2)=null
		/**	@nivel[x]:	GE = Gestiuni
						GR = Grupe
						CO = Conturi
						LO = Locatii
						CD = Cod
						CI = Cod intrare
						PR = Pret
						LM = loc de munca
						CM = comanda
						LU = luna
						DA = Data
		*/
	,@umalt varchar(200)=null	--> daca se completeaza:	se recalculeaza cantitatile, fara a afecta valorile, folosind coeficientul de conversie din nomenclator;
													-->		pentru codurile de nomenclator care nu au respectiva unitate de masura se va pune cantitate 0
	,@locmg varchar(200)=null
	,@tip_raport varchar(10)='d'	--> 'c'=centralizat, 'd'=detaliat, 'fm'=fisa magazie
	,@afispretcont bit=0
	)
as
	/*	test
	declare @dDataJos datetime, @dDataSus datetime,@cCod varchar(20), @cGestiune varchar(20), @cCodi varchar(20), @cCont varchar(40),
		@TipStocuri varchar(20), @den varchar(20), @gr_cod varchar(20), @tip_pret varchar(1), @tiprap varchar(20)
	select @dDataJos='2008-10-10', @dDataSus='2012-10-31',@cCod='122', @cGestiune=null, @cCodi=null, --@cCont='371', 
			@TipStocuri=''
		--@den='%', @gr_cod=null, 
		,@tip_pret='0'
		/*select * from tmpRefreshLuci where
	(@dDataJos='2008-1-1' and  @dDataSus='2009-10-1' and @cCod=null and  @cGestiune=null and  @cCodi=null and  @cCont=null and  @TipStocuri='M' and 
		@den='%' and  @gr_cod=null) or 1=1
		*/ -- select pentru refresh fields in Reporting, ca sa nu se incurce in tabela #stocuri
	--*/
set transaction isolation level read uncommitted
declare @eroare varchar(4000)
select @eroare=''
begin try
	--> nu are sens selectarea aceleiasi grupari de mai multe ori:
	if 1<(
	select top 1 count(1) from
	(	select @nivel1 nivel union all
		select @nivel2 nivel union all
		select @nivel3 nivel union all
		select @nivel4 nivel) n
	where nivel is not null
	group by nivel order by count(1) desc)
	raiserror('Nu este permisa selectarea aceleiasi grupari de mai multe ori!',16,1)

	if @lot is not null and @ccod is null
	begin
		raiserror('Nu este permisa filtrarea pe lot in absenta filtrului pe cod produs!',16,1)
		return
	end
	if @tip_raport is not null
	begin
		set @detalii=(case when @tip_raport in ('d','fm') then 1 else 0 end)
		if @tip_raport='fm'
		and (@ccod is null or @cgestiune is null)
			raiserror('Pentru fisa magazie este necesara completarea filtrelor "Gestiune" si "Cod"!',16,1)
	end
	if @detalii=0 and @nivel1 is null and @nivel2 is null and @nivel3 is null and @nivel4 is null
		return
	declare @q_dDataJos datetime, @q_dDataSus datetime,@q_cCod varchar(20), @q_cGestiune varchar(20), @q_cCodi varchar(20), @q_cCont varchar(40),
		@q_TipStocuri varchar(20), @q_den varchar(20), @q_gr_cod varchar(20), @q_tip_pret varchar(1), @q_tiprap varchar(1),
		@s_dDataJos varchar(20), @s_dDataSus varchar(20),
		@precizie_pret varchar(2)	--> cate zecimale sa aiba pretul afisat
	select @q_dDataJos=@dDataJos, @q_dDataSus=@dDataSus, @q_cCod=@cCod, @q_cGestiune=@cGestiune, @q_cCodi=@cCodi, @q_cCont=@cCont,
		@q_TipStocuri=@TipStocuri, @q_den=@den,
		@q_gr_cod=@gr_cod+(case when isnull((select val_logica from par where tip_parametru='GE' and parametru='GRUPANIV'),0)=0 then '' else '%' end),
		@q_tip_pret=@tip_pret, @q_tiprap=@tiprap,
		@comanda=isnull(@comanda,''),
		@s_dDataJos=''''+convert(varchar(20),@dDataJos,102)+'''', @s_dDataSus=''''+convert(varchar(20),@dDataSus,102)+'''',
		@precizie_pret='5'
	if @furnizor is null
		select @furnizor=@furnizor_nomenclator

		if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri
		if object_id('tempdb.dbo.#gestiuni') is not null drop table #gestiuni
		if object_id('tempdb.dbo.#preturi') is not null drop table #preturi
		if object_id('tempdb.dbo.#stocuri_grupat') is not null drop table #stocuri_grupat
		if object_id('tempdb..#fluni') is not null drop table #fluni
	--> variabile ajutatoare pt sql dinamic:
	declare @s_cCod varchar(200), @s_cGestiune varchar(200),
			@s_umalt varchar(200),
			@s_cCodi varchar(200),
			@s_gr_cod varchar(200),
			@s_tiprap varchar(200),
			@s_cCont varchar(200),
			@s_locatie varchar(200),
			@s_comanda varchar(200),
			@s_lot varchar(2000),
			@s_categPret varchar(200),
			@s_nivel1 varchar(200),
			@s_nivel2 varchar(200),
			@s_nivel3 varchar(200),
			@s_nivel4 varchar(200),
			@s_grupGestiuni varchar(200),
			@setare_reguli_nivel nvarchar(max),
			@expr_pret varchar(max)
			
	--> corelare campuri cu grupari pe nivele, dupa o regula specificata intr-un singur loc in codul procedurii:
	select @setare_reguli_nivel='set @s_nivel=(case @nivel when ''GE'' then ''gestiune''
									when ''GR'' then ''grupa''
									when ''CO'' then ''cont''
									when ''LO'' then ''locatie''
									when ''CD'' then ''cod''
									when ''CI'' then ''cod_intrare''
									when ''PR'' then ''pretRaport''
									when ''LT'' then ''lot''
									when ''UM'' then ''um''
									when ''UI'' then ''um''
									when ''LM'' then ''loc_de_munca''
									when ''CM'' then ''comanda''
									when ''LU'' then ''convert(varchar(20),month(data))+'''' ''''+convert(varchar(20),year(data))''
									when ''DA'' then ''convert(varchar(20),data,102)''
								else ''null'' end)'

	exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel1, @s_nivel=@s_nivel1 output
	exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel2, @s_nivel=@s_nivel2 output
	exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel3, @s_nivel=@s_nivel3 output
	exec sp_executesql @setare_reguli_nivel,N'@s_nivel nvarchar(200) output, @nivel nvarchar(200)', @nivel=@nivel4, @s_nivel=@s_nivel4 output

	declare @identificare_grupari nvarchar(max),
			@grGestiuni varchar(1),
			@grGrupe varchar(1),
			@grConturi varchar(1),
			@grLocatii varchar(1),
			@grCod varchar(1),
			@grCodIntrare varchar(1),
			@grPret varchar(1),
			@grLot varchar(1),
			@grUM varchar(1),
			@grUMIntrare varchar(1),
			@grLocm varchar(1),
			@grComanda varchar(1),
			@grLuna varchar(1),
			@grData varchar(1)
	-->	identificare date cerute (indiferent de ordinea gruparilor)
	select @identificare_grupari='
	select @tipgr=(case @cod when '''+isnull(@nivel1,'')+''' then ''1''
						when '''+isnull(@nivel2,'')+''' then ''2''
						when '''+isnull(@nivel3,'')+''' then ''3''
						when '''+isnull(@nivel4,'')+''' then ''4'' else null end)'

	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GE', @tipgr=@grGestiuni output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='GR', @tipgr=@grGrupe output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CO', @tipgr=@grConturi output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LO', @tipgr=@grLocatii output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CD', @tipgr=@grCod output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CI', @tipgr=@grCodIntrare output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='PR', @tipgr=@grPret output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LT', @tipgr=@grLot output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='UM', @tipgr=@grUM output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='UI', @tipgr=@grUMIntrare output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LM', @tipgr=@grLocm output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='CM', @tipgr=@grComanda output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='LU', @tipgr=@grLuna output
	exec sp_executesql @identificare_grupari,N'@tipgr nvarchar(20) output, @cod nvarchar(20)', @cod='DA', @tipgr=@grData output

	--> formez variabile string de filtrre, pentru simplificarea codului de sql dinamic si evitarea repetitiilor (vezi utilizarea @expr_pret):
			
	select	@s_cCod=(case when @q_cCod is null then 'null' else ''''+@q_cCod+'''' end),
			@s_umalt=''''+rtrim(@umalt)+'''',
			@s_cGestiune=(case when @q_cGestiune is null then 'null' else ''''+@q_cGestiune+'''' end),
			@s_cCodi=(case when @q_cCodi is null then 'null' else ''''+@q_cCodi+'''' end),
			@s_gr_cod=(case when @q_gr_cod is null then 'null' else ''''+@q_gr_cod+'''' end),
			@s_tiprap=(case when @q_tiprap is null then 'null' else ''''+@q_tiprap+'''' end),
			@s_cCont=(case when @q_cCont is null then 'null' else ''''+@q_cCont+'''' end),
			@s_locatie=(case when @locatie is null then 'null' else ''''+@locatie+'''' end),
			@s_comanda=(case when @comanda is null then 'null' else ''''+@comanda+'''' end),
			@s_lot=(case when @lot is null then '''''' else ''''+@lot+'''' end),
			@s_categPret=(case when @categPret is null then 'null' else ''''+convert(varchar(200),@categPret)+'''' end),
			@s_grupGestiuni=(case when @grupGestiuni is null then '''''' else ''''+@grupGestiuni+'''' end),
			@expr_pret=(case when @q_tip_pret='0' then 'r.pret' when @q_tip_pret='2' then 'case when g.Tip_gestiune=''A'' then r.pret_cu_amanuntul else 0 end'
				when @q_tip_pret='1' then 'r.pret_cu_amanuntul' when @q_tip_pret='2' then 'case when g.Tip_gestiune=''A'' then r.pret_cu_amanuntul else 0 end'
				else '0' end)	--> aici ramane asa? (pentru tip pret<>0 se iau preturi cu wIaPreturi, dar in exclusivitate (daca in exclusivitate ramane doar r.pret din toata expresia)?

	declare @comanda_str varchar(max),	--> insiruirea de instructiuni sql pt generarea raportului
			@com1 varchar(max)			--> instructiuni temporare (care urmeaza a se adauga la @comanda)

	--> se culeg datele de baza, cu gruparile formate in functie de ce s-a cerut:
	
	--dbo.fStocuri('+@s_dDataJos+','+@s_dDataSus+','+@s_cCod+','+@s_cGestiune+','+@s_cCodi+','+@s_gr_cod+','+@s_tiprap+','+@s_cCont+', 0, '+@s_locatie+', '''', '+@s_comanda+', '''', '''', '+@s_lot+', '+'@s_parXML'+') r
	select @comanda_str='
		if object_id(''tempdb.dbo.#stocuri'') is not null drop table #stocuri
		if object_id(''tempdb.dbo.#preturi'') is not null drop table #preturi
		
		declare @cSub varchar(20)
		select @cSub=val_alfanumerica from par where Tip_parametru="GE" and Parametru="SUBPRO"

		create table #stocuri(cont varchar(40), cod varchar(20), cod_intrare varchar(50), gestiune varchar(20), tert varchar(20),
			tip_document varchar(2), numar_document varchar(20), data datetime, stoci decimal(20,6), v_stoci decimal(20,6), intrari decimal(20,6), v_intrari decimal(20,6),
			iesiri decimal(20,6), v_iesiri decimal(20,6), DenGest varchar(500),
			loc_de_munca varchar(20), predator varchar(200), pretRaport varchar(200), comanda varchar(50), locatie varchar(20), tip_gestiune varchar(20),
			denumire_locatie varchar(500), valoare decimal(20,6), grupa varchar(200), grNivel1 varchar(200), grNivel2 varchar(200), grNivel3 varchar(200),
			grNivel4 varchar(200), gestiuneCustodie bit, lot varchar(2000), um varchar(100), pret varchar(200) default "0")
		
		if object_id(''tempdb.dbo.#stocuri_grupat'') is null
		create table #stocuri_grupat(
			stoci decimal(20,6), v_stoci decimal(20,6), intrari decimal(20,6), v_intrari decimal(20,6), iesiri decimal(20,6), v_iesiri decimal(20,6),
			grNivel1 varchar(200), grNivel2 varchar(200), grNivel3 varchar(200), grNivel4 varchar(200),
			numeNivel1 varchar(2000), numeNivel2 varchar(2000), numeNivel3 varchar(2000), numeNivel4 varchar(2000),
			tert varchar(20), tip_document varchar(20), numar_document varchar(20), data datetime, nume_tert varchar(2000),
			gestiuneCustodie bit, ordnivel1 varchar(2000), ordnivel2 varchar(2000), ordnivel3 varchar(2000), ordnivel4 varchar(2000), ordnivel5 varchar(2000),
			tipnivel1 varchar(2000), tipnivel2 varchar(2000), tipnivel3 varchar(2000), tipnivel4 varchar(2000), predator varchar(2000),
			detalii1 varchar(200) default '''', detalii2 varchar(200) default '''')
		
			declare @p xml
			select @p=(select '+@s_dDataJos+' dDataJos, '+@s_dDataSus+' dDataSus, '+@s_cCod+' cCod, '+@s_cGestiune+' cGestiune, '+@s_cCodi+' cCodi
							,'+@s_gr_cod+' cGrupa, '+@s_tiprap+' TipStoc, '+@s_cCont+' cCont, 0 Corelatii, '+@s_locatie+' Locatie
							,'+@s_comanda+' Comanda, "'+isnull(@furnizor,'')+'" Furnizor, '+@s_lot+' Lot, '+@s_grupGestiuni+' grupGestiuni
				,"'+isnull(@sesiune,'')+'" sesiune
			for xml raw)


				if object_id(''tempdb..#docstoc'') is not null drop table #docstoc
					create table #docstoc(subunitate varchar(9))
					exec pStocuri_tabela
				 
				exec pstoc @sesiune="", @parxml=@p
				alter table #docstoc add um varchar(100)
			
	'	--> completare cu unitate de masura: daca este, din pozdoc.detalii.@um_um, altfel din nomenclator
			--> deocamdata join cu pozdoc, pana ce pstocuri va aduce um; cel putin ar fi fain sa aduca idpozdoc, sa fie join-ul mai succint
	+	(case when @grUM is not null then '
			update d set um=p.detalii.value("(row/@um_um)[1]","varchar(100)")
					,d.pret_cu_amanuntul=(d.pret_cu_amanuntul*d.cantitate)/(p.detalii.value("(row/@cantitate_um)[1]","decimal(20,6)"))
					,d.pret=(d.pret*d.cantitate)/p.detalii.value("(row/@cantitate_um)[1]","decimal(20,6)")
					,d.cantitate=p.detalii.value("(row/@cantitate_um)[1]","decimal(20,6)")
				from #docstoc d inner join pozdoc p on d.subunitate=p.subunitate and d.tip_document=p.tip and d.data=p.data and d.numar_document=p.numar
					and d.numar_pozitie=p.numar_pozitie
				where p.detalii is not null
					and isnull(p.detalii.value("(row/@um_um)[1]","varchar(100)"),"")<>""
					and isnull(p.detalii.value("(row/@cantitate_um)[1]","decimal(20,6)"),0)<>0
			' else '' end) +
	-->	pe pozitiile care nu au UM dupa primul update, cautam UM pe pozitia de intrare si convertim cantitatea si pretul la acel UM.
	+	(case when @grUMIntrare is not null then '
			update d set um=p.detalii.value("(row/@um_um)[1]","varchar(100)")
					,d.pret_cu_amanuntul=(d.pret_cu_amanuntul*ump.coeficient)
					,d.pret=(d.pret*ump.coeficient)
					,d.cantitate=d.cantitate/ump.coeficient
				from #docstoc d inner join pozdoc p on d.idIntrareFirma=p.idPozdoc left join UMProdus ump on ump.cod=d.cod and ump.UM=p.detalii.value("(row/@um_um)[1]","varchar(100)")
				where p.detalii is not null and d.um is null
					and isnull(p.detalii.value("(row/@um_um)[1]","varchar(100)"),"")<>""
					and isnull(p.detalii.value("(row/@cantitate_um)[1]","decimal(20,6)"),0)<>0
			' else '' end) +
	-->	In final completam um=UM nomenclator.
	+	(case when @grUM is not null or @grUMIntrare is not null then '
			update d set um=n.um
				from #docstoc d
					inner join nomencl n on d.cod=n.cod
				where d.um is null
			' else '' end) +
	'
	select g.subunitate, g.cod_gestiune, g.denumire_gestiune, g.tip_gestiune, ISNULL(g.detalii.value(''(/*/@custodie)[1]'',''int''),0) as custodie into #gestiuni
	from gestiuni g
	'+(case when @locmg is null then '' else 'where g.detalii.value(''(/row/@lm)[1]'',''varchar(200)'') like '''+@locmg+'%''' end)+
	'
	insert into #stocuri(cont, cod, cod_intrare, gestiune, tert, tip_document, numar_document, data, stoci, v_stoci, intrari, v_intrari,
		iesiri, v_iesiri, DenGest, loc_de_munca, predator, pretRaport, comanda, locatie, tip_gestiune, valoare, grupa, grNivel1,
		grNivel2, grNivel3, grNivel4, gestiuneCustodie, lot, um)
	select max(r.cont),max(r.cod),max(r.cod_intrare),max(r.gestiune),
		max(case when data<'+@s_dDataJos+' then '''' else r.tert end) as tert, 
		max(case when data<'+@s_dDataJos+' then ''SI'' else r.tip_document end) as tip_document,
		max(case when data<'+@s_dDataJos+' then '''' else r.numar_document end) as numar_document,
		max(case when data<'+@s_dDataJos+' then '+@s_dDataJos+' else r.data end) as data,
		sum((case when in_out=1 then 1
				when (in_out=2 and data<'+@s_dDataJos+') then 1
				when (in_out=3 and data<'+@s_dDataJos+') then -1
				else 0 end)*r.cantitate) as stoci,
		sum((case when in_out=1 then 1
				when (in_out=2 and data<'+@s_dDataJos+') then 1
				when (in_out=3 and data<'+@s_dDataJos+') then -1
				else 0 end)*r.cantitate*'+@expr_pret+') as v_stoci,
		sum((case when in_out=2 and r.data between '+@s_dDataJos+' and '+@s_dDataSus+' then r.cantitate else 0 end)) as intrari,
		sum((case when in_out=2 and r.data between '+@s_dDataJos+' and '+@s_dDataSus+' then r.cantitate*'+@expr_pret+' else 0 end)) as v_intrari,
		sum((case when in_out=3 and r.data between '+@s_dDataJos+' and '+@s_dDataSus+' then r.cantitate else 0 end)) as iesiri,
		sum((case when in_out=3 and r.data between '+@s_dDataJos+' and '+@s_dDataSus+' then r.cantitate*'+@expr_pret+' else 0 end)) as v_iesiri,
		max(g.denumire_gestiune) as DenGest,'+(case when @q_tiprap='F' or @grLocm is not null then 'max(r.loc_de_munca)' else '''''' end)+' as loc_de_munca
		, max(rtrim(case when r.tip_document in(''TE'',''TI'',''DF'',''CM'') then r.predator 
			when data<'+@s_dDataJos+' then '''' 
			else ISNULL(t.denumire,r.tert) end)) predator,
		'+@expr_pret+' as pretRaport,
		max(rtrim(r.comanda)) comanda, max(r.locatie), max(g.tip_gestiune) tip_gestiune,
		(abs(sum((case when in_out=1 then 1
				when (in_out=2 and data<'+@s_dDataJos+') then 1
				when (in_out=3 and data<'+@s_dDataJos+') then -1
				else 0 end)*r.cantitate*'+@expr_pret+'))
			 +abs(sum(case when in_out=2 and r.data between '+@s_dDataJos+' and '+@s_dDataSus+' then r.cantitate*'+@expr_pret+' else 0 end))
			 +abs(sum(case when in_out=3 and r.data between '+@s_dDataJos+' and '+@s_dDataSus+' then r.cantitate*'+@expr_pret+' else 0 end))
			),'+(case when 'GR' in (@nivel1,@nivel2,@nivel3,@nivel4) then 'n.tip+''|''+n.grupa' else '''''' end)+'
			,'''','''','''','''','+
				(case when @grLocatii is not null then 'max(g.custodie)' else '0' end)+',
			max(r.lot) lot, max(r.um)
	from #docstoc r
		left join terti t on r.tert=t.tert and r.subunitate=t.Subunitate
			'+(case when @locmg is null then 'left outer' else 'inner' end)+	--> filtrarea trebuie sa fie stricta pe gestiuni daca filtrul de loc de munca al gestiunii e completat
			' join #gestiuni g on  r.subunitate=g.subunitate and r.gestiune=g.cod_gestiune
		'+(case when @grGrupe is not null then 'left join nomencl n on r.cod=n.cod' else '' end)+'
	where ('+
		(case @q_TipStocuri when 'M' then 'left(r.cont,3) not in (''345'',''354'',''371'',''357'')'
							when 'P' then 'left(r.cont,3) in (''345'',''354'')'
							when 'A' then 'left(r.cont,3) in (''371'',''357'')'
			else '1=1' end)+
	--	'@q_TipStocuri='''' or @q_TipStocuri=''M'' and left(r.cont,3) not in (''345'',''354'',''371'',''357'')
	--	or @q_TipStocuri=''P'' and left(r.cont,3) in (''345'',''354'') or @q_TipStocuri=''A'' and left(r.cont,3) in (''371'',''357'')'+
		')
	group by r.subunitate'+
		(case when @grConturi is not null then ',r.cont' else '' end)+
		(case when @grCod is not null or @tip_pret>0 then ',r.cod' else '' end)+
		(case when @grCodIntrare is not null then ',r.cod_intrare' else '' end)+
		(case when @grGestiuni is not null then ',r.gestiune' else '' end)+
		(case when @grGrupe is not null then ',n.tip+''|''+n.grupa' else '' end)+
		(case when @grPret is not null then ',r.pret,r.pret_cu_amanuntul' else '' end)+
		(case when @grLocatii is not null then ',r.locatie' else '' end)+
		(case when @grLot is not null then ',r.lot' else '' end)+
		(case when @grUM is not null or @grUMIntrare is not null then ',r.um' else '' end)+
		(case when @grLocm is not null then ',r.loc_de_munca' else '' end)+
		(case when @grComanda is not null then ',r.comanda' else '' end)+
		(case when @grLuna is not null then ',month(r.data),year(r.data)' else '' end)+
		(case when @detalii=1 then '
			,(case when data<'+@s_dDataJos+' then ''SI'' else r.tip_document end)
			,(case when data<'+@s_dDataJos+' then '''' else r.numar_document end)
			,(case when data<'+@s_dDataJos+' then '+@s_dDataJos+' else r.data end)
			,(case when data<'+@s_dDataJos+' then '''' else r.tert end)' else '' end)
		+(case when @q_tiprap='F' then ', r.loc_de_munca' else '' end)
		+(case when @q_tip_pret<3 then ','+@expr_pret else '' end)+'
	having
		(
									abs(sum((case when in_out=1 then 1
									when (in_out=2 and data<'+@s_dDataJos+') then 1
									when (in_out=3 and data<'+@s_dDataJos+') then -1
									else 0 end)*r.cantitate))>0.0009
		or
		 abs(sum((case when in_out=2 and data between '+@s_dDataJos+' and '+@s_dDataSus+' then r.cantitate else 0 end)))>0.0009
		or
		abs(sum((case when in_out=3 and r.data between '+@s_dDataJos+' and '+@s_dDataSus+' then cantitate else 0 end)))>0.0009
		)
		
		if object_id(''tempdb.dbo.#docstoc'') is not null drop table #docstoc
	'
	--> se completeaza cu lucruri auxiliare: pret din categorii preturi, denumiri gestiuni pentru custodie, denumiri locatii:
	if (@tip_pret>2)
	--(@tip_pret<10)
	select @comanda_str=@comanda_str+
	'
		create table #preturi(cod varchar(20),nestlevel int)
		insert into #preturi
		select s.cod, @@NESTLEVEL
		from #stocuri s
		group by s.cod

		exec CreazaDiezPreturi

			declare @px xml
			select @px=(select '+@s_categPret+' as categoriePret, '+@s_dDataSus+' as data,'+@s_cGestiune+' as gestiune for xml raw)
			exec wIaPreturi @sesiune='+isnull(''''+@sesiune+'''','null')+',@parXML=@px
			update #stocuri set pretRaport=pr.pret_vanzare
				from #stocuri c inner join #preturi pr on pr.Cod=c.cod
						-- where pr.pretRaport is not null
	-->	recalculare valori dupa inlocuirea pretului:
			update #stocuri set v_stoci=stoci*pretRaport, v_intrari=intrari*pretRaport, v_iesiri=iesiri*pretRaport, pret=pretRaport
	'
	else select @comanda_str=@comanda_str+'update s set pretRaport=(case when (abs(s.stoci)+abs(s.intrari)+abs(s.iesiri))=0 then 0 else s.valoare/(abs(s.stoci)+abs(s.intrari)+abs(s.iesiri)) end)
		from #stocuri s
	'
	select @comanda_str=@comanda_str+'
		update s set pret=convert(varchar(100),convert(float,pretRaport)),
			pretRaport=
		convert(varchar(20),convert(money,floor(convert(decimal(20,3),pretRaport)*100)/100),102)					--> formatare pret la patru zecimale (2 de la money
			+substring(convert(varchar(20),round(pretRaport,'+@precizie_pret+')),charindex(''.'',convert(varchar(20),pretRaport))+3,'+@precizie_pret+'-1)		-->  + inca 2 luate separat)
			+replicate(''0'','+@precizie_pret+'-len(substring(convert(varchar(20),round(pretRaport,'+@precizie_pret+')),charindex(''.'',convert(varchar(20),pretRaport))+3,'+@precizie_pret+'-1))-2)
		from #stocuri s
		
		update s set pretRaport=left(pretRaport,charindex(''.'',pretRaport)-1)
			+''.''
			+substring(pretRaport,charindex(''.'',pretRaport)+1,10)
		 from #stocuri s

		update s set grnivel1=rtrim('+@s_nivel1+'),
					grnivel2=rtrim('+@s_nivel2+'),
					grnivel3=rtrim('+@s_nivel3+'),
					grnivel4=rtrim('+@s_nivel4+')
		from #stocuri s'

		--> unitate de masura alternativa cu alterarea cantitatilor, daca este cazul:
	if @umalt is not null
	select @comanda_str=@comanda_str+'
		update s set
				s.stoci=(case when isnull(u.coeficient,0)=0 then 0 else s.stoci/isnull(u.coeficient,0) end),
				s.intrari=(case when isnull(u.coeficient,0)=0 then 0 else s.intrari/isnull(u.coeficient,0) end),
				s.iesiri=(case when isnull(u.coeficient,0)=0 then 0 else s.iesiri/isnull(u.coeficient,0) end)
			from #stocuri s --inner join nomencl n 
				left join UMProdus u on u.cod=s.cod and u.um='+@s_umalt+'
	'
	select @comanda_str=@comanda_str+'
	if exists(select * from sysobjects where name like "rapFisaStocuriSP" and type="P")
	begin
		declare @parXML xml -- se va construi cu ce trebuie 
		exec rapFisaStocuriSP @sesiune="'+isnull(@sesiune,'')+'", @parXML=@parXML -- procedura de modificare #stocuri, de ex. completare preturi pt. custodii 
	end'
	
		--> grupare finala pentru raport:
	select @comanda_str=@comanda_str+'
		insert into #stocuri_grupat(stoci, v_stoci, intrari, v_intrari, iesiri, v_iesiri,
			grNivel1, grNivel2, grNivel3, grNivel4,
			numeNivel1, numeNivel2, numeNivel3, numeNivel4,
			tert, tip_document, numar_document, data, nume_tert, gestiuneCustodie,
			ordnivel1, ordnivel2, ordnivel3, ordnivel4, ordnivel5,
			tipnivel1, tipnivel2, tipnivel3, tipnivel4, predator, detalii1, detalii2)
		select sum(isnull(stoci,0)), sum(isnull(v_stoci,0)), sum(isnull(intrari,0)), sum(isnull(v_intrari,0)), sum(isnull(iesiri,0)), sum(isnull(v_iesiri,0)),
			grNivel1, grNivel2, grNivel3, grNivel4,
			"", "", "", "",'+
		--	@numeNivel1+','+@numeNivel2+','+@numeNivel3+','+@numeNivel4+',
			'rtrim(isnull(max(s.tert),"")), max(s.tip_document), rtrim(max(s.numar_document)), max(s.data),"",gestiuneCustodie,
			convert(varchar(20),len(grnivel1)), convert(varchar(20),len(grnivel2)), convert(varchar(20),len(grnivel3)), convert(varchar(20),len(grnivel4)), "",
			"'+isnull(@nivel1,'')+'", "'+isnull(@nivel2,'')+'", "'+isnull(@nivel3,'')+'", "'+isnull(@nivel4,'')+'"
			,max(predator),
			'+(case when @afispretcont=1 then 'max(pret), max(cont)' else '"",""' end)+'
		from #stocuri s	'	--+@listaTabele
		+char(10)+'group by grNivel1, grNivel2, grNivel3, grNivel4'+
		(case when @detalii=1 then ',s.tert,s.tip_document,s.numar_document,s.data' else '' end)+', gestiuneCustodie'
	
	--/*	--> se culeg denumirile:
	if @detalii=1 select @comanda_str=@comanda_str+'
		update s set nume_tert=rtrim(isnull(t.denumire,'''')) from #stocuri_grupat s left join terti t on t.subunitate=1 and t.tert=s.tert'
	if @grGestiuni is not null
	begin
		if @q_tiprap='D'
		select @comanda_str=@comanda_str+'
			update s set numeNivel'+@grGestiuni+'=rtrim(isnull(c.denumire_gestiune,'''')) from #stocuri_grupat s left join #gestiuni c on c.subunitate=''1'' and s.grNivel'+@grGestiuni+'=c.cod_gestiune'
		if @q_tiprap='T'
		select @comanda_str=@comanda_str+'
			update s set numeNivel'+@grGestiuni+'=rtrim(isnull(c.denumire,'''')) 
			from #stocuri_grupat s left join terti c on c.subunitate=''1'' and s.grNivel'+@grGestiuni+'=c.tert'
		if @q_tiprap='F'
		select @comanda_str=@comanda_str+'
			update s set numeNivel'+@grGestiuni+'=rtrim(isnull(c.nume,'''')) 
			from #stocuri_grupat s left join personal c on s.grNivel'+@grGestiuni+' = c.marca'
	end
	if @grGrupe is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grGrupe+'=rtrim(isnull(c.denumire,'''')) from #stocuri_grupat s left join grupe c on s.grNivel'+@grGrupe+'=c.tip_de_nomenclator+''|''+c.grupa'
	if @grConturi is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grConturi+'=rtrim(isnull(c.denumire_cont,'''')) from #stocuri_grupat s left join conturi c on s.grNivel'+@grConturi+'=c.cont'
	if @grLocatii is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grLocatii+'=rtrim(isnull(c.Descriere,'''')) from #stocuri_grupat s left join locatii c on s.grNivel'+@grLocatii+'=c.Cod_locatie and s.gestiuneCustodie=0
		
		update s set numeNivel'+@grLocatii+'=rtrim(t.denumire)+ ISNULL(''/''+RTRIM(it.Descriere),'''')
		from #stocuri_grupat s,	terti t
			left join infotert it
				on it.subunitate=t.Subunitate and it.tert=t.tert and
					it.identificator<>''''
		where rtrim(t.tert)+REPLICATE('' '',13-LEN(rtrim(t.tert)))+ISNULL(rtrim(it.identificator),'''')=s.grNivel'+@grLocatii+'
		'

--> completez denumirile gruparilor (datorita sql dinamic evitam case-urile):
	--> care sunt identice cu codurile de grupare:
	if @grCodIntrare is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grCodIntrare+'=rtrim(s.grNivel'+@grCodIntrare+') from #stocuri_grupat s'
	if @grPret is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grPret+'=rtrim(s.grNivel'+@grPret+') from #stocuri_grupat s'
	if @grData is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grData+'=convert(varchar(20),data,103) from #stocuri_grupat s'
	if @grLot is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grLot+'=rtrim(s.grNivel'+@grLot+') from #stocuri_grupat s'
		
	--> care au denumiri luate din alte tabele:
	if @grCod is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grCod+'=rtrim(isnull(c.denumire,''''))+'' (''+'+(case when @umalt is null then 'rtrim(c.um)' else 'rtrim(isnull(u.um,''!!!''))' end)+'+'')'' from #stocuri_grupat s
			left join nomencl c on s.grNivel'+@grCod+'=c.cod
			'+(case when @umalt is not null then 'left join UMProdus u on u.cod=c.cod and u.um='+@s_umalt else '' end)
	if @grUM is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grUM+'=rtrim(isnull(u.denumire,s.grNivel'+@grUM+')) from #stocuri_grupat s inner join um u on u.um=s.grNivel'+@grUM
	if @grComanda  is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grComanda+'=rtrim(isnull(n.descriere,"")) from #stocuri_grupat s inner join comenzi n on n.subunitate=@cSub and n.comanda=grnivel'+@grComanda
	if @grLocm is not null select @comanda_str=@comanda_str+'
		update s set numeNivel'+@grLocm+'=rtrim(isnull(l.denumire,s.grNivel'+@grLocm+')) from #stocuri_grupat s inner join lm l on l.cod=s.grNivel'+@grLocm
	if @grLuna is not null select @comanda_str=@comanda_str+'
		select max(lunaalfa) lunaalfa, luna into #fluni from fcalendar("2010-1-1","2010-12-1") group by luna
		update s set numeNivel'+@grLuna+'=rtrim(isnull(f.lunaalfa,""))+" "+convert(varchar(20),year(s.data))
		,grnivel'+@grLuna+'=convert(varchar(20),year(s.data))+" "+(case when month(s.data)<10 then " "+convert(varchar(1),month(s.data)) else convert(varchar(2),month(s.data)) end)
		from #stocuri_grupat s inner join #fluni f on f.luna=month(s.data)'
		
	--> se stabileste ordonarea datelor:
	declare @reguliOrdonare varchar(max)	--> se impun aceleasi reguli de ordonare la toate 4 gruparile, deci se scrie o singura data:
	select @reguliOrdonare='ordnivel[1]=(case when tipnivel[1]=''PR'' then convert(varchar(20),replicate('' '',10-len(ordnivel[1])))+ordnivel[1]+''|''
											when tipnivel[1]<>''CD'' then grnivel[1] else '''' end)+'+(case when @ordonare=1	then 'numeNivel[1]' else 'grnivel[1]' end)+',
'
	select @comanda_str=@comanda_str+'
		update s set	'+replace(@reguliOrdonare,'[1]','1')+replace(@reguliOrdonare,'[1]','2')+replace(@reguliOrdonare,'[1]','3')+replace(@reguliOrdonare,'[1]','4')+'
						ordnivel5='+/*(case when @ordonare=1	then 's.tip_document+''|''+s.numar_document+''|''+convert(varchar(20),s.data,102)'
															else */'convert(varchar(20),s.data,102)+''|''+s.tip_document+''|''+s.numar_document+''|'''-- end)
															+'
		from #stocuri_grupat s
	'
	--> daca e nevoie de afisarea codurilor se adauga la denumiri:
	if @sicoduri=1
	begin
		select @com1=''
		select	@com1=@com1+(case when @s_nivel1 in ('pretRaport','cod_intrare','lot') then '' else 's.numeNivel1=grnivel1+'' - ''+numeNivel1,' end),
				@com1=@com1+(case when @s_nivel2 in ('pretRaport','cod_intrare','lot') then '' else 's.numeNivel2=grnivel2+'' - ''+numeNivel2,' end),
				@com1=@com1+(case when @s_nivel3 in ('pretRaport','cod_intrare','lot') then '' else 's.numeNivel3=grnivel3+'' - ''+numeNivel3,' end),
				@com1=@com1+(case when @s_nivel4 in ('pretRaport','cod_intrare','lot') then '' else 's.numeNivel4=grnivel4+'' - ''+numeNivel4,' end)
		--select @com1=left(@com1,len(@com1)-1)

		set @comanda_str=@comanda_str+'
			update s set '+@com1+'
						 s.nume_tert=s.tert+'' - ''+s.nume_tert
			from #stocuri_grupat s'
	end

	--> reordonare grupari (stilul folosit la acest raport - cu totalizari efectuate dupa aducerea datelor din sql - impune aceasta operatie)
	select @com1=''
	if @s_nivel2='null' set @com1=@com1+char(10)+'update #stocuri_grupat set grnivel2=grnivel1, numenivel2=numenivel1, grnivel1=null, numenivel1=null, tipnivel2=tipnivel1, tipnivel1=null'
	if @s_nivel3='null' set @com1=@com1+char(10)+'update #stocuri_grupat set grnivel3=grnivel2, numenivel3=numenivel2, grnivel2=grnivel1, numenivel2=numenivel1, grnivel1=null, numenivel1=null,
											tipnivel3=tipnivel2, tipnivel2=tipnivel1, tipnivel1=null'
	if @s_nivel4='null' set @com1=@com1+char(10)+'update #stocuri_grupat set grnivel4=grnivel3, numenivel4=numenivel3, grnivel3=grnivel2, numenivel3=numenivel2, grnivel2=grnivel1, numenivel2=numenivel1,
											grnivel1=null, numenivel1=null, tipnivel4=tipnivel3, tipnivel3=tipnivel2, tipnivel2=tipnivel1, tipnivel1=null'

	--> select final:
	select @comanda_str=@comanda_str+@com1+'
	select stoci, v_stoci, intrari, v_intrari, iesiri, v_iesiri,
			grNivel1, grNivel2, grNivel3, grNivel4,
			numeNivel1, numeNivel2, numeNivel3, numeNivel4,
			tert, tip_document, numar_document, data, nume_tert,
			tipnivel1, tipnivel2, tipnivel3, tipnivel4,
			ordnivel1, ordnivel2, ordnivel3, ordnivel4, ordnivel5, predator, detalii1, detalii2
	from #stocuri_grupat order by ordnivel1, ordnivel2, ordnivel3, ordnivel4, data, (case when stoci<>0 then 0 when intrari<>0 then 1 else 2 end)
	--*/--*/--*/--*/--*/--*/
	'
	select @comanda_str=replace(@comanda_str,'"','''')
	exec (@comanda_str)
end try
begin catch
	select @eroare='Eroare: '+error_message()+' (rapFisaStocuri)'
end catch

if object_id('tempdb.dbo.#stocuri') is not null drop table #stocuri
--if object_id('tempdb.dbo.#de_cumulatstoc') is not null drop table #de_cumulatstoc
if object_id('tempdb.dbo.#gestiuni') is not null drop table #gestiuni
if object_id('tempdb.dbo.#preturi') is not null drop table #preturi
if object_id('tempdb.dbo.#stocuri_grupat') is not null drop table #stocuri_grupat
if object_id('tempdb..#fluni') is not null drop table #fluni

if len(@eroare)>0
begin
	select 0 stoci, 0 v_stoci, 0 intrari, 0 v_intrari, 0 iesiri, 0 v_iesiri,
			'<Eroare!>' grNivel1, '' grNivel2, '' grNivel3, '' grNivel4,
			@eroare numeNivel1, '' numeNivel2, '' numeNivel3, '' numeNivel4,
			'' tert, '' tip_document, '' numar_document, '' data, '' nume_tert
	select @comanda_str for xml path('')
end
