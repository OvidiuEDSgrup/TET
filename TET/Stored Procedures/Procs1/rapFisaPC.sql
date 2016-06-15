--***
create procedure rapFisaPC (@pLM varchar(20)='', @pCom varchar(20)='', @pCentru varchar(20)=null, @pNivelMax int, @pDetalDOC varchar(20),
	 @pDinf datetime, @pDsup datetime, @PeConturi int=0, @PeLuni int=0,  @art_calc_multiplu varchar(100) = NULL,
	 @art_calc_nedet varchar(100) = null,@art_calc_excep varchar(100) = null, @siCoduri bit=0, @detaliat bit=1, @faraNivel int=-1)
as
declare @eroare varchar(max)
select @eroare=''
begin try
	if @peconturi=1
		set @detaliat=0
--	select @faraNivel=1
declare @pNivel int, @pCantPond int, @pArtSup varchar(100), @pExceptArtSup varchar(100),
	@pExcArtNeincl varchar(100), @pArtInf varchar(100), @pSub varchar(20), @pGrCom nvarchar(4000),
	@pComenziNedet nvarchar(4000), @pArtCalcNedet nvarchar(4000), @pNrOrd nvarchar(1)
select @pNivel=0, @pCantPond=1, @pArtSup=N'', @pExceptArtSup=N'*', @pExcArtNeincl=N'',
	@pArtInf=N'', @pSub=N'1', @pGrCom=N'', @pComenziNedet=N'', @pArtCalcNedet=N'', @pNrOrd=N'0'

declare @Sb char(9), @fltLocMunca char(9), @fltCentru char(6), @fltComanda char(20), @tipComanda char(1), 
	@q_pLM varchar(100),@q_pCom varchar(100),@q_pNivelMax int,@q_pDetalDOC int,@q_pDinf datetime,@q_pDsup datetime,@q_PeConturi int,
	@q_art_calc_multiplu varchar(200), @q_art_calc_nedet varchar(200), @q_art_calc_excep varchar(200), @q_data datetime, 
	@pas int, @maiSuntDate int, @LMCurent char(9), @ComCurenta char(20), @IdMax int

create table #fisatmp
(	
	lunaanalfa char(23),
	[Numar_de_ordine] [int] not NULL,
	[Nivel] [smallint] not NULL,
	[Descriere] [char](100) not NULL,
	[Cantitate] [float] not NULL,
	[Pret] [float] not NULL,
	[Valoare] [float] not NULL,
	[Tip] [char](1) not NULL,
	[Cod] [char](20) not NULL,
	[Locm] [char](9) not NULL,
	[comanda_sup] [char](20) not NULL,
	[art_sup] [char](9) not NULL,
	[NrOrdP] [int] not NULL,
	unic int not null,
	ordineLuni int default 0,
	ordineAni int default 0,
	val float default 0,
	tipvalori int default '',
	codS varchar(20) default '',
	ordine2 int default 0,
	identificatorUnic varchar(2000) default '',
	codSParinte varchar(20) default '')
	
	select	@pDinf=dbo.bom(@pDinf),
			@pDsup=dbo.eom(@pDsup)
	select /*@q_pLM=@pLM, @q_pCom=@pCom, */
		@fltLocMunca=@pLM, @fltCentru=@pCentru, @fltComanda=@pCom, 
		@q_pNivelMax=@pNivelMax, @q_pDetalDOC=@pDetalDOC, 
		@q_pDinf=@pDinf, @q_pDsup=@pDsup, @q_PeConturi=@PeConturi, 
		@q_art_calc_multiplu=','+rtrim(@art_calc_multiplu)+',', 
		@q_art_calc_nedet=','+rtrim(@art_calc_nedet)+',', 
		@q_art_calc_excep=','+rtrim(@art_calc_excep)+','

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	set @tipComanda=isnull((select max(tip_comanda) from comenzi where @fltComanda<>'' and subunitate=@Sb and comanda=@fltComanda), '')

if @peconturi=0
begin
	declare crspretun cursor for
	select @fltLocMunca, '', @pDsup
	where @fltComanda=''
	union all
	select p.loc_de_munca, p.comanda, p.data_lunii 
	from pretun p
	inner join comenzi c on c.subunitate=p.subunitate and c.comanda=p.comanda
	left join speciflm s on s.loc_de_munca=p.loc_de_munca
	where @fltComanda<>'' and p.subunitate=@Sb and p.data_lunii between @q_pDinf and @q_pDsup
	and p.comanda like rtrim(@fltComanda)+'%' and c.tip_comanda=@tipComanda
	and p.loc_de_munca like rtrim(@fltLocMunca)+'%'
	and (isnull(@fltCentru, '')='' or isnull(s.marca, '')=@fltCentru)

	select @pas=0, @maiSuntDate=0

	open crspretun
	fetch next from crspretun into @q_pLM, @q_pCom, @q_data
	while @@fetch_status=0
	begin
		declare @dat1 datetime 
		set @dat1=(case when @fltComanda ='' then dbo.BOM(@pDinf) else dbo.BOM(@q_data) end)
		exec rapfisa @pLM=@q_pLM,@pCom=@q_pCom,@pNivel=0,@pNivelMax=@q_pNivelMax,@pCantPond=1,@pArtSup='',@pExceptArtSup='',
					@pExcArtNeincl='',@pArtInf='',@pDetalDOC=@q_pDetalDOC,@pSub='1',@pDinf=@dat1,@pDsup=@q_data,@pGrCom='',
					@pComenziNedet='',@pArtCalcNedet='',@pNrOrd=0,@PeConturi=@q_PeConturi,@PeLuni=@PeLuni,@cu_tabela=1
		--select @q_plm, @q_pcom, @q_data
		select @LMCurent=@q_pLM, @ComCurenta=@q_pCom
		fetch next from crspretun into @q_pLM, @q_pCom, @q_data
		
		select @pas=@pas+1, @maiSuntDate=(case when @maiSuntDate=0 and @@fetch_status=0 then 1 else @maiSuntDate end)
		
		select * into #fisacmdttmp from fisacmdttmp
		drop table fisacmdttmp

		if @PeLuni=0 update #fisacmdttmp set lunaanalfa='' --where nivel<=0	--> pentru grupari si totalizari corecte in fisa
		
		if @q_PeConturi=0
		begin
			declare @nr int
			select @nr=count(1) from #fisacmdttmp
			delete from #fisacmdttmp where charindex(','+rtrim(cod)+',',','+rtrim(@q_art_calc_excep)+',')<>0 and tip='A'
											and @q_art_calc_excep is not null and @q_art_calc_excep<>',,'

			delete from #fisacmdttmp where exists (select 1 from #fisacmdttmp t where
				charindex(','+rtrim(cod)+',',','+rtrim(@q_art_calc_multiplu)+',')=0 and tip='A' and t.numar_de_ordine=#fisacmdttmp.nrordp)
						and @q_art_calc_multiplu is not null and @q_art_calc_multiplu<>',,'

			delete from #fisacmdttmp where exists (select 1 from #fisacmdttmp t where
				charindex(','+rtrim(cod)+',',','+rtrim(@q_art_calc_nedet)+',')<>0 and tip='A' and t.numar_de_ordine=#fisacmdttmp.nrordp)
						and @q_art_calc_nedet is not null and @q_art_calc_nedet<>',,'

			while (@nr>(select count(1) from #fisacmdttmp)) 
			begin
				select @nr=count(1) from #fisacmdttmp
				delete from #fisacmdttmp where not exists (select 1 from #fisacmdttmp t where t.numar_de_ordine=#fisacmdttmp.nrordp) and nrordp<>0
			end	
		end

		declare @total float
		select @total=sum(valoare) from #fisacmdttmp

		if @pas=1
		begin
			insert into #fisatmp(lunaanalfa, Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic)
			select lunaanalfa, Numar_de_ordine, Nivel, Descriere, 
			(case when @q_peconturi=1 then (valoare/@total)*100 else Cantitate end) as cantitate, 
			Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic
			from #fisacmdttmp
		end
		else begin
			set @IdMax=isnull((select max(Numar_de_ordine) from #fisatmp), 0)
			update #fisacmdttmp set Numar_de_ordine=Numar_de_ordine+@IdMax, NrOrdP=(case when NrOrdP<>0 then NrOrdP+@IdMax else NrOrdP end)
			
			update f
			set cantitate=f.cantitate+(case when @q_peconturi=1 then (f1.valoare/@total)*100 else f1.cantitate end), 
				valoare=f.valoare+f1.valoare, 
				pret=(f.valoare+f1.valoare)/(f.cantitate+(case when @q_peconturi=1 then (f1.valoare/@total)*100 else f1.cantitate end))
			from #fisatmp f, #fisacmdttmp f1
			where f.nivel=0 and f1.nivel=0 and f.Descriere=f1.Descriere and f.Tip=f1.Tip
				and f.lunaanalfa=f1.lunaanalfa
			
			update f2
			set NrOrdP=f.Numar_de_ordine
			from #fisatmp f, #fisacmdttmp f1, #fisacmdttmp f2
			where f.nivel=0 and f1.nivel=0 and f.Descriere=f1.Descriere and f.Tip=f1.Tip and f2.NrOrdP=f1.Numar_de_ordine /*and f2.Nivel=1*/
				and f.lunaanalfa=f1.lunaanalfa
			
			delete f1
			from #fisatmp f, #fisacmdttmp f1
			where f.nivel=0 and f1.nivel=0 and f.Descriere=f1.Descriere and f.Tip=f1.Tip and f.lunaanalfa=f1.lunaanalfa
			
			insert #fisatmp (lunaanalfa, Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic)
			select lunaanalfa, Numar_de_ordine, Nivel, Descriere, 
				(case when @q_peconturi=1 then (valoare/@total)*100 else Cantitate end) as cantitate, 
				Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic
			from #fisacmdttmp f
		end

		drop table #fisacmdttmp
	end

	close crspretun
	deallocate crspretun
	--/*
	--test select * from #fisatmp
	--> adaugare totaluri:
	update f set NrOrdP=-1 from #fisatmp f where nivel=0
	--select * from #fisatmp --where nivel
end	
else
	insert into #fisatmp(lunaanalfa, Numar_de_ordine, Nivel, Descriere, val, Cantitate, Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic, ordineLuni, ordineAni, ordine2, tipvalori, cods, codsparinte)
	select --data, month(data) as luna, year(data) as anul, rtrim(lm) as lm, comanda,  fisapecont.cont, rtrim(isnull(conturi.Denumire_cont,'')) as dencont, convert(decimal(17,2),suma ) as suma
	--*/*
		'' lunaanalfa, 
		dense_rank() over (order by f.cont) Numar_de_ordine, 0 Nivel,
		rtrim(f.cont)+' - '+isnull(c.denumire_cont,'') Descriere, f.suma, 0,0,f.suma val,
		f.Tip, '' Cod, f.lm Locm, f.comanda comanda_sup, isnull(c.articol_de_calculatie,'') art_sup,
		-1 NrOrdP, 0,
		(case when @PeLuni=0 then 0 else month(f.data) end) ordineLuni,
		(case when @PeLuni=0 then 0 else year(f.data) end) ordineAni,
		 0 ordine2, 3 tipvalori, f.cont codS, '' codSParinte
		--*/
	from FisaPeCont f
		left join conturi c on c.cont=f.cont
	where tip='D'
		and f.data between @pDinf and @pDsup
		and f.lm like @plm
		and f.comanda like @pcom
	
	select max(lunaalfa) lunaalfa, luna into #lunialfa from fCalendar('2010-1-1','2010-12-1') group by luna

	if @PeConturi = 1
	begin
		update f
		set f.lunaanalfa = l.luna
		from #fisatmp f
		inner join #lunialfa l on l.luna = f.ordineLuni
	end
	
	insert into #fisatmp(lunaanalfa, Numar_de_ordine, Nivel, Descriere, Cantitate, Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic)
	select lunaanalfa, -1, -1, 'Total', sum(cantitate), sum(cantitate)/sum(valoare), sum(valoare), '', '', '', '', '', 0, max(unic)+1
	from #fisatmp f where nivel=0 group by lunaanalfa

--	alter table #fisatmp add ordine2 int, identificatorUnic varchar(2000)
	update #fisatmp set identificatorUnic=rtrim(descriere)

	--> asigurarea identificarii unice a liniei (prin concatenarea descrierilor de sus in jos)
	declare @nivel int, @nivelmax int
	select @nivel=min(nivel), @nivelmax=max(nivel) from #fisatmp
	while (@nivel<=@nivelmax)
	begin
		update fp set identificatorUnic=f.identificatorUnic+'|'+rtrim(fp.descriere)
			from #fisatmp f inner join #fisatmp fp on f.nivel=fp.nivel-1 and f.numar_de_ordine=fp.nrordp
			where f.nivel=@nivel
		set @nivel=@nivel+1
	end

	begin
		update f set ordineluni=t.luna, ordineani=replace(rtrim(f.lunaanalfa), rtrim(t.lunaalfa)+' ','')
		from #fisatmp f
			cross apply (select top 1 luna, lunaalfa from #lunialfa c where rtrim(c.lunaalfa)+' '=left(f.lunaanalfa,len(rtrim(c.lunaalfa)+' '))) t
			
	--> re-ordonare (provenind de pe apeluri diferite ale procedurii rapfisa numerele de ordine nu pot sa fie corecte pentru luni diferite):
	update f set ordine2=ff.ordine2,
			--> daca e necesar sa apara si codul liniei:
			descriere=(case when @siCoduri=1 then '('+rtrim(f.cod)+') '+rtrim(f.descriere) else rtrim(f.descriere) end)
	from #fisatmp f
		inner join (select numar_de_ordine, lunaanalfa, nivel,
						dense_rank() over (partition by nivel order by identificatorUnic, (case when nivel>0 or @peluni=0 then descriere else '' end)) ordine2
					from #fisatmp ff) ff
			on f.numar_de_ordine=ff.numar_de_ordine and f.lunaanalfa=ff.lunaanalfa and f.nivel=ff.nivel

	update f set nrordp=ff.ordine2
	from #fisatmp f
		cross apply (select ff.ordine2 from #fisatmp ff where f.nrordp=ff.numar_de_ordine and ff.lunaanalfa=f.lunaanalfa) ff
	--/*

	update f set numar_de_ordine=f.ordine2
	from #fisatmp f

	if (@faraNivel>=0)
	begin
		delete f from #fisatmp f where f.nivel>-1 and f.nivel<=@faraNivel
		update f set nrordp=1
			from #fisatmp f where f.nivel=@faraNivel+1
		update f set nivel=nivel-@faraNivel-1
			from #fisatmp f where f.numar_de_ordine>-1 and f.nivel>@faraNivel
				and nivel<>-1
	/*	update f set nrordp=-1
			from #fisatmp f where f.nivel=@faraNivel+1	*/
	end

	end

	--*/	--*/
	--> completare cu detaliile pe cantitate si pret:
	--alter table #fisatmp add val float, tipvalori int, codS varchar(20), codSParinte varchar(20)
	update #fisatmp set val=valoare, tipvalori=3, codS=convert(varchar(20),numar_de_ordine)+'|'+convert(varchar(20),nivel),
			codSParinte=convert(varchar(20),nrordp)+'|'+convert(varchar(20),nivel-1)

	if (@detaliat=1)
	insert into #fisatmp(lunaanalfa, Numar_de_ordine, Nivel, Descriere, val, Cantitate, Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic, ordineLuni, ordineAni, ordine2, tipvalori, cods, codsparinte)
	select lunaanalfa, Numar_de_ordine, Nivel, Descriere, pret val, Cantitate, Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic, ordineLuni, ordineAni, ordine2, 2 as tipvalori, cods, codsparinte
	from #fisatmp union all
	select lunaanalfa, Numar_de_ordine, Nivel, Descriere, cantitate val, Cantitate, Pret, Valoare, Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, unic, ordineLuni, ordineAni, ordine2, 1 as tipvalori, cods, codsparinte
	from #fisatmp

	if @PeConturi = 1
	begin
		update f
		set f.lunaanalfa = l.lunaalfa
		from #fisatmp f
		inner join #lunialfa l on l.luna = f.lunaanalfa
	end

--> aducere date (si coloanele de totaluri se calculeaza in sql ca nu stiu in reporting ca sa mearga si cu ascundere de coloane cantitate si pret):
select lunaanalfa, Numar_de_ordine, Nivel, Descriere, (case when tipvalori=2 then (case when cantitate>0 then valoare/cantitate else 0 end) else val end) val,
			Tip, Cod, Locm, comanda_sup, art_sup, NrOrdP, ordineLuni, ordineAni, ordine2, tipvalori, 0 ingrafic, codS, codSParinte, identificatorUnic
	from  #fisatmp
union all
select 'Total', Numar_de_ordine, Nivel, max(Descriere) descriere, (case when tipvalori=2 then (case when sum(cantitate)>0 then sum(valoare)/sum(cantitate) else 0 end) else sum(val) end),
			max(Tip), max(Cod), max(Locm), max(comanda_sup), max(art_sup), max(NrOrdP), max(ordineLuni)+1, max(ordineAni)+1, max(ordine2), tipvalori, (case when tipvalori=3 and nivel=0 then 1 else 0 end),
			max(codS), max(codSParinte), max(identificatorUnic)
	from  #fisatmp group by nivel, numar_de_ordine, nrordp, tipvalori

if object_id('tempdb..#fisatmp') is not null drop table #fisatmp
if object_id('tempdb..#lunialfa') is not null drop table #lunialfa

end try
begin catch
	select @eroare=error_message()+' ('+OBJECT_NAME(@@PROCID)+')'
end catch

if len(@eroare)>0
select @eroare as descriere, '<EROARE>' as cod
