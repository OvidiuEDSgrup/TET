
CREATE procedure wScriuProgramLucru @sesiune varchar(50), @parXML XML
as
begin try
	DECLARE @idProgramDeLucru int, @tipprogram char(1), @update int, @mesaj varchar(400), 
		@lm varchar(9), @marca varchar(6), @tipprogramare varchar(20), @tiporepontaj varchar(3), 
		@datainceput datetime, @datasfarsit datetime, @orastart varchar(6), @orastop varchar(6), 
		@orastartOre varchar(2), @orastartMinute varchar(2), @orastopOre varchar(2), @orastopMinute varchar(2), 
		@oremunca int, @oreodihna int, @detalii XML

	set @idProgramDeLucru = @parXML.value('(/*/@idProgramDeLucru)[1]', 'int')
	set @tipprogram = @parXML.value('(/*/@tipprogram)[1]', 'char(1)')
	set @lm = @parXML.value('(/*/@lm)[1]', 'varchar(9)')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	set @tipprogramare = @parXML.value('(/*/@tipprogramare)[1]', 'varchar(20)')
	set @tiporepontaj = @parXML.value('(/*/@tiporepontaj)[1]', 'varchar(3)')	
	set @datainceput = @parXML.value('(/*/@datainceput)[1]', 'datetime')
	set @datasfarsit = @parXML.value('(/*/@datasfarsit)[1]', 'datetime')
	set @orastart = @parXML.value('(/*/@orastartafis)[1]', 'varchar(6)')
	set @orastop = @parXML.value('(/*/@orastopafis)[1]', 'varchar(6)')
	set @oremunca = @parXML.value('(/*/@oremunca)[1]', 'int')
	set @oreodihna = @parXML.value('(/*/@oreodihna)[1]', 'int')

	if @tipprogram='U'
		select @marca=null, @lm=null
	if @tipprogram='S' and @lm=''
		set @lm=null
	if @tipprogram='L' 
		set @marca=null

	if @parXML.exist('(/*/detalii)[1]') = 1
		set @detalii = @parXML.query('(/*/detalii/row)[1]')
	/** Alte **/
	set @update = isnull(@parXML.value('(/*/@update)[1]', 'bit'), 0)

	if isnull(@orastart,'')='' or isnull(@orastop,'')=''
		raiserror('Ati omis sa completati campurile corespunzatoare orei de start si/sau orei de finalizare!',11,1)	

	if (isnull(@oremunca,0)<>0 or isnull(@oreodihna,0)<>0) and @tipprogramare<>'Tura'
		raiserror('Ore munca/ore odihna se completeaza doar pentru tip programare "Tura"!',11,1)

--	calculez ora start si stop
	select @orastartOre=isnull(string,'00')
	from dbo.fsplit(@orastart,':')
	where id=1
	
	select @orastopOre=isnull(string,'00')
	from dbo.fsplit(@orastop,':')
	where id=1

--	calculez minutul start si stop
	select @orastartMinute=isnull(string,'00')
	from dbo.fsplit(@orastart,':')
	where id=2

	select @orastopMinute=isnull(string,'00')
	from dbo.fsplit(@orastop,':')
	where id=2
	
	if isnumeric(isnull(@orastartOre,'00'))<>1 or isnumeric(isnull(@orastartMinute,'00'))<>1
		raiserror('Ora start introdusa gresit! Formatul acceptat: 00:00',11,1)
	if isnumeric(isnull(@orastopOre,'00'))<>1 or isnumeric(isnull(@orastopMinute,'00'))<>1
		raiserror('Ora stop introdusa gresit! Formatul acceptat: 00:00',11,1)

--	calculez orastart din ora si minute
	set @orastart=replace(isnull(str(@orastartOre,2),'00'),' ','0')+replace(isnull(str(@orastartMinute,2),'00'),' ','0')+'00'
--	calculez orastop din ora si minute
	set @orastop=replace(isnull(str(@orastopOre,2),'00'),' ','0')+replace(isnull(str(@orastopMinute,2),'00'),' ','0')+'00'

	if @update = 0
		insert into ProgramLucru (Loc_de_munca, Marca, Tip_programare, Tip_ore_pontaj, data_inceput, data_sfarsit, ora_start, ora_stop, ore_munca, ore_odihna, detalii)
		select @lm, @marca, @tipprogramare, @tiporepontaj, @datainceput, @datasfarsit, @orastart, @orastop, @oremunca, @oreodihna, @detalii
	else
		if @idProgramDeLucru is not null
			update ProgramLucru	set 
				Loc_de_munca = @lm, Marca = @marca, Tip_programare = @tipprogramare, Tip_ore_pontaj = @tiporepontaj, 
				data_inceput=@datainceput, ora_start=@orastart, ora_stop=@orastop, ore_munca=@oremunca, ore_odihna=@oreodihna, 
				detalii = @detalii
			where idProgramDeLucru=@idProgramDeLucru

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuProgramLucru)'

	raiserror (@mesaj, 11, 1)
end catch
