--***
/**	functie lista acord global	*/
Create 
function [dbo].[fLista_acord_global] 
	(@pDatajos datetime, @pDatasus datetime, @pLocm_jos char(9), @pLocm_sus char(9), @Ordonare char(1), 
	@lDetaliere_comenzi int, @lComanda int, @pComanda char(20), @lMarca int, @pMarca char(6))
returns @Acord_global table
	(Data datetime, Marca char(6), Numar_curent int, Nume char(50), Cod_functie char(6), Grupa_de_munca char(1), 
	Salar_de_incadrare float, Denumire_functie char(30), Loc_de_munca char(9), Comanda char(13), Suma_corectie float, Procent_corectie float, 
	Procent_lucrat_acord float, Tip_salarizare char(1), Regim_de_lucru float, Ore_lucrate int, Ore_acord int, Ore_suplimentare_1 int, Ore_suplimentare_2 int, 
	Ore_pt_acord int, Salar_orar float, Salar_orar_calculat float, Salar_pontaj float, Coeficient_acord float,Realizat float, Coeficient_de_timp float, Ore_realizate_acord float)
as
begin
	declare @spSimex int, @lAcord_global_Tesa_acord int, @lOresupl1_ore_acord int, 
	@lOresupl2_ore_acord int, @Ore_luna float, @Orem_luna float
	Set @spSimex=dbo.iauParL('SP','SIMEX')
	Set @lAcord_global_Tesa_acord=dbo.iauParL('PS','ACGLOTESA')
	Set @lOresupl1_ore_acord=dbo.iauParL('PS','ACORD-OS1')
	Set @lOresupl2_ore_acord=dbo.iauParL('PS','ACORD-OS2')
	Set @Ore_luna=dbo.iauParLN(@pDatasus,'PS','ORE_LUNA')
	Set @OreM_luna=dbo.iauParLN(@pDatasus,'PS','NRMEDOL')

	insert into @Acord_global
	select a.data, a.marca, a.numar_curent, b.nume, b.cod_functie, b.grupa_de_munca, b.salar_de_incadrare, c.denumire, 
		a.loc_de_munca, isnull(r.Comanda,''), e.suma_corectie, e.procent_corectie, f.Sp_salar_realizat, 
		a.tip_salarizare, a.regim_de_lucru, a.ore_lucrate, a.ore_acord, a.ore_suplimentare_1, a.ore_suplimentare_2, 
		(ore_acord-(case when @lOresupl1_ore_acord=1 then a.Ore_suplimentare_1 else 0 end)-
		(case when @lOresupl2_ore_acord=1 then a.Ore_suplimentare_2 else 0 end)), a.salar_orar, 
		(case when a.Tip_salarizare in ('6','7') then a.salar_categoria_lucrarii else b.Salar_de_incadrare/
		(case when a.Tip_salarizare='2' then @Ore_luna else @Orem_luna end)*(case when b.Grupa_de_munca in ('C','O','P') then a.Regim_de_lucru/8 else 1 end) end),
		(ore_acord-(case when @lOresupl1_ore_acord=1 then a.Ore_suplimentare_1 else 0 end)-
		(case when @lOresupl2_ore_acord=1 then a.Ore_suplimentare_2 else 0 end))* 
		(case when a.Tip_salarizare in ('6','7') then a.salar_categoria_lucrarii else b.Salar_de_incadrare/
		(case when a.Tip_salarizare='2' then @Ore_luna else @Orem_luna end)*(case when b.Grupa_de_munca in ('C','O','P') then a.Regim_de_lucru/8 else 1 end) end)*isnull(r.manopera_comanda,1)/isnull(manopera_locm,1),
		a.coeficient_acord, 
		round(a.realizat*isnull(r.manopera_comanda,1)/isnull(manopera_locm,1),2), a.coeficient_de_timp, a.ore_realizate_acord 
	from pontaj a
		left outer join personal b on a.marca = b.marca
		left outer join functii c on b.cod_functie = c.cod_functie
		left outer join corectii e on a.marca = e.marca and e.data = dbo.eom(a.data) and e.tip_corectie_venit='L-'
		left outer join brut f on a.marca = f.marca and a.loc_de_munca = f.loc_de_munca and f.data = dbo.eom(a.data)
		left outer join (select loc_de_munca, Comanda, sum(cantitate*tarif_unitar) as Manopera_comanda from realcom where data between @pDatajos and @pDatasus group by loc_de_munca, comanda) r on @lDetaliere_comenzi=1 and a.loc_de_munca=r.loc_de_munca 
		left outer join (select loc_de_munca, sum(cantitate*tarif_unitar) as Manopera_locm from realcom where data between @pDatajos and @pDatasus group by loc_de_munca) r1 on @lDetaliere_comenzi=1 and a.loc_de_munca=r1.loc_de_munca 
	where a.data between @pDatajos and @pDatasus and (@pLocm_jos='' or a.loc_de_munca between @pLocm_jos and @pLocm_sus) 
		and ((a.tip_salarizare='5' or a.tip_salarizare='7' or @lAcord_global_Tesa_acord=1 and a.tip_salarizare='2') 
		and (@spSimex=0 or (select count(1) from realcom r where r.loc_de_munca=a.loc_de_munca and r.data between @pDatajos and @pDatasus)>0)) and (@lComanda=0 or r.comanda=@pComanda) and (@lMarca=0 or a.Marca=@pMarca)
	order by a.loc_de_munca, (case when @Ordonare=1 then a.marca else b.nume end), a.data
	return
end
