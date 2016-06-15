--***
/**	proc. pt. corectie contributii pe locuri de munca in CASbrut */
Create procedure PSCorectieCASbrut
	@dataJos datetime, @dataSus datetime, @pMarca char(6)
As
Begin try
	declare @utilizator varchar(20), @NCIndBug int, @NCTaxePLmCh int, @multiFirma int

 	set @utilizator = dbo.fIaUtilizator(null)
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCTaxePLmCh=dbo.iauParL('PS','N-C-TXLMC')
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	if object_id('tempdb..#casbrut_marca') is not null drop table #casbrut_marca
	if object_id('tempdb..#casbrut') is not null drop table #casbrut
	
--	pun datele din net in tabela temporara pt. a functiona mai rapid in cazul Multifirma
	if object_id('tempdb..#net') is null 
		select net.* into #net 
		from net 
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=net.loc_de_munca	
		where net.data between @datajos and @datasus
			and (@multiFirma=0 or dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null) 

--	pun datele din casbrut in tabela temporara grupate pe marca pt. a nu mai face subselect cu sum pt. fiecare marca.
	select marca, sum(CAS) as CAS, sum(Somaj_5) as somaj_5, sum(Fond_de_risc_1) as Fond_de_risc_1, sum(Camera_de_munca_1) as Camera_de_munca_1, 
		sum(asig_sanatate_pl_unitate) as asig_sanatate_pl_unitate, sum(CCI) as CCI, sum(Fond_de_garantare) as Fond_de_garantare, 
		sum(CAS_individual) as CAS_individual, sum(Somaj_1) as Somaj_1, sum(Asig_sanatate_din_net) as Asig_sanatate_din_net, sum(Impozit) as Impozit
	into #casbrut_marca 
	from casbrut 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=casbrut.loc_de_munca	
	where (@multiFirma=0 or dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null) 
	group by marca

--	pun datele din casbrut in tabela temporara pt. a functiona mai rapid in cazul Multifirma, selectia locului de munca pt. reglare
	select * into #casbrut
	from casbrut 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=casbrut.loc_de_munca	
	where (@multiFirma=0 or dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null) 

--	reglare contributii angajator
	Update casbrut set asig_sanatate_pl_unitate=isnull(casbrut.asig_sanatate_pl_unitate+
		(n.asig_sanatate_pl_unitate+n1.asig_sanatate_din_impozit-cm.asig_sanatate_pl_unitate), casbrut.asig_sanatate_pl_unitate)
	from #net n
		left outer join #net n1 on n1.data=dbo.bom(n.data) and n1.marca=n.marca
		left outer join #casbrut_marca cm on cm.marca=n.marca
		cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.asig_sanatate_pl_unitate desc) c1
	where casbrut.loc_de_munca=c1.Loc_de_munca 
		and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
		and abs((n.asig_sanatate_pl_unitate-cm.asig_sanatate_pl_unitate))>0

	Update casbrut set Somaj_5=isnull(casbrut.Somaj_5+(n.Somaj_5-cm.Somaj_5), casbrut.Somaj_5)
	from #net n
		left outer join #casbrut_marca cm on cm.marca=n.marca
		cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.somaj_5 desc) c1 
	where casbrut.loc_de_munca=c1.Loc_de_munca 
		and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
		and abs((n.Somaj_5-cm.Somaj_5))>0

	Update casbrut set Camera_de_munca_1=isnull(casbrut.Camera_de_munca_1+(n.Camera_de_munca_1-cm.Camera_de_munca_1), casbrut.Camera_de_munca_1)
	from #net n
		left outer join #casbrut_marca cm on cm.marca=n.marca
		cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.Camera_de_munca_1 desc) c1
	where casbrut.loc_de_munca=c1.Loc_de_munca 
		and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
		and abs((n.Camera_de_munca_1-cm.Camera_de_munca_1))>0

	Update casbrut set Fond_de_risc_1=isnull(casbrut.Fond_de_risc_1+(n.Fond_de_risc_1-cm.Fond_de_risc_1), casbrut.Fond_de_risc_1)
	from #net n
		left outer join #casbrut_marca cm on cm.marca=n.marca
		cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.Fond_de_risc_1 desc) c1
	where casbrut.loc_de_munca=c1.Loc_de_munca 
		and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
		and abs((n.Fond_de_risc_1-cm.Fond_de_risc_1))>0

	Update casbrut set CCI=isnull(casbrut.CCI+(n.Ded_suplim-cm.CCI), casbrut.CCI)
	from #net n
		left outer join #casbrut_marca cm on cm.marca=n.marca
		cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.CCI desc) c1 
	where casbrut.loc_de_munca=c1.Loc_de_munca  
		and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
		and abs((n.Ded_suplim-cm.CCI))>0

	Update casbrut set Fond_de_garantare=isnull(casbrut.Fond_de_garantare+(n.Somaj_5-cm.Fond_de_garantare), casbrut.Fond_de_garantare)
	from #net n
		left outer join #casbrut_marca cm on cm.marca=n.marca
		cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.Fond_de_garantare desc) c1
	where casbrut.loc_de_munca=c1.Loc_de_munca  
		and casbrut.marca=n.marca and n.data=@dataJos and (@pMarca='' or casbrut.marca=@pMarca) 
		and abs((n.Somaj_5-cm.Fond_de_garantare))>0

	Update casbrut set CAS=isnull(casbrut.CAS+(n.CAS+n1.CAS-cm.CAS), casbrut.CAS)
	from #net n
		left outer join #net n1 on n1.data=dbo.bom(n.data) and n1.marca=n.marca
		left outer join #casbrut_marca cm on cm.marca=n.marca
		cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.CAS desc) c1
	where casbrut.loc_de_munca=c1.Loc_de_munca  
		and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
		and abs((n.CAS+n1.CAS-cm.CAS))>0

--	reglare contributii individuale (daca se lucreaza cu repartizare contributii individuale pe locuri de munca de cheltuiala)
	if @NCTaxePLmCh=1
	Begin
		Update casbrut set CAS_individual=isnull(casbrut.CAS_individual+(n.Pensie_suplimentara_3-cm.CAS_individual), casbrut.CAS_individual)
		from #net n
			left outer join #casbrut_marca cm on cm.marca=n.marca
			cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.CAS_individual desc) c1
		where (@NCIndBug=1 and casbrut.loc_de_munca=n.Loc_de_munca or @NCIndBug=0 and casbrut.loc_de_munca=c1.Loc_de_munca) 
			and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
			and abs((n.Pensie_suplimentara_3-cm.CAS_individual))>0

		Update casbrut set Somaj_1=isnull(casbrut.Somaj_1+(n.Somaj_1-cm.Somaj_1), casbrut.Somaj_1)
		from #net n
			left outer join #casbrut_marca cm on cm.marca=n.marca
			cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.Somaj_1 desc) c1
		where (@NCIndBug=1 and casbrut.loc_de_munca=n.Loc_de_munca or @NCIndBug=0 and casbrut.loc_de_munca=c1.Loc_de_munca) 
			and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
			and abs((n.Somaj_1-cm.Somaj_1))>0

		Update casbrut set Asig_sanatate_din_net=isnull(casbrut.Asig_sanatate_din_net+(n.Asig_sanatate_din_net-cm.Asig_sanatate_din_net), casbrut.Asig_sanatate_din_net)
		from #net n
			left outer join #casbrut_marca cm on cm.marca=n.marca
			cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.Asig_sanatate_din_net desc) c1
		where (@NCIndBug=1 and casbrut.loc_de_munca=n.Loc_de_munca or @NCIndBug=0 and casbrut.loc_de_munca=c1.Loc_de_munca) 
			and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
			and abs((n.Asig_sanatate_din_net-cm.Asig_sanatate_din_net))>0

		Update casbrut set Impozit=isnull(casbrut.Impozit+(n.Impozit-cm.Impozit), casbrut.Impozit)
		from #net n
			left outer join #casbrut_marca cm on cm.marca=n.marca
			cross apply (select top 1 loc_de_munca from #casbrut b where b.marca=n.marca order by b.Impozit desc) c1
		where (@NCIndBug=1 and casbrut.loc_de_munca=n.Loc_de_munca or @NCIndBug=0 and casbrut.loc_de_munca=c1.Loc_de_munca) 
			and casbrut.marca=n.marca and n.data=@dataSus and (@pMarca='' or casbrut.marca=@pMarca) 
			and abs((n.Impozit-cm.Impozit))>0
	End
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura PSCorectieCASbrut (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
if object_id('tempdb..#casbrut_marca') is not null drop table #casbrut_marca
if object_id('tempdb..#casbrut') is not null drop table #casbrut
