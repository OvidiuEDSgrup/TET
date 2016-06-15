/** procedura pentru scriere instruiri cursuri **/
Create procedure wRUScriuPozInstruiri @sesiune varchar(50), @parXML XML
as
begin try
declare 
	--Date antet
	@numarfisa varchar(20), @data datetime, @id_instruire int, @tip varchar(2), @data_inceput datetime, @data_sfarsit datetime, @id_curs int, @tematica varchar(500), 
	@tiptrainer char(2), @trainer char(20), @tiplocatie char(2), @locatie char(20), @gid_instruire int, @gnumarfisa varchar(20), @stare_instruire char(1), @comanda varchar(20),
	--Date pozitie
	@id_poz_instruire int, @id_pers varchar(6), @durata int, @data_absolvirii datetime, @nota float, @stare_pozitie char(1), @explicatii varchar(500), 
	@data_operarii datetime, @ora_operarii char(6), @utilizator char(10), @seriediploma varchar(10), @nrdiploma varchar(20), @elibdiploma varchar(100), 
	--Altele
	@subtip varchar(2), @update bit, @eroare varchar(200)

	set @gid_instruire=0

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	select @subtip=@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)')
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

if @subtip='PR'
	exec wRUOPPreluarePersoanePeInstruire @sesiune, @parXML
else
Begin	
	declare crsPozInstruiri cursor for
	select id_instruire, tip, numarfisa, data, data_inceput, data_sfarsit, id_curs, tematica, tiptrainer, trainer, tiplocatie, locatie, stare_instruire, comanda, 
		isnull(id_poz_instruire,0), id_pers, durata, data_absolvirii, nota, explicatii, stare_pozitie, seriediploma, nrdiploma, elibdiploma, isnull(ptupdate,0), subtip
	from OPENXML(@iDoc, '/row/row') 
	WITH 
	(
--		Antet
		id_instruire int '../@id_instruire',
		tip varchar(2) '../@tip',
		numarfisa varchar(20) '../@nrfisa',
		data datetime '../@data',
		data_inceput datetime '../@data_inceput',
		data_sfarsit datetime '../@data_sfarsit',
		id_curs int '../@id_curs',
		tematica char(500) '../@tematica',
		tiptrainer char(2) '../@tiptrainer',
		trainer char(20) '../@trainer',
		tiplocatie char(2) '../@tiplocatie',
		locatie char(20) '../@locatie',
		stare_instruire char(1) '../@stare',
		comanda char(20) '../@comanda',
--		Pozitie
		id_poz_instruire int '@id_poz_instruire',
		id_pers varchar(6) '@id_pers',
		durata int '@durata',
		data_absolvirii datetime '@data_absolvirii',
		nota float '@nota',
		explicatii varchar(500) '@explicatii',
		stare_pozitie char(1) '@starepozitie',
		seriediploma varchar(10) '@seriediploma',
		nrdiploma varchar(20) '@nrdiploma',
		elibdiploma varchar(100) '@elibdiploma',
		ptupdate int '@update',
		subtip varchar(2) '@subtip'
	)
	open crsPozInstruiri
	fetch next from crsPozInstruiri into @id_instruire, @tip, @numarfisa, @data, @data_inceput, @data_sfarsit, @id_curs, @tematica, @tiptrainer, @trainer, @tiplocatie, @locatie, 
		@stare_instruire, @comanda, @id_poz_instruire, @id_pers, @durata, @data_absolvirii, @nota, @explicatii, @stare_pozitie, @seriediploma, @nrdiploma, @elibdiploma, @update, @subtip
	while @@fetch_status=0
	begin
		if @update=0
--		Adaugare date (nu modificare)
		begin
			if not exists (select Cod_functie from RU_cursuri_functii where ID_curs=@id_curs and cod_functie=isnull((select Cod_functie from RU_persoane where ID_pers=@id_pers),''))
			begin
				raiserror('Functia persoanei nu este asociata cursului selectat!',11,1)
				return -1
			end
			if @id_instruire = 0 and @gid_instruire=0
--		Adaugare evaluare
			begin
				exec wRUiauNrFisa @Tip=@Tip, @Numar=@numarfisa output, @Data=@Data output
				set @gnumarfisa=@numarfisa
				if @numarfisa = ''
				begin
					raiserror('Numar fisa necompletat!',11,1)
					return -1
				end
				if @id_curs is null
				begin
					raiserror('Curs necompletat!',11,1)
					return -1
				end
				if @trainer is null and @stare_instruire<>'P'
				begin
					raiserror('Trainer necompletat!',11,1)
					return -1
				end
				if @locatie is null and @stare_instruire<>'P'
				begin
					raiserror('Locatie necompletata!',11,1)
					return -1
				end

				create table #id_instruire (id_instruire int)
				insert into RU_instruiri (Numar_fisa, Data, Data_inceput, Data_sfarsit, ID_curs, Tematica, Tip_trainer, Trainer, Tip_locatie, Locatie, Stare, Comanda)
					output inserted.id_instruire into #id_instruire
					values (@numarfisa, @data, @data_inceput, @data_sfarsit, @id_curs, @tematica, @tiptrainer, @trainer, @tiplocatie, @locatie, @stare_instruire, @comanda)

			End
--		determin id_instruire la adaugare prima pozitie pe document
			if @id_instruire=0
				select @id_instruire=id_instruire, @gid_instruire=id_instruire from #id_instruire
			insert into RU_poz_instruiri (ID_instruire, ID_pers, Marca, Durata, Data_absolvirii, Nota, Stare_pozitie, Explicatii, Data_operarii, Ora_operarii, 
				Utilizator, Serie_diploma, Numar_diploma, Eliberat_diploma)
				values (@id_instruire, @id_pers, '', @durata, @data_absolvirii, @nota, @stare_pozitie, @explicatii, 
				convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', '')), @utilizator, @seriediploma, @nrdiploma, @elibdiploma)
		end
--		Gata adaugari
		else
			update RU_poz_instruiri set ID_pers=@id_pers, Durata=@durata, Data_absolvirii=@data_absolvirii, Nota=@nota, Stare_pozitie=@stare_pozitie, 
				Explicatii=@explicatii, Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
				Utilizator=@utilizator, Serie_diploma=@seriediploma, Numar_diploma=@nrdiploma, Eliberat_diploma=@elibdiploma
			where id_poz_instruire= @id_poz_instruire

		fetch next from crsPozInstruiri into @id_instruire, @tip, @numarfisa, @data, @data_inceput, @data_sfarsit, @id_curs, @tematica, @tiptrainer, @trainer, @tiplocatie, @locatie, 
			@stare_instruire, @comanda, @id_poz_instruire, @id_pers, @durata, @data_absolvirii, @nota, @explicatii, @stare_pozitie, @seriediploma, @nrdiploma, @elibdiploma, @update, @subtip
	End
	declare @docXMLIaPozInstruiri xml
	set @docXMLIaPozInstruiri ='<row id_instruire="'+rtrim(convert(varchar(6),@id_instruire))+'" tip="'+rtrim(@tip)+'"/>'
	exec wRUIaPozInstruiri @sesiune=@sesiune, @parXML=@docXMLIaPozInstruiri
end
end try

begin catch
	set @eroare='(wRUScriuPozInstruiri) '+char(10)+rtrim(ERROR_MESSAGE())
end catch

declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsPozInstruiri' and session_id=@@SPID )
if @cursorStatus=1 
	close crsPozInstruiri 
if @cursorStatus is not null 
	deallocate crsPozInstruiri

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
--
if len(@eroare)>0
	raiserror(@eroare,16,1)
