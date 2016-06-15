/**	procedura pentru calcul sindicat **/
Create procedure CalculSindicat
	@dataJos datetime, @dataSus datetime, @marca char(6)=null, @lm char(9)=null
As
Begin try
	declare @OreLuna float, @ARLCJ int, @cCodSindicat char(13), @lSindVBrut int, @lSindProc int, @nProcSind float, @NuDPSH int
	
	Exec Luare_date_par 'SP', 'ARLCJ', @ARLCJ OUTPUT, 0, 0
	Exec Luare_date_par 'PS', 'SIND%', @lSindProc OUTPUT, @nProcSind OUTPUT, @cCodSindicat OUTPUT
	Exec Luare_date_par 'PS', 'SINDVBRUT', @lSindVBrut OUTPUT, 0, 0
	Set @NuDPSH=dbo.iauParL('PS','NUDPSH')
	Set @OreLuna = dbo.iauParLN(@dataSus,'PS','ORE_LUNA')

	if @marca is null set @marca=''
	if @lm is null set @lm=''

	set transaction isolation level read uncommitted
	if object_id('tempdb..#codsindicat') is not null drop table #codsindicat
	if object_id('tempdb..#calcsind') is not null drop table #calcsind

--	selectez codul de sindicat exceptie, valabil pentru luna calculului de salarii
	select * into #codsindicat from 
	(select Data_inf, Marca, Cod_inf, Val_inf, Procent, RANK() over (partition by Marca order by Data_inf Desc) as ordine
	from extinfop where Cod_inf='SINDICAT' and Data_inf<=@dataSus and Val_inf<>'') a
	where Ordine=1

	if @cCodSindicat='' and @nProcSind=0 
			and not exists (select 1 from #codsindicat)
			and not exists (select 1 from personal where sindicalist=1 and (@lm='' or loc_de_munca between rtrim(@lm) and rtrim(@lm)+'ZZZ'))
		return

--	sterg retinerile generate anterior
	delete r
	from resal r
		left outer join personal p on p.Marca=r.Marca
--	aici nu apelez tabela #codsindicat ci extinfop: pt. a sterge eventuale retineri generate anterior pe alte coduri de beneficiar sindicat
		left outer join extinfop e on e.Marca=r.Marca and e.Cod_inf='SINDICAT' and e.Val_inf<>''
	where r.Data=@dataSus 
		and r.Cod_beneficiar=isnull(e.Val_inf,@cCodSindicat) and isnull(e.Val_inf,@cCodSindicat)<>''
		and (@marca='' or r.marca=@marca) 
		and (@lm='' or p.loc_de_munca between rtrim(@lm) and rtrim(@lm)+'ZZZ')
		and Numar_document='SINDICAT'
		and (exists (select m.marca from conmed m where m.data_inceput between @dataJos and @dataSus and m.tip_diagnostic='0-' and m.Marca=p.marca
			group by m.marca having sum(m.zile_lucratoare)=max(m.zile_lucratoare_in_luna)) or Data_document=@dataSus and Valoare_totala_pe_doc=Retinere_progr_la_lichidare)

--	pun intr-o tabela temporara datele pt. calcul
	Select p.marca, p.salar_de_incadrare as SalarIncadrare, p.sindicalist, 
	(case when r.RetinereProgr is not null then 1 else 0 end) as ExistaRet, isnull(r.RetinereProgr,0) as RetinereProgr, isnull(r.ProcentProgr,0) as ProcRetinere,
	(case when ra.RetinereProgrAnt is not null then 1 else 0 end)  as ExistaRetinereAnt, isnull(ra.RetinereProgrAnt,0) as RetinereProgrAnt, isnull(ra.RetinutLichidareAnt,0) as RetinereEfectAnt,
	isnull(b.venit_total-(case when @NuDPSH=1 then b.sume_exceptate else 0 end),0) as VenitTotal, 
	isnull(b.ore_lucrate_regim_normal+(case when isnull(substring(br.cod_fiscal,10,1),'')='4' then b.ore_nelucrate else 0 end),0) as OreLucrate, 
	(case when p.Grupa_de_munca='C' and p.Salar_lunar_de_baza<>0 then p.Salar_lunar_de_baza else 8 end) as RegimLucru, 
	isnull(e.Val_inf,@cCodSindicat) as cod_sindicat, 
	(case when isnull(e.Val_inf,'')<>'' and isnull(e.Procent,0)<>0 then isnull(e.Procent,0) else @nProcSind end) as procentSindicat,
	isnull(substring(br.cod_fiscal,10,1),'') as ModCalcul,
	(case when charindex('SUMA',upper(isnull(v.Descriere,'')))<>0 then 1 else 0 end) as SindExcSuma, 
	(case when ms.Data_inf is not null 
		then round(isnull(i.Salar_de_incadrare,p.Salar_de_incadrare)/@OreLuna*dbo.zile_lucratoare(@dataJos,ms.Data_inf-1)
			*(case when p.Grupa_de_munca='C' and p.Salar_lunar_de_baza<>0 then p.Salar_lunar_de_baza else 8 end),0)
			+round(p.Salar_de_incadrare/@OreLuna*dbo.zile_lucratoare(ms.Data_inf,@dataSus)*(case when p.Grupa_de_munca='C' and p.Salar_lunar_de_baza<>0 then p.Salar_lunar_de_baza else 8 end),0) 
		else 0 end) as SalarIncadrareMediu,
	0 as ValSindicat
	into #calcsind
	from personal p 
		left outer join #codsindicat e on e.Marca=p.Marca 
		left outer join valinfopers v on v.Cod_inf=e.Cod_inf and v.Valoare=e.Val_inf
		left outer join istPers i on i.Data=DateAdd(DAY,-1,@dataJos) and i.Marca=p.Marca
		left outer join extinfop ms on ms.Marca=p.marca and ms.Cod_inf='SALAR' and ms.Data_inf between @dataJos and @dataSus and ms.Procent>1
		outer apply (select marca, max(Retinere_progr_la_lichidare) as RetinereProgr, max(Procent_progr_la_lichidare) as ProcentProgr
			from resal where data=@dataSus and marca=p.marca and cod_beneficiar=isnull(e.Val_inf,@cCodSindicat) and (p.sindicalist=0 or numar_document='SINDICAT') group by marca) r
		outer apply (select marca, max(Retinere_progr_la_lichidare) as RetinereProgrAnt, max(Retinut_la_lichidare) as RetinutLichidareAnt
			from resal where data=dateadd(day,-1,@dataJos) and marca=p.marca and cod_beneficiar=isnull(e.Val_inf,@cCodSindicat) and (p.sindicalist=0 or numar_document='SINDICAT') group by marca) ra
		left outer join benret br on br.cod_beneficiar=isnull(e.Val_inf,@cCodSindicat)
		outer apply (select marca, sum(venit_total) as venit_total, sum(Suma_impozabila+Suma_imp_separat+Cons_admin) as sume_exceptate, 
			sum(ore_lucrate_regim_normal) as ore_lucrate_regim_normal, sum(ore_concediu_de_odihna+ore_obligatii_cetatenesti) as ore_nelucrate
				from brut where data=@datasus and Marca=p.Marca group by marca) b
	where (@marca='' or p.marca=@marca) 
		and (@lm='' or p.loc_de_munca between rtrim(@lm) and rtrim(@lm)+'ZZZ')
		and p.data_angajarii_in_unitate<=@dataSus 
		and not(p.loc_ramas_vacant=1 and (@dataSus>dbo.eom(p.Data_plec) or p.data_plec=@dataJos))
		and not exists (select m.marca from conmed m where m.data_inceput between @dataJos and @dataSus and m.tip_diagnostic='0-' and m.Marca=p.marca
			group by m.marca having sum(m.zile_lucratoare)=max(m.zile_lucratoare_in_luna)) 
	order by p.marca

--	sterg mai intai retinerea generata anterior pt. salariati care nu mai sunt sindicalisti
	delete r
	from resal r
		inner join #calcsind c on r.Marca=c.Marca
	where data=@dataSus and r.numar_document='SINDICAT'
		and (r.cod_beneficiar=c.cod_sindicat and c.sindicalist=0 or r.cod_beneficiar=@cCodSindicat and @cCodSindicat<>c.cod_sindicat and c.sindicalist=1)

--	calculez valoarea sindicatului conform setarilor
	update #calcsind
		set ValSindicat = round((case when sindicalist=1 
			then (case when @lSindProc=0 or SindExcSuma=1 then procentSindicat 
					else round((case when @Arlcj=1 or @lSindVBrut=1 and cod_sindicat=@cCodSindicat or cod_sindicat<>@cCodSindicat and ModCalcul='5' 
						then VenitTotal 
						else (case when SalarIncadrareMediu<>0 then SalarIncadrareMediu else SalarIncadrare end)
								*(case when ModCalcul in ('3','4') then OreLucrate/(@OreLuna/8*RegimLucru) else 1 end) end)*procentSindicat/100,2) 
				end)+(case when ExistaRetinereAnt>0 and RetinereProgrAnt-RetinereEfectAnt>0 then RetinereProgrAnt-RetinereEfectAnt else 0 end) 
			else (case when ExistaRet>0 and ProcRetinere<>0 then SalarIncadrare*(case when ModCalcul in ('3','4') then OreLucrate/(@OreLuna/8*RegimLucru) else 1 end)*ProcRetinere/100 else 0 end) end),0)

--	pun in resal, retinerile de tip sindicat (daca exista din calcule anterioare)
	update r set r.Valoare_totala_pe_doc=c.ValSindicat, r.Retinere_progr_la_lichidare=c.ValSindicat
	from resal r 
		inner join #calcsind c on c.Marca=r.Marca and r.cod_beneficiar=c.cod_sindicat
	where data=@dataSus and c.ExistaRet>0 and not(c.sindicalist=0 and c.RetinereProgr<>0 and c.ProcRetinere=0)
		and (c.sindicalist=0 or r.numar_document='SINDICAT') and not(c.sindicalist=0 and c.ProcRetinere<>0)

	update r set r.retinut_la_lichidare=c.ValSindicat
	from resal r
		inner join #calcsind c on c.Marca=r.Marca and r.cod_beneficiar=c.cod_sindicat
	where data=@dataSus and c.ExistaRet>0 and not(c.sindicalist=0 and c.RetinereProgr<>0 and c.ProcRetinere=0)
		and (c.sindicalist=0 or r.numar_document='SINDICAT')

--	inserare retineri sindicat
	insert into resal (Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, 
		Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
	select @dataSus, marca, cod_sindicat, 'SINDICAT', @dataSus, ValSindicat, 0, 0, ValSindicat, 0, 0, ValSindicat
	from #calcsind
	where ExistaRet=0 and sindicalist=1 and procentSindicat<>0

	if exists (select 1 from sysobjects where [type]='P' and [name]='calcul_sindicatSP')
		exec calcul_sindicatSP @dataJos, @dataSus, @marca, @lm

	if object_id('tempdb..#codsindicat') is not null drop table #codsindicat
	if object_id('tempdb..#calcsind') is not null drop table #calcsind
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura CalculSindicat (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

