--***
/**	procedura pentru lista avans salarii */
Create procedure rapAvansSalarii 
	(@dataJos datetime, @dataSus datetime, @MarcaJ char(6), @MarcaS char(6), @locm char(9)=null, @strict int=0, @locmExcep char(9)=null, 
	@mandatar char(6)=null, @grupaMunca char(1)=null, @card char(30)=null, @tipSalarizare char(1)=null, @tipstat varchar(30)=null, 
	@ordonare char(1), @LimitaAvans int, @LimitaPremii int, @listaDreptCond char(1)='T', @numaiOreAvMM0 int=0, @AparecorM int=0, @alfabetic int=0, @afisarecnp int=0)
as
/*
	Ordonare=0 -> Locuri de munca, salariati
	Ordonare=1 -> Salariati
	Ordonare=3 -> Mandatar
*/
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	declare @utilizator char(10), @dreptConducere int, @areDreptCond int, @DetTipCorectii int, @RetineriAvans int, @mandatari int, @Dafora int, @Salubris int

--	pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator=dbo.fIaUtilizator(null)
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')
	set @DetTipCorectii=dbo.iauParL('PS','SUBTIPCOR')
	set @RetineriAvans=dbo.iauParL('PS','RETAVANS')
	set @mandatari=dbo.iauParL('PS','MANDATARI')
	set @Dafora=dbo.iauParL('SP','DAFORA')
	set @Salubris=dbo.iauParL('SP','SALUBRIS')

--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0 -- daca utilizatorul nu are drept conducere atunci are acces doar la cei de tip salariat
			set @listaDreptCond='S'
	end

	select n.data, n.marca, max(rtrim(isnull(i.Nume,p.Nume)))+(case when @afisarecnp=1 then ' - '+rtrim(max(p.Cod_numeric_personal)) else '' end) as nume, 
		max(n.loc_de_munca) as loc_de_munca, max(rtrim(lm.denumire)) as denumire_lm, max(lm.cod_parinte) as lm_parinte, 
		isnull(max(i.cod_functie),max(p.cod_functie)) as cod_functie, max(rtrim(f.denumire)) as denumire_functie, isnull(max(i.Salar_de_incadrare),max(p.Salar_de_incadrare)) as salar_de_incadrare, 
		max(n.avans) as avans, max(n.premiu_la_avans) as premiu_la_avans, max(isnull(r.Retinut_la_avans,0)) as retinere_la_avans, 
		isnull(max(c1.suma_corectie),0) as suma_corectie_M, isnull(max(c2.suma_corectie),0) as suma_corectie_N, isnull(max(c3.suma_corectie),0) as suma_corectie_O, 
		(case when isnull(max(a.marca),'X')<>'X' then 1 else 0 end) as exista_avans_exceptie, 
		(case when @Dafora=1 then isnull(max(a.suma_avans),0) else 0 end) as avans_exceptie_Dafora, isnull(max(a.ore_lucrate_la_avans),0) as ore_avans_exceptie, 
		isnull(max(cm.zile_lucratoare),0) as zile_lucratoare_CM, 
		max(n.avans)-(case when @Dafora=1 then isnull(max(a.suma_avans),0) else 0 end) as avans_de_afisat, max(isnull(s.Suma_corectie,0)) as suma_corectieC_Salubris, 
		max(n.avans)+max(n.premiu_la_avans)+(case when @AparecorM=1 then isnull(max(c1.suma_corectie),0) else 0 end)- max(isnull(r.Retinut_la_avans,0)) as rest_de_plata_avans, 
		max(p.banca) as banca, max(p.categoria_salarizare) as categoria_salarizare, isnull(max(i.grupa_de_munca),max(p.grupa_de_munca)) as Grupa_de_munca, 
		(case when @ordonare='3' then max(isnull(m.mandatar,'')) else '' end) as Mandatar, max(isnull(pm.Nume,'')) as nume_mandatar, 
		(case when @ordonare='3' then max(isnull(m.mandatar,'')) else '' end)+(case when @ordonare='2' then '' else max(n.loc_de_munca) end)+(case when @alfabetic=1 then max(p.nume) else n.marca end) as ordonare 
	from net n 
		left outer join personal p on n.marca=p.marca
		left outer join infopers ip on n.marca=ip.marca
		left outer join avexcep a on n.data=a.data and n.marca=a.marca
		left outer join (select data, marca, sum(zile_lucratoare) as zile_lucratoare from conmed where data between @dataJos and @dataSus group by data, marca) cm on n.data=cm.data and n.marca=cm.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'M-', '', '', 0) c1 on @AparecorM=1 and n.data=c1.data and n.marca=c1.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'N-', '', '', 0) c2 on @AparecorM=1 and n.data=c2.data and n.marca=c2.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'O-', '', '', 0) c3 on @AparecorM=1 and n.data=c3.data and n.marca=c3.marca
		left outer join istpers i on n.data=i.data and n.marca=i.marca
		left outer join lm on n.loc_de_munca=lm.cod
		left outer join functii f on f.cod_functie=p.cod_functie
		left outer join mandatar m on @mandatari=1 and m.loc_munca=n.Loc_de_munca
		left outer join personal pm on @mandatari=1 and pm.marca=m.Mandatar
		left outer join (select data as data, marca, sum(Retinut_la_avans) as Retinut_la_avans from resal 
			where data between @dataJos and @dataSus and Retinut_la_avans<>0 group by data, marca) r on @RetineriAvans=1 and n.data=r.data and n.marca=r.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'C-', '', '', 0) s on @Salubris=1 and n.data=s.data and n.marca=s.marca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=n.Loc_de_munca
	where n.data = @dataSus and (@MarcaJ='' or n.marca between @MarcaJ and @MarcaS) 
		and (@locm is null or n.loc_de_munca like RTRIM(@locm)+(case when @strict=1 then '' else '%' end))
		and (@LimitaAvans<>1 or n.avans>0)  and (@LimitaPremii<>1 or n.premiu_la_avans>0) 
		and (@grupaMunca is null  or p.grupa_de_munca=@grupaMunca) 
		and (@mandatar is null  or exists (select loc_munca from mandatar where mandatar=@mandatar and Loc_munca=n.loc_de_munca)) 
		and (@card is null or p.banca=@card) and (@tipSalarizare is null or p.tip_salarizare=@tipSalarizare) 
		and (@dreptConducere=0 or (@AreDreptCond=1 and (@ListaDreptCond='T' or @ListaDreptCond='C' and p.pensie_suplimentara=1 or @ListaDreptCond='S' and p.pensie_suplimentara<>1)) 
			or (@AreDreptCond=0 and p.pensie_suplimentara<>1)) 
		and (@tipstat is null or ip.religia=@tipstat) 
		and (@numaiOreAvMM0=0 or a.ore_lucrate_la_avans>0) and (@locmExcep is null or n.loc_de_munca not like @locmExcep+'%')
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	group by n.Data, n.Marca 
	order by ordonare
end try

begin catch
	set @eroare='Procedura rapAvansSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapAvansSalarii '03/01/2012', '03/31/2012', '', 'ZZZ', Null, 0, Null, Null, Null, Null, Null, Null, '1', 0, 0, 'T', 0, 0, 0
*/
