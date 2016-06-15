--***
/* Procedura stocata care scrie date in parametri*/
create procedure setare_par @tip char(2), @par char(9), 
	@denp char(30) = NULL, @val_l bit = NULL, @val_n float = NULL, @val_a varchar(200) = NULL
as
begin
	if not exists (select * from sysobjects where name ='par' and xtype='V')
	begin
--	scris partea pt. tabela par cu SQL dinamic pt. a functiona si in cazul in care aceasta este view
		declare @comandaSql nvarchar(max)
		SET @comandaSql = N'
			if not exists (select 1 from par where tip_parametru = @tip and parametru = @par)
			INSERT par (tip_parametru, parametru, denumire_parametru, val_logica, val_numerica, val_alfanumerica)' 
			+'VALUES (@tip, @par, '+char(39)+char(39)+', 0, 0, '+char(39)+char(39)+')'
		exec sp_executesql @statement=@comandaSql, @params=N'@tip char(2), @par char(9)', @tip=@tip, @par=@par

		SET @comandaSql = N'
		update par
			set denumire_parametru=(case when @denp is null then denumire_parametru else @denp end),
				val_logica=(case when @val_l is null then val_logica else @val_l end),
				val_numerica=(case when @val_n is null then val_numerica else @val_n end),
				val_alfanumerica=(case when @val_a is null then val_alfanumerica else @val_a end)
			where tip_parametru=@tip and parametru=@par'
		exec sp_executesql @statement=@comandaSql, @params=N'@tip char(2), @par char(9), @denp char(30), @val_l bit, @val_n float, @val_a varchar(200)', 
			@tip=@tip, @par=@par, @denp=@denp, @val_l=@val_l, @val_n=@val_n, @val_a=@val_a
	end
	else 
	begin
		declare @utilizator varchar(20), @lm varchar(9)
		set @lm=''
		set @utilizator = dbo.fIaUtilizator(null)

		select @lm=isnull(min(Cod),'') from LMfiltrare where utilizator=@utilizator

		if not exists (select 1 from parlm where Loc_de_munca=@lm and tip_parametru = @tip and parametru = @par)
			insert into parlm 
				(Loc_de_munca, tip_parametru, parametru, denumire_parametru, val_logica, val_numerica, val_alfanumerica)
				values
				(@lm, @tip, @par, '', 0, 0, '')
		update parlm
		set denumire_parametru=(case when @denp is null then denumire_parametru else @denp end),
			val_logica=(case when @val_l is null then val_logica else @val_l end),
			val_numerica=(case when @val_n is null then val_numerica else @val_n end),
			val_alfanumerica=(case when @val_a is null then val_alfanumerica else @val_a end)
		where Loc_de_munca=@lm and tip_parametru=@tip and parametru=@par
	end
end
