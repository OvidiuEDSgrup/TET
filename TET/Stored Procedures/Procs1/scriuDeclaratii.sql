--***
Create procedure scriuDeclaratii
	@cod varchar(20), 
	@tip varchar(1),	-- TipDeclaratie=0 Initiala, 1 Rectificativa
	@data datetime,	
	@detalii xml=null, 
	@continut xml 
as  
Begin try
	declare @utilizator varchar(20)
	set @utilizator=dbo.fIaUtilizator(null)
	set @tip=(case when @tip='0' then '' when @tip='1' then 'R' else @tip end)

	if exists (select 1 from declaratii where cod=@cod and tip=@tip and data=@data 
			and (cod not like 'INTRASTAT_%' or detalii.value('/row[1]/@flux', 'varchar(1)')=@detalii.value('/row[1]/@flux', 'varchar(1)')))
		delete from declaratii where cod=@cod and tip=@tip and data=@data

	insert into declaratii (cod, tip, data, utilizator, data_operarii, detalii, continut)
	select @cod, @tip, @data, @utilizator, getdate(), @detalii, @continut
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura scriuDeclaratii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
