/*	procedura pentru raportul de angajari dupa durata contractului	*/
Create procedure rapAngajari 
	(@tipraport char(1), @dataJos datetime, @dataSus datetime, @marca char(6)=null, @cod_functie char(6)=null, @locm char(9)=null, @strict int=0, @tippersonal char(1)=null, 
	@tipzileramase int, @zileramase int, @dataAngajariiJos datetime, @dataAngajariiSus datetime, @ordonare char(50), @alfabetic int, @dataZiCrt datetime) 
as
/*
		@tipraport=1	->		Pe durata nedeterminata cu perioada de proba
		@tipraport=2	->		Pe durata nedeterminata fara perioada de proba
		@tipraport=3	->		Pe durata determinata
*/
begin
	declare @userASiS char(10), @DreptConducere int, @PerioadaProbaZile int, @LunaInch int, @AnulInch int, @DataInch datetime, @AreDreptCond int, 
		@formaJuridica varchar(100)	-- daca setat forma juridica foarte probabil se genereaza Revisalul din ASiS; 
									-- in acest caz la contractele pe perioada determinata trebuie cules data de sfarsit a contractului in campul Data_plec (fara a fi bifat Plecat)
									-- vom valida zilele ramase pana la finalul contractului functie de data_sfarsit si nu functie de durata exprimata in zile/luni

	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	set @DreptConducere=dbo.iauParL('PS','DREPTCOND')	
	set @PerioadaProbaZile=dbo.iauParL('PS','PPROBA_ZI')
	set @formaJuridica=dbo.iauParL('GE','FJURIDICA')
	set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)

	if @LunaInch not between 1 and 12 or @AnulInch<=1901
		return
	set @DataInch=dateadd(month,1,convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))
	if @dataJos='01/01/1901'
		Set @dataJos=@DataInch

	declare @listaDrept char(1)
	set @listaDrept='T'
	if @DreptConducere=1 
	begin
		set @AreDreptCond=isnull((select dbo.verificDreptUtilizator(@userASiS,'SALCOND')),0)
		if @AreDreptCond=0
			set @listaDrept='S'
	end
	
	select p.marca, p.nume, p.cod_numeric_personal as cnp, p.salar_de_baza, p.cod_functie, f.denumire as den_functie, p.loc_de_munca as lm, lm.Denumire as den_lm, 
	i.Nr_contract as numar_contract, isnull((select max(data_inf) from extinfop e where e.marca=p.marca and e.cod_inf='DATAINCH'),p.data_angajarii_in_unitate) as data_contract, 
	(case when p.Mod_angajare='D' then 'Durata determinata' else 'Durata nedeterminata' end) as tip_contract, 
	space(4-LEN(ltrim(rtrim(convert(char(3),p.Zile_absente_an)))))+ltrim(rtrim(convert(char(3),p.Zile_absente_an)))+' '+(case when @PerioadaProbaZile=1 then 'zile' else 'luni' end) as durata_contract, 
	p.Data_angajarii_in_unitate as data_angajarii, p.Data_plec as data_plecarii, (case when @ordonare='Loc de munca' then p.Loc_de_munca else '' end) as ordonare
	from personal p
		left outer join infopers i on i.Marca=p.Marca
		left outer join functii f on f.Cod_functie=p.Cod_functie
		left outer join lm on lm.Cod=p.Loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where (@marca is null or p.Marca=@marca) and (@cod_functie is null or p.Cod_functie=@cod_functie) 
		and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end))
		and (@tippersonal is null or @tippersonal='T' and p.Tip_salarizare between '1' and '2' or @tippersonal='M' and p.Tip_salarizare between '3' and '7')
		and (@tipraport='3' or p.Zile_absente_an between (case when @tipraport='1' then 1 else 0 end) and (case when @tipraport='1' then 99999 else 0 end))
		and (@tipraport='3' and p.Mod_angajare='D' or @tipraport<>'3' and p.Mod_angajare='N')
		and (@dataAngajariiJos is null or p.Data_angajarii_in_unitate between @dataAngajariiJos and @dataAngajariiSus)
		and (convert(char(1),loc_ramas_vacant)=0 or convert(char(1),loc_ramas_vacant)=1 and p.Data_plec>@dataJos) 
--	filtrari pt. contractele pe per. nedeterminata cu perioada de proba sau contractele pe per. determinata
--	@tipzileramase=1 - cel mult X zile ramase din contract/per. de proba; @tipzileramase=2 - exact X zile ramase din contract/per. de proba
		and (@zileramase is null or @tipzileramase=1 and @PerioadaProbaZile=0 and (@tipraport in ('1','2') or @formaJuridica='')
				AND datediff(day, @DataZiCrt, dateadd(month, p.Zile_absente_an, p.Data_angajarii_in_unitate))<=@ZileRamase and datediff(day,@DataZiCrt,dateadd(month,p.Zile_absente_an,p.Data_angajarii_in_unitate))>=0 
			or @tipzileramase=1 and @PerioadaProbaZile=1 and (@tipraport in ('1','2') or @formaJuridica='')
				AND datediff(day, @DataZiCrt, dateadd(DAY,p.Zile_absente_an,p.Data_angajarii_in_unitate))<=@ZileRamase and datediff(day,@DataZiCrt,dateadd(DAY,p.Zile_absente_an,p.Data_angajarii_in_unitate))>=0 
			or @tipzileramase=1 and @tipraport='3' and @formaJuridica<>'' AND datediff(day,@DataZiCrt,p.Data_plec)<=@ZileRamase and p.Loc_ramas_vacant=0 --and datediff(day,@DataZiCrt,p.Data_plec)>=0 
			or @tipzileramase=2 and @PerioadaProbaZile=0 and (@tipraport in ('1','2') or @formaJuridica='')
				AND datediff(day, @DataZiCrt, dateadd(month,p.Zile_absente_an,p.Data_angajarii_in_unitate))=@ZileRamase 
			or @tipzileramase=2 and @PerioadaProbaZile=1 and (@tipraport in ('1','2') or @formaJuridica='') 
				and datediff(day, @DataZiCrt, dateadd(DAY,p.Zile_absente_an,p.Data_angajarii_in_unitate))=@ZileRamase 
			or @tipzileramase=2 and @tipraport='3' and @formaJuridica<>'' AND datediff(day,@DataZiCrt,p.Data_plec)>=@ZileRamase)
--	filtru dupa drept de conducere/salariat
		and (@DreptConducere=0 or (@AreDreptCond=1 and (@listaDrept='T' or @listaDrept='C' and p.pensie_suplimentara=1 or @listaDrept='S' and p.pensie_suplimentara<>1)) 
			or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	order by (case when @ordonare='Loc de munca' then p.Loc_de_munca else '' end),
	(case when @Alfabetic=1 then p.Nume else p.Marca end)
	return
end
