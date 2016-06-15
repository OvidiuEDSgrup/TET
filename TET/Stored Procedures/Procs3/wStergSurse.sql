create procedure [dbo].[wStergSurse] @sesiune varchar(50), @parXML xml 
as

declare @cod varchar(8),@denumire varchar (50), @mesajeroare varchar(100)
		
select
  @cod=isnull(@parXML.value('(/row/@cod)[1]','varchar(8)'),''),
 @denumire=isnull(@parXML.value('(/row/@denumire)[1]','varchar(50)'),'')
 select @mesajeroare= 'Sursa nu se poate sterge pentru ca e folosita in contracte'
	if 
		@cod in (select cod from surse where  cod  in (select MOD_DE_PLATA from pozcon where tip='BF'))
		raiserror(@mesajeroare, 11, 1)
	else 
		delete from surse where Cod= @cod and Denumire=@denumire and cod not in (select MOD_DE_PLATA from pozcon where tip='BF')
		 
		  
