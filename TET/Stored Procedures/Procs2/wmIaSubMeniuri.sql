CREATE PROCEDURE wmIaSubMeniuri @sesiune varchar(50), @parXML xml
AS

set transaction isolation level read uncommitted
begin try
	declare 
		@userASiS varchar(50), @parinte varchar(50), @xmlPar xml


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
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
