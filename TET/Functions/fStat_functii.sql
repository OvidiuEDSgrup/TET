--***
/**	functie lista stat functii	*/
Create function fStat_functii 
	(@dataJos datetime, @dataSus datetime, @oFunctie int, @cFunctia char(6), @FFArborescent int, @unLm int, @lmJos char(9), @lmSus char(9), @Ordonare char(50), 
	@salariatiPlecatiLuna int, @detaliereSalariati int, @tipSalarizare int=0)
returns @stat_functii table
	(Data datetime, Luna char(15), Loc_de_munca char(9), Denumire_lm char(30), Cod_functie char(6), Denumire_functie char(30), Marca char(6), Nume char(50), Numar_salariati int, 
	Functie_COR char(6), Nivel_studii varchar(10))
as
begin
	declare  @Perioada char(30), @AnulInch int, @LunaInch int, @q_tipSalarizare int
	set @AnulInch=dbo.iauParN('PS','ANUL-INCH')
	set @LunaInch=dbo.iauParN('PS','LUNA-INCH')
	set @q_tipSalarizare=isnull(@tipSalarizare,0)
	
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)
	
	if month(@dataJos)=month(@dataSus) and year(@dataJos)=year(@dataSus) and ((year(@dataJos)=@AnulInch and month(@dataJos)>=@LunaInch) or year(@dataJos)>@AnulInch)
		set @Perioada='Luna'
	else
		set @Perioada='Perioada'

	insert @stat_functii
	select @dataSus as Data, max(l.LunaAlfa) as Luna_alfa, (case when @Ordonare='Pe functie' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end ) as Loc_de_munca, max(lm.Denumire) as Denumire_lm, 
	isnull(i.Cod_functie,p.Cod_functie) as Cod_functie, max(f.Denumire) as Denumire_functie, (case when @detaliereSalariati=1 then p.Marca else '' end), 
	(case when @detaliereSalariati=1 then max(p.Nume) else '' end) as Nume, count(p.Marca) as Numar_marci, max(fc.Cod_functie) as Functie_COR, max(f.Nivel_de_studii)
	from personal p
		left outer join istPers i on i.Data=@dataSus and i.Marca=p.Marca
		left outer join functii f on f.Cod_functie=isnull(i.Cod_functie,p.Cod_functie)
		left outer join extinfop e on e.Marca=p.Cod_functie and e.Cod_inf='#CODCOR'
		left outer join Functii_COR fc on fc.Cod_functie=e.Val_inf
		left outer join lm on lm.Cod=isnull(i.Loc_de_munca,p.Loc_de_munca)
		left outer join calstd l on l.data=@dataJos
	where @Perioada='Luna' and p.Grupa_de_munca not in ('O','P') 
		and (@oFunctie=0 or isnull(i.Cod_functie,p.Cod_functie) like  rtrim(@cFunctia)+(case when @FFArborescent=1 then '%' else '' end)) 
		and (@unLm=0 or isnull(i.Loc_de_munca,p.Loc_de_munca) between @lmJos and @lmSus) 
		and (((convert(char(1),p.Loc_ramas_vacant)=1 and (@salariatiPlecatiLuna=0 and p.Data_plec>=@dataJos or @salariatiPlecatiLuna=1 and p.Data_plec>@dataSus)) 
			or convert(char(1),p.Loc_ramas_vacant)=0)) and p.Data_angajarii_in_unitate<=@dataSus
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
		and (@q_tipSalarizare=0 or @q_tipSalarizare=1 and p.Tip_salarizare in ('1','2') or @q_tipSalarizare=2 and p.Tip_salarizare in ('3','4','5','6','7'))
	group by (case when @Ordonare='Pe functie' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end ), isnull(i.Cod_functie,p.Cod_functie), (case when @detaliereSalariati=1 then p.Marca else '' end)
	union all
	select i.Data as Data, max(l.LunaAlfa) as Luna_alfa, (case when @Ordonare='Pe functie' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end) as Loc_de_munca, max(lm.Denumire) as Denumire_lm, 
	i.Cod_functie as Cod_functie, max(f.Denumire) as Denumire_functie, (case when @detaliereSalariati=1 then i.Marca else '' end), 
	(case when @detaliereSalariati=1 then max(i.Nume) else '' end) as Nume, count(i.Marca) as Numar_marci, max(fc.Cod_functie) as Functie_COR, max(f.Nivel_de_studii)
	from istpers i 
		left outer join calstd l on i.Data=l.data
		left outer join personal p on p.Marca=i.Marca 
		left outer join functii f on f.Cod_functie=i.Cod_functie
		left outer join extinfop e on e.Marca=i.Cod_functie and e.Cod_inf='#CODCOR'
		left outer join Functii_COR fc on fc.Cod_functie=e.Val_inf
		left outer join lm on lm.Cod=i.Loc_de_munca 
	where @Perioada<>'Luna' and i.Data between @dataJos and @dataSus and i.Grupa_de_munca not in ('O','P') 
		and (@oFunctie=0 or i.cod_functie like rtrim(@cFunctia)+(case when @FFArborescent=1 then '%' else '' end)) 
		and (@unLm=0 or i.loc_de_munca  between @lmJos and @lmSus) 
		and (((convert(char(1),p.loc_ramas_vacant)=1 and (@salariatiPlecatiLuna=0 and p.data_plec>=dbo.bom(i.Data) or @salariatiPlecatiLuna=1 and p.data_plec>i.Data)) or convert(char(1),p.loc_ramas_vacant)=0)) and p.data_angajarii_in_unitate<=i.Data
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.Loc_de_munca))
		and (@q_tipSalarizare=0 or @q_tipSalarizare=1 and i.Tip_salarizare in ('1','2') or @q_tipSalarizare=2 and i.Tip_salarizare in ('3','4','5','6','7'))
	group by i.Data, (case when @Ordonare='Pe functie' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end ), i.cod_functie, (case when @detaliereSalariati=1 then i.marca else '' end)
	order by Data, (case when @Ordonare='Pe functie' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end), Cod_functie, (case when @detaliereSalariati=1 then max(p.Nume) else '' end)
	return
end
