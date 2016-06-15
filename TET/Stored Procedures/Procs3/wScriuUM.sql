--***
CREATE procedure wScriuUM  @sesiune varchar(50),@parXML xml
as  
declare @UM varchar(4),@denumire_UM varchar(30), @update int, @o_UM varchar(3),@mesaj varchar(254)
select @UM=isnull(@parXML.value('(/row/@UM)[1]','varchar(4)'),''),
	@o_UM=isnull(@parXML.value('(/row/@o_UM)[1]','varchar(3)'),''),
	@denumire_UM=isnull(@parXML.value('(/row/@denumire_UM)[1]','varchar(30)'),''),
	@update=isnull(@parXML.value('(/row/@update)[1]','int'),0) 
begin try
	if len(rtrim(@UM))>3 
		raiserror('Unitatea de masura trebuie sa aiba maxim 3 caractere!',16,1)

	if @update=1 
	begin 
		if exists (select 1 from nomencl where Um=@o_UM or UM_1=@o_UM or UM_2=@o_UM) and @UM<>@o_UM
			raiserror ('Aceasta unitate de masura este atribuita in nomenclator, nu i se poate schimba codificarea!',11,1)	
		else		
			update UM set UM=@UM, Denumire= @denumire_UM where um=@o_UM
	end  
	else   
	begin  
		if exists(select 1 from um where um=@UM)
			raiserror ('Aceasta unitate de masura se gaseste deja in catalogul de unitati de masura!',11,1)	
		insert into um (UM,Denumire)  
		values (upper(@UM), upper(@denumire_UM))  
	end  
end try
begin catch
	set @mesaj = '(wScriuUM:) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
/*
sp_help um
*/
