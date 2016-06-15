
CREATE procedure rapPontajPreluat
	(@datajos datetime, @datasus datetime, @lm varchar(9)=null, @strict int=0, @marca varchar(6)=null, @functie varchar(6)=null, @tipprogramare char(50)=null)
as
begin try
	set transaction isolation level read uncommitted
	declare @mesaj varchar(500), @parXML xml

	set @parXML=(select convert(char(10),@datajos,101) datainceput, convert(char(10),@datasus,101) datasfarsit, 
		@lm lm, @strict strict, @marca marca, 1 dinraport for xml raw)

-- citesc cu procedura de calcul, pontajul rezultat 
	if object_id('tempdb..#pontaj') is not null drop table #pontaj
	Create table #pontaj 
		(tip char(1), idPontajElectronic int, idProgramDeLucru int, marca varchar(6), data datetime, loc_de_munca varchar(9), 
		tip_programare varchar(50), data_inceput_prg datetime, ora_start_prg varchar(10), data_sfarsit_prg datetime, ora_stop_prg varchar(10), ore_program int, 
		data_ora_intrare datetime, ora_intrare varchar(10), data_ora_iesire datetime, ora_iesire varchar(10), tip_ore_pontaj varchar(50), ore_pontaj int)

	insert into #pontaj 
		(tip, idPontajElectronic, idProgramDeLucru, marca, data, loc_de_munca, 
		tip_programare, data_inceput_prg, ora_start_prg, data_sfarsit_prg, ora_stop_prg, ore_program, 
		data_ora_intrare, ora_intrare, data_ora_iesire, ora_iesire, tip_ore_pontaj, ore_pontaj)
	exec wPontajRezultat '', @parXML

	select row_number() over (order by po.loc_de_munca, p.nume, po.data_inceput_prg, po.data_sfarsit_prg) as id, 
		tip, po.marca, p.nume, data, po.loc_de_munca as lm, lm.Denumire as den_lm, 
		idPontajElectronic, idProgramDeLucru, 
		tip_programare, data_inceput_prg, ora_start_prg, data_sfarsit_prg, ora_stop_prg, ore_program, 
		data_ora_intrare, ora_intrare, data_ora_iesire, ora_iesire, 
		tip_ore_pontaj, ore_pontaj
	from #pontaj po
		left outer join personal p on p.Marca=po.marca
		left outer join lm on lm.Cod=po.loc_de_munca
	where (@tipprogramare is null or po.tip_programare=@tipprogramare)	
	order by id

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (rapPontajPreluat)'

	raiserror (@mesaj, 11, 1)
end catch

/*
	exec rapPontajPreluat '11/06/2012', '11/07/2012', null, 0, '13', null, null
*/
