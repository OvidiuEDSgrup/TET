
CREATE function wfProgramLucru (@sesiune varchar(50), @parXML xml)
returns @programLucru table 
	(data datetime, idProgramDeLucru int, loc_de_munca varchar(9), marca varchar(6), tip_programare varchar(50), tip_ore_pontaj varchar(3), 
	data_inceput datetime, ora_start varchar(10), data_sfarsit datetime, ora_stop varchar(10), data_start datetime, data_stop datetime)
begin
	declare @datajos datetime, @datasus datetime, @data_inceput datetime, @datastart datetime, @datastop datetime
	set @datajos = @parXML.value('(/*/@datainceput)[1]', 'datetime')
	set @datasus = @parXML.value('(/*/@datasfarsit)[1]', 'datetime')

	insert into @programLucru
	select data, idProgramDeLucru, loc_de_munca, marca, tip_programare, tip_ore_pontaj, data_inceput, ora_start, Data_sfarsit, ora_stop, 
	convert(datetime,data,108)+convert(datetime,CONVERT(time,left(ora_start,2)+':'+SUBSTRING(ora_start,3,2)+':'+SUBSTRING(ora_start,5,2)),114) as data_start,
	convert(datetime,DateAdd(day,(case when ora_stop<ora_start then 1 else 0 end),data),108)
		+convert(datetime,CONVERT(time,left(ora_stop,2)+':'+SUBSTRING(ora_stop,3,2)+':'+SUBSTRING(ora_stop,5,2)),114) as data_stop
	from (select fc.Data, idProgramDeLucru, loc_de_munca, marca, tip_programare, tip_ore_pontaj, data_inceput, ora_start, data_sfarsit, ora_stop, 
			RANK() over (partition by fc.Data, Marca, Loc_de_munca, Tip_ore_pontaj order by Data_inceput Desc) as ordine
		from ProgramLucru pl 
			inner join fCalendar (@datajos, @datasus) fc on 1=1
		where data_inceput<=fc.Data and (pl.Data_sfarsit is null or pl.Data_sfarsit>=fc.Data)
			and pl.Tip_programare<>'Tura') a
	where Ordine=1
	
/*	partea de mai jos se refera la programul de lucru in ture
	se determina zilele in care salariatul trebuie sa fie la munca, in raport de data inceput program/ore munca/ore odihna*/

/*	citesc data de inceput in raport cu care studiez fCalendar*/
	declare @programLucruTura table 
		(idProgramDeLucru int, loc_de_munca varchar(9), marca varchar(6), tip_programare varchar(50), tip_ore_pontaj varchar(3), 
		data_inceput datetime, ora_start varchar(10), data_sfarsit datetime, ora_stop varchar(10), ore_munca int, ore_odihna int)

	insert into @programLucruTura
	select idProgramDeLucru, loc_de_munca, marca, tip_programare, tip_ore_pontaj, data_inceput, ora_start, Data_sfarsit, ora_stop, ore_munca, ore_odihna
		from (select idProgramDeLucru, loc_de_munca, marca, tip_programare, tip_ore_pontaj, data_inceput, ora_start, data_sfarsit, ora_stop, ore_munca, ore_odihna, 
			RANK() over (partition by Marca, Loc_de_munca, Tip_ore_pontaj order by Data_inceput Desc) as ordine
		from ProgramLucru pl 
		where data_inceput<=@datasus and (pl.Data_sfarsit is null or pl.Data_sfarsit>=@datajos)
			and pl.Tip_programare='Tura') a
	where Ordine=1

	select @data_inceput=data_inceput from @programLucruTura
	where tip_programare='Tura'
	order by data_inceput

/*	creez tabela temporara in care determin tura pe zile*/
	declare @programtura table (nrcrt int, idProgramDeLucru int, loc_de_munca varchar(9), marca varchar(6), tip_programare varchar(20), tip_ore_pontaj varchar(50), 
		data_inceput datetime, data datetime, data_start datetime, data_stop datetime, ore_munca int, ore_odihna int)

	insert into @programtura
	select ROW_NUMBER() over (partition by pl.marca order by pl.data_inceput), pl.idProgramDeLucru, pl.loc_de_munca, pl.marca, pl.tip_programare, pl.Tip_ore_pontaj, 
		convert(datetime,pl.data_inceput,108)+convert(datetime,CONVERT(time,left(pl.ora_start,2)+':'+SUBSTRING(pl.ora_start,3,2)+':'+SUBSTRING(pl.ora_start,5,2)),114), fc.Data, '', '',
		pl.Ore_munca, pl.Ore_odihna
	from @programLucruTura pl
		left outer join fCalendar(@data_inceput, @datasus) fc on 1=1
	where pl.tip_programare='Tura'

	update @programtura set @datastart=(case when nrcrt=1 then data_inceput else DateAdd(HOUR,ore_odihna,@datastop) end),
		@datastop=DateAdd(HOUR,ore_munca,@datastart),
		data_start=@datastart, 
		data_stop=@datastop,
		data=CONVERT(char(10),@datastart,101)
		
/*	inserez pozitiile calculate pentru tura*/
	insert into @programLucru
	select data, idProgramDeLucru, loc_de_munca, marca, tip_programare, tip_ore_pontaj,
		data_inceput, replace(convert(char(10),data_start,108),':',''), null, replace(convert(char(10),data_stop,108),':',''), data_start, data_stop
	from @programtura
	where data between @datajos and @datasus

	RETURN
END
