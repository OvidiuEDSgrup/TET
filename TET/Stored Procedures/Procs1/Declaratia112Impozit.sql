--***
Create procedure Declaratia112Impozit
	(@dataJos datetime, @dataSus datetime, @ImpozitPL int, @lm char(9)='')
as
Begin try
	declare @utilizator varchar(20), @lista_lm int, @Sub varchar(9), @CodFiscal varchar(13), @AnPLImpozit int, @ImpPLFaraSal int, @LmImpStatPl int,
	@ContPerm varchar(13), @ContOcazP varchar(13), @ContOcazO varchar(13), @ContZilieri varchar(13), @Colas int, @TertImpozSal int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @CodFiscal=dbo.iauParA('PS','CODFISC')
	if @CodFiscal=''
		set @CodFiscal=dbo.iauParA('GE','CODFISC')
	set @CodFiscal=ltrim(rtrim((case when left(upper(@CodFiscal),2)='RO' then substring(@CodFiscal,3,13)
		when left(upper(@CodFiscal),1)='R' then substring(@CodFiscal,2,13) else @CodFiscal end)))
	set @AnPLImpozit=dbo.iauParL('PS','AN-PL-IMP')
	set @ImpPLFaraSal=dbo.iauParL('PS','D112IPLFS')
	set @LmImpStatPl=dbo.iauParL('PS','D112PLLMS')
	set @ContPerm=dbo.iauParA('PS','N-I-PMACC')
	set @ContOcazP=dbo.iauParA('PS','N-I-OCZPC')
	set @ContOcazO=dbo.iauParA('PS','N-I-OCAZC')
	set @ContZilieri=dbo.iauParA('PS','N-I-ZILC')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @TertImpozSal=dbo.iauParL('PS','TERTIMSAL')
	set @lm=isnull(@lm,'')

	if object_id('tempdb..#net') is null 
	begin
		select n.* 
		into #net 
		from net n
			left outer join istPers i on i.Data=dbo.EOM(n.data) and i.Marca=n.Marca
		where n.Data between @datajos and @datasus
			and (isnull(@lm,'')='' or n.Loc_de_munca like rtrim(@lm)+'%')
			and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=n.loc_de_munca))
	end

	if object_id('tempdb..#SalariiZilieri') is null 
	begin
		select sz.* into #SalariiZilieri 
		from SalariiZilieri sz
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=sz.loc_de_munca
		where sz.Data between @dataJos and @dataSus
			and (@lm='' or sz.Loc_de_munca like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) 
	end

	if object_id('tempdb..#Impozit') is not null drop table #Impozit
	if object_id('tempdb..#tmpImpozit') is not null drop table #tmpImpozit

	create table #Impozit
		(Data datetime, CodFiscal char(13), idCodFiscal int, Sediu char(2), Impozit decimal(10))

	if exists (select * from sys.objects where object_id = OBJECT_ID(N'fD112ImpozitSP') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
		insert into #Impozit
		select Data, CodFiscal, ROW_NUMBER() over (order by Data, CodFiscal, Sediu), Sediu, sum(Impozit) from dbo.fD112ImpozitSP (@dataJos, @dataSus, @ImpozitPL)
		group by Data, CodFiscal, Sediu
	else
	Begin
		create table #tmpImpozit (Data datetime, CodFiscal char(13), idCodFiscal int identity(1,1), Sediu char(2), Impozit decimal(10))

		insert into #tmpImpozit
--	total impozit pe codul fiscal al sediului
		select n.data, @CodFiscal, 'P', sum(Impozit+Diferenta_impozit) as Impozit
		from #net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
		where n.data=@dataSus and @ImpozitPL=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT'))
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		group by n.data
--	impozit pe coduri fiscale definite ca proprietate pe cont de impozit (daca se lucreaza cu setarea [X]Analitic punct de lucru la contul de impozit 
--	analiticul contului (nu contul) de impozit este completat in macheta salariati in campul Judet, dupa acesta, separat cu virgula)
		union all 
		select n.data, isnull(nullif(p.Valoare,''),@CodFiscal), 
		(case when isnull(nullif(p.Valoare,''),@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
		sum(Impozit+Diferenta_impozit) as Impozit
		from #net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join conturi c on c.Subunitate=@Sub and c.Cont='444.'+rtrim(substring(i.Judet,charindex(',',i.Judet)+1,10))
			left outer join proprietati p on p.tip='CONT' and p.cod_proprietate='CODFISCAL' 
			and p.Cod=rtrim((case when i.Grupa_de_munca='P' then @ContOcazP when i.Grupa_de_munca='O' then @ContOcazO else @ContPerm end))+'.'+rtrim(substring(i.Judet,charindex(',',i.Judet)+1,10)) and p.Valoare<>''
		where n.data=@dataSus and @ImpozitPL=1 and @AnPLImpozit=1 and @Colas=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT'))
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		group by n.data, isnull(nullif(p.Valoare,''),@CodFiscal)
--	impozit pe coduri fiscale definite ca proprietate pe loc de munca
		union all 
		select n.data, isnull(nullif(s.Valoare,''),isnull(nullif(p.Valoare,''),@CodFiscal)), 
		(case when isnull(nullif(s.Valoare,''),isnull(nullif(p.Valoare,''),@CodFiscal))=@CodFiscal then 'P' else 'S' end), sum(Impozit+Diferenta_impozit) as Impozit
		from #net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join lm lm on @LmImpStatPl=0 and lm.Cod=i.Loc_de_munca or @LmImpStatPl=1 and lm.Cod=n.Loc_de_munca
			left outer join proprietati p on p.tip='LM' and p.cod_proprietate='CODFISCAL' and (@LmImpStatPl=0 and p.Cod=i.Loc_de_munca or @LmImpStatPl=1 and p.Cod=n.Loc_de_munca) and p.Valoare<>''
			left outer join proprietati s on s.tip='PERSONAL' and s.cod_proprietate='CODFISCAL' and s.Cod=n.Marca and s.Valoare<>''
		where n.data=@dataSus and @ImpozitPL=1 and @AnPLImpozit=0 and @Colas=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT'))
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		group by n.data, isnull(nullif(s.Valoare,''),isnull(nullif(p.Valoare,''),@CodFiscal))
		union all 
--	specific Colas: codul fiscal pentru impozit se ia din dreptul tertului atasat salariatului in macheta salariati
		select n.data, isnull(nullif(p.Valoare,''),@CodFiscal), 
			(case when isnull(nullif(p.Valoare,''),@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
			sum(Impozit+Diferenta_impozit) as Impozit
		from #net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join extinfop e on n.Marca=e.Marca and e.Cod_inf='TERTIMPZ' and e.Val_inf<>''
			left outer join proprietati p on p.tip='TERT' and p.cod_proprietate='CODFISCAL' and p.Cod=e.Val_inf and p.Valoare<>''
		where n.data=@dataSus and @ImpozitPL=1 and @Colas=1 and @TertImpozSal=1 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT'))
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		group by n.data, isnull(nullif(p.Valoare,''),@CodFiscal)
		union all 
--	specific Colas: codul fiscal pentru impozit se ia din dreptul locului de munca
		select n.data, isnull(substring(s.Comanda,charindex(',',s.Comanda)+1,25),@CodFiscal), 
			(case when isnull(substring(s.Comanda,charindex(',',s.Comanda)+1,25),@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
			sum(Impozit+Diferenta_impozit) as Impozit
		from #net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join lm lm on lm.Cod=n.Loc_de_munca
			left outer join speciflm s on lm.Cod=s.Loc_de_munca
		where n.data=@dataSus and @ImpozitPL=1 and @Colas=1 and @TertImpozSal=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT'))
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		group by n.data, isnull(substring(s.Comanda,charindex(',',s.Comanda)+1,25),@CodFiscal)

--	inserez impozitul pt. zilieri
		insert into #tmpImpozit
		select dbo.eom(s.Data), @CodFiscal, 'P', sum(s.Impozit) as Impozit
		from #SalariiZilieri s
		where @ImpozitPL=0
		group by dbo.eom(s.Data)
		union all
		select dbo.eom(s.Data), isnull(nullif(p.Valoare,''),@CodFiscal), 
			(case when isnull(nullif(p.Valoare,''),@CodFiscal)=@CodFiscal then 'P' else 'S' end), sum(s.Impozit) as Impozit
		from #SalariiZilieri s
			left outer join lm lm on lm.Cod=s.Loc_de_munca
			left outer join proprietati p on p.tip='LM' and p.cod_proprietate='CODFISCAL' and p.Cod=s.Loc_de_munca and p.Valoare<>''
		where @ImpozitPL=1 and @AnPLImpozit=0 and @Colas=0 
		group by dbo.eom(s.Data), isnull(nullif(p.Valoare,''),@CodFiscal)
		union all
		select dbo.eom(s.Data), isnull(nullif(pc.Valoare,''),@CodFiscal), 
		(case when isnull(nullif(pc.Valoare,''),@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
		sum(s.Impozit) as Impozit
		from #SalariiZilieri s
			left outer join Zilieri z on z.Marca=s.Marca
			left outer join Judete j on j.cod_judet=z.Judet
			left outer join proprietati pj on pj.tip='JUDET' and pj.cod_proprietate='ANCTIMPOZIT' and pj.Cod=z.Judet and pj.Valoare<>''
			left outer join conturi c on c.Subunitate=@Sub and c.Cont='444.'+rtrim(pj.Valoare)
			left outer join proprietati pc on pc.tip='CONT' and pc.cod_proprietate='CODFISCAL' 
			and pc.Cod=rtrim(@ContZilieri)+'.'+rtrim(pj.Valoare) and pc.Valoare<>''
		where @ImpozitPL=1 and @AnPLImpozit=1 and @Colas=0
		group by dbo.eom(s.Data), isnull(nullif(pc.Valoare,''),@CodFiscal)

	--	la final inserez pozitiile pt. punctele de lucru care nu au salariati 
	--	pentru a face legatura cu codurile fiscale deja completate
		insert into #tmpImpozit
		select @dataSus, p.Valoare, (case when p.Valoare=@CodFiscal then 'P' else 'S' end), 0 as Impozit
		from proprietati p 
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.cod
		where @ImpozitPL=1 and @AnPLImpozit=0 and @Colas=0 and @ImpPLFaraSal=1 
			and p.tip='LM' and p.cod_proprietate='CODFISCAL' and p.Valoare<>''
			and p.Valoare not in (select CodFiscal from #tmpImpozit)
			and (@lm='' or p.Cod like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) 
		group by p.Valoare

		insert into #Impozit
		select Data, CodFiscal, ROW_NUMBER() over (order by Data, Sediu, CodFiscal), Sediu, sum(Impozit) from #tmpImpozit group by Data, Sediu, CodFiscal
	End
	
	if object_id('tempdb..#ImpozitPL') is not null 
		insert into #ImpozitPL 
		select Data, CodFiscal, idCodFiscal, Sediu, Impozit from #impozit

	select Data, CodFiscal, idCodFiscal, Sediu, Impozit 
	from #Impozit
	
	return
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura Declaratia112Impozit (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec Declaratia112Impozit '11/01/2012', '11/30/2012', 1
	select sum(Impozit) from fDeclaratia112Impozit ('05/01/2011', '05/31/2011', 1) 
*/
