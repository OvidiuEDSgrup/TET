--***
create procedure wScriuProgramareGantt @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@dataStart datetime, @dataStop datetime, @oraStart varchar(6), @oraStop varchar(6),
		@identificator varchar(20), @oraStartInt int, @oraStopInt int

	select
		@identificator = isnull(@parXML.value('(/*/@comanda)[1]', 'varchar(20)'), ''),
		@dataStart = @parXML.value('(/*/@dataStart)[1]', 'datetime'),
		@dataStop = @parXML.value('(/*/@dataStop)[1]', 'datetime'),
		@oraStart = isnull(replace(@parXML.value('(/*/@oraStart)[1]', 'varchar(6)'), ':', ''), ''),
		@oraStop = isnull(replace(@parXML.value('(/*/@oraStop)[1]', 'varchar(6)'), ':', ''), '')

	-- =========
	-- Validari
	-- =========

	if @identificator = ''
		raiserror('Nu s-a putut identifica programarea!', 16, 1)

	if @dataStart > @dataStop
		raiserror('Data start dupa data stop!', 16, 1)

	if @oraStart = '' or @oraStop = ''
		raiserror('Specificati ore valide!', 16, 1)

	--
	-- daca oraStart = oraStop, nu se va putea vedea pe grafic, de aceea trebuie sa fie
	-- un interval mai mare specificat.
	--
	
	if @oraStart = @oraStop
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
		raiserror('Introduceti doar valori numerice!', 16, 1)
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
			raiserror('Ora de start nu poate fi dupa ora de stop!', 16, 1)
			return
		end
	
	-- =======
	-- Update
	-- =======

	update Programator
	set Data_planificarii = @dataStart, Data_planificarii_stop = @dataStop,
		Ora_planificarii_start = @oraStart, Ora_planificarii_stop = @oraStop
	where Numar_curent = @identificator
	
end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
