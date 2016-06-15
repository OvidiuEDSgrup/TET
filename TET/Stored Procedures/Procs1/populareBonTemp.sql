-- creaza tabela #bonTemp cu structura corecta
create procedure populareBonTemp @sesiune varchar(50), @parXML xml output
as

declare @msgEroare varchar(500), @idAntetBon int, @tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @utilizator varchar(50), 
		@numarDoc int, @tipDoc varchar(2), @GESTPV varchar(20), @oraDoc varchar(6), @comandaASiS varchar(50), @codiinden int, @xmlPoz xml
set nocount on

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	-- la validare si la salvare se trimite diferit documentul, uneori cu root 'Date' inainte de document
	if left(convert(varchar(max), @parXML),5)='<Date'
		set @xmlPoz=@parxml.query('/date/*')
	else
		set @xmlPoz=@parXML
	
	select	@CasaDoc = @xmlPoz.value('(/document/@casamarcat)[1]','int'),
			@numarDoc = @xmlPoz.value('(/document/@numarDoc)[1]','int'),
			@tipDoc = @xmlPoz.value('(/document/@tipdoc)[1]','varchar(2)'),
			@DataDoc = @xmlPoz.value('(/document/@data)[1]','datetime'),
			@oraDoc = @xmlPoz.value('(/document/@ora)[1]','varchar(6)'),
			@tert = isnull(upper(@xmlPoz.value('(/document/@tert)[1]','varchar(50)')),''),
			@vanzDoc = upper(@xmlPoz.value('(/document/@vanzator)[1]','varchar(50)')),
			@vanzDoc = isnull(@vanzDoc, @utilizator),
			@GESTPV = upper(@xmlPoz.value('(/document/@GESTPV)[1]','varchar(50)')),
			@GESTPV = ISNULL(@GESTPV, dbo.wfProprietateUtilizator('GESTPV',@utilizator))
			
	set @codiinden=isnull((select top 1 val_logica from par where tip_parametru='PV' and parametru='CODIINDEN'),0)
	
	insert #bonTemp(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,  
		Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,  
		Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,  
		Loc_de_munca,Discount, lm_real, Comanda_asis,[Contract], o_pretcatalog, idPozContract,idCt, detalii)
	select 
		@CasaDoc, 
		(case when @tipDoc='AC' then 1 else 0 end) as factura_chitanta, 
		@numarDoc, 
		nrlinie as linie,
		@DataDoc as data, 
		isnull(@oraDoc,'') as ora, 
		(case when @tipDoc='TE' and b.tip='21' then '11' else b.tip end) as tip, 
		@vanzDoc as vinzator, 
		@tert as client, 
		isnull(b.barcode,'') as cod_tastatura, 
		isnull(b.cod,'') as cod_plu, 
		isnull(b.cod,'') as cod_produs, 
		'0'/*valabilitate - am lasat implicit 0 pt. linii tip incasare. La produse se face update mai jos */ as categorie, 
		ISNULL(b.um,1) as um, 
		cantitate, 
		isnull(b.cotatva,0) as cota_tva, 
		isnull(b.tva,0) as tva,
		isnull(b.pretcatalog,b.pret) as pret,
		b.valoare as total,
		0 as retur, 1 as inregistrare_valida, '' as operat, 
		(case when b.tip='21' and @codiinden=1 and charindex('|',b.denumire)>1 then left(b.denumire,charindex('|',b.denumire)-1) else isnull(iddocumentincasare,'') end) as nr_doc_incas, 
		'01/01/1901' as data_doc, 
		(case when isnull(gestiune,'')<>'' then gestiune else @GESTPV end) as gestiune,
		isnull(b.discount,0) as discount, 
		nullif(b.lm,'') as lm_real, 
		b.comanda_asis as Comanda_asis, 
		b.[contract] as [contract],
		o_pretcatalog as o_pretcatalog,
		idPozContract,
		idCt,
		detalii
	from (select   
		xA.row.value('@nrlinie', 'int') as nrlinie,
		xA.row.value('@tip', 'varchar(2)') as tip,
		xA.row.value('@cod', 'varchar(20)') as cod,
		xA.row.value('@barcode', 'varchar(50)') as barcode,
		xA.row.value('@codUM', 'varchar(50)') as um,
		xA.row.value('@cantitate', 'decimal(10,3)') as cantitate,
		xA.row.value('@pret','decimal(10,3)') as pret,
		xA.row.value('@pretcatalog','decimal(10,3)') as pretcatalog,
		xA.row.value('@cotatva', 'decimal(5,2)') as cotatva,
		xA.row.value('@valoare', 'decimal(10,2)') as valoare,
		xA.row.value('@tva', 'decimal(10,2)') as tva,
		xA.row.value('@discount', 'decimal(10,2)') as discount,
		xA.row.value('@denumire', 'varchar(120)') as denumire,		
		xA.row.value('@iddocumentincasare', 'varchar(20)') as iddocumentincasare,
		xA.row.value('@gestiune', 'varchar(20)') as gestiune, -- se trimite pentru comenzi/devize. Daca sunt probleme, sa nu se trimita de acolo!
		xA.row.value('@lm', 'varchar(20)') as lm,
		xA.row.value('@comanda_asis', 'varchar(20)') as comanda_asis,
		xA.row.value('@contract', 'varchar(20)') as [contract],
		xA.row.value('@o_pretcatalog','decimal(10,3)') as o_pretcatalog,
		xA.row.value('@idPozContract','int') as idPozContract,
		xA.row.value('@idCt','int') as idCt,
		xA.row.query('.') as detalii
	from @xmlPoz.nodes('document/pozitii/row') as xA(row)
		) as b 

update b
	set detalii.modify('delete (/row[1]/@*[local-name()=("denumire", "cod", "nrlinie", "tip", "barcode", "codUM", "cantitate", "pret", "pretcatalog", 
		"cotatva", "valoare", "tva", "discount", "iddocumentincasare", "gestiune", "lm", "comanda", "contract", "um", "poza", "nr",
		"trebuieCantarit", "touch", "tipLinie", "valoarefaradiscount", "pretftva", "valftva", "observatii", "durataInput", "clipboardIsSimilar", "idCt", "idComandaHrc")])')
from #bonTemp b

update b
	set detalii.modify('delete (/row[1]/@*[substring(local-name(),1,2) ="o_"])')
from #bonTemp b

update b
	set detalii=null
from #bonTemp b
where b.detalii.value('count(/row/@*)', 'INT')=0

-- stergem din antet datele legate de pozitii
set @parXml.modify('delete //document/pozitii')

	
end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+' (populareBonTemp)'
	raiserror(@msgeroare,11,1)
end catch
