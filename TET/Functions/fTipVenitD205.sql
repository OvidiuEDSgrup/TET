-- functie ce returneaza denumirea tipurilor de venituri cuprinse in D112.
create function fTipVenitD205()
returns @tipvenit table 
	(tip_venit varchar(20), denumire varchar(1000))
begin
	insert into @tipvenit
	select '01', 'Venituri din drepturi de proprietate intelectuala' union all
	select '02', 'Venituri din activitati desfasurate in baza contractelor/ conventiilor civile incheiate potrivit Codului civil, precum si a contractelor de agent' union all
	select '03', 'Venituri din activitatea de expertiza contabila si tehnica, judiciara si extrajudiciara' union all
	select '04', 'Venituri din activitati independente realizate intr-o forma de asociere cu o persoana juridica, microintreprindere' union all
	select '05', 'Venituri sub forma castigurilor din operatiuni de vanzare cumparare de valuta la termen, pe baza de contract, precum si  orice alte operatiuni similare' union all
	select '17', 'Venituri obtinute din valorificarea bunurilor mobile sub forma deseurilor din patrimoniul afacerii, potrivit art. 78 alin. (1) lit f. din Codul fiscal' union all	
	select '06', 'Castiguri din transferul titlurilor de valoare, altele decat partile sociale si valorile mobiliare in cazul societatilor inchise' union all
	select '07', 'Venituri din salarii' union all
	select '08', 'Venituri din dividende' union all
	select '09', 'Venituri din dobanzi' union all
	select '10', 'Castiguri din transferul valorilor mobiliare, in cazul societatilor inchise, si a partilor sociale' union all
	select '11', 'Venituri din lichidarea persoanei juridice' union all
	select '12', 'Venituri din premii' union all
	select '13', 'Venituri din pensii' union all
	select '14', 'Venituri din activitati agricole' union all
	select '15', 'Venituri din arendare' union all
	select '16', 'Venituri din alte surse'

	return
end
