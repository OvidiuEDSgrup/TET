--***
Create procedure wStergClaseSalarizare @sesiune varchar(50), @parXML xml
as

declare @ClasaSalarizare varchar(13), @mesaj varchar(254), @mesajEroare varchar(254)
Set @ClasaSalarizare = @parXML.value('(/row/@clasasal)[1]','varchar(13)')

set @mesajEroare=''
begin try
select @mesajEroare=
	(case when exists (select 1 from personal p where Categoria_salarizare=@ClasaSalarizare) 
		then 'Clasa de salarizare selectata este folosita in personal!'
	when exists (select 1 from istpers i where Categoria_salarizare=@ClasaSalarizare) 
		then 'Clasa de salarizare selectata este folosita in istoric personal!' else '' end)

	if @mesajEroare=''	
	Begin
		delete from categs where Categoria_salarizare=@ClasaSalarizare
		delete from proprietati where Tip='CATEGSAL' and Cod=@ClasaSalarizare
	End
	else 
		raiserror(@mesajEroare, 16, 1)
end try

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wStergClaseSalarizare)'
	raiserror(@mesaj, 11, 1)
end catch
