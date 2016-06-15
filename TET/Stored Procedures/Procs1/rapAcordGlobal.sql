/**	procedura pentru raportul acord global */
Create procedure rapAcordGlobal
	(@dataJos datetime, @dataSus datetime, @locm char(9)=null, @strict int=0, @comanda char(20)=null, @marca char(6)=null, @ordonare char(1), @detalierecomenzi int)
as
begin try
	set transaction isolation level read uncommitted
	declare @sub char(9), @spSimex int, @Acord_global_Tesa_acord int, @Oresupl1_ore_acord int, @Oresupl2_ore_acord int, @Ore_luna float, @Orem_luna float

	Set @sub=dbo.iauParA('GE','SUBPRO')
	Set @spSimex=dbo.iauParL('SP','SIMEX')
	Set @Acord_global_Tesa_acord=dbo.iauParL('PS','ACGLOTESA')
	Set @Oresupl1_ore_acord=dbo.iauParL('PS','ACORD-OS1')
	Set @Oresupl2_ore_acord=dbo.iauParL('PS','ACORD-OS2')
	Set @Ore_luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	Set @OreM_luna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
	
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	Set @utilizator = dbo.fIaUtilizator(null)

	select a.data, a.marca, a.numar_curent, p.nume, p.cod_functie, f.denumire as den_functie, a.loc_de_munca as lm, lm.Denumire as den_lm, 
		p.grupa_de_munca, p.salar_de_incadrare, isnull(r.Comanda,'') as comanda, isnull(z.Descriere,'') as den_comanda, 
		isnull(c.suma_corectie,0) as suma_corectie, isnull(c.procent_corectie,0) as procent_corectie, b.Sp_salar_realizat as procent_lucrat_acord, 
		a.tip_salarizare, a.regim_de_lucru, a.ore_lucrate, a.ore_acord, a.ore_suplimentare_1, a.ore_suplimentare_2, 
		(ore_acord-(case when @Oresupl1_ore_acord=1 then a.Ore_suplimentare_1 else 0 end)-(case when @Oresupl2_ore_acord=1 then a.Ore_suplimentare_2 else 0 end)) as ore_pt_acord, 
		a.salar_orar, (case when a.Tip_salarizare in ('6','7') then a.salar_categoria_lucrarii else p.Salar_de_incadrare/
		(case when a.Tip_salarizare='2' then @Ore_luna else @Orem_luna end)*(case when p.Grupa_de_munca in ('C','O','P') then a.Regim_de_lucru/8 else 1 end) end) as salar_orar_calculat,
		(ore_acord-(case when @Oresupl1_ore_acord=1 then a.Ore_suplimentare_1 else 0 end)-
		(case when @Oresupl2_ore_acord=1 then a.Ore_suplimentare_2 else 0 end))* 
		(case when a.Tip_salarizare in ('6','7') then a.salar_categoria_lucrarii else p.Salar_de_incadrare/
		(case when a.Tip_salarizare='2' then @Ore_luna else @Orem_luna end)*(case when p.Grupa_de_munca in ('C','O','P') then a.Regim_de_lucru/8 else 1 end) end)*isnull(r.manopera_comanda,1)/isnull(manopera_locm,1) as salar_pontaj,
		a.coeficient_acord, round(a.realizat*isnull(r.manopera_comanda,1)/isnull(manopera_locm,1),2) as realizat, a.coeficient_de_timp, a.ore_realizate_acord 
	from pontaj a
		left outer join personal p on a.marca = p.marca
		left outer join lm on a.Loc_de_munca= lm.Cod
		left outer join functii f on p.cod_functie = f.cod_functie
		left outer join corectii c on a.marca = c.marca and c.data = dbo.eom(a.data) and c.tip_corectie_venit='L-'
		left outer join brut b on a.marca = b.marca and a.loc_de_munca = b.loc_de_munca and b.data = dbo.eom(a.data)
		left outer join (select loc_de_munca, Comanda, sum(cantitate*tarif_unitar) as Manopera_comanda from realcom where data between @dataJos and @dataSus group by loc_de_munca, comanda) r on @detalierecomenzi=1 and a.loc_de_munca=r.loc_de_munca 
		left outer join (select loc_de_munca, sum(cantitate*tarif_unitar) as Manopera_locm from realcom where data between @dataJos and @dataSus group by loc_de_munca) r1 on @detalierecomenzi=1 and a.loc_de_munca=r1.loc_de_munca 
		left outer join comenzi z on z.Subunitate=@sub and z.Comanda=r.Comanda
	where a.data between @dataJos and @dataSus 
		and (@locm is null or a.loc_de_munca like rtrim(@locm)+(case when @strict=1 then '' else '%' end)) 
		and ((a.tip_salarizare='5' or a.tip_salarizare='7' or @Acord_global_Tesa_acord=1 and a.tip_salarizare='2') 
		and (@spSimex=0 or (select count(1) from realcom r where r.loc_de_munca=a.loc_de_munca and r.data between @dataJos and @dataSus)>0)) 
		and (@comanda is null or r.comanda=@comanda) and (@marca is null or a.Marca=@marca)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare lu where lu.utilizator=@utilizator and lu.cod=a.loc_de_munca))
	order by a.loc_de_munca, (case when @Ordonare=1 then a.marca else p.nume end), a.data
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapAcordGlobal (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
/*
	exec rapAcordGlobal '09/01/2011', '09/30/2011', null, 0, null, null, '1', 0
*/
