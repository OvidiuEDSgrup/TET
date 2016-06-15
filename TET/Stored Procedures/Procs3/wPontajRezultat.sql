
CREATE procedure wPontajRezultat @sesiune varchar(50), @parXML XML
as
begin try
	set transaction isolation level read uncommitted
	declare @pontajZilnic int, @datainceput datetime, @datasfarsit datetime, @marca varchar(6), @lm varchar(9), @strict int, 
		@mesaj varchar(500), @parXML1 xml, @dinRaport int

	set @pontajZilnic = dbo.iauParL('PS','PONTZILN')
	set @datainceput = @parXML.value('(/*/@datainceput)[1]', 'datetime')
	set @datasfarsit = @parXML.value('(/*/@datasfarsit)[1]', 'datetime')
	set @marca = isnull(@parXML.value('(/*/@marca)[1]', 'varchar(6)'),'')
	set @lm = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(9)'),'')
	set @strict = @parXML.value('(/*/@strict)[1]', 'int')
	set @dinRaport = isnull(@parXML.value('(/*/@dinraport)[1]', 'int'),0)
	set @parXML1=(select 'OP' tip for xml raw)
	
	if object_id('tempdb..#concedii') is not null drop table #concedii
	if object_id('tempdb..#ProgramLucru') is not null drop table #ProgramLucru
	if object_id('tempdb..#PontajProgram') is not null drop table #PontajProgram

--	stabilesc programul de lucru valabil pentru perioda selectata pentru fiecare zi din perioada
	select * into #ProgramLucru from wfProgramLucru (@sesiune, @parXML)

--	citesc datele din pontajul electronic si le potrivesc cu cele din programul efectiv de lucru (data inceput, ora start, ora stop)
	select pe.idPontajElectronic, pe.marca, pe.data_ora_intrare, pe.data_ora_iesire, 
		(case when isnull(pl.Loc_de_munca,'')='' then p.Loc_de_munca else pl.Loc_de_munca end) as loc_de_munca, pl.Tip_programare, pl.Tip_ore_pontaj, 
		pl.idProgramDeLucru, pl.data_inceput as data_inceput_pl, left(pl.ora_start,2)+':'+SUBSTRING(pl.ora_start,3,2) as ora_start, 
		left(pl.ora_stop,2)+':'+SUBSTRING(pl.ora_stop,3,2) as ora_stop, 
		convert(datetime,CONVERT(char(10),pe.data_ora_intrare,101),101)+CONVERT(time,left(pl.ora_start,2)+':'+SUBSTRING(pl.ora_start,3,2)+':'+SUBSTRING(pl.ora_start,5,2)) as data_inceput_prg,
		convert(datetime,CONVERT(char(10),pe.data_ora_iesire,101),101)+CONVERT(time,left(pl.ora_stop,2)+':'+SUBSTRING(pl.ora_stop,3,2)+':'+SUBSTRING(pl.ora_stop,5,2)) as data_sfarsit_prg, 
		convert(float,0) as ore_pontaj, convert(float,0) as ore_program
	into #PontajProgram
	from PontajElectronic pe
		left outer join personal p on p.Marca=pe.marca
		left outer join #ProgramLucru pl on convert(datetime,convert(char(10),pe.data_ora_intrare,101),101)=pl.Data
			and (pl.Marca=pe.marca or isnull(pl.Marca,'')='' and pl.Loc_de_munca=p.Loc_de_munca or isnull(pl.Marca,'')='' and isnull(pl.Loc_de_munca,'')='')
	where CONVERT(CHAR(10),pe.data_ora_intrare,101) between @datainceput and @datasfarsit
		and (@marca='' or pe.marca=@marca)
		and (@lm='' or p.Loc_de_munca=@lm)
		and (pl.Marca=pe.marca 
			or isnull(pl.Marca,'')='' and pl.Loc_de_munca=p.Loc_de_munca 
				and not exists (select 1 from #ProgramLucru pl1 where pl1.Marca=pe.marca and pl1.data=pl.data and pl1.Tip_programare=pl.Tip_programare)
			or isnull(pl.Marca,'')='' and isnull(pl.Loc_de_munca,'')='' 
				and not exists (select 1 from #ProgramLucru pl2 where (pl2.Marca=pe.marca or isnull(pl2.Marca,'')='' and pl2.Loc_de_munca=p.Loc_de_munca) 
					and pl2.data=pl.data /*and pl2.Tip_programare=pl.Tip_programare*/))

--	calculez orele efectiv lucrate si orele de program
	update #PontajProgram set 
		ore_pontaj=floor(DATEDIFF(MINUTE,dbo.data_maxima(data_ora_intrare,isnull(data_inceput_prg,'01/01/1901')),dbo.data_minima(data_ora_iesire,isnull(data_sfarsit_prg,'12/31/2999')))/60.00),
		ore_program=floor(DATEDIFF(MINUTE,data_inceput_prg,data_sfarsit_prg)/60.00)

--	Pun in tabela #concedii datele operate in concedii medicale, concedii de odihna si concedii\alte care apoi le unesc la pontajul zilnic 
	select Marca, Data_inceput, ora_inceput, Data_sfarsit, ora_sfarsit, Denumire as tip_programare, tip_ore_pontaj, zile, ore as ore_program
	into #concedii
	from dbo.fDate_pontaj_automat (dbo.bom(@datainceput), dbo.eom(@datasfarsit), @datasfarsit, 'TC', @marca, 0, 1)

--	selectez datele de dus in pontaj, pentru moment cu afisare pe verticala
	select 'P' as tip, pp.idPontajElectronic, pp.idProgramDeLucru, pp.marca, convert(datetime,convert(char(10),pp.data_ora_intrare,101),101) as data, pp.loc_de_munca,  
		pp.Tip_programare, pp.data_inceput_prg, pp.ora_start as ora_start_prg, pp.data_sfarsit_prg, pp.ora_stop as ora_stop_prg, pp.ore_program, 
		pp.data_ora_intrare, pp.data_ora_iesire, tp.denumire as tip_ore_pontaj, 
		(case when Tip_programare='Tesa' or ore_pontaj>ore_program then ore_program else ore_pontaj end) as ore_pontaj
	into #pontaj
	from #PontajProgram pp
		left outer join wfTipProgramareOrePontaj(@sesiune,@parXML1) tp on tp.Tip=pp.Tip_ore_pontaj
	union all 
	select 'C' as tip, 0, 0, c.Marca, fc.Data, p.Loc_de_munca, 
	c.tip_programare, (case when @dinRaport=1 and c.ora_inceput='' then fc.data else c.Data_inceput end) as data_inceput, c.ora_inceput, c.Data_sfarsit, c.ora_sfarsit, 
	(case when c.ora_inceput<>'' then c.ore_program else rl.RL end), 
	'', '', c.tip_ore_pontaj as tip_ore_pontaj, (case when c.ora_inceput<>'' then c.ore_program when @dinRaport=1 then 0 else rl.RL end) as ore_pontaj
	from #concedii c
		left outer join personal p on p.Marca=c.Marca
		inner join fCalendar(@datainceput, @datasfarsit) fc on fc.data between convert(char(10),c.data_inceput,101) and convert(char(10),c.Data_sfarsit,101)
			or fc.data between convert(char(10),c.data_inceput,101) and convert(char(10),c.Data_sfarsit,101)
		left outer join fDate_pontaj_automat(@datainceput,@datasfarsit,@datasfarsit,'RL','',0,0) rl on rl.Marca=c.Marca

	update #pontaj set tip_ore_pontaj=REPLACE(rtrim(tip_ore_pontaj),' ','_')
	
	if exists (select 1	from sysobjects where name = 'wPontajRezultatSP')
		exec wPontajRezultatSP @sesiune = @sesiune, @parXML = @parXML
	
	select tip, idPontajElectronic, idProgramDeLucru, po.marca, data, po.loc_de_munca, 
		Tip_programare, data_inceput_prg as data_inceput_prg, ora_start_prg, data_sfarsit_prg as data_sfarsit_prg, ora_stop_prg, ore_program, 
		data_ora_intrare, rtrim(convert(char(10),data_ora_intrare,108)) as ora_intrare, data_ora_iesire, rtrim(convert(char(10),data_ora_iesire,108)) as ora_iesire, 
		tip_ore_pontaj, ore_pontaj 
	from #pontaj po
		left outer join personal p on p.marca=po.marca
	order by data_inceput_prg, data_sfarsit_prg

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wPontajRezultat)'

	raiserror (@mesaj, 11, 1)
end catch

/*
	exec wPontajRezultat '', '<row datainceput="2012-11-06" datasfarsit="2012-11-07" marca="" dinraport="1" />'
	exec wPontajRezultat '', '<row datainceput="2012-11-01" datasfarsit="2012-11-15" marca="13" dinraport="1" />'
*/
