--***
create procedure wStergVechimiSalariati (@sesiune varchar(250), @parXML xml)
as

-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergVechimiSalariatiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wStergVechimiSalariatiSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(20), @mesaj varchar(80), @marca varchar(6), @numar_pozitie int,@tipv varchar(1)
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if @utilizator is null
		return -1
	
	select  @marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
			@numar_pozitie=isnull(@parXML.value('(/row/row/@numar_pozitie)[1]','int'),0),
			@tipv=isnull(@parXML.value('(/row/row/@tipv)[1]','varchar(1)'),'')		

	delete from Vechimi 
	where Marca=@marca and tip=@tipv and Numar_pozitie=@numar_pozitie
	
	delete from Vechimi 
	where Marca=@marca and tip=(case when @tipv='T' then '1' when @tipv='I' then '2' when @tipv='M' then '3' else '0' end)
		and Numar_pozitie=@numar_pozitie
end try

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wStergVechimiSalariati)'
	raiserror(@mesaj,11,1) 
end catch


