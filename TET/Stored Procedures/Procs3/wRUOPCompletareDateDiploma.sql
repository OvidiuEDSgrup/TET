--***
create procedure wRUOPCompletareDateDiploma @sesiune varchar(50), @parXML xml 
as     
begin try 
	declare @tip varchar(2), @subtip varchar(2), @id_instruire int, @id_poz_instruire int, @id_pers int, @seriediploma varchar(10), @nrdiploma varchar(20), @elibdiploma varchar(100)

	declare @iDoc int 
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	select @subtip=subtip, @id_instruire=id_instruire, @id_poz_instruire=isnull(id_poz_instruire,0), @id_pers=isnull(id_pers,0), 
		@seriediploma=isnull(seriediploma,''), @nrdiploma=isnull(nrdiploma,''), @elibdiploma=isnull(elibdiploma,'')
	from OPENXML(@iDoc, '/parametri')
	WITH 
	(
		subtip varchar(2) './row/@subtip',
		id_instruire int './@id_instruire',
		id_poz_instruire int './row/@id_poz_instruire',		
		id_pers int './row/@id_pers',
		seriediploma varchar(10) './@seriediploma',
		nrdiploma varchar(10) './@nrdiploma',
		elibdiploma varchar(100) './@elibdiploma'
	)

	if @seriediploma='' or @nrdiploma='' or @elibdiploma=''
		raiserror ('Date diploma necompletate',11,1)

	if @id_poz_instruire=0 or @id_pers=0
		raiserror('wRUOPCompletareDateDiploma: Operatie de completare date diploma nepermisa pe antetul documentului, selectati o pozitie din document, pe care se vor completa date legate de diploma!',16,1)
	else
		update RU_poz_instruiri set Serie_diploma=@seriediploma, Numar_diploma=@nrdiploma, Eliberat_diploma=@elibdiploma 
		where ID_instruire=@id_instruire and ID_poz_instruire=@id_poz_instruire

	exec sp_xml_removedocument @iDoc 
--	select * from RU_instruiri
end try

begin catch
	declare @eroare varchar(200) 
	set @eroare='(wRUOPCompletareDateDiploma) '+ERROR_MESSAGE()
	raiserror(@eroare, 11, 1) 
end catch
