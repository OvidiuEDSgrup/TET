--***
Create procedure rapCentralizatorManopera
	@dataJos datetime, @dataSus datetime, @locm char(9)=null, @strict int=0, @locmBen char(9), @comanda char(20)=null, @marca char(6)=null, @tipAcord char(1)=null, 
	@manopDirCuOreSupl int=0, @brutFaraOreSupl int=0, @ordonare int
as
/*
	@ordonare=1	Locuri de munca, comenzi
	@ordonare=2	Comenzi, locuri de munca
	@ordonare=3	Locuri de munca, comenzi, operatii
*/
begin try
	set transaction isolation level read uncommitted
	declare @userASiS char(10), @Sub char(9), @OreLuna int, @NrMOreLuna int, 
	@procCasIndiv decimal(5,2), @procCasCN decimal(5,2), @procCasCD decimal(5,2), @procCasCS decimal(5,2), @procCCI decimal(5,2), @procCass decimal(5,2), @procFaambp decimal(7,3), 
	@CalcITM int, @procITM decimal(5,2), @procSomaj decimal(5,2), @procFondGar decimal(5,2), 
	@SalComenzi int, @ButonRealizari int, @IndiciPontajLm int, @IndiciRealcom int, @ProcOS1 float, @ProcOS2 float, @ProcOS3 float, @ProcOS4 float, @Simex int, @ArlCJ int

	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @NrMOreLuna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	set @procCasIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @procCasCN=dbo.iauParLN(@dataSus,'PS','CASGRUPA3')
	set @procCasCD=dbo.iauParLN(@dataSus,'PS','CASGRUPA2')
	set @procCasCS=dbo.iauParLN(@dataSus,'PS','CASGRUPA1')
	set @procCCI=dbo.iauParLN(@dataSus,'PS','COTACCI')
	set @procCass=dbo.iauParLN(@dataSus,'PS','CASSUNIT')
	set @procFaambp=dbo.iauParLN(@dataSus,'PS','0.5%ACCM')
	set @CalcITM=dbo.iauParL('PS','1%CAMERA')
	set @procITM=dbo.iauParLN(@dataSus,'PS','1%CAMERA')
	set @procSomaj=dbo.iauParLN(@dataSus,'PS','3.5%SOMAJ')
	set @procFondGar=dbo.iauParLN(@dataSus,'PS','FONDGAR')
	
	set @SalComenzi=dbo.iauParL('PS','SALCOM')
	set @ButonRealizari=dbo.iauParN('PS','REALIZARI')
	set @IndiciPontajLm=dbo.iauParL('PS','INDICIPLM')
	set @IndiciRealcom=dbo.iauParL('PS','INDICICOM')
	set @ProcOS1=dbo.iauParN('PS','OSUPL1')
	set @ProcOS2=dbo.iauParN('PS','OSUPL2')
	set @ProcOS3=dbo.iauParN('PS','OSUPL3')
	set @ProcOS4=dbo.iauParN('PS','OSUPL4')
	set @Simex=dbo.iauParL('SP','SIMEX')
	set @ArlCJ=dbo.iauParL('SP','ARLCJ')

	if object_id('tempdb..#manopera') is not null drop table #manopera

	select (case when @ordonare=1 or @ordonare=3 then a.Loc_de_munca else a.Comanda end) as nivel_sup, 
	(case when @Ordonare=1 or @ordonare=3 then a.Comanda else a.Loc_de_munca end) as nivel_inf, 
	rtrim(a.Loc_de_munca) as lm, rtrim(lm.denumire) as den_lm, a.comanda, rtrim(c.Descriere) as den_comanda, a.Cod as cod_operatie, isnull(o.denumire,'') as den_operatie, 
	a.marca, isnull(p.nume,'') as nume, isnull(p.spor_conditii_1,0) as spor_conditii_1, 
	a.cantitate, a.Cantitate+(case when @manopDirCuOreSupl=1 and @SalComenzi=1 then 
		isnull((select ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4 from pontaj where marca=a.marca and data=a.data and numar_curent = convert(int,substring(a.numar_document,3,20))),0) 
		else 0 end) as cantitate_afisata, 
	a.tarif_unitar, 
	a.Tarif_unitar*(case when @SalComenzi=1 and a.Cantitate=0 and (select ore_suplimentare_1 from pontaj where marca=a.marca and data=a.data and numar_curent = convert(int,substring(a.numar_document,3,20)))<>0 then @ProcOS1/100 
		when @SalComenzi=1 and a.Cantitate=0 and (select ore_suplimentare_2 from pontaj where marca=a.marca and data=a.data and numar_curent = convert(int,substring(a.numar_document,3,20)))<>0 then @ProcOS2/100 
		when @SalComenzi=1 and a.Cantitate=0 and (select ore_suplimentare_3 from pontaj where marca=a.marca and data=a.data and numar_curent = convert(int,substring(a.numar_document,3,20)))<>0 then @ProcOS3/100 
		when @SalComenzi=1 and a.Cantitate=0 and (select ore_suplimentare_4 from pontaj where marca=a.marca and data=a.data and numar_curent = convert(int,substring(a.numar_document,3,20)))<>0 then @ProcOS4/100 
		else 1 end) as tarif_unitar_afisat, 
	a.numar_document, a.Data, a.norma_de_timp, 
	isnull((select sum(cantitate) from realcom where marca=a.marca and loc_de_munca=a.Loc_de_munca and data between dbo.bom(a.data) and dbo.eom(a.data)),0) as total_ore_realizate, 
	isnull((select sum(realizat_acord) from brut where marca=a.marca and year(data)=year(a.data) and month(data)=month(a.data)),0) as realizat_acord_brut, 
	isnull((select sum(total_ore_lucrate) from brut where marca=a.marca and loc_de_munca=a.Loc_de_munca and year(data)=year(a.data) and month(data)=month(a.data)),0) as total_ore_lucrate, 
	isnull((select sum(venit_total-(case when @BrutFaraOreSupl=1 then Indemnizatie_ore_supl_1+Indemnizatie_ore_supl_2+Indemnizatie_ore_supl_3+Indemnizatie_ore_supl_4 else 0 end)) 
		from brut where marca=a.marca and loc_de_munca=a.Loc_de_munca and year(data)=year(a.data) and month(data)=month(a.data)),0) as venit_total, 
	(case when @manopDirCuOreSupl=1 /*and a.Cantitate<>0*/ then (select ore_suplimentare_1*@ProcOS1/100 from pontaj where marca=a.marca and data=a.data 
	and numar_curent = convert(int,substring(a.numar_document,3,20))) else 0 end) as ore_supl1, 
	(case when @manopDirCuOreSupl=1 /*and a.Cantitate<>0*/ then (select ore_suplimentare_2*@ProcOS2/100 from pontaj where marca=a.marca and data=a.data 
	and numar_curent = convert(int,substring(a.numar_document,3,20))) else 0 end) as ore_supl2,
	(case when @manopDirCuOreSupl=1 /*and a.Cantitate<>0*/ then (select ore_suplimentare_3*@ProcOS3/100 from pontaj where marca=a.marca and data=a.data 
	and numar_curent = convert(int,substring(a.numar_document,3,20))) else 0 end) as ore_supl3,
	(case when @manopDirCuOreSupl=1 /*and a.Cantitate<>0*/ then (select ore_suplimentare_4*@ProcOS4/100 from pontaj where marca=a.marca and data=a.data 
	and numar_curent = convert(int,substring(a.numar_document,3,20))) else 0 end) as ore_supl4,
	(case when @manopDirCuOreSupl=1 then (select sum(ore_suplimentare_1*@ProcOS1/100+ore_suplimentare_2*@ProcOS2/100+ore_suplimentare_3*@ProcOS3/100+
	ore_suplimentare_4*@ProcOS4/100) from pontaj where marca=a.marca and data between dbo.bom(a.data) and dbo.eom(a.data) and loc_de_munca=a.Loc_de_munca) else 0 end) as ore_supl_cu_procent, 
	(case when @manopDirCuOreSupl=1 then (select sum(ore_suplimentare_1+ore_suplimentare_2+ore_suplimentare_3+ore_suplimentare_4) 
		from pontaj where marca=a.marca and data between dbo.bom(a.data) and dbo.eom(a.data) and loc_de_munca=a.Loc_de_munca) else 0 end) as ore_supl_fara_procent, 
	0 as numitor, convert(float,0) as manopera_directa, convert(float,0) as brut, convert(float,0) as contributii_unitate, convert(float,0) as total_cheltuieli, 
	(case when @Ordonare=3 then a.cod else '' end) as ordonare_operatie 
	into #manopera
	from realcom a
		left outer join comenzi c on c.subunitate=@Sub and a.comanda = c.comanda 
		left outer join lm on lm.cod = a.loc_de_munca
		left outer join catop o on a.cod = o.cod
		left outer join personal p on a.marca = p.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
	where (a.data between @dataJos and @dataSus) 
		and (@marca is null or a.Marca=@marca) 
		and (@locm is null or a.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and (@comanda is null or a.Comanda=@comanda) 
		and (@locmBen is null or c.loc_de_munca_beneficiar=@locmBen) 
		and (@tipAcord is null or @tipAcord='1' and a.marca='' or @tipAcord='2' and a.marca<>'')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	order by (case when @Ordonare=1 or @ordonare=3 then a.Loc_de_munca else a.Comanda end), 
		(case when @ordonare=1 or @ordonare=3 then a.Comanda else a.Loc_de_munca end), a.Marca, ordonare_operatie /*, a.Numar_document, a.Data*/

--	calculez manopera directa
	update #manopera set manopera_directa=round(convert(decimal(12,3),cantitate_afisata*tarif_unitar_afisat*(case when (@SalComenzi=1 and @IndiciPontajLm=1 or @IndiciRealcom=1) and Norma_de_timp<>0 then Norma_de_timp else 1 end)+
		(case when cantitate<>0 then (ore_supl1+ore_supl2+ore_supl3+ore_supl4)*tarif_unitar else 0 end)),2),
		numitor=(case when LEFT(Numar_document,3)='DLG' then total_ore_lucrate else total_ore_realizate end)+
				(case when cantitate<>0 or cantitate<>cantitate_afisata then ore_supl_cu_procent else ore_supl_fara_procent end)
--	calculez total brut
	update #manopera set brut=round(convert(decimal(12,5),(case when venit_total=0 then manopera_directa 
		else venit_total*((case when cantitate<>cantitate_afisata or numitor=0 then 0 else cantitate_afisata end)
			+(case when cantitate<>0 or cantitate<>cantitate_afisata then ore_supl1+ore_supl2+ore_supl3+ore_supl4 else 0 end))/
			(case when numitor=0 then 1 else numitor end) end)),2)
--	calculez contributii unitate
	update #manopera set contributii_unitate=round(convert(decimal(12,2),brut*((@procCasCN-@procCasIndiv)/100+@procCCI/100+@procCass/100+@procSomaj/100+@procFondGar/100
		+@procFaambp/100+(case when @CalcITM=1 then @procITM/100 else 0 end))),2)
--	calculez total cheltuieli
	update #manopera set total_cheltuieli=round(brut+contributii_unitate,2)

	select data, marca, nume, nivel_sup, nivel_inf, lm, den_lm, comanda, den_comanda, cod_operatie, den_operatie, spor_conditii_1,
		numar_document, cantitate, cantitate_afisata, tarif_unitar, tarif_unitar_afisat, norma_de_timp, 
		total_ore_realizate, realizat_acord_brut, total_ore_lucrate, venit_total, 
		ore_supl1, ore_supl2, ore_supl3, ore_supl4,	ore_supl_cu_procent, ore_supl_fara_procent, 
		manopera_directa, brut, contributii_unitate, total_cheltuieli, ordonare_operatie 
	from #manopera
	order by nivel_sup, nivel_inf, Marca, ordonare_operatie
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapCentralizatorManopera (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#manopera') is not null drop table #manopera

/*
	exec rapCentralizatorManopera '04/01/2012', '04/30/2012', '12161', 0, null, null, '2382', null, 1, 0, 1
*/
