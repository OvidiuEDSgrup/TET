--***
/**	proc. calcul Tesa acord	*/
Create procedure calcul_Tesa_acord
	(@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLoc_de_munca char(9))
As
Begin
	declare @Loc_de_munca char(9), @Coef_acord_locm float, @Coef_timp_locm float, @Salimob int, @Modatim int, 
	@Drumuri_Oradea int, @ARLCJ int, @Spicul int, @nOre_luna float, @lIndici_pontaj_lm int, @Coef_ARL float, @nProc_Tesa_acord float
	Set @lIndici_pontaj_lm=dbo.iauParL('PS','INDICIPLM')
	Set @Salimob=dbo.iauParL('SP','SALIMOB')
	Set @Modatim=dbo.iauParL('SP','MODATIM')
	Set @Drumuri_Oradea=dbo.iauParL('SP','DRUMOR')
	Set @ARLCJ=dbo.iauParL('SP','ARLCJ')
	Set @Spicul=dbo.iauParL('SP','SPICUL')
	Set @nProc_Tesa_acord=dbo.iauParN('PS','TESA-AC-%')
	Set @nOre_Luna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
--anulare calcul anterior
	update pontaj set Coeficient_acord=(case when @lIndici_pontaj_lm=0 or Tip_salarizare='2' then 0 else Coeficient_acord end), Realizat=0,Ore_realizate_acord=0
	where data between @dataJos and @dataSus and (@pLoc_de_munca='' or Loc_de_munca=@pLoc_de_munca) 
	and Tip_salarizare in ('1','2') and Realizat>=0.00001
	if @ARLCJ=1
		delete from reallmun where data=@dataJos and (@pLoc_de_munca='' or Loc_de_munca=@pLoc_de_munca)

--calcul Tesa acord
	select a.Data, a.Marca, a.Loc_de_munca, a.Numar_curent, 
		(case when @Modatim=1 or @lIndici_pontaj_lm=1 and a.Coeficient_acord<>0 then a.Coeficient_acord 
		when @ARLCJ=1 and dbo.calcul_coeficient_acord_ARL(@dataJos, @dataSus, a.Loc_de_munca)<>0
		then dbo.calcul_coeficient_acord_ARL(@dataJos, @dataSus, a.Loc_de_munca) 
		when @Spicul=1 and isnull(c.Procent_corectie,0)<>0 then isnull(c.Procent_corectie,0) else @nProc_Tesa_acord end)/100 as Coeficient_acord
	into #pontaj_tesa_acord
	from pontaj a
		left outer join (select Marca, Loc_de_munca, max(Procent_corectie) as Procent_corectie from corectii where data between @dataJos and @dataSus and Procent_corectie<>0 group by Marca, Loc_de_munca) c on @Spicul=1 and a.Marca=c.Marca and a.Loc_de_munca=c.Loc_de_munca
	where a.data between @dataJos and @dataSus and (@pLoc_de_munca='' or a.Loc_de_munca like rtrim(@pLoc_de_munca)+'%') and a.Tip_salarizare='2'
	
	Create Unique Clustered Index [Principal] ON dbo.#pontaj_tesa_acord (Data Asc, Marca Asc, Numar_curent Asc)

	update pontaj set pontaj.Coeficient_acord=a.Coeficient_acord, 
		Ore_realizate_acord=round(Ore_acord*(case when @Drumuri_Oradea=1 or @Modatim=1 then 1 else a.Coeficient_acord end),2),
		Realizat=(case when abs(pontaj.Realizat-p.Salar_de_incadrare)<p.Salar_de_incadrare/10000 then p.Salar_de_incadrare else round(Ore_acord*p.Salar_de_incadrare/(case when p.Grupa_de_munca in ('C','O','P') then @nOre_luna*Regim_de_lucru/8 else @nOre_luna end)*a.Coeficient_acord/(case when @Modatim=1 then 100 else 1 end),2) end)
	from #pontaj_tesa_acord a
		left outer join personal p on a.marca=p.marca
	where pontaj.data between @dataJos and @dataSus 
		and a.Data=pontaj.Data and a.Marca=pontaj.marca and a.Numar_curent=pontaj.Numar_curent
		and (@pLoc_de_munca='' or pontaj.Loc_de_munca like rtrim(@pLoc_de_munca)+'%') and pontaj.Tip_salarizare='2'
	
	if @ARLCJ=1
		insert into reallmun (Data, Loc_de_munca, Valoare_manopera, Coeficient_de_acord, Coeficient_de_timp, Ore_realizate_in_acord, Salar_pontaj, Ore_pontaj)
		select distinct @dataJos, Loc_de_munca, 0, Coeficient_acord, 0, 0, 0, 0
		from pontaj 
		where data between @dataJos and @dataSus and (@pLoc_de_munca='' or Loc_de_munca=@pLoc_de_munca) and Tip_salarizare='2'
	drop table #pontaj_tesa_acord
End
