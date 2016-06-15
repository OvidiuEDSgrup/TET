/* procedura pt. raportul WEB Contributii salariale */
Create procedure ContributiiSalarii 
	@datajos datetime, @datasus datetime, @locm varchar(9)=null, @marca varchar(6)=null, @tippersonal char(1)=null, @scriu_diez int=0
AS
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#contributii') is not null drop table #contributii
	if object_id('tempdb..#net') is not null drop table #net
	if object_id('tempdb..#brut') is not null drop table #brut
	if object_id('tempdb..#ImpozitPL') is not null drop table #ImpozitPL

	declare @NCCnph int, @AjDecesUnit int, @userASiS char(10), @lmjos varchar(9), @lmsus varchar(9), @marcajos varchar(6), @marcasus varchar(6), @ImpozitPL int

	set @NCCnph=dbo.iauParL('PS','NC-CPHAND')
	set @AjDecesUnit=dbo.iauParL('PS','AJDUNIT-R')
	set @ImpozitPL=dbo.iauParL('PS','D112IMZPL')
	set @userASiS=dbo.fIaUtilizator(null)
	set @lmjos=(case when @locm is null then '' else @locm end)
	set @lmsus=(case when @locm is null then 'ZZZ' else rtrim(@locm)+'ZZZ' end)
	set @marcajos=(case when @marca is null then '' else @marca end)
	set @marcasus=(case when @marca is null then 'ZZZ' else @marca end)
		
	create table #contributii
	(grupa int, ordered int, data datetime, contributie varchar(200), baza_de_calcul float, procent float, valoare_contributie float, nr_salariati int)

	create table #ImpozitPL (Data datetime, CodFiscal char(13), idCodFiscal int, Sediu char(2), Impozit decimal(10))

	select n.* 
	into #net 
	from net n
		left outer join istPers i on i.Data=dbo.EOM(n.data) and i.Marca=n.Marca
	where n.Data between @datajos and @datasus
		and (@locm is null or n.Loc_de_munca like rtrim(@locm)+'%')
		and (@marca is null or n.Marca=@marca)
		and (@tipPersonal is null or (@tipPersonal='T' and i.tip_salarizare in ('1','2')) or (@tipPersonal='M' and i.tip_salarizare in ('3','4','5','6','7')))
		and (dbo.f_areLMFiltru(@userASiS)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@userASiS and l.cod=n.loc_de_munca))

	select b.Data, b.Marca, sum(b.Venit_total) as Venit_total, sum(Compensatie) as Compensatie, 
		sum(ind_c_medical_unitate+CMunitate) as cm_unitate, 
		sum(ind_c_medical_cas+cmcas) as cm_fnuass,
		sum(spor_cond_9) as cm_faambp,
		sum(ind_c_medical_cas+cmcas+spor_cond_9) as cm_fonduri 
	into #brut 
	from brut b
		left outer join istPers i on i.Data=b.data and i.Marca=b.Marca
	where b.Data between @datajos and @datasus
		and (@locm is null or i.Loc_de_munca like rtrim(@locm)+'%')
		and (@marca is null or b.Marca=@marca)
		and (@tipPersonal is null or (@tipPersonal='T' and i.tip_salarizare in ('1','2')) or (@tipPersonal='M' and i.tip_salarizare in ('3','4','5','6','7')))
		and (dbo.f_areLMFiltru(@userASiS)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@userASiS and l.cod=i.loc_de_munca))
	Group by b.Data, b.Marca	

	insert into #ImpozitPL
	exec Declaratia112Impozit @dataJos, @dataSus, @ImpozitPL, @locm

	while (@datajos<=@datasus)
	begin 
		declare @datalunii1 datetime, @datalunii datetime
		set @datalunii1=dbo.bom(@datajos)
		set @datalunii=dbo.eom(@datajos)
		 
		insert into #contributii (grupa, ordered, data, contributie, baza_de_calcul, procent, valoare_contributie, nr_salariati)
		select 1, 1, @datalunii, 'Impozit salarii', isnull(sum(VENIT_BAZA),0), '16', isnull(sum(impozit+Diferenta_impozit),0),0 as nr_asigurati
		from #net where data = @datalunii and loc_de_munca not like 'CST'
		union
		select 1, 2, @datalunii, 'Impozit consiliu adm.', isnull(sum(VENIT_BAZA),0) as impozit, '16', isnull(sum(impozit+Diferenta_impozit),0) as impozit, 0 as nr_asigurati
		from #net
		where data = @datalunii and loc_de_munca like 'CST'
		union
		select 1, 3, @datalunii, 'Impozit zilieri', isnull(sum(s.Venit_total),0), '16', isnull(sum(s.impozit),0), 0 as nr_asigurati
		from SalariiZilieri s
			left outer join Zilieri z on z.marca=s.marca  
		where Data between @datalunii1 and @datalunii
			and (dbo.f_areLMFiltru(@userASiS)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@userASiS and l.cod=z.Loc_de_munca))
		union
		select 1, 4, @datalunii, ' cod fiscal '+(case when Sediu='P' then 'sediu' else 'punct de lucru' end)+' '+CodFiscal, 0, '16', isnull(i.impozit,0), 0 as nr_asigurati
		from #impozitPL i
		where exists (select 1 from #ImpozitPL where Sediu='S')
		union 
		select 3 as grupa, 1 as ordered, @datalunii, 'CAS ANGAJATI' as contributie, 
			isnull((select sum(baza_CAS)from #net where data = @datalunii),0) as baza_de_calcul, 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASINDIV') as procent,
			isnull((select sum(pensie_suplimentara_3) from #net where data = @datalunii),0) as valoare_contributie, --CAS angajati
			(select count(1) from #net where data = @datalunii) as nr_asigurati
		union
		select 4 as grupa, 1, @datalunii, 'CAS angajator - conditii normale', 
			isnull((select sum(n1.Baza_CAS_cond_norm) 
				from #net n1 
					left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data) where n1.data = @datalunii),0), 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASGRUPA3')-
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASINDIV'), 
			isnull((select sum(n1.cas) from #net n1 
				left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data)
			where n1.data = @datalunii and n1.Baza_CAS_cond_norm != 0),0),
			0 as nr_asigurati
		union
		select 4 as grupa, 2, @datalunii, 'CAS angajator - conditii deosebite', 
			(select sum(n1.Baza_CAS_cond_deoseb) 
				from #net n1 
					left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data) where n1.data = @datalunii), 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASGRUPA2')-
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASINDIV'), 
			isnull((select sum(n1.cas) from #net n1 
				left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data)
			where n1.data = @datalunii and n1.Baza_CAS_cond_deoseb != 0),0),
			0 as nr_asigurati
		union 
		select 4 as grupa, 3, @datalunii, 'CAS angajator - conditii speciale', 
			(select sum(n1.Baza_CAS_cond_spec) 
				from #net n1 
					left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data) where n1.data = @datalunii), 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASGRUPA1')-
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASINDIV'), 
			isnull((select sum(n1.cas) from #net n1 
				left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data)
			where n1.data = @datalunii and n1.Baza_CAS_cond_spec != 0),0),
			0 as nr_asigurati
		union
		select 4 as grupa, 4, @datalunii, 'CAS angajator pt. zile de concediu medical', 
			(select sum(Baza_CAS_cond_norm) from #net where data = @datalunii1), '' ,
			(select sum(CAS) from #net where data = @datalunii1),
			0 as nr_asigurati
		union 
		select 4 as grupa, 5, @datalunii, 'Ajutor de deces din CAS', '', '', 
		-isnull((select sum(compensatie) from #brut where Data=@datalunii and @AjDecesUnit=0),0), 
		0 as nr_asigurati
		union
		select 5 as grupa, 1, @datalunii, 'Carti de munca angajator', 
			(select sum(Baza_CAS_cond_norm) from #net where data = @datalunii), '0.75',
			(select sum(camera_de_munca_1) from #net where data = @datalunii), 
			0 as nr_asigurati
		union
		select 6, 1, @datalunii, 'Fond sanatate angajator', 
			(select sum(b.Venit_total-b.cm_fonduri) 
				from #brut b 
					left outer join #net n on n.Data=b.Data and n.Marca=b.Marca
				where b.data = @datalunii and n.Loc_de_munca not like 'CST'),
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASSUNIT'),
			(select sum(asig_sanatate_pl_unitate) from #net where data = @datalunii and loc_de_munca not like 'CST'),
			0 as nr_asigurati
		union
		select 6, 2, @datalunii, 'Fond sanatate angajator consiliu adm.', 
			isnull((select sum(b.Venit_total-b.cm_fonduri) 
				from #brut b 
					left outer join #net n on n.Data=b.Data and n.Marca=b.Marca
				where b.data = @datalunii and n.Loc_de_munca like 'CST'),0),			
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASSUNIT'),
			isnull((select sum(asig_sanatate_pl_unitate) from #net where data = @datalunii and loc_de_munca like 'CST'),0),
			0 as nr_asigurati
		union
		select 7, 1, @datalunii, 'Fond sanatate asigurati', 
			(select sum((case when n.Asig_sanatate_din_net<>0 then n.Asig_sanatate_din_net else b.venit_total-(b.cm_fonduri+b.cm_unitate) end))
				from #brut b
					inner join personal p on b.marca = p.marca
					inner join #net n on n.marca = b.marca and n.Data=@datalunii1
				where b.data = @datalunii and n.loc_de_munca not like 'CST' and p.as_sanatate != 0), 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASSIND'),
			(select sum(asig_sanatate_din_impozit) + sum(asig_sanatate_din_net)	from #net where data = @datalunii and loc_de_munca not like 'CST'),
			0 as nr_asigurati
		union
		select 7, 2, @datalunii, 'Fond sanatate asigurati consiliu adm.',
			isnull((select sum((case when n.Asig_sanatate_din_net<>0 then n.Asig_sanatate_din_net else b.venit_total-(b.cm_fonduri+b.cm_unitate) end))
				from #brut b
					inner join personal p on b.marca = p.marca
					inner join #net n on n.marca = b.marca and n.Data=@datalunii1
				where b.data = @datalunii and n.loc_de_munca like 'CST' and p.as_sanatate != 0),0), 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='CASSIND'),
			isnull((select sum(asig_sanatate_din_impozit) + sum(asig_sanatate_din_net) from #net where data = @datalunii and loc_de_munca like 'CST'),0),
			0 as nr_asigurati
		union
		select 8, 1, @datalunii, 'Fond somaj angajati',
			(select sum(Asig_sanatate_din_CAS) 
				from #net n 
					left outer join personal p on n.Marca=p.Marca
				where n.data = @datalunii and n.somaj_1<>0), --Fond somaj angajati 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='SOMAJIND'),
			(select sum(somaj_1) from #net where data = @datalunii),
		0 as nr_asigurati 
		union
		select 9, 1, @datalunii, 'Fond somaj angajator', 
			(select sum(Asig_sanatate_din_CAS) from #net where data = @datalunii and somaj_5<>0), --Fond somaj angajator
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='3.5%SOMAJ'), 
			(select sum(somaj_5) from #net where data = @datalunii),
			0 as nr_asigurati
		union
		select 9, 3, @datalunii, 'Scutire somaj',	0, 0,
			-isnull((select round(sum(isnull(Scutire_art80,0)),0)+round(sum(isnull(Scutire_art85,0)),0) from dbo.fScutiriSomaj (@dataJos, @datalunii, @marcajos, @marcasus, @lmjos, @lmsus)),0),
			0 as nr_asigurati 
		union
		select 9, 4, @datalunii, 'Subventie somaj',	0, 0,
			-(select sum(n.Chelt_prof) from #net n left outer join personal p on p.Marca=n.Marca where data = @datalunii and p.coef_invalid in ('1','2','3','4','7','8','9')),
			0 as nr_asigurati 
		union
		select 10, 1, @datalunii, 'Fond accidente de munca si boli profesionale',
			(select sum(n.Baza_CAS_cond_norm+n.Baza_CAS_cond_deoseb+n.Baza_CAS_cond_spec+
					(case when year(n.data)>2011 then n1.Asig_sanatate_din_CAS else n1.Baza_CAS_cond_norm+n1.Baza_CAS_cond_deoseb+n1.Baza_CAS_cond_spec end)) 
				from #net n
					left outer join #net n1 on n1.Data=@datalunii1 and n1.Marca=n.Marca
				where n.Data = @datalunii and n.Fond_de_risc_1<>0), --Fond accidente
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='0.5%ACCM'),
			(select sum(fond_de_risc_1) from #net where data = @datalunii),
			0 as nr_asigurati
		union
		select 10, 2, @datalunii, 'Sanatate din FAAMBP', '', '', 
			-(select sum(asig_sanatate_din_impozit) from #net where data = @datalunii),
			0 as nr_asigurati
		union
		select 10, 3, @datalunii, 'Contributie concedii si indemnizatii din FAAMBP', '', '', 
			-(select sum(ded_suplim) from #net where data = @datalunii1),
			0 as nr_asigurati
		union
		select 10, 4, @datalunii, 'Indemnizatie CM din FAAMBP', '', '',
			-isnull((select sum(cm_faambp) from #brut where data = @datalunii),0),
			0 as nr_asigurati
		union
		select 11, 1, @datalunii, 'Contributie concedii si indemnizatii', 
			(select sum(Baza_CAS) from #net	where data = @datalunii1), --Fond medicale
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='COTACCI'),
			(select sum(n1.ded_suplim) + sum(n2.ded_suplim) from #net n1 
				left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data)
			where n1.data = @datalunii),
			0 as nr_asigurati
		union
		select 11, 2, @datalunii, 'Indemnizatie concedii medicale din FNUASS', '', '',
			-isnull((select sum(cm_fnuass) from #brut where data = @datalunii),0),
		0 as nr_asigurati
		/*union
		select 10, 3, 'Fond medicale de virat/recuperat', '', '',
		(select (sum(n1.ded_suplim) + sum(n2.ded_suplim)) - sum(b.cm_CAS) from #net n1 
		left outer join #net n2 on n1.marca=n2.marca and n2.data=dbo.bom(n1.data)
		left outer join (select data,marca,sum(ind_c_medical_cas) as cm_cas 
		from brut group by data,marca) b on b.marca=n1.marca and b.data=n1.data
		where n1.data = @datalunii)*/
		union
		select 12, 1, @datalunii, 'Fond garantare creante salariale',
			(select sum((case when n.CM_incasat<>0 then n.CM_incasat else b.venit_total-b.cm_fonduri end)) 
				from #net n
					left outer join #brut b on b.Marca=n.Marca
				where n.data = dbo.bom(@datalunii) and n.Somaj_5<>0), --Fond garantare creante salariale 
			(select Val_numerica from par_lunari where data = @datalunii and tip='PS' and Parametru='FONDGAR'), 
			(select sum(somaj_5) from #net where data = @datalunii1),
			0 as nr_asigurati
		union
		select 13, 1, @datalunii, 'Fond neangajare persoane cu handicap', '', '', 
			isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'CPH'+'%'
				and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
				and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102))=@datalunii),0),
			0 as nr_asigurati

		delete from #contributii where grupa=1 and ordered=3 and valoare_contributie=0 and data=@datalunii
		insert into #contributii (grupa, ordered, data, contributie, baza_de_calcul, procent, valoare_contributie, nr_salariati)
		select 2, 1, @datalunii, 'Total contributii sociale', 0, 0, sum((case when a.valoare_contributie<0 then 0 else a.valoare_contributie end)), 0
		from (select grupa, data, sum(valoare_contributie) as valoare_contributie from #contributii where Data=@datalunii and grupa>1 and grupa<13 group by data, grupa) a

		set @datajos = dateadd(m,1,@datajos)
	end

	alter table #contributii add den_grupa varchar(100) 
	update #contributii set den_grupa=(case when grupa=1 then 'TOTAL IMPOZIT' when grupa=2 then 'TOTAL CONTRIBUTII SOCIALE' 
			when grupa=3 then 'CAS ANGAJATI' when grupa=4 then 'CAS DE VIRAT'
			when grupa=5 then 'CARTI DE MUNCA ANGAJATOR' when grupa=6 then 'TOTAL SANATATE ANGAJATOR DE VIRAT' when grupa=7 then 'TOTAL SANATATE ANGAJATI DE VIRAT'
			when grupa=8 then 'FOND SOMAJ ASIGURATI' when grupa=9 then 'FOND SOMAJ ANGAJATOR' when grupa=10 then 'FOND ACCIDENTE DE VIRAT' 
			when grupa=11 then 'FOND CONTRIBUTII CONCEDII SI INDEMNIZATII' when grupa=12 then 'FOND DE GARANTARE CREANTE SALARIALE' 
			when grupa=13 then 'FOND PERSOANE CU HANDICAP' else '' end)

	if @scriu_diez=1 and object_id('tempdb..#contribsal') is not null
		insert into #contribsal
		select grupa, den_grupa, ordered, data, contributie, baza_de_calcul, procent, valoare_contributie, nr_salariati 
		from #contributii
		where contributie not like '%adm%' and contributie<>'Carti de munca angajator' or valoare_contributie<>0
	else
		select grupa, den_grupa, ordered, data, contributie, baza_de_calcul, procent, valoare_contributie, nr_salariati 
		from #contributii
		where contributie not like '%adm%' and contributie<>'Carti de munca angajator' or valoare_contributie<>0
		order by grupa, ordered
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura ContributiiSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#contributii') is not null drop table #contributii
if object_id('tempdb..#net') is not null drop table #net
if object_id('tempdb..#brut') is not null drop table #brut

/*
	exec as login='cluj\lucian'
	exec ContributiiSalarii '05/01/2013', '05/31/2013', null
*/
