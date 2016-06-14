--***
--if exists (select * from sysobjects where name ='rapRegistruDeCasa')
--drop procedure rapRegistruDeCasa
--go
----***
--create procedure rapRegistruDeCasa (@cont varchar(13),@datajos datetime,@datasus datetime,@utilizator varchar(100),
--		@jurnal varchar(100), @valuta varchar(4000),@tipC varchar(200),	@locm varchar(9)) as

	--	CG\Financiar\Registru de casa.rdl
	declare @cont nvarchar(4),@datajos datetime,@datasus datetime,@utilizator nvarchar(4000),@jurnal nvarchar(4000),@valuta nvarchar(4000),@tipC nvarchar(200),
		@locm varchar(9)
	--select @cont=N'5311',@datajos='2010-12-01 00:00:00',@datasus='2010-12-10 00:00:00',@utilizator=NULL,@jurnal=NULL,@valuta=NULL,
	--@tipC=N'A', @locm='2'
	select @cont=N'5311.4',@datajos='2012-05-25 00:00:00',@datasus='2012-05-25 00:00:00',@utilizator=NULL,@jurnal=NULL,@valuta=NULL,@tipC=N'A',@locm=NULL

	set transaction isolation level read uncommitted
	begin try
		exec verific_plan_contabil @cont
	end try
	begin catch
		declare @eroare varchar(200)
		set @eroare=error_message()
		raiserror(@eroare,16,1)
		return
	end catch
		declare @rulajelm int
		set @rulajelm=isnull((select val_logica from par where Tip_parametru='GE' and parametru='rulajelm'),0)

	/** pregatirea filtrarii pe locuri de munca */
	declare @utilizatorAsis varchar(20), @eLmUtiliz int
	set @utilizatorAsis=dbo.fIaUtilizator(null)
	set @eLmUtiliz=dbo.f_areLMFiltru(@utilizatorAsis)
			
	/**filtrare pe conturile asociate utilizatorilor (CONTPLIN)*/
	declare @eContUtiliz int
	declare @ContUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
	insert into @ContUtiliz(valoare, cod_proprietate)
	select rtrim(valoare),cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='CONTPLIN'
	delete c from @ContUtiliz c where exists (select 1 from @ContUtiliz cc		-- eliminare conturi ale caror parinti apar de asemenea
		where c.valoare like cc.valoare+'%' and c.valoare<>cc.valoare)	-- (oricum, situatia tratata aici este contraindicata)
	set @eContUtiliz=isnull((select max(1) from @ContUtiliz),0)

	--inregistrarile raportului CG\Financiar\Registru de casa
	select subunitate, (case when cont_corespondent=@cont then cont_corespondent else cont end) as cont, data, numar, 
	(case when cont_corespondent=@cont then (case plata_incasare
	when 'ID' then 'PD' when 'PD' then 'ID' end) else plata_incasare end) as plata_incasare, tert, factura, 
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
	 explicatii, utilizator, jurnal, numar_pozitie,0 as sold,0 as soldv

	into #inreg

	from pozplin p
	where subunitate='1' and ((cont=@cont or exists(select 1 from conturi c where subunitate='1' and cont_parinte=@cont and p.Cont=c.Cont))
			  or (cont_corespondent=@cont or exists(select 1 from conturi c where subunitate='1' and cont_parinte=@cont and p.cont_corespondent=c.cont)))
	and ((@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where cont like u.valoare+'%')) or (@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where Cont_corespondent like u.valoare+'%')))
	and data between @datajos and @datasus 
	and (@utilizator is null or utilizator=@utilizator)
	and (@jurnal is null or rtrim(jurnal)=@jurnal) 
	and (@valuta is null or rtrim(valuta)=@valuta /*or rtrim(valuta)=''*/)
	and (@locm is null or p.Loc_de_munca like @locm+'%')
	and (@eLmUtiliz=0 or exists (select 1 from lmfiltrare lf where lf.utilizator=@utilizatorAsis and p.Loc_de_munca=lf.cod))

	union all

	select subunitate, cont_debitor, data, numar, 'ID', '', '', cont_creditor, suma , 
	suma as sumai,0 as sumap,valuta, curs, suma_valuta, suma_valuta,0, explicatii, utilizator, jurnal, nr_pozitie,
	0 as sold, 0 as soldv

	from pozncon
	where tip='UA' and subunitate='1' and
	(cont_debitor=@cont or exists (select 1 from conturi where subunitate='1' and cont_parinte=@cont and pozncon.cont_debitor=conturi.cont)) and 
	(@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where Cont_debitor like u.valoare+'%')) and
	data between @datajos and @datasus and (@utilizator is null or utilizator=@utilizator)
	and (@jurnal is null or rtrim(jurnal)=@jurnal) and 
	(@valuta is null or rtrim(valuta)=@valuta or rtrim(valuta)='')
	and (@locm is null or pozncon.Loc_munca like @locm+'%')
	and (@eLmUtiliz=0 or exists (select 1 from lmfiltrare lf where lf.utilizator=@utilizatorAsis and pozncon.Loc_munca=lf.cod))
	declare @datatjos datetime
	set @datatjos='1901-1-1'
	--tabela temporara cu solduri pe zile
	declare @datat datetime
	create table #tempp (data datetime, sold float, soldv float)
	declare bd cursor                   
	for select distinct data
	from #inreg
	union select dateadd(d,-1,min(data))
	from #inreg 
	union select dateadd(d,1,max(data))
	from #inreg
	order by data                
	open bd                   
	fetch next from bd into @datat                   

		while @@fetch_status=0                   
		begin
		set @datat=dateadd(d,1,@datat)	/** mai jos s-a inlocuit SolduriCont cu SoldConturi pentru a realiza filtrarea pe conturi in exterior*/
		insert into #tempp 
		select dateadd(d,-1,@datat),(select sum(case @tipC when 'A' then suma_debit when 'P' then suma_credit
		else (case when suma_debit-suma_credit>=0 then suma_debit-suma_credit else suma_credit-suma_debit end) end) 
		from dbo.fRulajeConturi(1,@cont,null, @datat, @jurnal,@locm, @datatjos) x 
			where (@eContUtiliz=0 and Are_analitice=0 or exists (select 1 from @ContUtiliz u where u.valoare=x.Cont))) as sold,
		(select sum(case @tipC when 'A' then suma_debit when 'P' then suma_credit
		else (case when suma_debit-suma_credit>=0 then suma_debit-suma_credit else suma_credit-suma_debit end) end) 
		from dbo.fRulajeConturi (1,@cont,@valuta, @datat, @jurnal,@locm, @datatjos) x
			where (@eContUtiliz=0 and Are_analitice=0 or exists (select 1 from @ContUtiliz u where u.valoare=x.Cont))
			) as soldv
		set @datatjos=@datat
	
	fetch next from bd into @datat                   
	end                   
	close bd                   
	deallocate bd

	update t set sold=tv.sold, soldv=tv.soldv
	from #tempp t inner join 
	(select sum(t2.sold) sold, sum(t2.soldv) soldv, t1.data from #tempp t1 inner join #tempp t2 on t1.data>=t2.data group by t1.data)
		tv on t.data=tv.data

	--formarea datasetului 
	select * from #inreg
	union all select '','',data,'','','','','','',0,0,'','',0,0,0,'','','','',sold,soldv	from #tempp

	order by data,numar_pozitie
	drop table #tempp
	drop table #inreg
