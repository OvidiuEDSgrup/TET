if OBJECT_ID('tempdb..#bonTemp') is not null drop table #bonTemp
	CREATE TABLE #bonTemp(Casa_de_marcat smallint NOT NULL,Factura_chitanta bit, Numar_bon int,Numar_linie smallint NOT NULL,Data datetime NOT NULL, Ora char(6) NOT NULL,Tip char(2) NOT NULL,Vinzator char(10) NOT NULL,Client char(13) NOT NULL,Cod_citit_de_la_tastatura char(20) NOT NULL,CodPLU char(20) NOT NULL,Cod_produs char(20) NOT NULL,Categorie smallint NULL,UM smallint NOT NULL,Cantitate float NOT NULL,Cota_TVA real NOT NULL,Tva float NOT NULL,Pret float NOT NULL,Total float NOT NULL,Retur bit NOT NULL,Inregistrare_valida bit NOT NULL,Operat bit NOT NULL,Numar_document_incasare char(20) NOT NULL,Data_documentului datetime NOT NULL,Loc_de_munca char(9) NOT NULL,Discount float NOT NULL, lm_real varchar(9) null, Comanda_asis varchar(20) null, [Contract] varchar(20) null constraint PK_numar_linie primary key(Data, Casa_de_marcat, Vinzator, Numar_bon, numar_linie))
		
	insert #bonTemp(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client, Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret, Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului
	, Loc_de_munca,Discount, lm_real, Comanda_asis,[Contract])
	select b.Casa_de_marcat , b.Chitanta as factura_chitanta, b.Numar_bon, 
			isnull(nrlinie,ROW_NUMBER() over (partition by b.data, b.casa_de_marcat, b.numar_bon, b.vinzator order by b.tip)) as linie,
			b.data as data, b.ora as ora, 
			(case when b.tipdoc='TE' and b.tip='21' then '11' else b.tip end) as tip, 
			b.Vinzator as vinzator, b.Tert as client, 
			isnull(isnull(b.barcode,b.cod),'') as cod_tastatura, isnull(b.cod,'') as cod_plu, isnull(b.cod,'') as cod_produs, 
			'0' as categorie, ISNULL(b.um,1) as um, cantitate, isnull(b.cotatva,0) as cota_tva, isnull(b.tva,0) as tva,isnull(b.pretcatalog,b.pret) as pret,
			b.valoare as total, 0 as retur, 1 as inregistrare_valida, '' as operat, 
			(case when b.tip='21' and /*@codiinden*/0=1 and charindex('|',b.denumire)>1 then left(b.denumire,charindex('|',b.denumire)-1) else isnull(iddocumentincasare,'') end) as nr_doc_incas, 
			'01/01/1901' as data_doc, isnull(b.gestiune,b.gestantet) as gestiune, isnull(b.discount,0) as discount, b.lm as lm_real, b.comanda_asis as Comanda_asis, b.[contract] as [contract]
		from (select
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
			where bon is not null
			) as b 
--/*sp
	select btmp.Comanda_asis,btmp.Loc_de_munca,bp.Loc_de_munca,* 
--sp*/update bp set Loc_de_munca=btmp.Loc_de_munca
	from #bonTemp btmp inner join bonuri bp 
		on btmp.Data=bp.Data and btmp.Casa_de_marcat=bp.Casa_de_marcat and btmp.Vinzator=bp.Vinzator and btmp.Numar_bon=bp.Numar_bon 
			and btmp.Numar_linie=bp.Numar_linie
	where btmp.Loc_de_munca<>bp.Loc_de_munca and isnull(btmp.Comanda_asis,'')=isnull(bp.Comanda_asis,'') 
		and ISNULL(btmp.[Contract],'')=ISNULL(bp.[Contract],'')
	--select Loc_de_munca,* from #bonTemp
	drop table #bonTemp
	
go
--/*
select ab.gestiune as gestpozbonxml,b.Loc_de_munca,ab.comanda_asis comanda_asis_xml,b.Comanda_asis,ab.[contract] as contract_xml,b.[Contract],* 
from bonuri b inner join 
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
			where bon is not null --and a.UID='96DC6297-3DFB-EA11-13FC-2FF06BBF41FF'
			) as ab 
	on ab.Data=b.Data and ab.Casa_de_marcat=b.Casa_de_marcat and ab.Vinzator=b.Vinzator and ab.Numar_bon=b.Numar_bon 
		and ab.nrlinie=b.Numar_linie
where ab.gestiune<>b.Loc_de_munca and isnull(ab.Comanda_asis,'')=isnull(b.Comanda_asis,'') 
		and ISNULL(ab.[Contract],'')=ISNULL(b.[Contract],'')	
--*/