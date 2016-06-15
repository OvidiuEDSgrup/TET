--***
/**	proc.calcul retineri si restpl	*/
Create procedure CalculRetineriSiRestPlata
	@dataJos datetime, @dataSus datetime, @marca varchar(6), @lm varchar(9)
As
Begin try
	if exists (select * from sysobjects where name ='CalculRetineriSiRestPlataSP')
		exec CalculRetineriSiRestPlataSP @dataJos, @dataSus, @marca, @lm

	declare @Detaliere_retineri int, @Lichid_ret_avans int, @Ret_procent_tl int, @Op_ret_venit_net int, @Proc_ret_venit_net float, @ACorU_restpl int, @CAS_CorU int, 
			@Drumor int, @Modatim int, @Salubris int, @Colas int, @Dafora int, @nOre_luna float, @cCod_sindicat char(13), @dataSus1000 datetime,
			@ret_Salubris float, @ret_COLAS float, @Salar_net_crt float, @val_de_retinut float, @val_de_retinut_perm float, @retinut_anterior float, 
			@retinere_calculata float, @marca_ant varchar(6), @codBenAvMatImpozabile varchar(20), @NumarDocAvMatImp varchar(10)

	set @Detaliere_retineri=dbo.iauParL('PS','SUBTIPRET')
	set @Lichid_ret_avans=dbo.iauParL('PS','LICHRETAV')
	set @Ret_procent_tl=dbo.iauParL('PS','RETPTL')
	set @Op_ret_venit_net=dbo.iauParL('PS','OPRETLO')
	set @Proc_ret_venit_net=dbo.iauParN('PS','OPRETLO')
	set @ACorU_restpl=dbo.iauParL('PS','ADRPL-U')
	set @CAS_CorU=dbo.iauParL('PS','CALCAS-U')
	set @cCod_sindicat=dbo.iauParA('PS','SIND%')
	set @codBenAvMatImpozabile=dbo.iauParA('PS','CODBENAMI')
	set @Drumor=dbo.iauParL('SP','DRUMOR')
	set @Modatim=dbo.iauParL('SP','MODATIM')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @nOre_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @dataSus1000=Dateadd(year,1000,@dataSus)
	set @NumarDocAvMatImp='AVMIMP'+left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)

	if @marca is null set @marca=''
	if @lm is null set @lm=''

	select @ret_Salubris=0, @ret_COLAS=0, @Salar_net_crt=0, @val_de_retinut=0, @val_de_retinut_perm=0, @retinere_calculata=0, @retinut_anterior=0, @marca_ant=''

	if object_id('tempdb..#pontaj_marca_locm') is not null drop table #pontaj_marca_locm
	if object_id('tempdb..#personalret') is not null drop table #personalret
	if object_id('tempdb..#brutret') is not null drop table #brutret
	if object_id('tempdb..#calculret') is not null drop table #calculret

--	pun in tabela temporara datele din pontaj grupate pe data, marca, loc de munca	
	Create table #Pontaj_marca_locm (Data datetime, Marca char(6), Loc_de_munca char(9), Regim_de_lucru float, Grupa_de_munca char(1), Tip_salarizare char(1), 
		Coeficient_acord float, Ore_intr_tehn_1 int, Ore_intr_tehn_2 int, Ore_intemperii int, Ore_intr_tehn_3 float) 
	Create Unique Clustered Index [Marca_locm] ON #pontaj_marca_locm (Data Asc, Marca Asc, Loc_de_munca Asc)
	exec pPontaj_marca_locm @dataJos, @dataSus, @marca, @lm

--	filtrez tabela personal dupa criteriile de filtrare si mai jos fac inner join
	select * into #personalret
	from personal
	where (@marca='' or marca=@marca) 
		and (@lm='' or loc_de_munca like rtrim(@lm)+'%')
		and (loc_ramas_vacant=0 or data_plec>=@dataJos) 
	create index marca on #personalret (marca)

--	generare retineri pornind de la avantajele materiale impozabile (cu toate contributiile)
	if @codBenAvMatImpozabile<>''
	begin
		delete r 
		from resal r
		inner join #personalret p on p.Marca=r.Marca
		where r.Data=@dataSus and r.Cod_beneficiar=@codBenAvMatImpozabile and r.Numar_document=@NumarDocAvMatImp
		insert into resal 
			(Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, Retinere_progr_la_lichidare, 
			Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
		select c.data, c.marca, @codBenAvMatImpozabile, @NumarDocAvMatImp, c.data, (case when c.Suma_neta<>0 then c.Suma_neta else c.suma_corectie end), 
			0, 0, (case when c.Suma_neta<>0 then c.Suma_neta else c.suma_corectie end), 0, 0, 0
		from fSumeCorectie (@dataJos, @dataSus, 'AI', @marca, @Lm, 0) c
			inner join #personalret p on p.marca=c.marca
	end

--	pun datele citite mai jos in tabele temporare; cu outer apply mergea mai greu
	select b.data, b.marca, sum(b.compensatie) as aj_deces
		,sum(b.ore_lucrate_regim_normal*(case when @Drumor=1 then (case when isnull(j.coeficient_acord,0)<1 then isnull(j.coeficient_acord,0) else 1 end) else 1 end)) as ore_lucrate_regim_normal
		,sum(ore_concediu_medical) as ore_concediu_medical, sum(b.ore_concediu_de_odihna) as ore_concediu_de_odihna, sum(b.ore_obligatii_cetatenesti) as ore_obligatii_cetatenesti
		,sum(b.restituiri+b.CO+b.ind_c_medical_cas+b.ind_c_medical_unitate+b.spor_cond_9) as corectie_Colas
	into #brutret
	from brut b
		inner join #personalret p on p.marca=b.marca
		left outer join #Pontaj_marca_locm j on b.data=j.data and b.marca=j.marca and b.loc_de_munca=j.loc_de_munca 
	where b.data=@datasus
	group by b.data, b.marca

	update r set r.valoare_retinuta_pe_doc=0 
	from resal r 
		inner join #personalret p on p.marca=r.marca
	where r.data=@dataSus and r.numar_document='TICHETE'

--	selectare date din resal in tabela temporara
	select r.data, r.marca, r.cod_beneficiar as cod_beneficiar, r.numar_document, r.valoare_totala_pe_doc as val_totala, r.valoare_retinuta_pe_doc as val_retinuta, 
		r.retinere_progr_la_lichidare as ret_progr_lich, r.procent_progr_la_lichidare as procent_progr_la_lich, r.retinut_la_avans, r.retinut_la_lichidare as retinut_la_lich, 
		br.tip_retinere as tip_ret_benret, isnull(t.tip_retinere,'') as tip_ret_subtip, 
		(case when @Detaliere_retineri=1 then t.tip_retinere else br.tip_retinere end) as tip_ret, p.salar_de_incadrare as salar_inc, substring(br.cod_fiscal,10,1) as baza_procent, 
		isnull(b.corectie_Colas,0) as corectie_COLAS, isnull(n.venit_net,0) as venit_net, isnull(n.venit_total,0) as venit_total, isnull(b.aj_deces,0) as aj_deces,
		isnull(b.ore_lucrate_regim_normal+(case when @Modatim=1 then b.ore_concediu_de_odihna+b.ore_concediu_medical else 0 end)
			+(case when substring(br.cod_fiscal,10,1)='4' then b.ore_concediu_de_odihna+b.ore_obligatii_cetatenesti else 0 end),0) as ore_lucrate, 
		isnull(c.retinut_la_lichidare,0) as ret_chitanta, isnull(d.valoare_retinuta_pe_doc,0) as val_retinuta_ant, isnull(d.retinere_progr_la_lichidare,0) as ret_progr_lich_ant, 
		isnull(d.retinut_la_lichidare,0) as retinut_la_lich_ant, isnull(u.suma_corectie,0) as val_cor_U, dbo.fCodb_sindicat(r.marca,@dataSus) as cod_sindicat,
		convert(decimal(12,2),0) as ret_Salubris, convert(decimal(12,2),0) as val_de_retinut, convert(decimal(12,2),0) as val_de_retinut_perm, convert(decimal(12,2),0) as retinere_calculata, 
		(case when @Salubris=1 or @Colas=1 then convert(int,left(br.cod_fiscal,9)) else 0 end) as Ord1, 
		(case when @Detaliere_retineri=1 then t.tip_retinere else br.tip_retinere end) as Ord2 
	into #calculret
	from resal r 
		inner join #personalret p on r.marca=p.marca
		left outer join benret br on r.cod_beneficiar=br.cod_beneficiar
		left outer join tipret t on br.tip_retinere=t.subtip
		left outer join net n on r.marca=n.marca and r.data=n.data
		left outer join #brutret b on r.marca=b.marca 
		left outer join resal c on c.data=@dataSus1000 and r.marca=c.marca and r.cod_beneficiar=c.cod_beneficiar and r.numar_document=c.numar_document
		left outer join resal d on d.data=@dataJos-1 and r.marca=d.marca and r.cod_beneficiar=d.cod_beneficiar and r.numar_document=d.numar_document
		left outer join corectii u on r.marca=u.marca and r.data=u.data and u.tip_corectie_venit='U-'
	where r.data=@dataSus and r.retinut_la_avans=0
	order by r.marca,Ord1,Ord2
--	pun index pe tabela pt. a functiona update-ul pe index (sper ca merge).
	create index ordonare on #calculret (marca,Ord1,Ord2)

--	calcul retineri 
	update #calculret set 
		@ret_Salubris=(case when @Salubris=1 and ret_progr_lich_ant-retinut_la_lich_ant>0 and tip_ret_benret<>'M' then ret_progr_lich_ant-retinut_la_lich_ant else 0 end),
		@val_de_retinut=(case when val_totala=0 or cod_beneficiar=cod_sindicat then 0 
			else (select dbo.valoare_minima(ret_progr_lich+round(procent_progr_la_lich*salar_inc/100,0)+@ret_Salubris, val_totala-val_retinuta_ant-ret_chitanta, @val_de_retinut)) end),
		@val_de_retinut=(case when @Lichid_ret_avans=1 and val_totala-val_retinuta_ant<2*ret_progr_lich and val_totala-val_retinuta_ant>ret_progr_lich then 
			(case when val_totala=0 or cod_beneficiar=cod_sindicat then 0 
			else (select dbo.valoare_maxima(ret_progr_lich+round(procent_progr_la_lich*salar_inc/100,0)+@ret_Salubris, val_totala-val_retinuta_ant, @val_de_retinut)) end) else @val_de_retinut end),
		@val_de_retinut_perm=(case when val_totala=0 or cod_beneficiar=cod_sindicat then ret_progr_lich+round(procent_progr_la_lich*salar_inc/100,0)+@ret_Salubris else 0 end),
		ret_Salubris=@ret_Salubris, val_de_retinut=@val_de_retinut, val_de_retinut_perm=@val_de_retinut_perm

--	calcul retineri de tip procentual
	update #calculret 
		set @ret_COLAS=(case when @Colas=1 and cod_beneficiar='9999' then (select dbo.valoare_minima (salar_inc*ore_lucrate/@nOre_luna+corectie_COLAS, salar_inc, @ret_COLAS)) else 0 end),
			@val_de_retinut = (case when val_totala = 0 then 0 
				else (select dbo.valoare_minima(ret_progr_lich+ret_Salubris+round(procent_progr_la_lich/100*(case when @Colas=1 and cod_beneficiar='9999' then @ret_COLAS else salar_inc*ore_lucrate/@nOre_luna end),0)
					,val_totala-val_retinuta_ant-ret_chitanta,@val_de_retinut)) end),
			@val_de_retinut_perm = (case when val_totala=0 then ret_progr_lich+round(procent_progr_la_lich/100* 
				(case when @Colas=1 and cod_beneficiar='9999' then @ret_COLAS else salar_inc*ore_lucrate/@nOre_luna end),0)+ret_Salubris else 0 end),
			@val_de_retinut_perm = (case when val_totala=0 then ret_progr_lich+round(procent_progr_la_lich/100* 
				(case when @Colas=1 and cod_beneficiar='9999' then @ret_COLAS else salar_inc*ore_lucrate/@nOre_luna end),0)+ret_Salubris else 0 end),
			val_de_retinut=@val_de_retinut, val_de_retinut_perm=@val_de_retinut_perm
	where (@Drumor=1 or @Modatim=1 and cod_beneficiar='1' or @Ret_procent_tl=1 and baza_procent = '' or baza_procent = '3' or baza_procent = '4') and procent_progr_la_lich>0

	update #calculret
		set @val_de_retinut=(case when val_totala=0 or cod_beneficiar=cod_sindicat then 0 
			else (select dbo.valoare_minima (ret_progr_lich+round(procent_progr_la_lich*(case when baza_procent='5' then venit_total else venit_net end)/100,0), 
				val_totala-val_retinuta_ant-ret_chitanta, @val_de_retinut)) end),
			@val_de_retinut_perm=(case when val_totala=0 or cod_beneficiar=cod_sindicat 
				then ret_progr_lich+round(procent_progr_la_lich*(case when baza_procent='5' then venit_total else venit_net end)/100,0) else 0 end),
			val_de_retinut=@val_de_retinut, val_de_retinut_perm=@val_de_retinut_perm
	where @Dafora=1 or baza_procent='2' or baza_procent='5'

-- s-a inlocuit procedura Calcul_retinut_la_lichidare cu partea de mai jos.
	if @Op_ret_venit_net=0
		update #calculret set retinere_calculata=val_de_retinut+val_de_retinut_perm

	if @Op_ret_venit_net=1
		update cr 
			set @Salar_net_crt=round(n.venit_net*@Proc_ret_venit_net/100,0)-n.avans-n.premiu_la_avans-n.cm_incasat-n.co_incasat-n.suma_incasata-n.diferenta_impozit+b.aj_deces
					-(case when cr.marca<>@marca_ant then 0 else @retinut_anterior end),
				@retinere_calculata=(case when @salar_net_crt<val_de_retinut+val_de_retinut_perm and val_de_retinut+val_de_retinut_perm>0
					then (case when @salar_net_crt<0 then 0 else @salar_net_crt end) else val_de_retinut+val_de_retinut_perm end),
				@retinut_anterior=(case when cr.marca=@marca_ant then @retinut_anterior else 0 end)+@retinere_calculata, 
				cr.retinere_calculata=@retinere_calculata, @marca_ant=cr.marca
		from #calculret cr 
			left outer join net n on n.data=cr.data and n.marca=cr.marca
			left outer join #brutret b on b.data=cr.data and b.marca=cr.marca

--	pun retinerile in tabela net grupate pe cele 4 tipuri de retineri
	update n 
		set n.Debite_externe=n.Debite_externe+isnull(cr.Debite_externe,0), n.Rate=n.Rate+isnull(cr.Rate,0),
			n.Debite_interne=n.Debite_interne+isnull(cr.Debite_interne,0), n.Cont_curent=n.Cont_curent+isnull(cr.Cont_curent,0)
	from net n
		inner join #personalret p on p.marca=n.marca
		left outer join (select marca, sum(case when tip_ret in ('1','5') then retinere_calculata else 0 end) as debite_externe, 
			sum(case when tip_ret='2' then retinere_calculata else 0 end) as Rate, sum(case when tip_ret='3' then retinere_calculata else 0 end) as Debite_interne,
			sum(case when tip_ret='4' then retinere_calculata else 0 end) as Cont_curent
			from #calculret group by marca) cr on cr.marca=n.marca
	where n.data=@dataSus

--	pun retinerile gata calculate in tabela resal
	update r 
		set r.retinut_la_lichidare=cr.retinere_calculata,
			r.valoare_retinuta_pe_doc=(case when r.cod_beneficiar=cr.cod_sindicat then 0 else cr.val_retinuta_ant end)+cr.retinere_calculata+cr.ret_chitanta 
	from resal r
		inner join #calculret cr on cr.Data=r.Data and cr.Marca=r.Marca and cr.Cod_beneficiar=r.Cod_beneficiar and cr.Numar_document=r.Numar_document
	where r.data=@dataSus 

--	calcul rest de plata 
	update n 
		set rest_de_plata=venit_net-avans-premiu_la_avans-cm_incasat-co_incasat-suma_incasata-diferenta_impozit-debite_externe-rate-debite_interne-cont_curent
			+isnull(b.aj_deces,0)+(case when @ACorU_restpl=1 and @CAS_CorU=0 then isnull(u.Suma_corectie,0) else 0 end)
	from net n
		inner join #personalret p on p.marca=n.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'U-', '', '', 0) u on u.Data=n.Data and u.marca=n.marca
		left outer join #brutret b on b.data=n.data and b.marca=n.marca
	where n.data=@dataSus
			
	if object_id('tempdb..#pontaj_marca_locm') is not null drop table #pontaj_marca_locm
	if object_id('tempdb..#personalret') is not null drop table #personalret
	if object_id('tempdb..#brutret') is not null drop table #brutret
	if object_id('tempdb..#calculret') is not null drop table #calculret

	if exists (select * from sysobjects where name ='CalculRetineriSiRestPlataSP1')
		exec CalculRetineriSiRestPlataSP1 @dataJos, @dataSus, @marca, @lm

End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura CalculRetineriSiRestPlata (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

