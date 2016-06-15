--***
Create function fDeclaratia112Scutiri 
	(@dataJos datetime, @dataSus datetime, @peMarca int, @lm char(9)='')
returns @DateScutiri table 
	(Data datetime, Marca char(6), CNP char(13), Motiv_scutire int, 
 	Scutire_asigurat decimal(10), Scutire_asigurat_CN decimal(10), Scutire_asigurat_CD decimal(10), Scutire_asigurat_CS decimal(10), 
	Scutire_angajator decimal(10), Scutire_angajator_CN decimal(10), Scutire_angajator_CD decimal(10), Scutire_angajator_CS decimal(10))
as
Begin
	declare @utilizator varchar(20), @lista_lm int, @AnRegCom int, @DataExpOUG6 datetime, @STOUG28 int, @SalMediu float

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @AnRegCom=dbo.iauParN('PS','REGCOMAN')
	set @DataExpOUG6=dbo.EOY(convert(datetime,'01/01/'+str(@AnRegCom+3,4)))
	set @STOUG28=dbo.iauParLL(@dataSus,'PS','STOUG28')
	set @SalMediu=dbo.iauParLN(dbo.EOM(DateADD(year,-1,@dataSus)),'PS','SALMBRUT')

	insert into @DateScutiri
--	scutiri aferent somaj tehnic conform OUG28
	select b.data, max(b.Marca), p.Cod_numeric_personal, 1, sum(b.Ind_invoiri), sum((case when po.grupa_de_munca='N' then b.Ind_invoiri else 0 end)), 
		sum((case when po.grupa_de_munca='D' then b.Ind_invoiri else 0 end)), sum((case when po.grupa_de_munca='S' then b.Ind_invoiri else 0 end)), 
		max(b.Ind_invoiri), sum((case when po.grupa_de_munca='N' then b.Ind_invoiri else 0 end)), 
		sum((case when po.grupa_de_munca='D' then b.Ind_invoiri else 0 end)), sum((case when po.grupa_de_munca='S' then b.Ind_invoiri else 0 end)) 
	from brut b 
		left outer join personal p on p.marca=b.marca
		left outer join istpers i on i.data=b.data and i.marca=b.marca
		left outer join (select dbo.eom(data) as data, marca, loc_de_munca, max(grupa_de_munca) as grupa_de_munca 
			from pontaj where data between @dataJos and @dataSus group by dbo.eom(data), marca, loc_de_munca) po on po.data=b.data and po.marca=b.marca and po.loc_de_munca=b.loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.Loc_de_munca
	where @STOUG28=1 and b.Data=@dataSus and b.Ind_invoiri<>0
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		and (@lista_lm=0 or lu.cod is not null) 
	group by b.data, p.Cod_numeric_personal, (case when @peMarca=1 then b.Marca else '' end)
	union all
--	scutiri conform OUG13/2010 (angajatorii beneficiaza de scutirea la plata contributiilor de asigurari sociale timp de 6 luni de la momentul angajarii)
	select b.Data, max(b.Marca), p.Cod_numeric_personal, 2, 0, 0, 0, 0, sum(b.Venit_total-(b.Ind_c_medical_CAS+b.Spor_cond_9)), 
	sum(b.Venit_cond_normale-(b.Ind_c_medical_unitate+b.Ind_c_medical_CAS+b.Spor_cond_9))+max(n.Baza_CAS_cond_norm), sum(b.Venit_cond_speciale), sum(b.Venit_cond_speciale)
	from brut b
		left outer join personal p on p.marca=b.marca
		left outer join istpers i on i.data=b.data and i.marca=b.marca
		left outer join net n on n.data=dbo.bom(b.data) and n.marca=b.marca
		left outer join extinfop e on e.marca=b.marca and e.cod_inf='OUG13' and e.data_inf>=p.Data_angajarii_in_unitate
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.Loc_de_munca
	where b.data=@dataSus and upper(isnull(e.val_inf,''))='DA' 
		and (day(p.Data_angajarii_in_unitate)=1 and b.data>=dbo.eom(p.Data_angajarii_in_unitate) and b.data<=dbo.eom(DateAdd(month,5,p.Data_angajarii_in_unitate)) 
			or day(p.Data_angajarii_in_unitate)<>1 and b.data>=dbo.eom(DateAdd(month,1,p.Data_angajarii_in_unitate)) and b.data<=dbo.eom(DateAdd(month,6,p.Data_angajarii_in_unitate)))
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		and (@lista_lm=0 or lu.cod is not null) 
	group by b.data, p.Cod_numeric_personal, (case when @peMarca=1 then b.Marca else '' end)
	union all
--	scutiri conform OUG6 (SRLD-uri, scutiri la contributiile angajatorului la CAS si FAAMBP)
	select b.Data, max(b.Marca), p.Cod_numeric_personal, 3, 0, 0, 0, 0, 0, 
		(case when sum(b.Venit_cond_normale-(b.Ind_c_medical_unitate+b.Ind_c_medical_CAS+b.Spor_cond_9))>@SalMediu then @SalMediu else sum(b.Venit_cond_normale-(b.Ind_c_medical_unitate+b.Ind_c_medical_CAS+b.Spor_cond_9)) end), 
	0, 0
	from brut b
		left outer join personal p on p.marca=b.Marca
		left outer join istpers i on i.data=b.data and i.marca=b.marca
		left outer join extinfop e on e.marca=b.Marca and e.cod_inf='OUG6'
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.Loc_de_munca
	where b.data=@dataSus and upper(isnull(e.val_inf,''))='DA' and b.Data<=@DataExpOUG6
		and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		and (@lista_lm=0 or lu.cod is not null) 
	group by b.data, p.Cod_numeric_personal, (case when @peMarca=1 then b.Marca else '' end)
	return
End

/*
	select * from fDeclaratia112Scutiri ('02/01/2011', '02/28/2011', 0)
*/	
