--***
create procedure wStergDetasari (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wStergDetasariSP')
begin
	declare @returnValue int
	exec @returnValue=wStergDetasariSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(20), @mesaj varchar(80), @marca varchar(6), @nrcrt int
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select  @marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),''),
			@nrcrt=isnull(@parXML.value('(/row/row/@nrcrt)[1]','int'),0)		

	delete from extinfop 
	where Marca=@marca and Cod_inf in ('DETDATAINC','DETDATASF','DETNATIONAL') 
		and Procent=@nrcrt
end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1) 
end catch


