
Create procedure rapVerificarePrezenta
	(@datajos datetime, @datasus datetime, @lm varchar(9), @strict int, @marca varchar(6), @functie varchar(6), @oraPrezenta varchar(6), @tip char(1))
/*
	@tip=P -> Prezenti
	@tip=A -> Absenti
	@tip=I -> Intarziati
*/
as
begin try
	set transaction isolation level read uncommitted
	declare @mesaj varchar(500), @parXML xml, @parXML1 xml

	set @parXML1=(select 'OP' tip for xml raw)
	
	if object_id('tempdb..#pontaj') is not null drop table #pontaj
	if object_id('tempdb..#ProgramLucru') is not null drop table #ProgramLucru
	if object_id('tempdb..#tmpPrezenta') is not null drop table #tmpPrezenta
	
	set @parXML=(select @datajos datainceput, @datasus datasfarsit, @lm lm, @strict strict, @marca marca, 1 dinraport for xml raw)

-- citesc cu procedura de calcul, pontajul rezultat 
	Create table #pontaj (tip char(1), idPontajElectronic int, idProgramDeLucru int, marca varchar(6), data datetime, loc_de_munca varchar(9), 
	tip_programare varchar(50), data_inceput_prg datetime, ora_start_prg varchar(10), data_sfarsit_prg datetime, ora_stop_prg varchar(10), ore_program int, 
	data_ora_intrare datetime, ora_intrare varchar(10), data_ora_iesire datetime, ora_iesire varchar(10), tip_ore_pontaj varchar(50), ore_pontaj int)

	insert into #pontaj (tip, idPontajElectronic, idProgramDeLucru, marca, data, loc_de_munca, 
		tip_programare, data_inceput_prg, ora_start_prg, data_sfarsit_prg, ora_stop_prg, ore_program, 
		data_ora_intrare, ora_intrare, data_ora_iesire, ora_iesire, tip_ore_pontaj, ore_pontaj)
	exec wPontajRezultat '', @parXML

--	stabilesc programul de lucru valabil pentru perioda selectata pentru fiecare zi din perioada
	select data, idProgramDeLucru, loc_de_munca, marca, Tip_programare, data_inceput, ora_start, Data_sfarsit, ora_stop, data_start, data_stop
	into #ProgramLucru 
	from wfProgramLucru ('', @parXML)

	select p.Marca, p.Nume, p.Loc_de_munca, fc.Data+CONVERT(time,rtrim(isnull(@oraPrezenta,'00:00'))+':00') as data_prezenta, 
		pl.idProgramDeLucru, pl.Tip_programare, pl.data_inceput, pl.ora_start, pl.ora_stop, pl.data_start, pl.data_stop,
		convert(datetime,CONVERT(char(10),fc.data,101),101)+CONVERT(time,left(pl.ora_start,2)+':'+SUBSTRING(pl.ora_start,3,2)+':'+SUBSTRING(pl.ora_start,5,2)) as data_inceput_prg
	into #tmpPrezenta 
	from Personal p
		inner join fCalendar(@datajos,@datasus) fc on 1=1
		left outer join #ProgramLucru pl on fc.data=pl.Data
			and (pl.Marca=p.marca or isnull(pl.Marca,'')='' and pl.Loc_de_munca=p.Loc_de_munca or isnull(pl.Marca,'')='' and isnull(pl.Loc_de_munca,'')='')
--	filtrez salariatii dupa filtre
	where (Loc_ramas_vacant=0 or Data_plec>@datajos)
		and (@lm is null or p.Loc_de_munca like rtrim(@lm)+(case when @strict=1 then '' else '%' end))
		and (@marca is null or p.Marca=@marca) 
		and Data_angajarii_in_unitate<=@datajos
		and (@functie is null or Cod_functie=@functie)
--	filtrez salariatii dupa programul de lucru
		and (pl.Marca=p.marca 
			or isnull(pl.Marca,'')='' and pl.Loc_de_munca=p.Loc_de_munca 
				and not exists (select 1 from #ProgramLucru pl1 where pl1.Marca=p.marca and pl1.data=pl.data /*and pl1.Tip_programare=pl.Tip_programare*/)
			or isnull(pl.Marca,'')='' and isnull(pl.Loc_de_munca,'')='' 
				and not exists (select 1 from #ProgramLucru pl2 where (pl2.Marca=p.marca or isnull(pl2.Marca,'')='' and pl2.Loc_de_munca=p.Loc_de_munca) 
					and pl2.data=pl.data /*and pl2.Tip_programare=pl.Tip_programare*/))

--	selectul final cu filtrarea datelor functie de parametrul @tip
	select row_number() over (order by pr.loc_de_munca, p.nume) as id, 
	pr.marca, p.nume, pr.Loc_de_munca as lm, lm.Denumire as den_lm, p.Cod_functie, f.Denumire as den_functie,
		pr.Tip_programare, pr.data_prezenta, 
		left(pr.ora_start,2)+':'+SUBSTRING(pr.ora_start,3,2) as ora_start, left(pr.ora_stop,2)+':'+SUBSTRING(pr.ora_stop,3,2) as ora_stop, 
		pe.data_intrare, pe.ora_intrare, pe.data_iesire, pe.ora_iesire
	from #tmpPrezenta pr
		left outer join personal p on p.Marca=pr.Marca
		left outer join lm on lm.Cod=p.Loc_de_munca
		left outer join functii f on f.Cod_functie=p.Cod_functie
		outer apply 
			(select top 1 convert(char(10),pe.data_ora_intrare,103) as data_intrare, convert(char(10),pe.data_ora_intrare,108) as ora_intrare, 
				convert(char(10),pe.data_ora_iesire,103) as data_iesire, convert(char(10),pe.data_ora_iesire,108) as ora_iesire
			from PontajElectronic pe where pe.marca=p.Marca and pe.data_ora_intrare<=data_prezenta and DateDiff(HOUR,pe.data_ora_intrare,pr.data_prezenta)<=10) pe
	where pr.data_prezenta between pr.data_start and pr.data_stop 
/*	absent daca ->	nu are pozitie cu intrare si fara iesire in pontajElectronic
					nu are pozitie cu intrare si iesire care sa acopere data de prezenta
					nu are pozitie in #concedii */
		and (@tip='A' 
			and not exists (select 1 from #pontaj pe where pe.tip='P' and pe.marca=pr.Marca and pe.data_ora_iesire=pe.data_ora_intrare and DateDiff(day,pe.data_ora_intrare,pr.data_prezenta)<=1) 
			and not exists (select 1 from #pontaj pe where pe.tip='P' and pe.marca=pr.Marca and pe.Tip_programare=pr.tip_programare 
				and pr.data_prezenta between pe.data_ora_intrare and pe.data_ora_iesire)
			and not exists (select 1 from #pontaj pe where pe.tip='C' and pe.marca=pr.Marca and pr.data_prezenta between pe.data_inceput_prg and pe.data_sfarsit_prg) 
		or @tip in ('P','') and (exists (select 1 from #pontaj pe where pe.tip='P' and pe.marca=pr.Marca and pe.data_ora_iesire=pe.data_ora_intrare and DateDiff(day,pe.data_ora_intrare,pr.data_prezenta)<=1) 
				or exists (select 1 from #pontaj pe where pe.tip='P' and pe.marca=pr.Marca and pr.data_prezenta between pe.data_ora_intrare and pe.data_ora_iesire))
		or @tip='I' and exists (select 1 from #pontaj pe where pe.tip='P' and pe.marca=pr.Marca and pe.data_ora_intrare between pr.data_start and pr.data_prezenta)
		or @tip='' and exists (select 1 from #pontaj pe where pe.tip='C' and pe.marca=pr.Marca and pr.data_prezenta between pe.data_ora_intrare and pe.data_ora_iesire))

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (rapVerificarePrezenta)'
	raiserror (@mesaj, 11, 1)
end catch

/*
	exec rapVerificarePrezenta '11/04/2012', '11/04/2012', null, 0, null, null, '08:00', 'A'
	exec rapVerificarePrezenta '11/05/2012', '11/05/2012', null, 0, null, null, '08:00', 'A'
	exec rapVerificarePrezenta '11/15/2012', '11/15/2012', null, 0, null, null, '09:00', 'A'
*/
