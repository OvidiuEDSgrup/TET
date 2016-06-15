--***
/**	procedura calcul acord ind	*/
Create procedure psacord_ind
@datajos datetime, @datasus datetime, @validare_pontaj bit, @pmarca char(6)
As
Declare @nRealizari int, @lAcordind_Tesa_acord bit, @spDrumco bit, @spArlcj bit, @SpModatim bit, @lIndici_realiz bit, @lIndici_lm bit, @lSal_com int, @Sp1_dupa_ore bit, @Sp2_dupa_ore bit, @Ore_luna int, @Nrm_luna float,
@marca char(6), @loc_de_munca char(9), @numar_document char(20), @data datetime, @comanda char(13), @cod_reper char(20), @cod_operatie char(20), @cantitate float, @categ_salar char(4), @norma_de_timp float, @tarif_unitar float, @grupa_de_munca char(1), @salar_de_incadrare float, @coef_acord_ARL float, @realizat_marca float, @ore_acord_marca float, @ore_realiz_regie int, @ore_realiz_acord int, @gore_realiz_regie int, @gore_realiz_acord int, @gsal_inc float, @ggrupa char(1),
@total_pontaj float, @gmarca char(6), @glm char(9), @gfetch int

exec Luare_date_par 'SP', 'DRUMCO', @SpDrumco output, 0, 0
exec Luare_date_par 'SP', 'ARLCJ', @SpARLCJ output, 0, 0
exec Luare_date_par 'SP', 'MODATIM', @SpModatim output, 0, 0
exec Luare_date_par 'PS', 'REALIZARI', 0, @nRealizari output, 0
exec Luare_date_par 'PS', 'INDICICOM', @lIndici_realiz output, 0, 0
exec Luare_date_par 'PS', 'INDICIPLM', @lIndici_lm output, 0, 0
exec Luare_date_par 'PS', 'SALCOM', @lSal_com output, 0, 0
exec Luare_date_par 'PS', 'ACINDTESA', @lAcordind_Tesa_acord output, 0 , 0
exec Luare_date_par 'PS', 'SCOND1', @Sp1_dupa_ore output, 0 , 0
exec Luare_date_par 'PS', 'SCOND2', @Sp2_dupa_ore output, 0 , 0
Set @Ore_luna = dbo.iauParLN(@datasus,'PS','ORE_LUNA')
Set @Nrm_luna = dbo.iauParLN(@datasus,'PS','NRMEDOL')

if @nRealizari=1
	update pontaj set coeficient_acord=0, realizat=0, ore_realizate_acord=0 where data between @datajos and @datasus 
	and (@lAcordind_Tesa_acord=1 AND tip_salarizare=2 or tip_salarizare='4') and realizat>=0.001 and (@pmarca='' or marca=@pmarca)

Declare cursor_realiz Cursor For
Select r.marca, r.loc_de_munca, r.numar_document, r.data, r.comanda, r.cod_reper, r.cod, r.cantitate, 
r.categoria_salarizare, r.norma_de_timp, r.tarif_unitar, p.grupa_de_munca, p.salar_de_incadrare, 
isnull((select sum(ore_regie) from pontaj p where p.data between @datajos and @datasus and p.marca=r.marca 
and (@lAcordind_Tesa_acord=1 AND p.tip_salarizare=2 or tip_salarizare='4') 
and (@SpDrumco=1 or @SpARLCJ=1 or p.loc_de_munca=r.loc_de_munca)),0), 
isnull((select sum(ore_acord) from pontaj p where p.data between @datajos and @datasus and p.marca=r.marca 
and (@lAcordind_Tesa_acord=1 AND p.tip_salarizare=2 or tip_salarizare='4') 
and (@SpDrumco=1 or @SpARLCJ=1 or p.loc_de_munca=r.loc_de_munca)),0)
from realcom r 
	left outer join personal p on r.marca = p.marca
where r.data between @datajos and @datasus and r.marca<>'' and (@pmarca='' or r.marca=@pmarca) and (@lSal_com=0 or r.categoria_salarizare='' or r.categoria_salarizare<>'' and not exists (select t.marca from pontaj t where t.data=r.data and t.marca=r.marca and t.loc_de_munca=r.loc_de_munca and rtrim(convert(char(3),t.numar_curent))=rtrim(substring(r.numar_document,3,18)) and t.ore_regie=r.cantitate))
order by r.marca, r.loc_de_munca

open cursor_realiz
fetch next from cursor_realiz into @marca, @loc_de_munca, @numar_document, @data, @comanda, @cod_reper, @cod_operatie,
@cantitate, @categ_salar, @norma_de_timp, @tarif_unitar, @grupa_de_munca, @salar_de_incadrare, @ore_realiz_regie, 
@ore_realiz_acord
set @gfetch=@@fetch_status
Set @gmarca = @marca
Set @glm = @loc_de_munca
Set @gore_realiz_regie = @ore_realiz_regie
Set @gore_realiz_acord = @ore_realiz_acord
Set @gsal_inc = @salar_de_incadrare
Set @ggrupa = @grupa_de_munca
While @@fetch_status = 0 
Begin
	Set @realizat_marca = 0
	Set @ore_acord_marca = 0
	while @gmarca=@marca and (@SpARLCJ=1 or @SpDrumco=1 or @glm=@loc_de_munca) and @gfetch=0
	begin
		Set @realizat_marca = @realizat_marca + round(@cantitate * @tarif_unitar * 
		(case when @lIndici_realiz=1 and @norma_de_timp>0 then @norma_de_timp else 1 end),2)
		Set @ore_acord_marca = @ore_acord_marca + @cantitate * 
		(case when @lIndici_realiz=0 and @categ_salar='' then @norma_de_timp else 1 end)

		fetch next from cursor_realiz into @marca, @loc_de_munca, @numar_document, @data, @comanda, @cod_reper, @cod_operatie, @cantitate, @categ_salar, @norma_de_timp, @tarif_unitar, @grupa_de_munca, @salar_de_incadrare, @ore_realiz_regie, 
		@ore_realiz_acord
		set @gfetch=@@fetch_status
	End 

	update pontaj set realizat = /*realizat +*/ @realizat_marca, ore_realizate_acord = round((case when @ore_acord_marca>2*ore_acord then ore_acord else @ore_acord_marca end),0),
		ore__cond_1=round((case when @Sp1_dupa_ore=1 and @SpARLCJ=0 then round((case when @ore_acord_marca>2*ore_acord then ore_acord else @ore_acord_marca end),0) else ore__cond_1 end),0),
		ore__cond_2=round((case when @Sp2_dupa_ore=1 and @SpARLCJ=0 then round((case when @ore_acord_marca>2*ore_acord then ore_acord else @ore_acord_marca end),0) else ore__cond_2 end),0)
	where pontaj.marca=@gmarca and (@lAcordind_Tesa_acord=1 and pontaj.tip_salarizare='2' or pontaj.tip_salarizare='4') 
		and pontaj.data between @datajos and @datasus and (@SpDrumco=1 or @SpARLCJ=1 or pontaj.loc_de_munca=@glm) 
		and convert(char(10),pontaj.data,102)+pontaj.loc_de_munca+convert(char(3),pontaj.numar_curent)
		in (select top 1 convert(char(10),c.data,102)+c.loc_de_munca+convert(char(3),c.numar_curent) 
		from pontaj c where c.marca=pontaj.marca and (@lAcordind_Tesa_acord=1 and c.tip_salarizare='2' or c.tip_salarizare='4') 
		and c.data between @datajos and @datasus and (@SpDrumco=1 or @SpARLCJ=1 or c.loc_de_munca=@glm) order by c.data desc)

	update pontaj set coeficient_acord = @realizat_marca/
	(case when (case when @SpARLCJ=0 then 0 else @gore_realiz_regie end)+@gore_realiz_acord<>0 then 
	(((case when @SpARLCJ=0 then 0 else @gore_realiz_regie end)+@gore_realiz_acord)*@gsal_inc/
	((case when pontaj.tip_salarizare='2' then @Ore_luna else @Nrm_luna end)*
	(case when charindex(@ggrupa,'CO')<>0 then pontaj.regim_de_lucru/8 else 1 end))) else 1 end)
	where pontaj.data between @datajos and @datasus and pontaj.marca=@gmarca 
		and (@lAcordind_Tesa_acord=1 and pontaj.tip_salarizare='2' or pontaj.tip_salarizare='4') 
		and (@SpDrumco=1 or @SpARLCJ=1 or pontaj.loc_de_munca=@glm) 
		and convert(char(10),pontaj.data,102)+pontaj.loc_de_munca+convert(char(3),pontaj.numar_curent)
		in (select top 1 convert(char(10),c.data,102)+c.loc_de_munca+convert(char(3),c.numar_curent) 
		from pontaj c where c.marca=@gmarca 
		and (@lAcordind_Tesa_acord=1 and c.tip_salarizare='2' or c.tip_salarizare='4') 
		and c.data between @datajos and @datasus 
		and (@SpDrumco=1 or @SpARLCJ=1 or c.loc_de_munca=@glm)) 
		and @SpModatim=0 and not(@lIndici_lm=1 and pontaj.coeficient_acord<>0)

/*	if @validare_pontaj=1 and @gmarca  not in (select marca from pontaj where pontaj.marca=@gmarca 
	and (@lAcordind_Tesa_acord=1 and pontaj.tip_salarizare='2' or pontaj.tip_salarizare='4') 
	and pontaj.data between @datajos and @datasus 
	and (@SpDrumco=1 or @SpARLCJ=1 or pontaj.loc_de_munca=@glm))
	Begin
--		print 'Marca '+@gmarca+ 'are realizari in acord individual si nu este pontata in acord individual!'
		RAISERROR ('Marca %s are realizari in acord individual si nu este pontata in acord individual! Reveniti cu calcul acord dupa ce modificati datele!', 16, 1, @gmarca)
--		rollback transaction
 End */
	Set @gmarca = @marca
	Set @glm = @loc_de_munca
	Set @gore_realiz_regie = @ore_realiz_regie
	Set @gore_realiz_acord = @ore_realiz_acord
	Set @gsal_inc = @salar_de_incadrare
	Set @ggrupa = @grupa_de_munca
End
close cursor_realiz
Deallocate cursor_realiz
