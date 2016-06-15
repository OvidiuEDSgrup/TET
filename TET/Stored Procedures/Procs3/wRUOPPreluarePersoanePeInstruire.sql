--***
Create procedure wRUOPPreluarePersoanePeInstruire @sesiune varchar(50), @parXML xml                
as              
declare @id_instruire int, @tip char(2), @numarfisa char(20), @data datetime, @id_curs int, @tematica varchar(500), @tiptrainer char(2), @trainer char(20), 
	@tiplocatie char(2), @locatie char(20), @comanda varchar(20), @stare_instruire char(1), @data_inceput datetime, @data_sfarsit datetime, @data_absolvirii datetime, @durata int, 
	@explicatii varchar(500), @userASiS varchar(20), @err int, @dencurs varchar(100)

set @id_instruire = ISNULL(@parXML.value('(/row/@id_instruire)[1]', 'int'), 0)
set @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
set @numarfisa = ISNULL(@parXML.value('(/row/@nrfisa)[1]', 'varchar(20)'), '')
set @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')
set @data_inceput = ISNULL(@parXML.value('(/row/@data_inceput)[1]', 'datetime'), '')
set @data_sfarsit = ISNULL(@parXML.value('(/row/@data_sfarsit)[1]', 'datetime'), '')
set @id_curs = ISNULL(@parXML.value('(/row/@id_curs)[1]', 'int'), 0)
set @tematica = ISNULL(@parXML.value('(/row/@tematica)[1]', 'varchar(500)'), '')
set @tiptrainer = ISNULL(@parXML.value('(/row/@tiptrainer)[1]', 'varchar(2)'), '')
set @trainer = ISNULL(@parXML.value('(/row/@trainer)[1]', 'varchar(20)'), '')
set @tiplocatie = ISNULL(@parXML.value('(/row/@tiplocatie)[1]', 'varchar(2)'), '')
set @locatie = ISNULL(@parXML.value('(/row/@locatie)[1]', 'varchar(20)'), '')
set @comanda = ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), '')
set @stare_instruire = ISNULL(@parXML.value('(/row/@stare)[1]', 'varchar(2)'), '')
set @data_absolvirii = ISNULL(@parXML.value('(/row/row/@data_absolvirii)[1]', 'datetime'), '')
set @durata = ISNULL(@parXML.value('(/row/row/@durata)[1]', 'int'), 0)
set @explicatii = ISNULL(@parXML.value('(/row/row/@explicatii)[1]', 'varchar(500)'), '')

select @dencurs=Denumire, @durata=(case when @durata=0 then Durata else @durata end) from RU_cursuri where ID_curs=@id_curs

if isnull(@tip,'')=''
	set @tip = 'IS'
exec wIaUtilizator @sesiune=@sesiune,@utilizator=@userASiS

begin try 
    if not exists (select Cod_functie from RU_cursuri_functii where ID_curs=@id_curs)
		raiserror('Cursul selectat nu are atasate functii!',16,1)
    if exists (select 1 from RU_poz_instruiri where ID_instruire=@id_instruire)
		raiserror('Aceasta instruire are deja introdusi salariati! Operatia este anulata!',16,1)
--	creez tabela temporara ce contine salariatii cu functie atasata cursului
	select p.ID_pers, 'IS' as subtip  
	into #tmpinstruiri
	from RU_persoane p
		left outer join RU_cursuri_functii cf on cf.Cod_functie=p.Cod_functie
		left outer join personal ps on ps.Marca=p.Marca
	where cf.ID_curs=@id_curs and (isnull(ps.Marca,'')='' or convert(int,ps.Loc_ramas_vacant)=0)
--	formez XML pt. apelare procedura wRUScriuPozInstruiri
	declare @input XMl
	set @input=
	(select @tip as '@tip', @id_instruire as '@id_instruire',  rtrim(@numarfisa) as '@nrfisa', @data as '@data', convert(char(10),@data_inceput,101) as '@data_inceput', 
		convert(char(10),@data_sfarsit,101) as '@data_sfarsit',	@id_curs as '@id_curs', @tematica as '@tematica', rtrim(@tiptrainer) as '@tiptrainer', 
		rtrim(@trainer) as '@trainer', rtrim(@tiplocatie) as '@tiplocatie', rtrim(@locatie) as '@locatie', rtrim(@comanda) as '@comanda', rtrim(@stare_instruire) as '@stare',
		(select rtrim(ID_pers) as '@id_pers', subtip as '@subtip', @durata as '@durata', convert(char(10),@data_absolvirii,101) as '@data_absolvirii', @explicatii as '@explicatii', 
		(case when @stare_instruire in ('P','A') then 'P' else 'A' end) as '@starepozitie'
		from #tmpinstruiri
		Order by ID_pers
		for XML path,type
		)
	for xml Path,type)

	exec wRUScriuPozInstruiri @sesiune=@sesiune, @parXML=@input

	select 'S-au preluat persoanele de pe functiile atasate cursului: '+rtrim(@id_curs)+' - '+rtrim(@dencurs)+' !' as textMesaj for xml raw, root('Mesaje')
end try        

begin catch 
	declare @eroare varchar(200) 
	set @eroare='(wRUOPPreluarePersoanePeInstruire)'+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
