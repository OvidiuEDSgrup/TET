--***
/* extrage filtrele din XML, returnand un tabel cu nume filtru si valoare */
create function wfIaFiltreDinXml (@parXML xml)
returns table
as
return 
	select distinct 
			xA.row.value('../@numeElement', 'varchar(50)') as element,
			xA.row.value('@data', 'varchar(200)') as valoare
	from @parXML.nodes('row/filtre/*/row') as xA(row)
