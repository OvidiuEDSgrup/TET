/***--
Procedura stocata executa wIaMeniuMobil pentru a returna sub-meniurile din WMS
param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@parinte	->	meniul trimis ca parinte de la care se afiseaza copii
--***/
CREATE PROCEDURE wmIaMeniuWMS @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmIaMeniuWMSSP')
begin 
	declare @returnValue int
	exec @returnValue = wmIaMeniuWMSSP @sesiune, @parXML output
	return @returnValue
end

set transaction isolation level read uncommitted

declare @userASiS varchar(50), @mesaj varchar(100),
		@parinte varchar(50), @xmlPar xml

begin try
	/*Validare utilizator */
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	/*Citeste id-ul meniului curent pentru a afisa doar copii acestui meniu */
	select	@parinte = isnull(@parXML.value('(/row/@meniuParinte)[1]', 'varchar(50)'), '910');
	/*Executa wIaMeniuMobil pentru subMeniu*/
	set @xmlPar = (select @parinte meniuParinte for xml raw)
	exec wIaMeniuMobil @sesiune=@sesiune, @parXML=@xmlPar
	
end try
begin catch
	set @mesaj = '(wmIaMeniuWMS)'+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from AntDisp
--select * from PozDispOp
