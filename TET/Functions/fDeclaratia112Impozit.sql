--***
Create
function [dbo].[fDeclaratia112Impozit] (@DataJ datetime, @DataS datetime, @ImpozitPL int)
returns @DateImpozit table (Data datetime, CodFiscal char(13), idCodFiscal int identity(1,1), 
	Sediu char(2), Impozit decimal(10))
as
Begin
	declare @Sub varchar(9), @CodFiscal varchar(13), @AnPLImpozit int, @ImpPLFaraSal int, @LmImpStatPl int, 
	@ContPerm varchar(13), @ContOcazP varchar(13), @ContOcazO varchar(13), @ContZilieri varchar(13), 
	@Colas int, @TertImpozSal int
	set @Sub=dbo.iauParA('GE','SUBPRO')
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

	if exists (select * from sys.objects where object_id = OBJECT_ID(N'fD112ImpozitSP') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
		insert into @DateImpozit
		select Data, CodFiscal, Sediu, sum(Impozit) from dbo.fD112ImpozitSP (@DataJ, @DataS, @ImpozitPL)
		group by Data, CodFiscal, Sediu
	else
	Begin
		declare @tmpImpozit table (Data datetime, CodFiscal char(13), idCodFiscal int identity(1,1), 
		Sediu char(2), Impozit decimal(10))

		insert into @tmpImpozit
		select n.data, @CodFiscal, 'P', sum(Impozit+Diferenta_impozit) as Impozit
		from net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
		where n.data=@DataS and @ImpozitPL=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('CCC','DAC'))
		group by n.data
		union all 
		select n.data, isnull(p.Valoare,@CodFiscal), 
		(case when isnull(p.Valoare,@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
		sum(Impozit+Diferenta_impozit) as Impozit
		from net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join conturi c on c.Subunitate=@Sub and c.Cont='444.'+rtrim(substring(i.Judet,charindex(',',i.Judet)+1,10))
			left outer join proprietati p on p.tip='CONT' and p.cod_proprietate='CODFISCAL' 
			and p.Cod=rtrim((case when i.Grupa_de_munca='P' then @ContOcazP when i.Grupa_de_munca='O' then @ContOcazO else @ContPerm end))+'.'+rtrim(substring(i.Judet,charindex(',',i.Judet)+1,10)) and p.Valoare<>''
		where n.data=@DataS and @ImpozitPL=1 and @AnPLImpozit=1 and @Colas=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('CCC','DAC'))
		group by n.data, isnull(p.Valoare,@CodFiscal)
		union all 
		select n.data, isnull(p.Valoare,@CodFiscal), 
		(case when isnull(p.Valoare,@CodFiscal)=@CodFiscal then 'P' else 'S' end), sum(Impozit+Diferenta_impozit) as Impozit
		from net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join lm lm on @LmImpStatPl=0 and lm.Cod=i.Loc_de_munca or @LmImpStatPl=1 and lm.Cod=n.Loc_de_munca
			left outer join proprietati p on p.tip='LM' and p.cod_proprietate='CODFISCAL' and (@LmImpStatPl=0 and p.Cod=i.Loc_de_munca or @LmImpStatPl=1 and p.Cod=n.Loc_de_munca) and p.Valoare<>''
		where n.data=@DataS and @ImpozitPL=1 and @AnPLImpozit=0 and @Colas=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('CCC','DAC'))
		group by n.data, isnull(p.Valoare,@CodFiscal)
		union all 
		select n.data, isnull(p.Valoare,@CodFiscal), 
			(case when isnull(p.Valoare,@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
			sum(Impozit+Diferenta_impozit) as Impozit
		from net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join extinfop e on n.Marca=e.Marca and e.Cod_inf='TERTIMPZ' and e.Val_inf<>''
			left outer join proprietati p on p.tip='TERT' and p.cod_proprietate='CODFISCAL' and p.Cod=e.Val_inf and p.Valoare<>''
		where n.data=@DataS and @ImpozitPL=1 and @Colas=1 and @TertImpozSal=1 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('CCC','DAC'))
		group by n.data, isnull(p.Valoare,@CodFiscal)
		union all 
		select n.data, isnull(substring(s.Comanda,charindex(',',s.Comanda)+1,25),@CodFiscal), 
			(case when isnull(substring(s.Comanda,charindex(',',s.Comanda)+1,25),@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
			sum(Impozit+Diferenta_impozit) as Impozit
		from net n
			left outer join istpers i on i.Data=n.Data and i.Marca=n.Marca
			left outer join lm lm on lm.Cod=n.Loc_de_munca
			left outer join speciflm s on lm.Cod=s.Loc_de_munca
		where n.data=@DataS and @ImpozitPL=1 and @Colas=1 and @TertImpozSal=0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('CCC','DAC'))
		group by n.data, isnull(substring(s.Comanda,charindex(',',s.Comanda)+1,25),@CodFiscal)
	--	inserez impozitul pt. zilieri
		insert into @tmpImpozit
		select dbo.eom(s.Data), @CodFiscal, 'P', sum(s.Impozit) as Impozit
		from SalariiZilieri s
		where s.Data between @DataJ and @DataS and @ImpozitPL=0 group by dbo.eom(s.Data)
		union all
		select dbo.eom(s.Data), isnull(p.Valoare,@CodFiscal), 
			(case when isnull(p.Valoare,@CodFiscal)=@CodFiscal then 'P' else 'S' end), sum(s.Impozit) as Impozit
		from SalariiZilieri s
			left outer join lm lm on lm.Cod=s.Loc_de_munca
			left outer join proprietati p on p.tip='LM' and p.cod_proprietate='CODFISCAL' and p.Cod=s.Loc_de_munca and p.Valoare<>''
		where s.Data between @DataJ and @DataS and @ImpozitPL=1 and @AnPLImpozit=0 and @Colas=0 
		group by dbo.eom(s.Data), isnull(p.Valoare,@CodFiscal)
		union all
		select dbo.eom(s.Data), isnull(pc.Valoare,@CodFiscal), 
		(case when isnull(pc.Valoare,@CodFiscal)=@CodFiscal then 'P' else 'S' end), 
		sum(s.Impozit) as Impozit
		from SalariiZilieri s
			left outer join Zilieri z on z.Marca=s.Marca
			left outer join Judete j on j.cod_judet=z.Judet
			left outer join proprietati pj on pj.tip='JUDET' and pj.cod_proprietate='ANCTIMPOZIT' and pj.Cod=z.Judet and pj.Valoare<>''
			left outer join conturi c on c.Subunitate=@Sub and c.Cont='444.'+rtrim(pj.Valoare)
			left outer join proprietati pc on pc.tip='CONT' and pc.cod_proprietate='CODFISCAL' 
			and pc.Cod=rtrim(@ContZilieri)+'.'+rtrim(pj.Valoare) and pc.Valoare<>''
		where s.Data between @DataJ and @DataS and @ImpozitPL=1 and @AnPLImpozit=1 and @Colas=0
		group by dbo.eom(s.Data), isnull(pc.Valoare,@CodFiscal)
	--	la final inserez pozitiile pt. punctele de lucru care nu au salariati - pt. a face legatura 
	--	cu codurile fiscale deja completate
		insert into @tmpImpozit
		select @DataS, p.Valoare, (case when p.Valoare=@CodFiscal then 'P' else 'S' end), 0 as Impozit
		from proprietati p 
		where @ImpozitPL=1 and @AnPLImpozit=0 and @Colas=0 and @ImpPLFaraSal=1 
			and p.tip='LM' and p.cod_proprietate='CODFISCAL' and p.Valoare<>''
			and p.Valoare not in (select CodFiscal from @DateImpozit)
		group by p.Valoare

		insert into @DateImpozit
		select Data, CodFiscal, Sediu, sum(Impozit) from @tmpImpozit group by Data, CodFiscal, Sediu
	End
	return
End

/*
	select * from fDeclaratia112Impozit ('07/01/2011', '07/31/2011', 1) 
	select sum(Impozit) from fDeclaratia112Impozit ('05/01/2011', '05/31/2011', 1) 
*/
