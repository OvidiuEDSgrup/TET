CREATE PROCEDURE wmIaMeniuIntrariIesiri @sesiune varchar(50), @parXML xml
AS

set transaction isolation level read uncommitted

declare @userASiS varchar(50), @mesaj varchar(100),
		@parinte varchar(50), @xmlPar xml

begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Citeste id-ul meniului curent pentru a afisa doar copii acestui meniu */
	select	@parinte = isnull(@parXML.value('(/row/@meniuParinte)[1]', 'varchar(50)'), '910');
	
	if (@parXML.value('(/row/@meniuParinte)[1]','varchar(50)')) is null
		set @parXML.modify('insert attribute meniuParinte {sql:variable("@parinte")} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@meniuParinte)[1] with sql:variable("@parinte")')
	
	exec wIaMeniuMobil @sesiune=@sesiune, @parXML=@parXML
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+ ' (wmIaMeniuIntrariIesiri)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
