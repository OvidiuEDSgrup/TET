--***
/**	procedura ce returneaza date pt. declaratia 205 */
Create procedure rapDeclaratia205 
	(@dataJos datetime, @dataSus datetime, @tipdecl int, @tipVenit varchar(100), @ticheteInVenitBrut int, 
	@contImpozit char(30), @contFactura char(30), @contImpozitDividende char(30), @lm char(9), @strict int=0, 
	@grupare char(2)='', @alfabetic int=1, @marca varchar(6)=null, @angajatiPrinDetasare int=null, @cnp varchar(13)=null, @sirDeMarci varchar(1000)=null)
as  
/*
	@grupare=1	-> grupare pe tipuri de venit
*/
Begin try
	set transaction isolation level read uncommitted
	declare @utilizator varchar(20), @lista_lm int, @luna int, @an int, @LunaAlfa varchar(15), @contImpozitAgricol varchar(30), --	cont impozit agricol setat la momentul generarii D112
		@CodSindicat char(13), @SindicatProcentual int, @ProcentSindicat float, @NuAsig_N int, 
		@Sub char(9), @vcif varchar(13), @cif varchar(13), @den char(200),
		@TotalBazaImpozit decimal(12), @TotalImpozit decimal(12), @tipVenitVanzareDeseuri char(2), @parXML xml

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	select @Sub=max(case when Parametru='SUBPRO' then Val_alfanumerica else '' end), 
		@vcif=max(case when Parametru='CODFISC' then Val_alfanumerica else '' end), 
		@den=max(case when Parametru='NUME' then Val_alfanumerica else '' end), 
		@contImpozitAgricol=max(case when Parametru='D112CIMAA' then Val_alfanumerica else '' end), 
		@SindicatProcentual=max(case when Parametru='SIND%' then Val_logica else 0 end),
		@ProcentSindicat=max(case when Parametru='SIND%' then Val_numerica else 0 end),
		@CodSindicat=max(case when Parametru='SIND%' then Val_alfanumerica else '' end), 
		@NuAsig_N=max(case when Parametru='NUASS-N' then Val_logica else 0 end)
	from par 
	where Tip_parametru='GE' and Parametru in ('SUBPRO','CODFISC','NUME') or Tip_parametru='PS' and Parametru in ('D112CIMAA','SIND%','NUASS-N')

	select @cif=ltrim(rtrim((case when left(upper(@vcif),2)='RO' then substring(@vcif,3,13)
		when left(upper(@vcif),1)='R' then substring(@vcif,2,13) else @vcif end)))
	select @luna=month(@dataSus), @an=year(@dataSus), @sirDeMarci=nullif(@sirDeMarci,'')

	set @parXML=(select @dataJos datajos, @dataSus datasus, @tipdecl tipdecl, @tipVenit tipvenit, @ticheteInVenitBrut ticheteinvenitbrut, @contImpozit contimpozit, @contFactura contfactura, 
		@contImpozitDividende contimpozitdiv, @lm lm, @strict strict, @marca marca for xml raw)

	if exists (select 1 from sysobjects where name='rapDeclaratia205SP' and xtype='P')
		exec rapDeclaratia205SP @parXML
	else 
	Begin
		set @parXML=(select @dataJos datajos, @dataSus datasus, 'LR' lunaApelare, @lm lm, @marca marca for xml raw)
		if object_id('tempdb..#impozit') is not null drop table #impozit
		if object_id('tempdb..#ticheteD205') is not null drop table #ticheteD205
		if object_id('tempdb..#sindicat') is not null drop table #sindicat

--	preluam date din istpers.detalii daca tabela are detalii
	if object_id('tempdb..#istpersdetalii') is not null 
		drop table #istpersdetalii
	create table #istpersdetalii (data datetime, marca varchar(6), tipsalar char(1))
	
	if exists (select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='istpers' and sc.name='detalii') 
		exec extragDetaliiIstpers @parXML=@parXML

--	daca apelam doar aici neconditionat de optiunea de mai jos (nu doar in procedura genDeclaratia205) atunci dadea mesaj de eroare (An INSERT EXEC statement cannot be nested)
		if object_id('tempdb..#net') is null 
		Begin
			select top 0 Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
				Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
				CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
				VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
			into #net from net where data between @datajos and @datasus
			create unique index [Data_Marca] ON #net (Data, Marca)
--	tabela #net se completeaza in procedura NetCuRectificari
--			insert into #net
			exec NetCuRectificari @parXML
		End
--	pun tichetele de insumat la venit brut in tabela temporara. Functioneaza mult mai rapid.
		select data, marca, valoare_tichete into #ticheteD205 from fDecl205Tichete (@dataJos, @dataSus) 
--	pun valoarea sindicatului deductibil in tabela temporara. Functioneaza mult mai rapid.
		select data, marca, SindicatDeductibil into #sindicat from fSindicatDeductibil (@dataJos, @dataSus) 

--	completez intr-o tabela temporara baza impozit/impozit 
--	mai intai se insereaza asiguratii care au realizat venituri din vanzare deseuri
--	primul select este pornit de la specificul Grupului RematInvest (au evidentiat impozitul direct pe receptie pe un alt cod cu minus)
--	(linia cu cod=IMPPF are in cantitate procentul de impozit si in campul pret de stoc are baza impozitului/100)
--	selectul de dupa primul union all se refera la cei care au evidentiat retinerea impozitului prin plata furnizor
--	tip_salar defineste locul de desfasurare al activitatii: 1 Salarii din Romania / 2 Salarii din strainatate
		create table #impozit 
			(data datetime, tip_venit char(2), tip_salar char(1), tip_impozit char(1), cnp varchar(13), nume varchar(200), tip_functie char(1), 
			venit_brut decimal(10), deduceri_personale decimal(10), deduceri_alte decimal(10), baza_impozit decimal(10), impozit decimal(10), venit_net decimal(10))
		set @tipVenitVanzareDeseuri=(case when @an>=2012 then '16' else '17' end)

		insert into #impozit
		select @dataSus, @tipVenitVanzareDeseuri, '' as tip_salar, '2', left(rtrim(t.Cod_fiscal),13), max(t.Denumire), '', 0, 0, 0, 
--	am tratat pentru Rematinvest 3 cazuri intrucat s-au generat 3 variante in pozdoc pt. impozit.
			round(sum(p.Pret_de_stoc*(case when cantitate=-1 then 100/16.00 when round(cantitate,2)=-0.16 then 1 else 100 end)),0), round(sum(ROUND(-p.Cantitate*p.Pret_de_stoc,2)),0), 0
		from pozdoc p
			left outer join terti t on p.Subunitate=t.Subunitate and p.Tert=t.Tert
		where (@tipVenit='' or charindex(@tipVenitVanzareDeseuri,@tipVenit)<>0) and p.Subunitate=@Sub and Data between @dataJos and @dataSus and p.Tip='RM'
			and (charindex(',',@contImpozit)=0 and p.Cont_de_stoc=@contImpozit or charindex(',',@contImpozit)<>0 and charindex(rtrim(p.Cont_de_stoc),@contImpozit)<>0)
			and (charindex(',',@contFactura)=0 and p.Cont_factura=@contFactura or charindex(',',@contFactura)<>0 and charindex(rtrim(p.Cont_factura),@contFactura)<>0)
			and @marca is null and @cnp is null and @sirDeMarci is null
		Group by t.Cod_fiscal
		union all 
		select @dataSus, @tipVenitVanzareDeseuri, '' as tip_salar, '2', left(rtrim(t.Cod_fiscal),13), max(t.Denumire), '', 0, 0, 0, 
			sum(f.Valoare), sum(p.Suma), 0
		from pozplin p
			left outer join terti t on p.Subunitate=t.Subunitate and p.Tert=t.Tert
			left outer join facturi f on f.Subunitate=p.Subunitate and f.Factura=p.Factura and f.Tert=p.Tert and f.Tip=0x54
		where (@tipVenit='' or charindex(@tipVenitVanzareDeseuri,@tipVenit)<>0) and p.Subunitate=@Sub and p.Data between @dataJos and @dataSus and p.Plata_incasare='PF'
			and p.Cont=@contImpozit and p.Cont_corespondent=@contFactura
			and @marca is null and @cnp is null and @sirDeMarci is null
		Group by t.Cod_fiscal
		union all
--	inserez asiguratii care au realizat venituri din activitati agricole - doar incepand cu veniturile anului 2012
		select @dataSus, '14', '' as tip_salar, '2', CNP, Nume, '', 0, 0, 0, Baza, Contributie, 0
		from fDecl112ActivAgricole (@dataJos, @dataSus, @lm, '', @contImpozitAgricol)
		where @an>=2012 and (@tipVenit='' or charindex('14',@tipVenit)<>0) and @marca is null and @sirDeMarci is null
		union all
--	inserez asiguratii care au realizat venituri din dividende
--	din analiza facuta a rezultat ca ar trebui sa incarcam in D205, contituirea impozitului pe dividende (repartizarea), adica creditarea lui 446
--	in acest caz impozitul=suma pozitie si baza se recalculeaza pornind de la impozit
		select @dataSus, '08', '' as tip_salar, '2', left(rtrim(t.Cod_fiscal),13), max(t.Denumire), '', 0, 0, 0, sum(round(p.Suma*100/16,0)), sum(p.Suma), 0
		from pozplin p
			left outer join terti t on p.Subunitate=t.Subunitate and p.Tert=t.Tert
		where (@tipVenit='' or charindex('08',@tipVenit)<>0) and p.Subunitate=@Sub and p.Data between @dataJos and @dataSus and p.Plata_incasare='PD' 
			and p.Tert<>'' and len(rtrim(t.Cod_fiscal))=13 and @contImpozitDividende<>'' 
			and (charindex(',',@contImpozitDividende)=0 and p.Cont=@contImpozitDividende or charindex(',',@contImpozitDividende)<>0 and charindex(rtrim(p.Cont),@contImpozitDividende)<>0)
			and @marca is null and @cnp is null and @sirDeMarci is null
		Group by t.Cod_fiscal
--	inserez asiguratii care au realizat venituri din conventii civile/drepturi de autor/expertiza contabila si tehnica
		union all
		select (case when @marca is null and @cnp is null then @dataSus else n.Data end), 
			(case when i.Tip_colab='DAC' then '01' when i.Tip_colab='CCC' then (case when @an>=2012 then '02' else '06' end) when i.Tip_colab='ECT' then '03' else '' end), '' as tip_salar, 
			(case when i.Tip_impozitare='8' then '1' else '2' end), p.Cod_numeric_personal, max(p.Nume) as Nume, '', 0, 0, 0, sum(n.Venit_baza), sum(n.Impozit+n.Diferenta_impozit), 
			sum(n.Venit_net)
		from #net n
			left outer join personal p on p.Marca=n.Marca
			left outer join istPers i on i.Data=n.Data and i.Marca=n.Marca
		where n.Data between @dataJos and @dataSus and n.Data=dbo.EOM(n.Data)
			and (@marca is null or n.Marca=@marca)
			and (@cnp is null or p.Cod_numeric_personal=@cnp)
			and (@sirDeMarci is null or charindex (','+rtrim (n.Marca)+',',rtrim(@sirDeMarci))<>0)
			and (isnull(@lm,'')='' or i.Loc_de_munca like rtrim(@lm)+(case when @strict=1 then '' else '%' end))
			and i.Grupa_de_munca in ('O','P') and i.Tip_colab in ('DAC','CCC','ECT')
			and ((@tipVenit='' or charindex('01',@tipVenit)<>0 or charindex('02',@tipVenit)<>0 or charindex('03',@tipVenit)<>0 or charindex('06',@tipVenit)<>0) and i.Tip_colab='DAC' 
				or (@tipVenit='' or charindex('06',@tipVenit)<>0 and @an<2012 or charindex('02',@tipVenit)<>0 and @an>=2012) and i.Tip_colab='CCC')
		group by (case when @marca is null and @cnp is null then @dataSus else n.Data end), p.Cod_numeric_personal, 
			(case when i.Tip_colab='DAC' then '01' when i.Tip_colab='CCC' then (case when @an>=2012 then '02' else '06' end) when i.Tip_colab='ECT' then '03' else '' end),
			(case when i.Tip_impozitare='8' then '1' else '2' end)
		union all
--	inserez, incepand cu veniturile anului 2012 salariatii cu contract de munca 
		select (case when @marca is null and @cnp is null then @dataSus else n.Data end), '07', isnull(id.tipsalar,'1') as tip_salar, '2', p.Cod_numeric_personal, max(p.Nume) as Nume, 
			(case when i.grupa_de_munca in ('N','C') and i.tip_colab='FDP' or charindex(i.grupa_de_munca,'OP')<>0 then '2' else '1' end), 
			sum(n.VENIT_TOTAL-(case when @NuAsig_N=0 then n.Suma_neimpozabila else 0 end)+(case when @ticheteInVenitBrut=1 then isnull(t.valoare_tichete,0) else 0 end)), 
			sum(n.Ded_baza), sum(isnull(n1.Ded_baza,0))+sum(isnull(s.SindicatDeductibil,0)), 
			sum((case when i.tip_impozitare<>'3' and i.grad_invalid not in ('1','2') then n.Venit_baza else 0 end)), sum(n.Impozit+n.Diferenta_impozit), 
			sum(n.venit_net)
		from #net n
			left outer join personal p on p.Marca=n.Marca
			left outer join istPers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join #istpersdetalii id on id.data=n.data and id.marca=n.marca
			left outer join #net n1 on n1.Data=dbo.bom(n.Data) and n1.Marca=n.Marca
			left outer join #sindicat s on s.Data=n.Data and s.Marca=n.Marca
			left outer join #ticheteD205 t on t.data=n.Data and t.marca=n.marca and @ticheteInVenitBrut=1
		where n.Data between @dataJos and @dataSus and n.Data=dbo.EOM(n.Data)
			and (@marca is null or n.Marca=@marca) 
			and (@cnp is null or p.Cod_numeric_personal=@cnp)
			and (@sirDeMarci is null or charindex (','+rtrim (n.Marca)+',',rtrim(@sirDeMarci))<>0)
			and (isnull(@lm,'')='' or i.Loc_de_munca like rtrim(@lm)+(case when @strict=1 then '' else '%' end))
			and (year(@dataSus)>=2013 or isnull(@angajatiPrinDetasare,0)=0 and isnull(i.Mod_angajare,'')<>'R' or isnull(@angajatiPrinDetasare,0)=1 and i.Mod_angajare='R')
			and @an>=2012 and (@tipVenit='' or charindex('07',@tipVenit)<>0) and not(i.Tip_colab in ('DAC','CCC','ECT') and i.Grupa_de_munca in ('O','P'))
		group by (case when @marca is null and @cnp is null then @dataSus else n.Data end), p.Cod_numeric_personal, isnull(id.tipsalar,'1'), 
			(case when i.grupa_de_munca in ('N','C') and i.tip_colab='FDP' or charindex(i.grupa_de_munca,'OP')<>0 then '2' else '1' end)
		union all
--	inserez, incepand cu veniturile anului 2012 impozitul aferent zilierilor
		select (case when @marca is null and @cnp is null then @dataSus else dbo.EOM(s.Data) end), '07', '1' as tip_salar, '2', z.Cod_numeric_personal, max(z.Nume) as Nume, '2', 
			sum(s.Venit_total), 0, 0, sum(s.Venit_total), sum(s.Impozit), sum(s.Venit_total-s.Impozit)
		from SalariiZilieri s
			left outer join Zilieri z on s.Marca=z.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=s.loc_de_munca
		where s.Data between @dataJos and @dataSus and (@marca is null or s.Marca=@marca)
			and (@cnp is null or z.Cod_numeric_personal=@cnp)
			and (@sirDeMarci is null or charindex (','+rtrim (s.Marca)+',',rtrim(@sirDeMarci))<>0)
			and (isnull(@lm,'')='' or s.Loc_de_munca like rtrim(@lm)+(case when @strict=1 then '' else '%' end))
			and @an>=2012 and (@tipVenit='' or charindex('07',@tipVenit)<>0)
			and (@lista_lm=0 or lu.cod is not null) 
		group by (case when @marca is null and @cnp is null then @dataSus else dbo.EOM(s.Data) end), z.Cod_numeric_personal
		union all
--	inserez date NEGESTIONATE in ASiS pe parcursul anului
		select @dataSus, d.tip_venit, (case when d.tip_venit='07' then '1' else '' end) as tip_salar, d.tip_impozit, isnull(p.Cod_numeric_personal,d.cnp), isnull(p.nume,d.nume), 
			tip_functie, venit_brut, deduceri_personale, deduceri_alte, baza_impozit, impozit, 0
		from DateD205 d
			left outer join personal p on p.Marca=d.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=d.loc_de_munca
		where An=@an and @an>=2012 and (@marca is null or p.Marca=@marca)
			and (isnull(@lm,'')='' or p.Loc_de_munca like rtrim(@lm)+(case when @strict=1 then '' else '%' end))
			and (@tipVenit='' or charindex(d.Tip_venit,@tipVenit)<>0)
			and (@cnp is null or p.Cod_numeric_personal=@cnp or d.CNP=@cnp)
			and (@sirDeMarci is null or charindex (','+rtrim (d.Marca)+',',rtrim(@sirDeMarci))<>0)
			and (@lista_lm=0 or lu.cod is not null) 

		if exists (select 1 from sysobjects where name='rapDeclaratia205SP1' and xtype='P')
			exec rapDeclaratia205SP1 @parXML

		delete from #impozit where CNP in (select CNP from #impozit group by CNP having SUM(venit_brut+deduceri_personale+deduceri_alte+baza_impozit+Impozit)=0)
		update #impozit set deduceri_alte=0 where tip_venit='07' and tip_functie='2'

		select @TotalBazaImpozit=sum(Baza_impozit), @TotalImpozit=sum(Impozit) from #impozit
		where (@tipVenit='' or Tip_venit=@tipVenit)
		select @TotalBazaImpozit=isnull(@TotalBazaImpozit,0), @TotalImpozit=isnull(@TotalImpozit,0)

--		inserez total general ca header fisier (prima linie din fisierul exportat)
		select @dataSus as data, '' as tip_venit, '' as denumire, 0 as nr_ben, '' as tip_salar, '' as tip_impozit, @cif as cnp, @den as nume, '' as tip_functie, 
			0 as venit_brut, 0 as deduceri_personale, 0 as deduceri_alte, @TotalBazaImpozit as baza_impozit, @TotalImpozit as impozit, 0 as venit_net, 
			convert(char(4),@an)+','+(case when @tipdecl=0 then '1' else '2' end)
			+','+rtrim(@cif)+',0,0,,,'+rtrim(convert(char(12),CONVERT(decimal(12),@TotalBazaImpozit)))
			+','+rtrim(convert(char(12),CONVERT(decimal(12),@TotalImpozit))) as detalii, @den as ordonare
		where @an<2012
		union all
--		inserez datele finale prelucrate
		select Data, a.Tip_venit, max(tv.denumire) as denumire, count(1) as nr_ben, (case when @grupare='' then tip_salar else '' end), 
			(case when @grupare='' then tip_impozit else '' end), (case when @grupare='' then CNP else '' end) as cnp, max(Nume) as nume, 
			(case when @grupare='' then tip_functie else '' end) as tip_functie, 
			sum(Venit_brut) as Venit_brut, sum(Deduceri_personale) as Deduceri_personale, sum(Deduceri_alte) as Deduceri_alte, sum(Baza_impozit) as Baza_impozit, sum(impozit) as impozit, sum(venit_net) as venit_net, 
			rtrim(a.tip_venit)+','+rtrim((case when @grupare='' then tip_impozit else '' end))+','+rtrim((case when @grupare='' then CNP else '' end))
				+',0,0,,,'+rtrim(convert(char(10),sum(Baza_impozit)))+','+rtrim(convert(char(10),sum(Impozit))),
			max((case when @alfabetic=1 then nume else cnp end)) as ordonare
		from #impozit a
			left outer join fTipVenitD205() tv on tv.tip_venit=a.tip_venit
		Group by Data, a.Tip_venit, 
			(case when @grupare='' then CNP else '' end), 
			(case when @grupare='' then tip_salar else '' end), 
			(case when @grupare='' then tip_impozit else '' end), 
			(case when @grupare='' then tip_functie else '' end)
		order by Tip_venit, tip_salar, ordonare

		if object_id('tempdb..#net') is not null drop table #net
		if object_id('tempdb..#impozit') is not null drop table #impozit
		if object_id('tempdb..#ticheteD205') is not null drop table #ticheteD205
		if object_id('tempdb..#sindicat') is not null drop table #sindicat
		if object_id('tempdb..#istPersdetalii') is not null drop table #istPersdetalii
	End
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapDeclaratia205 (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapDeclaratia205 '01/01/2012', '12/31/2012', 0, '07', 0, '','', '', null, 0, '', 1, null, null, '1880107203671'
*/
