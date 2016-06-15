--***
Create procedure wStergSalariati @sesiune varchar(50), @parXML xml
as

declare @marca varchar(6), @mesaj varchar(254)
set @marca = @parXML.value('(/row/@marca)[1]','varchar(6)')

set @mesaj=''
begin try
	select @mesaj=
	(case when exists (select 1 from net r where marca=@marca) then 'Salariatul selectat este folosit in net!' else '' end)

if @mesaj=''	
begin
	delete from personal where marca=@marca
	delete from infopers where marca=@marca
	delete from extinfop where marca=@marca and left(cod_inf,1)<>'#'
	delete from extPers where marca=@marca
	delete from studpers where marca=@marca
	delete from profpers where marca=@marca
end
else 
	raiserror(@mesaj, 16, 1)
end try

begin catch
	set @mesaj='(wStergSalariati) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	--SELECT ERROR_MESSAGE() AS mesajeroare FOR XML RAW
end catch
