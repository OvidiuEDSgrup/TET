--***
/**	procedura completez curscor	*/
Create procedure completez_curscor
	@datajos datetime, @datasus datetime, @pmarca char(6), @plocm char(9)
As
Begin try
	If not exists (Select * from sysobjects where name='curscor' and type = 'U')
	Begin
		CREATE TABLE dbo.curscor(Data datetime not null, Marca char(6) not null, Loc_de_munca char(9) not null, 
			Tip_corectie_venit char(2) not null, Suma_corectie float not null, Procent_corectie real not null, Expand_locm bit not null) 
		ON [PRIMARY]
		CREATE UNIQUE CLUSTERED INDEX Data_Marca ON dbo.curscor 
			(Data ASC, Marca ASC, Loc_de_munca ASC, Tip_corectie_venit ASC) ON [PRIMARY]
	End
	truncate table curscor

	declare @data datetime, @marca char(6), @loc_de_munca char(9), @tip_corectie_venit char(2), @suma_corectie float, @procent_corectie float, @eroare varchar(2000)
--	scriu din corectii pe marci
	Declare cursor_corectii_marci Cursor For
	Select c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit, c.suma_corectie, c.procent_corectie
	from corectii c 
		left outer join personal p on p.Marca=c.Marca
	where c.data between @datajos and @datasus and c.marca<>'' and (@pmarca='' or c.marca=@pmarca) 
--		and (@plocm='' or c.loc_de_munca between rtrim(@plocm) and rtrim(@plocm)+'ZZZ')
		and (@plocm='' or p.loc_de_munca between rtrim(@plocm) and rtrim(@plocm)+'ZZZ')
	order by c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit

	open cursor_corectii_marci
	fetch next from cursor_corectii_marci into @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
	While @@fetch_status = 0 
	Begin
		if exists (select * from curscor where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and tip_corectie_venit=@tip_corectie_venit)
			update curscor set suma_corectie = suma_corectie+@suma_corectie, 
			procent_corectie = procent_corectie+@procent_corectie,  expand_locm = 0
			where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and tip_corectie_venit=@tip_corectie_venit
		else 
			insert into curscor(Data, Marca, Loc_de_munca, tip_corectie_venit, suma_corectie, procent_corectie, expand_locm)
			select @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie, 0

		fetch next from cursor_corectii_marci into @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
	End
	close cursor_corectii_marci
	Deallocate cursor_corectii_marci
	
--	scriu din corectii pe locuri de munca
	declare @ptdata datetime, @ptmarca char(6), @ptlocm char(9), @DRUMOR int, @SALIMOB int
	Exec Luare_date_par 'SP', 'DRUMOR', @DRUMOR OUTPUT , 0, 0
	Exec Luare_date_par 'SP', 'SALIMOB', @SALIMOB OUTPUT , 0, 0

	Declare cursor_corectii_locm Cursor For
	Select c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit, c.suma_corectie, c.procent_corectie
	from corectii c
	where c.data between @datajos and @datasus and c.marca='' 
		and (@plocm='' or c.loc_de_munca between rtrim(@plocm) and rtrim(@plocm)+'ZZZ') 
		and	(c.suma_corectie<>0 or c.procent_corectie<>0)
	order by c.data, c.marca, c.loc_de_munca, c.tip_corectie_venit

	open cursor_corectii_locm
	fetch next from cursor_corectii_locm into @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
	While @@fetch_status = 0
	Begin
		Declare cursor_pontaj Cursor For
		Select p.data, p.marca, p.loc_de_munca from pontaj p
		where p.data between @datajos and @datasus and (@pmarca='' or p.marca=@pmarca) 
			and (p.loc_de_munca between rtrim(@loc_de_munca) and rtrim(@loc_de_munca)+'ZZZ') 
			and p.tip_salarizare>=(case when @SALIMOB=1 then '7' when @DRUMOR=1 then '3' else '1' end)
		order by p.data, p.marca, p.numar_curent
		open cursor_pontaj
		fetch next from cursor_pontaj into @ptdata, @ptmarca, @ptlocm
		While @@fetch_status = 0
		Begin
			if not exists (select * from curscor where data=@data and marca=@ptmarca and loc_de_munca=@ptlocm and tip_corectie_venit=@tip_corectie_venit)
				insert into curscor (Data, Marca, Loc_de_munca, tip_corectie_venit, suma_corectie, procent_corectie, expand_locm)
				select @data, @ptmarca, @ptlocm, @tip_corectie_venit, @suma_corectie, @procent_corectie, 1

			fetch next from cursor_pontaj into @ptdata, @ptmarca, @ptlocm
		End
		close cursor_pontaj
		Deallocate cursor_pontaj
		fetch next from cursor_corectii_locm into @data, @marca, @loc_de_munca, @tip_corectie_venit, @suma_corectie, @procent_corectie
	End
	close cursor_corectii_locm
	Deallocate cursor_corectii_locm
End	try

begin catch
	set @eroare='Procedura completez_curscor (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
