--***
/**	functie lista angajari	*/
Create
function  [dbo].[fAngajari] (@TipRaport char(50), @DataJos datetime, @DataSus datetime, @oMarca int, @Marca char(6), @oFunctie int, @Cod_functie char(6),@unLocm int, @Loc_de_munca char(9), @Strict int, @unTipPersonal int, @TipPersonal char(1), 
	@FiltruZileRamase int, @ZileRamase int, @oDataAngajarii int, @DataAngajariiJos datetime, @DataAngajariiSus datetime, 
	@pOrdonare char(50), @Alfabetic int, @DataZiCrt datetime) 
	returns @Angajari table (Marca char(6), Nume char(50), CNP char(13), Salar_de_baza float, Cod_functie char(6), 
	Denumire_functie char(30), Loc_de_munca char(9), Denumire_lm char(30), Numar_contract char(20), Data_contract datetime, 
	Tip_contract char(30), Durata_contract int, Data_angajarii datetime, Data_plecarii datetime, Ordonare char(50))
as
begin
	declare @userASiS char(10), @PerioadaProbaZile int, @LunaInch int, @AnulInch int, @DataInch datetime
	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	set @PerioadaProbaZile=dbo.iauParL('PS','PPROBA_ZI')
	set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	if @LunaInch not between 1 and 12 or @AnulInch<=1901
		return
	set @DataInch=dateadd(month,1,convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))
	if @DataJos='01/01/1901'
		Set @DataJos=@DataInch
	
	insert @Angajari
	select p.Marca, p.Nume, p.Cod_numeric_personal, p.Salar_de_baza, p.Cod_functie, f.denumire, p.Loc_de_munca, l.Denumire, 
	i.Nr_contract, isnull((select max(data_inf) from extinfop e where e.marca=p.marca and e.cod_inf='DATAINCH'),p.data_angajarii_in_unitate), 
	(case when p.Mod_angajare='D' then 'Durata determinata' else 'Durata nedeterminata' end), p.Zile_absente_an, p.Data_angajarii_in_unitate, p.Data_plec, 
	(case when @pOrdonare='Loc de munca' then p.Loc_de_munca else '' end) as Ordonare
	from personal p
		left outer join infopers i on i.Marca=p.Marca
		left outer join functii f on f.Cod_functie=p.Cod_functie
		left outer join lm l on l.Cod=p.Loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where (@oMarca=0 or p.Marca=@Marca) and (@oFunctie=0 or p.Cod_functie=@Cod_functie) 
		and (@unLocm=0 or p.Loc_de_munca between @Loc_de_munca and rtrim(@Loc_de_munca)+(case when @Strict=1 then '%' else '' end))
		and (@unTipPersonal=0 or @TipPersonal='T' and p.Tip_salarizare between '1' and '2' or @TipPersonal='M' and p.Tip_salarizare between '3' and '7')
		and (@TipRaport='Pe durata determinata' or 
		p.Zile_absente_an between (case when @TipRaport='Pe durata nedeterminata cu perioada de proba' then 1 else 0 end) and 
		(case when @TipRaport='Pe durata nedeterminata cu perioada de proba' then 99999 else 0 end))
		and (@TipRaport='Pe durata determinata' and p.Mod_angajare='D' or @TipRaport<>'Pe durata determinata' and p.Mod_angajare='N')
		and (@oDataAngajarii=0 or p.Data_angajarii_in_unitate between @DataAngajariiJos and @DataAngajariiSus)
		and (convert(char(1),loc_ramas_vacant)=0 or convert(char(1),loc_ramas_vacant)=1 and p.Data_plec>@DataJos) 
		and (@FiltruZileRamase=0 or @FiltruZileRamase=1 and @PerioadaProbaZile=0 AND datediff(day, @DataZiCrt, dateadd(month, p.Zile_absente_an, p.Data_angajarii_in_unitate))<=@ZileRamase and datediff(day,@DataZiCrt,dateadd(month,p.Zile_absente_an,p.Data_angajarii_in_unitate))>=0 
		or @FiltruZileRamase=1 and @PerioadaProbaZile=1 AND datediff(day, @DataZiCrt, dateadd(DAY,p.Zile_absente_an,p.Data_angajarii_in_unitate))<=@ZileRamase and datediff(day, @DataZiCrt, dateadd(DAY,p.Zile_absente_an,p.Data_angajarii_in_unitate))>= 0 
		or @FiltruZileRamase=2 and @PerioadaProbaZile=0 AND datediff(day, @DataZiCrt, dateadd(month, p.Zile_absente_an, p.Data_angajarii_in_unitate))=@ZileRamase 
		or @FiltruZileRamase=2 and @PerioadaProbaZile=1 AND datediff(day, @DataZiCrt, dateadd(DAY,p.Zile_absente_an,p.Data_angajarii_in_unitate))=@ZileRamase)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	order by (case when @pOrdonare='Loc de munca' then p.Loc_de_munca else '' end),
	(case when @Alfabetic=1 then p.Nume else p.Marca end)
	return
end
