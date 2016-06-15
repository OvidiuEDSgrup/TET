--***
Create procedure rapAcordIndividual
	@dataJos datetime, @dataSus datetime, @marca char(6)=null, @locm char(9)=null, @strict int=0, @exceptieacordcolectiv int, 
	@tipraport int, @afisareacord int, @ordonare int, @comanda varchar(20)=null, @salariatiregie int=null
as
/*
	@afisareacord	-> afisare acord al corectia L.
	@tip_raport:	1	= Acord individual
					2	= Acord indirect
*/
begin
	set transaction isolation level read uncommitted
	declare @userASiS char(10), @OreLuna int, @NrMOreLuna float, @SalariatiPeComenzi int, @ButonRealizari int, @IndiciRealcom int, @Simex int, @ArlCJ int
--	pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @NrMOreLuna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	set @SalariatiPeComenzi=dbo.iauParL('PS','SALCOM')
	set @ButonRealizari=dbo.iauParN('PS','REALIZARI')
	set @IndiciRealcom=dbo.iauParL('PS','INDICICOM')
	set @Simex=dbo.iauParL('SP','SIMEX')
	set @ArlCJ=dbo.iauParL('SP','ARLCJ')

	select a.data as data, a.marca as marca, p.nume as nume, a.numar_curent as numar_curent, 
	isnull(i.Cod_functie,p.cod_functie) as cod_functie, f.denumire as den_functie, a.loc_de_munca as lm, lm.Denumire as den_lm,
	isnull(i.grupa_de_munca,p.grupa_de_munca) as grupa_de_munca, isnull(i.salar_de_incadrare,p.salar_de_incadrare) as salar_de_incadrare, 
	isnull(c.suma_corectie,0) as suma_corectieL, isnull(c.procent_corectie,0) as procent_corectieL, 
	isnull(b.Sp_salar_realizat,0) as procent_lucrat_acord, a.tip_salarizare as tip_salarizare, 
	a.ore_lucrate as ore_lucrate, round(a.salar_orar,3) as salar_orar, a.ore_regie as ore_regie, a.ore_acord as ore_acord, 
	a.ore_suplimentare_1 as ore_suplimentare_1, a.ore_suplimentare_2 as ore_suplimentare_2, a.ore_suplimentare_3 as ore_suplimentare_3, a.ore_suplimentare_4 as ore_suplimentare_4, 
	round(isnull(i.salar_de_incadrare,p.salar_de_incadrare)/(case when a.Tip_salarizare='2' then @OreLuna else @NrMOreLuna end),3) as salar_orar_pontaj,
	round((case when @ArlCJ=1 and a.Tip_salarizare='4' then a.Ore_acord else a.Ore_lucrate end)*
	isnull(i.salar_de_incadrare,p.salar_de_incadrare)/(case when a.Tip_salarizare='2' then @OreLuna else @NrMOreLuna end),3) as salar_pontaj,
	round(a.coeficient_acord,3) as coeficient_acord, a.realizat as realizat_acord, a.coeficient_de_timp as coeficient_timp, a.ore_realizate_acord as ore_realizate_acord, 
	isnull(r.Realizat_pe_marca,0) as realizat_pe_marca, isnull(r.Ore_acord_realcom,0) as ore_acord_realcom, 
	round((case when (a.Ore_acord+(case when @ArlCJ=1 then 0 else a.Ore_regie end))=0 then 0 when isnull(r.Realizat_pe_marca,0)/((a.Ore_acord+(case when @ArlCJ=1 then 0 else a.Ore_regie end))*
		isnull(i.salar_de_incadrare,p.salar_de_incadrare)/(case when a.Tip_salarizare='2' then @OreLuna else @NrMOreLuna end))=0 and @afisareacord=1 
		then isnull((case when c.procent_corectie>70 then c.procent_corectie/70 else c.procent_corectie end),0)
		else isnull(r.Realizat_pe_marca,0)/((a.Ore_acord+(case when @ArlCJ=1 then 0 else a.Ore_regie end))
		*isnull(i.salar_de_incadrare,p.salar_de_incadrare)/(case when a.Tip_salarizare='2' then @OreLuna else @NrMOreLuna end)) end),6) as coef_acord_calculat,
	(case when a.realizat=0 and @afisareacord=1 then b.Sp_salar_realizat 
	else (case when isnull(r.Realizat_pe_marca,0)=0 and (@ButonRealizari=2 or 1=1) then a.Realizat else isnull(r.Realizat_pe_marca,0) end) end) as realizat_acord_calculat,
	(case when (a.Ore_regie+a.Ore_acord)=0 then 0 else round(isnull(r.Ore_acord_realcom,0)/(a.Ore_regie+a.Ore_acord),6) end) as coef_orar_calculat
	from pontaj a
		left outer join personal p on a.marca = p.marca
		left outer join functii f on p.cod_functie = f.cod_functie
		left outer join lm on lm.Cod = a.Loc_de_munca
		left outer join istpers i on i.Data=dbo.eom(a.Data) and i.marca = a.marca
		left outer join corectii c on a.marca = c.marca and c.data = dbo.eom(a.data) and c.tip_corectie_venit='L-'
		left outer join brut b on a.marca = b.marca and a.loc_de_munca = b.loc_de_munca and b.data = dbo.eom(a.data)
--	legatura pe realcom pentru cazul in care se lucreaza cu setarea de pontaj pe comenzi
		left join realcom rm on a.marca=rm.marca and a.loc_de_munca=rm.loc_de_munca and a.data=rm.data and 'PS'+rtrim(a.numar_curent)=isnull(rm.numar_document,'')
		left outer join (select Data, Marca, sum(round((case when @IndiciRealcom=1 and norma_de_timp>0 then norma_de_timp else 1 end)*cantitate*tarif_unitar,2)) as Realizat_pe_marca,
			sum(round((case when @IndiciRealcom=0 and categoria_salarizare='' then norma_de_timp else 1 end)*cantitate,0)) as Ore_acord_realcom
			from realcom 
			where Data between @dataJos and @dataSus Group by Data, Marca) r on r.Data=a.Data and r.Marca=a.Marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
	where a.data between @dataJos and @dataSus and (@marca is null or a.marca=@marca) 
		and (@locm is null or a.loc_de_munca like rtrim(@locm)+(case when @strict=0 then '' else '%' end)) and (@exceptieacordcolectiv=0 or a.tip_salarizare='2') 
--	filtrarea pe comanda functioneaza doar daca se lucreaza cu setarea de pontaj pe comenzi
		and (@comanda is null or rm.comanda like @comanda)
		and (@tipraport=1 and (a.tip_salarizare='4' or @SalariatiPeComenzi=1 and @salariatiregie=1 and a.Tip_salarizare in ('1','3') and isnull(rm.Comanda,'')<>'') 
			or @tipraport=2 and (a.tip_salarizare='2' or a.tip_salarizare='5' and (@Simex=0 or (select count(1) from realcom r where r.loc_de_munca=a.loc_de_munca and r.data between @dataJos and @dataSus)=0))) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	order by a.loc_de_munca, (case when @Ordonare=1 then a.marca else p.nume end), a.data

	return
end

/*
	exec rapAcordIndividual '01/01/2013', '01/31/2013', null, null, 0, 0, 1, 0, 0, null, 1
*/
