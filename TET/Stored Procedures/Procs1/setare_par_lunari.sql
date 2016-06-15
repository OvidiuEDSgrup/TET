--***
/** Procedura stocata care scrie date in parametri lunari*/
Create procedure setare_par_lunari  
	@Data datetime, @tip char(2), @par char(9), 
	@denp char(30) = NULL, @val_l bit = NULL, @val_n float = NULL, @val_a varchar(200) = NULL, @val_d datetime = NULL
as
Begin

	if not exists (select * from sysobjects where name ='par_lunari' and xtype='V')
--	parametrii lunari
	begin
--	scris partea pt. tabela par cu SQL dinamic pt. a functiona si in cazul in care aceasta este view
		declare @comandaSql nvarchar(max)
		SET @comandaSql = N'
			if not exists (select 1 from par_lunari where Data = @Data and tip = @tip and parametru = @par)
				insert into par_lunari 
				(data, tip, parametru, denumire_parametru, val_logica, val_numerica, val_alfanumerica, val_data)
				values (@Data, @tip, @par, '''', 0, 0, '''', '''')'

		exec sp_executesql @statement=@comandaSql, @params=N'@data datetime, @tip char(2), @par char(9)', @data=@data, @tip=@tip, @par=@par

		SET @comandaSql = N'
			update par_lunari set 
				denumire_parametru=(case when @denp is null then denumire_parametru else @denp end),
				val_logica=(case when @val_l is null then val_logica else @val_l end),
				val_numerica=(case when @val_n is null then val_numerica else @val_n end),
				val_alfanumerica=(case when @val_a is null then val_alfanumerica else @val_a end),
				val_data=(case when @val_d is null then val_data else @val_d end)
			where data=@data and tip=@tip and parametru=@par'

		exec sp_executesql @statement=@comandaSql, @params=N'@data datetime, @tip char(2), @par char(9), @denp char(30), @val_l bit, @val_n float, @val_a varchar(200), @val_d datetime', 
			@data=@data, @tip=@tip, @par=@par, @denp=@denp, @val_l=@val_l, @val_n=@val_n, @val_a=@val_a, @val_d=@val_d
	end
	else
--	parametrii lunari pe locuri de munca	
	begin
		declare @utilizator varchar(20), @lm varchar(9)
		set @lm=''
		set @utilizator = dbo.fIaUtilizator(null)

		select @lm=isnull(min(Cod),'') from LMfiltrare where utilizator=@utilizator and cod in (select cod from lm where Nivel=1)

		if not exists (select 1 from par_lunari_lm where Loc_de_munca=@lm and Data = @Data and tip = @tip and parametru = @par)
			insert into par_lunari_lm 
			(loc_de_munca, data, tip, parametru, denumire_parametru, val_logica, val_numerica, val_alfanumerica, val_data)
			values (@lm, @Data, @tip, @par, '', 0, 0, '', '')

		update par_lunari_lm set 
			denumire_parametru=(case when @denp is null then denumire_parametru else @denp end),
			val_logica=(case when @val_l is null then val_logica else @val_l end),
			val_numerica=(case when @val_n is null then val_numerica else @val_n end),
			val_alfanumerica=(case when @val_a is null then val_alfanumerica else @val_a end),
			val_data=(case when @val_d is null then val_data else @val_d end)
		where Loc_de_munca=@lm and data=@data and tip=@tip and parametru=@par
	end
End	
