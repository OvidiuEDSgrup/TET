--***
/**	proc. scriu corectii locm	*/
create procedure [dbo].[scriu_corectii_locm]
@datajos datetime, @datasus datetime, @pmarca char(6), @ploc_de_munca char(9)
As
Begin
	declare @cdata datetime, @cmarca char(6), @cloc_de_munca char(9), @tip_corectie_venit char(2), @suma_corectie float,
	@procent_corectie float, @ptdata datetime, @ptmarca char(6), @ptlocm char(9), @DRUMOR int, @SALIMOB int
	Exec Luare_date_par 'SP', 'DRUMOR', @DRUMOR OUTPUT , 0, 0
	Exec Luare_date_par 'SP', 'SALIMOB', @SALIMOB OUTPUT , 0, 0

	Declare cursor_corectii_locm Cursor For
	Select c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit, c.suma_corectie, c.procent_corectie
	from corectii c
	where c.data between @datajos and @datasus and c.marca='' 
		and (@ploc_de_munca='' or c.loc_de_munca between rtrim(@ploc_de_munca) and rtrim(@ploc_de_munca)+'ZZZ') 
		and	(c.suma_corectie<>0 or c.procent_corectie<>0)
	order by c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit

	open cursor_corectii_locm
	fetch next from cursor_corectii_locm into @cdata, @cmarca, @cloc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
	While @@fetch_status = 0
	Begin
		Declare cursor_pontaj Cursor For
		Select p.data, p.marca, p.loc_de_munca from pontaj p
		where p.data between @datajos and @datasus and (@pmarca='' or p.marca=@pmarca) and
		(p.loc_de_munca between rtrim(@cloc_de_munca) and rtrim(@cloc_de_munca)+'ZZZ') and
		p.tip_salarizare>=(case when @SALIMOB=1 then '7' when @DRUMOR=1 then '3' else '1' end)
		order by p.data, p.marca, p.numar_curent
		open cursor_pontaj
		fetch next from cursor_pontaj into @ptdata, @ptmarca, @ptlocm
		While @@fetch_status = 0
		Begin
			if not exists (select * from curscor where data=@cdata and marca=@ptmarca and loc_de_munca=@ptlocm and tip_corectie_venit=@tip_corectie_venit)
				insert into curscor (Data, Marca, Loc_de_munca, tip_corectie_venit, suma_corectie, procent_corectie, expand_locm)
				select @cdata, @ptmarca, @ptlocm, @tip_corectie_venit, @suma_corectie, @procent_corectie, 1

			fetch next from cursor_pontaj into @ptdata, @ptmarca, @ptlocm
		End
		close cursor_pontaj
		Deallocate cursor_pontaj
		fetch next from cursor_corectii_locm into @cdata, @cmarca, @cloc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
	End
	close cursor_corectii_locm
	Deallocate cursor_corectii_locm
End
