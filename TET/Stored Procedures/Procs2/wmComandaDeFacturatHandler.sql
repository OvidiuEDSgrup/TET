--***  
/* Trateaza alegerile din wmFacturareComenzi. */
CREATE procedure [dbo].[wmComandaDeFacturatHandler] @sesiune varchar(50), @parXML xml as  
if exists(select * from sysobjects where name='wmComandaDeFacturatHandlerSP' and type='P')
begin
	exec wmComandaDeFacturatHandlerSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @xmlFinal xml, @linieXML xml, @stareBkFacturabil varchar(20),
		@facturaDeIncasat varchar(100), @cod varchar(100), @idpunctlivrare varchar(100), @comanda varchar(100), @eroare varchar(4000), @data datetime, 
		@backCount smallint, @actiune varchar(30)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null
	return -1

select	@comanda=@parXML.value('(/row/@wmIaComenziDeFacturat.cod)[1]','varchar(100)'),
		@cod=@parXML.value('(/row/@wmComandaDeFacturat.cod)[1]','varchar(100)'),
		@actiune='back(1)'

-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f
		
-- citire date din par
select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @subunitate end),
		@stareBkFacturabil=(case when Parametru='STBKFACT' then rtrim(Val_alfanumerica) else @stareBkFacturabil end)
from par
where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru = 'STBKFACT')

if @cod='<FacturareComanda>' -- facturare comanda
begin
	begin try
		declare @xml xml, @NrDocFisc varchar(10), @stare varchar(20), @gestiune varchar(20), @lm varchar(20), @numedelegat varchar(80),
				@codFormular varchar(100)
		-- iau numar document
		set @xml= (select 'O' tipmacheta, 'AP' tip, @utilizator utilizator for xml raw)
		exec wIauNrDocFiscale @parxml=@xml, @numar=@NrDocFisc output
		
		-- citesc date din antet
		select @stare=c.Stare, @gestiune=rtrim(c.Gestiune), @data=c.Data, @lm=rtrim(c.Loc_de_munca)
		from con c  
		where c.subunitate=@subunitate and c.Tip='BK' and c.Contract=@comanda and c.Responsabil=@utilizator and c.Stare=@stareBkFacturabil and c.tert=@tert 
			and c.Punct_livrare=@idpunctlivrare 
		
		-- nume delegat=nume user logat
		select @numedelegat=rtrim(u.Nume) from utilizatori u where u.ID=@utilizator
		-- setare cod formular din proprietati, sau un cod implicit 
		-- in viitor am putea da raiserror daca nu e configurat, sau sa alegem un formular din antform
		select @codFormular= isnull(rtrim(dbo.wfProprietateUtilizator('FormAP', @utilizator)),'')
		if @codFormular=''
			set @codFormular='FACTURA'
		
		-- generare AP
		set @xml = (select @stare stare, @comanda numar, @tert tert, convert(varchar,@data,101) data, @gestiune gestiune, 
						@NrDocFisc numardoc, CONVERT(varchar,GETDATE(),101) datadoc, @lm lm, 
						@numedelegat numedelegat, '<NrMijlocTransp. - de facut>' nrmijltransp,
						'Factura generata din ASiSmobil' observatii, 1 faramesaje
					for xml raw('parametri'))
		exec wOPGenTEsauAPdinBK @sesiune=@sesiune, @parXML=@xml
		
		-- tiparire formular
		set @xml = (select @codFormular nrform, 'AP' tip, @NrDocFisc numar, convert(varchar,GETDATE(),101) data, @tert tert, @gestiune gestiune, '0' debug
					for xml raw)
			exec wTipFormular @sesiune=@sesiune, @parXML=@xml
	end try
	begin catch
		set @eroare=ERROR_MESSAGE() 
		raiserror(@eroare, 16, 1) 
	end catch	
	
	-- nu mai trimit mesaj, trimite wTipFormular
	--select 'Facturare comanda '+@comanda as titlu, 'wmComandaDeFacturatHandler' as detalii,0 as areSearch, 'back(1)' actiune
	--for xml raw,Root('Mesaje')   

	return 0
end
if @cod='<CodNou>' -- adauga cod pe comanda
begin
	declare @codProdus varchar(100)
	select	@codProdus=@parXML.value('(/row/@wmComandaDeFacturatHandler.cod)[1]','varchar(20)'), -- aici se insereaza cod prin wmNomenclator
			@actiune='back(2)'
	
	-- verific daca nu s-a scanat un cod de bare in zona 'searchText' se va adauga in comanda curenta 
	-- -> cred ca va cauza probleme cand cauta manual un produs
	declare @codcitit varchar(100), @codScanat varchar(100)
	select	@codcitit=rtrim(@parXML.value('(/row/@searchText)[1]','varchar(100)')),
			@codcitit=REPLACE(@codcitit,'CipherLab','')

	if len(isnull(@codcitit,''))>0
	begin
		--il cautam in tabela de coduri de bare  
		select @codScanat=rtrim(cb.Cod_produs) from codbare cb where cb.Cod_de_bare=@codcitit
		--il cautam si in nomenclator -> dezactivat pt. ca adauga produse ala'ndala
		--if @codScanat is null  
		--	select @codScanat=cod from nomencl where cod=@codcitit
		   
		if @codScanat is not null --inseamna ca l-am gasit  
		begin  
			if @parXML.value('(/row/@codExact)[1]', 'varchar(20)') is not null                    
				set @parXML.modify('replace value of (/row/@codExact)[1] with sql:variable("@codScanat")')                       
			else             
				set @parXML.modify ('insert attribute codExact{sql:variable("@codScanat")} into (/row)[1]')
			if @parXML.value('(/row/@searchText)[1]', 'varchar(200)') is not null                  
				set @parXML.modify ('delete (/row/@searchText)[1]') 
		end
	end  

	if @codProdus is null -- e null daca inca nu s-a  ales un cod cu proc. wmNomenclator
	begin
		-- din comanda de facturat nu mai sugerez discountul tertului - de discutat...
		
		-- adaug linie noua in pe comanda
		if @parXML.value('(/row/@faradetalii)[1]', 'varchar(200)') is not null                  
			set @parXML.modify('replace value of (/row/@faradetalii)[1] with "1"')
		else
			set @parXML.modify ('insert attribute faradetalii{"1"} into (/row)[1]') 
		exec wmNomenclator @sesiune,@parXML
		
		select 'wmComandaDeFacturatHandler' as detalii,1 as areSearch, 'Comanda:'+@comanda as titlu , 
			'D' as tipdetalii, (case when @codScanat is not null then 'autoSelect' else null end) as actiune,
			(case when @codScanat is not null then 1 else null end) as clearSearch,
			(select datafield as '@datafield',nume as '@nume',tipobiect as '@tipobiect',latime as '@latime',modificabil as '@modificabil'  
			from webConfigForm where tipmacheta='M' and meniu='MD' and vizibil=1   
			order by ordine  
			for xml path('row'), type) as 'form'  
		for xml raw,Root('Mesaje')  

		return
	end
	else
	begin
		-- daca este @codProdus, a s-a ales cod nou folosind wmNomenclator
		select	@cod=@codProdus
		
		if @parXML.value('(/row/@wmComandaDeFacturatHandler.cod)[1]', 'varchar(200)') is not null                  
			set @parXML.modify ('delete (/row/@wmComandaTertDeschisaHandler.cod)[1]') 
		if @parXML.value('(/row/@wmComandaDeFacturat.cod)[1]', 'varchar(200)') is not null                  
			set @parXML.modify('replace value of (/row/@wmComandaDeFacturat.cod)[1] with sql:variable("@cod")')
		else           
			set @parXML.modify ('insert attribute wmComandaDeFacturat.cod {sql:variable("@cod")} into (/row)[1]') 
	end
		
	
end

declare @cantitate decimal(12,3),@pret decimal(12,3), @discount decimal(12,2), @input XML
-- citesc date din antet comanda
select @gestiune = c.Gestiune, @data=c.Data from con c where c.Subunitate=@subunitate and c.Tip='BK' and c.Contract=@comanda and Punct_livrare=@idPunctLivrare

select	@cantitate=@parXML.value('(/row/@cantitate)[1]','decimal(12,3)'),
		@pret=@parXML.value('(/row/@pret)[1]','decimal(12,3)'),
		@discount=@parXML.value('(/row/@discount)[1]','decimal(12,2)')
		
if not exists ( select 1 from pozcon pc where pc.Subunitate=@subunitate and pc.Tip='BK' and pc.Contract=@comanda and pc.tert=@tert and pc.Cod=@cod )
begin -- daca nu exista, adaug linie noua
	-- schimb stare pentru ca wScriuPozCon nu scrie linii noi decat pentru stare 0
	update con set stare='0' 
	from con c
	where c.subunitate=@subunitate and c.Tip='BK' and c.Contract=@comanda and c.tert=@tert and c.Punct_livrare=@idpunctlivrare 
	
	begin try -- folosesc try catch pt. ca sa ma asigur ca se schimba starea inapoi in 1
		set @eroare = null
		set @input=(select @subunitate as '@subunitate','BK' as '@tip',rtrim(@comanda) as '@numar',rtrim(@gestiune) as '@gestiune',
						rtrim(@tert) as '@tert', convert(char(10),@data,101) as '@data', @idpunctlivrare as '@punctlivrare',
						(select @cod as '@cod',convert(char(10),convert(decimal(12,3),isnull(@cantitate,1))) as '@cantitate',isnull(@discount,0) as '@discount' for xml Path,type)
					for xml Path,type)
		exec wScriuPozCon @sesiune,@input
	end try 
	begin catch
		set @eroare='(wmComandaDeFacturatHandler)'+ERROR_MESSAGE() 
	end catch	
	
	update con set stare=@stareBkFacturabil
	from con c
	where c.subunitate=@subunitate and c.Tip='BK' and c.Contract=@comanda and c.tert=@tert and c.Punct_livrare=@idpunctlivrare 
	
	if @eroare is not null
		raiserror(@eroare, 16, 1) 
end
else
begin
	if @cantitate=0
		delete from pozcon
		where Subunitate=@subunitate and tip='BK' and tert=@tert and contract=@comanda and cod=@cod
	update pozcon set Cant_aprobata=(case when @cantitate is null then Cant_aprobata else @cantitate end),
		pret=(case when @pret is null then pret else @pret end), discount=(case when @discount is null then discount else @discount end)
	where Subunitate=@subunitate and tip='BK' and tert=@tert and contract=@comanda and cod=@cod
end


select 'Facturare comanda '+@comanda as titlu, 'wmComandaDeFacturatHandler' as detalii,0 as areSearch, @actiune actiune
for xml raw,Root('Mesaje')   

--select * from tmp_facturi_de_listat
