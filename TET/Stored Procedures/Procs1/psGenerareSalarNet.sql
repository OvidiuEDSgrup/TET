--***
/**	proc. gen. corectie salar net	*/
Create 
procedure psGenerareSalarNet
@DataJ datetime, @DataS datetime, @pmarca char(6), @ploc_de_munca char(9)
as
Begin
	declare @OreLuna int, @ncursvnet float
	Set @OreLuna = dbo.iauParLN(@DataS,'PS','ORE_LUNA')
	Exec Luare_date_par 'PS', 'CURSVNET', 0, @ncursvnet OUTPUT, 0
	set @ncursvnet=@ncursvnet/10

	delete from corectii where data=@DataS and (isnull(@pmarca,'')='' or Marca=@pmarca)
		and Loc_de_munca between rtrim(isnull(@ploc_de_munca,'')) and rtrim(isnull(@ploc_de_munca,''))+'ZZ' and tip_corectie_venit='H-' 
		and suma_neta<>0 and marca in (select marca from personal where convert(int,Categoria_salarizare)<>0)

	insert into corectii
	(Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
	select @DataS, a.marca, a.loc_de_munca, 'H-', 0, 0, round(convert(int,a.Categoria_salarizare)*@ncursvnet*(convert(float,isnull(b.total_ore,0))/convert(float,@OreLuna)),0) 
	from personal a
		left outer join (select marca, sum(ore_regie+ore_acord+ore_concediu_de_odihna+ore_obligatii_cetatenesti+ore_intrerupere_tehnologica) as total_ore from pontaj where data between @DataJ and @DataS group by marca) b on b.marca=a.marca
	where a.Loc_de_munca between rtrim(isnull(@ploc_de_munca,'')) and rtrim(isnull(@ploc_de_munca,''))+'ZZ' 
		and (isnull(@pmarca,'')='' or a.Marca=@pmarca) and a.categoria_salarizare<>''
End		
