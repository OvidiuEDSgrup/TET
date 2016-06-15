--***
/**	functie calc. zile CO cuvenite	*/
Create function ls_zile_CO_cuvenite 
	(@marca varchar(6), @data datetime, @Calcul_pana_la_luna_curenta int)
returns @ls_zile_co_cuvenite table 
	(marca char(6), zile int)
As
Begin
	Declare @ZileCOCuvenite float, @vmarca char(6)

	declare tmpco cursor for select marca from personal 
	where (isnull(@marca,'')='' or marca=@marca) and grupa_de_munca not in ('O')
		and (convert(int,loc_ramas_vacant)=0 or Data_plec>=dbo.bom(@data))
		and data_angajarii_in_unitate<=@data
		
	open tmpco
	fetch next from tmpco into @vmarca
	while @@fetch_status=0
	begin
		select @ZileCOCuvenite=dbo.zile_CO_cuvenite (@vmarca, @Data, @Calcul_pana_la_luna_curenta)

		insert into @ls_zile_co_cuvenite(marca,zile)
			values (@vmarca,round(@ZileCOCuvenite,0))

		fetch next from tmpco into @vmarca
	end

	close tmpco
	deallocate tmpco
	Return
End
