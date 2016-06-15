--***
Create procedure wStergCategoriiSalarizare @sesiune varchar(50), @parXML xml
as

declare @CategoriaSalarizare varchar(13), @mesaj varchar(254), @mesajEroare varchar(254)
Set @CategoriaSalarizare = @parXML.value('(/row/@categsal)[1]','varchar(13)')

set @mesajEroare=''
begin try
select @mesajEroare=
	(case when exists (select 1 from personal p where Categoria_salarizare=@CategoriaSalarizare) 
		then 'Categoria de salarizare selectata este folosita in personal!'
	when exists (select 1 from istpers i where Categoria_salarizare=@CategoriaSalarizare) 
		then 'Categoria de salarizare selectata este folosita in istoric personal!' else '' end)

	if @mesajEroare=''	
	Begin
		delete from categs where Categoria_salarizare=@CategoriaSalarizare
		delete from proprietati where Tip='CATEGSAL' and Cod=@CategoriaSalarizare
	End
	else 
		raiserror(@mesajEroare, 16, 1)
end try

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wStergCategoriiSalarizare)'
	raiserror(@mesaj, 11, 1)
end catch
