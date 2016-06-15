--***
create procedure wOPAdaugaProgramareGantt @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@dataStart datetime, @oraStart varchar(6), @dataStop datetime, @oraStop varchar(6),
		@descriere varchar(200), @post_de_lucru smallint, @utilizator varchar(20), @stare varchar(1),
		@numar_curent int, @oraStartInt int, @oraStopInt int, @nr_inmatriculare varchar(10),
		@persContact varchar(100), @telContact varchar(20)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@dataStart = isnull(@parXML.value('(/*/@dataStart)[1]', 'datetime'), ''),
		@oraStart = isnull(replace(@parXML.value('(/*/@oraStart)[1]', 'varchar(6)'), ':', ''), ''),
		@dataStop = isnull(@parXML.value('(/*/@dataStop)[1]', 'datetime'), ''),
		@oraStop = isnull(replace(@parXML.value('(/*/@oraStop)[1]', 'varchar(6)'), ':', ''), ''),
		@descriere = isnull(@parXML.value('(/*/@descriere)[1]', 'varchar(200)'), ''),
		@post_de_lucru = isnull(@parXML.value('(/*/@post_lucru)[1]', 'smallint'), 0),
		@stare = isnull(@parXML.value('(/*/@stare)[1]', 'varchar(1)'), '1'),
		@nr_inmatriculare = isnull(@parXML.value('(/*/@nr_inmatriculare)[1]', 'varchar(10)'), ''),
		@persContact = isnull(@parXML.value('(/*/@persContact)[1]', 'varchar(100)'), ''),
		@telContact = isnull(@parXML.value('(/*/@telContact)[1]', 'varchar(20)'), '')
		
	if @post_de_lucru = 0
	begin
		raiserror('Selectati un post de lucru!', 16, 1)
		return
	end

	if @dataStart > @dataStop
		raiserror('Data de inceput a programarii nu poate fi dupa data de sfarsit!', 16, 1)

	if @oraStart = '' or @oraStop = ''
	begin
		raiserror('Specificati ore valide!', 16, 1)
		return
	end

	--
	-- daca oraStart = oraStop, nu se va putea vedea pe grafic, de aceea trebuie sa fie
	-- un interval mai mare specificat.
	--

	if left(@oraStart, 2) = left(@oraStop, 2)
		raiserror('Specificati un interval mai mare!', 16, 1)

	--
	-- verificam daca orele introduse sunt numerice
	--

	if isnumeric(@oraStart) =  1 and isnumeric(@oraStop) = 1
	begin
		set @oraStartInt = convert(int, @oraStart)
		set @oraStopInt = convert(int, @oraStop)
	end
	else
	begin
		raiserror('Introduceti doar valori numerice! Ex: 08:00', 16, 1)
		return
	end

	if left(@oraStart, 2) > 24 or left(@oraStop, 2) > 24
	begin
		raiserror('Ora invalida! Trebuie sa fie in intervalul (00:00 - 24:00)', 16, 1)
		return
	end

	if @dataStart = @dataStop
		if @oraStartInt > @oraStopInt
		begin
			raiserror('Ora de start nu poate fi dupa ora de stop in cadrul aceleiasi zile!', 16, 1)
			return
		end

	if (select count(*) from Programator) = 0
		set @numar_curent = 0
	else
		select @numar_curent = max(Numar_curent) from Programator
	
	insert into Programator (Numar_curent, Data, Descriere_problema, Tert, Cod, Postul, Data_planificarii,
		Ora_planificarii_start, Data_planificarii_stop, Ora_planificarii_stop, Utilizator, Data_operarii,
		Ora_operarii, Stare, Deviz, nr_inmatriculare_prog, nume_prog, telefon_prog, numar_parinte, Motiv_intrare)
	select
		@numar_curent + 1, getdate(), rtrim(@descriere), '', '', @post_de_lucru, @dataStart, @oraStart,
		@dataStop, @oraStop, rtrim(@utilizator), getdate(), replace(convert(varchar(8), getdate(), 114), ':', ''),
		'1', '', rtrim(@nr_inmatriculare), rtrim(@persContact), rtrim(@telContact), 0, ''

	select
		'S-a facut programarea cu numarul ' + convert(varchar(20), @numar_curent + 1) + ', in data de ' +
		convert(varchar(10), @dataStart, 103) + '.'  as textMesaj,
		'Succes' as titluMesaj
	for xml raw, root('Mesaje')
	
end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
