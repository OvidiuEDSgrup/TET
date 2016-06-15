--***
Create 
procedure wStergFunctii @sesiune varchar(50), @parXML xml
as

declare @CodFunctie varchar(13), @mesaj varchar(254), @mesajEroare varchar(254)
Set @CodFunctie = @parXML.value('(/row/@cod)[1]','varchar(13)')

set @mesajEroare=''
begin try
select @mesajEroare=
	(case when exists (select 1 from personal p where cod_functie=@CodFunctie) 
		then 'Codul de functie selectat este folosit in personal!'
	when exists (select 1 from istpers i where cod_functie=@CodFunctie) 
		then 'Codul de functie selectat este folosit in istoric personal!' else '' end)

	if @mesajEroare=''	
	Begin
		delete from functii where Cod_functie=@CodFunctie
		delete from extinfop where Marca=@CodFunctie and cod_inf='#CODCOR'
		delete from proprietati where Tip='FUNCTII' and Cod=@CodFunctie
	End
	else 
		raiserror(@mesajEroare, 16, 1)
end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
