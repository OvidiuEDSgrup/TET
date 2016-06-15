--***
create procedure rapCheltuieliPeConturi @sesiune varchar(50), @datajos datetime, @datasus datetime
as
begin
	set transaction isolation level read uncommitted
	SELECT f.cont, max(c.Denumire_cont) as denCont, 
		0 as ch_directe,
		0 as ch_generale,
		0 as ch_indirecte,
		SUM(f.suma) as total
	into #temp
	FROM fisapecont f
	left outer join conturi c on f.cont=c.cont
	where f.data between @datajos and @datasus
	group by f.cont
	order by f.cont
	
	-- indirectele astfel calculate au sume dublate, daca exista decontare intre sectii 
	-- (comenzi auxiliare la una din sectii decontate pe alta sectie, purt�nd regie de sectie) 
	-- solutia este: aceste comenzi sa nu primeasca regie de sectie (eventual doar de la locuri de munca cu activitate de baza)
	-- se va face o procedura "calcul2" (sau mai mare) pentru a rezolva problema specifica 
	update #temp set ch_indirecte=regiilm.suma
	from 
	(select fc.cont,SUM(fc.suma) as suma
		from FisaPeCont fc where fc.data between @datajos and @datasus and tip='D' and 
			lm in (select distinct lm_inf from costsql where data between @datajos and @datasus and art_sup='L') and Comanda=''
			group by fc.cont) regiilm
		where regiilm.cont=#temp.cont

	-- aceste sume sunt corecte
	update #temp set ch_generale=regii.suma
	from 
	(select fc.Cont,SUM(fc.suma) as suma from FisaPeCont fc 
		where fc.data between @datajos and @datasus and tip='D' and lm='' and comanda=''
		group by fc.cont) regii
		where regii.cont=#temp.cont
	
	-- calcul directe prin diferente: sumele sunt afectate de "imprecizia" indirectelor de locm
	update #temp set ch_directe=total-ch_generale-ch_indirecte

	select * from #temp
end
