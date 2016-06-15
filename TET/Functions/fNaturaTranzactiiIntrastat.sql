--***
Create function fNaturaTranzactiiIntrastat (@parXML xml)
returns @naturatranz table
	(cod varchar(20), denumire varchar(300))
as
begin
	declare @tip varchar(10), @nattranza varchar(10)

	set @tip = ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(10)'), 'A')
	set @nattranza = ISNULL(@parXML.value('(/row/@nattranza)[1]', 'varchar(10)'), '1')

	if @tip='A'
		insert @naturatranz
		select '1' as cod, '1. Schimburi de bunuri care implica transferul efectiv sau intentionat al dreptului de proprietate contra unei compensatii' as denumire
		union all 
		select '2' as cod, '2. Returnari si inlocuiri de bunuri in mod gratuit dupa inregistrarea operatiunii initiale' as denumire
		union all 
		select '3' as cod, '3. Schimburi de bunuri care implica transferul de proprietate fara compensatii financiare sau de alta natura' as denumire
		union all 
		select '4' as cod, '4. Schimburi de bunuri in scopul prelucrarii pe baza de contract (fara transferul dreptului de proprietate)' as denumire
		union all 
		select '5' as cod, '5. Schimburi de bunuri dupa prelucrare pe baza de contract (fara transferul dreptului de proprietate)' as denumire
		union all 
		select '6' as cod, '6. Tranzactii particulare inregistrate pentru scopuri nationale' as denumire
		union all 
		select '7' as cod, '7. Schimburi de bunuri in cadrul unor proiecte comune de aparare sau alte programe comune interguvernamentale' as denumire
		union all 
		select '8' as cod, '8. Furnizarea de materiale de constructie si echipament tehnic in cadrul unui contract general \- o singura factura emisa' as denumire
		union all 
		select '9' as cod, '9. Alte schimburi de bunuri' as denumire
		order by 1

	if @tip='B'
	begin
		if @nattranza=1
			insert into @naturatranz
			select '1' as cod, '1. Cumparare / vanzare definitiva' as denumire
			union all 
			select '2' as cod, '2. Livrare pentru vanzare la vedere sau cu testare\, pentru consignatie sau prin intermediul unui agent comisionar' as denumire
			union all 
			select '3' as cod, '3. Comert barter (compensatie in natura)' as denumire
			union all 
			select '4' as cod, '4. Leasing financiar (inchiriere-achizitie)' as denumire
			union all
			select '9' as cod, '9. Altele' as denumire

		if @nattranza=2
			insert into @naturatranz
			select '1' as cod, '1. Returnari de bunuri' as denumire
			union all 
			select '2' as cod, '2. Inlocuiri de bunuri returnate' as denumire
			union all 
			select '3' as cod, '3. Inlocuiri (de exemplu\, sub garantie) a bunurilor care nu au fost returnate' as denumire
			union all
			select '9' as cod, '9. Altele' as denumire

		if @nattranza=4
			insert into @naturatranz
			select '1' as cod, '1. Bunuri destinate reintroducerii in statul membru de unde au fost expediate initial' as denumire
			union all 
			select '2' as cod, '2. Bunuri care nu sunt destinate reintroducerii in statul membru de unde au fost expediate initial' as denumire
	
		if @nattranza=5
			insert into @naturatranz
			select '1' as cod, '1. Bunuri reintroduse in statul membru de unde au fost expediate initial' as denumire
			union all 
			select '2' as cod, '2. Bunuri care nu sunt reintroduse in statul membru de unde au fost expediate initial' as denumire
	
		if @nattranza=9
			insert into @naturatranz
			select '1' as cod, '1. Inchirieri\, imprumuturi\, leasing operational cu durata de peste 24 de luni' as denumire
			union all 
			select '9' as cod, '9. Altele' as denumire
	end
	return 
end
