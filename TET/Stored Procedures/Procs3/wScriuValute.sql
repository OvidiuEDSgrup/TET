--***
create procedure wScriuValute @sesiune varchar(50),@parXML xml
as 
declare @valuta varchar(3),@denumire_valuta varchar(30), @update int, @o_valuta varchar(3),@mesaj varchar(254)
select @valuta=isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),''),
	@o_valuta=isnull(@parXML.value('(/row/@o_valuta)[1]','varchar(3)'),''),
	@denumire_valuta=isnull(@parXML.value('(/row/@denumire_valuta)[1]','varchar(30)'),''),
	@update=isnull(@parXML.value('(/row/@update)[1]','int'),0)

begin try
	if @update=1 
	begin  
		if exists (select 1 from curs where valuta=@o_valuta) and @valuta<>@o_valuta
			raiserror ('Pe aceasta valuta au fost definite cursuri, nu i se poate schimba codificarea',11,1)
		else	
			update valuta set Valuta=@valuta, Denumire_valuta= @denumire_valuta where valuta=@o_valuta
	end  
	else   
	begin 
		if exists(select 1 from valuta where valuta=@valuta)
			raiserror ('Aceasta valuta se gaseste deja in catalogul de valute!',11,1)
		else			 
			insert into valuta (Valuta, Denumire_valuta, Curs_curent)  
			values (upper(@valuta), upper(@denumire_valuta), 0)  
	end  
end try
begin catch
	set @mesaj = '(wScriuValute:) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
  /*
  sp_help valuta
  */ 
