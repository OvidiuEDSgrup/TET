--***
/**	functie scutiri contrib.OUG13 **/
Create function fPSScutiriOUG13
	(@dataJos datetime, @dataSus datetime, @oMarca int, @Marca char(6), @Locm char(9), @Strict int) 
returns @ScutiriOUG13 table 
	(Data datetime, Marca char(6), Loc_de_munca char(9), CAS decimal(10,2), Somaj decimal(10,2), CASS decimal(10,2), 
	CCI decimal(10,2), Fond_garantare decimal(10,2), Fambp decimal(10,2), Itm decimal(10,2))
as
begin
	declare @utilizator varchar(20), @lista_lm int

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	insert @ScutiriOUG13
	select n.Data, n.Marca, n.Loc_de_munca, n.CAS+isnull(n1.CAS,0), n.Somaj_5, n.Asig_sanatate_pl_unitate, n.Ded_suplim, isnull(n1.Somaj_5,0), n.Fond_de_risc_1, n.Camera_de_munca_1
	from net n
		left outer join personal p on n.marca=p.marca
		left outer join net n1 on dbo.bom(n.data)=n1.data and n.marca=n1.marca 
		left outer join extinfop e on e.marca=n.marca and e.cod_inf='OUG13' and e.data_inf>=p.Data_angajarii_in_unitate
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=n.loc_de_munca
	where n.data=@dataSus and (@oMarca=0 or n.Marca=@Marca) 
		and (@Locm='' or n.Loc_de_munca like rtrim(@Locm)+(case when @Strict=1 then '%' else '' end))
		and upper(isnull(e.val_inf,''))='DA' and (day(p.Data_angajarii_in_unitate)=1 and n.data>=dbo.eom(p.Data_angajarii_in_unitate)
		and n.data<=dbo.eom(DateAdd(month,5,p.Data_angajarii_in_unitate)) 
			or day(p.Data_angajarii_in_unitate)<>1 and n.data>=dbo.eom(DateAdd(month,1,p.Data_angajarii_in_unitate))
		and n.data<=dbo.eom(DateAdd(month,6,p.Data_angajarii_in_unitate)))
		and (@lista_lm=0 or lu.cod is not null) 

	return
end
