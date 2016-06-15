--***
create procedure rapRegistruDeCasa (@sesiune varchar(50)=null, @cont varchar(40),@datajos datetime,@datasus datetime,
		@utilizator varchar(100)=null, @jurnal varchar(100)=null, @valuta varchar(4000)=null, @locm varchar(9)=null,
		@tipC varchar(1)=null, --> parametru care va fi intern pentru procedura, a ramas aici pentru compatibilitate cu rdl vechi.
		@invaluta int=0,	--> pentru varianta in valuta a a raportului
		@parXML xml = null
		,@centralizare int=0	--> centralizare: 0 = document, varianta implicita, grupat pe cont, data, numar, plata_incasare, tert, marca, valuta
										-->		  1 = detaliat, fara nici un fel de grupare
		)
as
set transaction isolation level read uncommitted
declare @eroare varchar(max)
begin try
	/**	CG\Financiar\Registru de casa.rdl
	declare @cont nvarchar(40),@datajos datetime,@datasus datetime
	select @cont='531.01.02',@datajos='2015-1-13 00:00:00',@datasus='2015-1-13 00:00:00'
	exec rapRegistruDeCasa @sesiune=null, @cont=@cont,@datajos =@datajos,@datasus =@datasus,
		@utilizator=null, @jurnal=null, @valuta=null, @locm=null,
		@tipC=null, --> parametru care va fi intern pentru procedura, a ramas aici pentru compatibilitate cu rdl vechi.
		@invaluta =0
	--*/
	
	if object_id('tempdb..#tempp') is not null drop table #tempp
	if object_id('tempdb..#conturi') is not null drop table #conturi
	if object_id('tempdb..#inreg') is not null drop table #inreg
	select @cont=rtrim(@cont)
	begin try
		exec verific_plan_contabil @cont
	end try
	begin catch
		set @eroare=error_message()
		raiserror(@eroare,16,1)
		return
	end catch
		declare @rulajelm int
		select @rulajelm=isnull((select val_logica from par where Tip_parametru='GE' and parametru='rulajelm'),0),
			@tipC=(select max(rtrim(tip_cont)) from conturi where cont=@cont)

	/** pregatirea filtrarii pe locuri de munca */
	declare @utilizatorAsis varchar(20), @eLmUtiliz int
	select @utilizatorAsis=dbo.fIaUtilizator(@sesiune)
	set @eLmUtiliz=dbo.f_areLMFiltru(@utilizatorAsis)
	
	if @invaluta=1
	begin
		declare @are_analitice int
		select @are_analitice=are_analitice, @valuta=isnull(p.valoare,'')
			from conturi c
				left join proprietati p on p.tip='cont' and p.cod_proprietate='invaluta' and p.valoare<>'' and c.cont=p.cod
			where c.cont=@cont
		if isnull(@are_analitice,0)=1
			raiserror('Contul completat are analitice!',16,1)
	end
	create table #conturi (cont varchar(500), valuta varchar(100))
	insert into #conturi (cont, valuta)
	select c.cont, isnull(p.valoare,'') valuta from conturi c
		left join proprietati p on p.tip='cont' and p.cod_proprietate='invaluta' and p.valoare<>'' and c.cont=p.cod
		where (c.cont=@cont or c.cont_parinte=@cont)
			and (@valuta is null or rtrim(isnull(p.valoare,''))=@valuta)
		group by c.cont, isnull(p.valoare,'')

	/**filtrare pe conturile asociate utilizatorilor (CONTPLIN)*/
	declare @eContUtiliz int
	declare @ContUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @ContUtiliz(valoare, cod_proprietate)
	select rtrim(valoare),cod_proprietate from fPropUtiliz(@sesiune) where valoare<>'' and cod_proprietate='CONTPLIN'
	delete c from @ContUtiliz c
		where exists (select 1 from @ContUtiliz cc		-- eliminare conturi ale caror parinti apar de asemenea
			where c.valoare like cc.valoare+'%' and c.valoare<>cc.valoare)	-- (oricum, situatia tratata aici este contraindicata)
	select @eContUtiliz=isnull((select max(1) from @ContUtiliz),0)
	delete c from @ContUtiliz c where not exists (select 1 from #conturi co where co.cont=c.valoare)	--> si care nu sunt 

	--inregistrarile raportului CG\Financiar\Registru de casa
	select subunitate, (case when cont_corespondent=@cont then cont_corespondent else cont end) as cont, data, numar, 
		(case when cont_corespondent=@cont then (case plata_incasare
			when 'ID' then 'PD' when 'PD' then 'ID' end) else plata_incasare end) as plata_incasare, tert, factura, isnull(marca,'') as marca, 
		(case when cont_corespondent=@cont then cont else cont_corespondent end) as cont_corespondent, suma,
		(case when left(plata_incasare,1)='I' and cont_corespondent<>@cont then suma else 0 end) +
		(case when left(plata_incasare,1)='P' and cont_corespondent=@cont then suma else 0 end) as sumai,
		(case when left(plata_incasare,1)='P' and cont_corespondent<>@cont then suma else 0 end)+
		(case when left(plata_incasare,1)='I' and cont_corespondent=@cont then suma else 0 end) as sumap,
		valuta, curs,
		suma_valuta,
		(case when left(plata_incasare,1)='I' and cont_corespondent<>@cont then suma_valuta else 0 end)+
		(case when left(plata_incasare,1)='P' and cont_corespondent=@cont then suma_valuta else 0 end) as sumavi,
		(case when left(plata_incasare,1)='P' and cont_corespondent<>@cont then suma_valuta else 0 end)+
		(case when left(plata_incasare,1)='I' and cont_corespondent=@cont then suma_valuta else 0 end) as sumavp,
		explicatii, utilizator, jurnal, numar_pozitie,0 as sold,0 as soldv, 0 as sold_prec, 0 as soldv_prec
	into #inreg

	from pozplin p
	where subunitate='1' and (/*(cont=@cont or exists(select 1 from conturi c where subunitate='1' and cont_parinte=@cont and p.Cont=c.Cont))
			  or (cont_corespondent=@cont or exists(select 1 from conturi c where subunitate='1' and cont_parinte=@cont and p.cont_corespondent=c.cont))*/
			  exists (select 1 from #conturi c where (c.cont=p.cont or c.cont=p.cont_corespondent)))
		and ((@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where cont like u.valoare+'%'))
			or (@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where Cont_corespondent like u.valoare+'%')))
		and data between @datajos and @datasus and (@utilizator is null or utilizator=@utilizator)
		and (@jurnal is null or rtrim(jurnal)=@jurnal)
		and (@locm is null or p.Loc_de_munca like @locm+'%')
		and (@eLmUtiliz=0 or exists (select 1 from lmfiltrare lf where lf.utilizator=@utilizatorAsis and p.Loc_de_munca=lf.cod))

	union all

	select subunitate, cont_debitor, data, numar, 'ID', '', '', '', cont_creditor, suma , 
		suma as sumai,0 as sumap,valuta, curs, suma_valuta, suma_valuta,0, explicatii, utilizator, jurnal, nr_pozitie,
		0 as sold, 0 as soldv, 0 as sold_prec, 0 as soldv_prec

	from pozncon
	where tip='UA' and subunitate='1' and
		(--cont_debitor=@cont or exists (select 1 from conturi where subunitate='1' and cont_parinte=@cont and pozncon.cont_debitor=conturi.cont)
			exists (select 1 from #conturi c where c.cont=pozncon.cont_debitor)
		) and 
		(@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where Cont_debitor like u.valoare+'%')) and
		data between @datajos and @datasus and (@utilizator is null or utilizator=@utilizator)
		and (@jurnal is null or rtrim(jurnal)=@jurnal)
		and (@locm is null or pozncon.Loc_munca like @locm+'%')
		and (@eLmUtiliz=0 or exists (select 1 from lmfiltrare lf where lf.utilizator=@utilizatorAsis and pozncon.Loc_munca=lf.cod))

	if exists (select 1 from sysobjects where [type]='P' and [name]='rapRegistruDeCasaSP')
	begin
		-- trimitem filtrele in un XML si pastram alt parXML care poate fi format prin apelare raport din SQL
		declare @xmlFiltre xml
		set @xmlFiltre = (select
				@sesiune sesiune, @cont cont, @datajos datajos,@datasus datasus,
				@utilizator utilizator, @jurnal jurnal, @valuta valuta, @locm locm,
				@tipC tipc for xml raw)
		exec rapRegistruDeCasaSP @xmlFiltre, @parXML
	end	

	declare @datatjos datetime
	set @datatjos='1901-1-1'
	declare @datat datetime
	
	create index diez_inreg_data on #inreg(data)	
	
	if object_id('tempdb..#pRulajeConturi_t') is null
	begin
		create table #pRulajeConturi_t (Subunitate varchar(10) default 1)
		exec pRulajeConturi_tabela
	end
	
	select @datat=min(data) from #inreg
	declare @soldi decimal(15,5), @soldvi decimal(15,5)
	
	exec pRulajeConturi @nivelplancontabil=1, @dData=@datat, @ccont=@cont, @cJurnal=@jurnal, @cLM=@locm, @datajos=@datatjos, @cvaluta='', @sesiune=@sesiune
	select @soldi=(select sum(case @tipC when 'A' then suma_debit when 'P' then suma_credit
		else (case when 1=1 or suma_debit-suma_credit>=0 then suma_debit-suma_credit else suma_credit-suma_debit end) end)	--	tratat pentru "Bifunctionale" sa faca tot timpul Suma_debit-Suma_credit
		from #pRulajeConturi_t x
			where (@eContUtiliz=0 and Are_analitice=0 or exists (select 1 from @ContUtiliz u where u.valoare=x.Cont))
			)
	--, @grupare1='', @grupare2=''
	
	if @invaluta=1 and isnull(@valuta,'')<>''
	begin
		truncate table #pRulajeConturi_t
		exec pRulajeConturi @nivelplancontabil=1, @dData=@datat, @ccont=@cont, @cJurnal=@jurnal, @cLM=@locm, @datajos=@datatjos, @cvaluta=@valuta, @sesiune=@sesiune
		select @soldvi=(select sum(case @tipC when 'A' then suma_debit when 'P' then suma_credit
			else (case when 1=1 or suma_debit-suma_credit>=0 then suma_debit-suma_credit else suma_credit-suma_debit end) end)	--	tratat pentru "Bifunctionale" sa faca tot timpul Suma_debit-Suma_credit
			from #pRulajeConturi_t x
				where (@eContUtiliz=0 and Are_analitice=0 or exists (select 1 from @ContUtiliz u where u.valoare=x.Cont))
				and x.valuta=@valuta
				)
	end
	/*
	
	select @soldi=(select sum(case @tipC when 'A' then suma_debit when 'P' then suma_credit
				else (case when 1=1 or suma_debit-suma_credit>=0 then suma_debit-suma_credit else suma_credit-suma_debit end) end)	--	tratat pentru "Bifunctionale" sa faca tot timpul Suma_debit-Suma_credit
				from dbo.fRulajeConturi(1,@cont,null, @datat, @jurnal,@locm, @datatjos, null) x 
					where (@eContUtiliz=0 and Are_analitice=0 or exists (select 1 from @ContUtiliz u where u.valoare=x.Cont))),
			@soldvi=(select sum(case @tipC when 'A' then suma_debit when 'P' then suma_credit
				else (case when 1=1 or suma_debit-suma_credit>=0 then suma_debit-suma_credit else suma_credit-suma_debit end) end)	--	tratat pentru "Bifunctionale" sa faca tot timpul Suma_debit-Suma_credit
				from dbo.fRulajeConturi (1,@cont,@valuta, @datat, @jurnal,@locm, @datatjos, null) x
					where (@eContUtiliz=0 and Are_analitice=0 or exists (select 1 from @ContUtiliz u where u.valoare=x.Cont)))
	
	if (@valuta is not null and @valuta<>'') 
	select @soldi=@soldvi*x.curs
		from (select top 1 curs from #inreg order by data, numar_pozitie) x	*/
		-- se calculeaza soldurile de inceput si sfarsit de zi (lei/valuta):
	create table #tempp (data datetime, sold float, soldv float, sold_prec float, soldv_prec float, valuta varchar(10))
	insert into #tempp(data, sold, soldv, sold_prec, soldv_prec, valuta)
		select d.data,@soldi+sum(s.suma),@soldvi+sum(s.suma_valuta),		
				@soldi+sum(case when d.data=s.data then 0 else s.suma end),
				@soldvi+sum(case when d.data=s.data then 0 else s.suma_valuta end)
				,max(d.valuta) valuta
				from 
			(select max(d.valuta) valuta, d.data from #inreg d group by d.data) d, 
			(select (--case when @valuta is null then 
					sum(case when left(d.plata_incasare,1)='I' then suma else -suma end)
								--else sum(case when left(d.plata_incasare,1)='I' then suma_valuta*curs else -suma_valuta*curs end) end
								) as suma,
					sum(case when left(d.plata_incasare,1)='I' then suma_valuta else -suma_valuta end) as suma_valuta, d.data from #inreg d group by d.data) s
			where d.data>=s.data group by d.data order by data

	-- coloana folosita in raportul / formular registru de casa / o zi.
	alter table #inreg -- se va lua cu max in raport...
		add observatiiFooter varchar(8000) 
	update #inreg set observatiiFooter='Casier, '

	if exists (select 1 from sysobjects where [type]='P' and [name]='rapRegistruDeCasaSP1') -- necesar la formular
	begin
		-- trimitem filtrele in un XML si pastram alt parXML care poate fi format prin apelare raport din SQL
		declare @xmlFiltre1 xml
		set @xmlFiltre1 = (select
				@sesiune sesiune, @cont cont, @datajos datajos,@datasus datasus,
				@utilizator utilizator, @jurnal jurnal, @valuta valuta, @locm locm,
				@tipC tipc for xml raw)
		exec rapRegistruDeCasaSP1 @xmlFiltre1, @parXML
	end	
	
	--formarea datasetului 
--> centralizare: 0 = grupat pe document
									-->		 1 = varianta implicita, grupat pe cont, data, numar, plata_incasare, tert, marca, valuta
									-->		 2 = fara nici un fel de grupare
	--> pozitii in functie de parametrul de centralizare:
	select --*  
		subunitate, cont, data, numar, plata_incasare, tert, max(factura) factura, marca, cont_corespondent, 
		sum(suma) suma, sum(sumai) sumai, sum(sumap) sumap, valuta, max(curs) curs, sum(suma_valuta) suma_valuta, sum(sumavi) sumavi, sum(sumavp) sumavp,
		(case when max(explicatii)=min(explicatii) then max(explicatii) else '<multiple>' end) explicatii, max(utilizator) utilizator, max(jurnal) jurnal, max(numar_pozitie) numar_pozitie, 0 sold, 0 soldv, 0 sold_prec, 0 soldv_prec, 
		max(observatiiFooter) observatiiFooter 
		, 0 as antet
	from #inreg where @centralizare=0
	--where (@valuta is null or valuta=@valuta)
	group by subunitate, cont, data, numar, plata_incasare, tert, marca, valuta, cont_corespondent
	union all
	select --*  
		subunitate, cont, data, numar, plata_incasare, tert, factura factura, marca, cont_corespondent cont_corespondent, 
		suma suma, sumai sumai, sumap sumap, valuta, curs curs, suma_valuta suma_valuta, sumavi sumavi, sumavp sumavp,
		explicatii explicatii, utilizator utilizator, jurnal jurnal, numar_pozitie numar_pozitie, 0 sold, 0 soldv, 0 sold_prec, 0 soldv_prec, 
		observatiiFooter observatiiFooter 
		, 0 as antet
	from #inreg where @centralizare=1
	--> antet
	union all 
	select '','',data,'','','','','','','',0,0,'','',0,0,0,'','','','',sold,soldv,sold_prec, soldv_prec, '' as observatiiFooter, 1 as antet from #tempp
	--where (@valuta is null or valuta=@valuta)
	order by data, antet desc, numar_pozitie
	
end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch
	if object_id('tempdb..#tempp') is not null drop table #tempp
	if object_id('tempdb..#conturi') is not null drop table #conturi
	if object_id('tempdb..#inreg') is not null drop table #inreg
if len(@eroare)>0 
begin
	select --*  
		'1' subunitate, @eroare cont, '1901-1-1' data, '<EROARE>' numar, '' plata_incasare, '' tert, '' factura, '' cont_corespondent, 
		0 suma, 0 sumai, 0 sumap, '' valuta, '' curs, 0 suma_valuta, 0 sumavi, 0 sumavp,
		'' explicatii, '' utilizator, '' jurnal, 0 numar_pozitie, 0 sold, 0 soldv, 0 sold_prec, 0 soldv_prec, 
		'' observatiiFooter 
		, 0 as antet
--	raiserror(@eroare, 16,1)
end
