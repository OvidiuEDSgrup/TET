select * 
from bt b inner join 
	(select
			a.Casa_de_marcat, a.Chitanta,a.Numar_bon,a.Data_bon data,a.Vinzator,a.Tert,a.Gestiune gestantet,'' as ora,
			isnull(xA.row.value('../@tipdoc', 'varchar(20)'),'') as tipdoc,
			xA.row.value('@nrlinie', 'int') as nrlinie,
			xA.row.value('@tip', 'varchar(2)') as tip,
			xA.row.value('@cod', 'varchar(20)') as cod,
			xA.row.value('@barcode', 'varchar(50)') as barcode,
			xA.row.value('@codUM', 'varchar(50)') as um,
			xA.row.value('@cantitate', 'decimal(10,3)') as cantitate,
			xA.row.value('@pret','decimal(10,3)') as pret,
			xA.row.value('@pretcatalog','decimal(10,3)') as pretcatalog,
			xA.row.value('@cotatva', 'decimal(5,2)') as cotatva,
			xA.row.value('@valoare',' decimal(10,2)') as valoare,
			xA.row.value('@tva',' decimal(10,2)') as tva,
			xA.row.value('@discount',' decimal(10,2)') as discount,
			xA.row.value('@denumire',' varchar(120)') as denumire,
			xA.row.value('@iddocumentincasare',' varchar(20)') as iddocumentincasare,
			xA.row.value('@gestiune',' varchar(20)') as gestiune, -- se trimite pentru comenzi/devize
			xA.row.value('@lm',' varchar(20)') as lm,
			xA.row.value('@comanda_asis',' varchar(20)') as comanda_asis,
			xA.row.value('@contract',' varchar(20)') as [contract]
			from antetbonuri a
			cross apply	bon.nodes('date/document/pozitii/row') as xA(row)
			where bon is not null and a.UID='96DC6297-3DFB-EA11-13FC-2FF06BBF41FF'
			) as ab 
	on ab.Data=b.Data and ab.Casa_de_marcat=b.Casa_de_marcat and ab.Vinzator=b.Vinzator and ab.Numar_bon=b.Numar_bon 
		and ab.nrlinie=b.Numar_linie
where ab.gestiune<>b.Loc_de_munca and isnull(ab.Comanda_asis,'')=isnull(b.Comanda_asis,'') 
		and ISNULL(ab.[Contract],'')=ISNULL(b.[Contract],'')	
--where a.UID='96DC6297-3DFB-EA11-13FC-2FF06BBF41FF'
--bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)')