--***       
if exists (select 1 from sysobjects where name='yso_wOPPlataStornare')
drop procedure yso_wOPPlataStornare
go 
create procedure [dbo].[yso_wOPPlataStornare](@sesiune varchar(50), @parXML xml) as             
begin try           
	set transaction isolation level read uncommitted
	--begin tran yso_wOPPlataStornare
	declare @tert varchar(20), @factura varchar(20), @valtotala float, @datafacturii datetime,         
		@valuta varchar(3), @curs float, @valoarevaluta float, @sumavaluta float,         
		@contcasa varchar(13), @sumalei float, @numar varchar(20), @data datetime, @contfactura varchar(13),         
		@lm varchar(9), @comanda varchar(20), @userASIS varchar(20), @nrpoz int, @suma float, @chitanta varchar(20), 
		@formular varchar(13),@generare int, @subunitate varchar(9), @tip varchar(2)
	-- 
	set @tip=isnull(@parXML.value('(/*/@tip)[1]','varchar(2)')      ,'')  
	set @tert=isnull(@parXML.value('(/*/@tert)[1]','varchar(20)')      ,'')    
	set @numar=isnull(@parXML.value('(/*/@numar)[1]','varchar(20)'),'')
	set @data=isnull(@parXML.value('(/*/@data)[1]','datetime'),'')
	set @factura=isnull(@parXML.value('(/*/@factura)[1]','varchar(20)')        ,'')    
	set @valtotala=isnull(@parXML.value('(parametri/@valtotala)[1]','decimal(10,2)')       ,'')     
	set @datafacturii=isnull(@parXML.value('(/*/@data)[1]','datetime')  ,'')          
	set @valuta=isnull(@parXML.value('(parametri/@valuta)[1]','varchar(3)')        ,'')    
	set @curs=isnull(@parXML.value('(parametri/@curs)[1]','decimal(12,4)')        ,'')    
	set @valoarevaluta=isnull(@parXML.value('(parametri/@valoarevaluta)[1]','decimal(12,4)'),'')    
	set @contfactura=isnull(@parXML.value('(/*/@contfactura)[1]','varchar(13)'),'')        
	set @lm=isnull(@parXML.value('(/*/@lm)[1]','varchar(9)'),'')         
	set @comanda=isnull(@parXML.value('(/*/@comanda)[1]','varchar(20)'),'')
	set @chitanta=isnull(@parXML.value('(/*/@chitanta)[1]','varchar(20)'),'')        
	set @generare=ISNULL(@parXML.value('(/*/@generare)[1]', 'int'), '')
	set @formular=ISNULL(nullif(@parXML.value('(/*/@formular)[1]', 'varchar(13)'),''), '')
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
 	--        
	exec luare_date_par 'GE', 'SUBPRO', 0,0,@subunitate output 
 
	set @contcasa=isnull(@parXML.value('(/*/@contcasa)[1]','varchar(13)'),'')        
	
	if @contcasa=''
		select top 1 @contcasa=RTRIM(valoare) from proprietati where Tip='UTILIZATOR' and Cod_proprietate='CONTCASA' and Cod=@userASiS
BEGIN--/*SP
	declare @eXml bit, @nrformular varchar(10)
	select @eXml=(select top 1 f.eXML from antform f where f.Numar_formular=@formular)
		,@nrformular=upper(ISNULL(@parXML.value('(/*/@nrformular)[1]', 'varchar(10)'), ''))
		
	if @contcasa=''
		select top 1 @contcasa=RTRIM(valoare) from proprietati where Tip='UTILIZATOR' and Cod_proprietate='CONTPLIN' and Cod=@userASiS
END--SP*/
	
	if @contcasa=''
		select top 1 @contcasa=RTRIM(val_alfanumerica) from par	where Tip_parametru='GE' and Parametru='CCASA'
	if @contcasa=''        
		raiserror('Introduceti contul de casa! Nu s-a inregistrat incasarea!',16,1)        

	set @nrpoz=ISNULL((select MAX(numar_pozitie) from pozplin where subunitate=@subunitate and cont=@contcasa and data=@datafacturii),0)        
	set @nrpoz=@nrpoz+1        

	if @valuta<>''
		set @suma=-@valoarevaluta
	else
		set @suma=-@valtotala
		
	if isnull(@suma,0)=0
		select @suma=-SUM(cantitate*Pret_vanzare+TVA_deductibil)
			from PozDoc where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@data
	    
/*SP Luare numar din plaja 
BEGIN
		declare @nrPozXml int
		set @nrPozXml=isnull(@nrPozXml,0)+1
		
		if ISNULL(@chitanta, '')=''
		begin	
			declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20), @NumarDocPrimit int
			set @tipPentruNr='RE'
			set @LM = (case when @LM is null then '' else @LM end)
			set @fXML = '<row/>'
			set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
			set @fXML.modify ('insert attribute meniu {"PI"} into (/row)[1]')
			set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
			set @fXML.modify ('insert attribute subtip {"IB"} into (/row)[1]')
			set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
			set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')

			exec wIauNrDocFiscale @parXML=@fXML,@Numar=@NumarDocPrimit output, @NrDoc=@NrDocPrimit output

			if isnull(@NumarDocPrimit,0)=0
				raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			set @chitanta=@NrDocPrimit
			
			if @parXML.value('(/row/row[sql:variable("@nrPozXml")]/@numar)[1]','varchar(10)') is null 
				set @parXML.modify ('insert attribute numar {sql:variable("@numar")} into (/row/row[sql:variable("@nrPozXml")])[1]')
			else
				set @parXML.modify('replace value of (/row/row[sql:variable("@nrPozXml")]/@numar)[1] with sql:variable("@numar")')
		end
END--SP*/
	          
	--set @chitanta=(case when @numar<>@factura then @chitanta else @numar end)
	set @chitanta=(case when @chitanta='' then @numar else @chitanta end)

	--Date introduse gresit
	if @chitanta=''
		raiserror ('Introduceti numarul de chitanta pentru acele cazuri in care numarul difera de factura!Nu s-a inregistrat incasarea!',16,1)        
	else 
	--else if @numar=''         
		--raiserror('Introduceti numarul de chitanta! Nu s-a inregistrat incasarea!',16,1)        
	if not exists (select 1 from conturi where cont=@contcasa and Are_analitice=0)
		raiserror('Contul introdus nu se afla in planul de conturi/sau are analitice!Nu s-a inregistrat incasarea!',16,1)
	 --else if @suma<>0   
		-- raiserror('Platiti fie in lei fie in valuta! Nu s-a inregistrat incasarea!',16,1)        
	else if @suma=0   
		raiserror('Introduceti o valoare pentru incasare! Nu s-a inregistrat incasarea!',16,1)         
	--Factura in lei, suma in lei=0 sau factura in valuta, suma in valuta=0        
	else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma=0        
		raiserror('Factura e in lei, deci introduceti doar suma in lei! Nu s-a inregistrat incasarea!',16,1)        
	else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma=0        
		raiserror('Factura e in valuta, deci introduceti doar suma in valuta! Nu s-a inregistrat incasarea!',16,1)        
	--Cont lei sau valuta        
	else if substring(@contcasa,1,4) not in ('5314','5125')  and @curs<>0 and @valuta<>'' and @valoarevaluta<>0         
		raiserror('Factura e in valuta, deci contul de casa trebuie sa fie 5314 / 5125 sau analitice ale lui! Nu s-a inregistrat incasarea!',16,1)        
	else if substring(@contcasa,1,4)not in ('5311','5125') and @curs=0 and @valuta='' and @valoarevaluta=0 and @valtotala<>0        
		raiserror('Factura e in lei, deci contul de casa trebuie sa fie 5311 / 5125 sau analitice ale lui! Nu s-a inregistrat incasarea!',16,1)        
	--Factura in lei sau valuta, incasare peste valoarea facturii        
	--else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma<>0 and @valtotala<@suma        
	--	raiserror('Nu puteti plati mai mult decat valoarea facturii! Nu s-a inregistrat incasarea!',16,1)        
	else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma<>0 and @valoarevaluta<@suma        
		raiserror('Nu puteti plati, in valuta, mai mult decat valoarea facturii! Nu s-a inregistrat incasarea!',16,1)          
	--Mai exista o incasare pe aceasta factura        
	else if exists (select * from pozplin where subunitate=@subunitate and data=@datafacturii and Plata_incasare='PS' and tert=@tert and Factura=@factura and Suma<>0)        
		raiserror('S-a platit deja aceasta factura! Nu mai puteti sa o platiti decat la Plati/Incasari! Nu s-a inregistrat incasarea!',16,1)          
	--Inregistrare incasare     
	else 
	if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma<>0        
	begin
		declare 
			@docRE xml

		set @docRE=
			(SELECT
				@contcasa cont, convert(varchar(10), @data,101) data,'RE' tip, 
				(select
					'AP'+@numar numar, convert(decimal(15,2),@suma) suma,  'PS' subtip,
					'Stornare factura '+ @factura+ ' din data '+convert(varchar(10), @datafacturii,101) explicatii, @tert tert, @factura factura
				for XML raw, TYPE)
			for xml RAW)

		exec wScriuPozplin @sesiune=@sesiune, @parXML=@docRE

		/** Tiparim si un formular */
--/*SP	-------------------------------Generare formular daca e pusa bifa-----------------------------------------
		if @generare=1 and isnull(@formular,'')<>''
		begin
			if object_id('temdb..#expeditie') is not null
				drop table #expeditie
			if @sesiune='' select @nrformular
			select tip='PROPUTILIZ', Cod=@userASIS, Cod_proprietate='UltFormGenPSAP', Valoare=@nrformular into #expeditie where @nrformular<>''
			--union all
			--select tip='TERT', Cod=@tert, Cod_proprietate='UltModPlataAPBK', Valoare=@modPlata where @modPlata<>''
			
			update pp
			set pp.valoare=e.valoare
			from proprietati pp inner join #expeditie e on e.tip=pp.Tip and e.Cod=pp.Cod and e.Cod_proprietate=pp.Cod_proprietate
				and pp.Valoare_tupla=''
			if @@ROWCOUNT<(select COUNT(1) from #expeditie)
				insert proprietati (Tip,Cod,Cod_proprietate,Valoare,Valoare_tupla)
				select e.tip,e.Cod,e.Cod_proprietate,e.Valoare,'' 
				from #expeditie e left join proprietati pp on e.tip=pp.Tip and e.Cod=pp.Cod and e.Cod_proprietate=pp.Cod_proprietate
				and pp.Valoare_tupla=''
				where pp.Valoare is null 
		
			declare @p2Sp xml,@paramXmlStringSp varchar(max)
			set @paramXmlStringSp= (select 'IB' as tip, @formular as nrform, @tert as tert, rtrim(@chitanta) as numar, --/*SP
					rtrim(@contcasa) as cont, 2 as nrExemplare, scriuavnefac=(case @eXml when 1 then 0 end) /* SP*/
					, rtrim(@factura) as factura, @datafacturii as data, '0' as inXML for xml raw)
			--/*SP
			if isnull(@sesiune,'')='' select @paramXmlStringSp
			if @eXml=1
			begin
				delete avnefac where Terminal=@userASIS
				insert avnefac
				select
				@userASIS, --Terminal	char	25
				'1', --Subunitate	char	9
				'RE', --Tip	char	2
				'AP'+@numar, --Numar	char	20
				'', --Cod_gestiune	char	9
				@datafacturii, --Data	datetime	8
				@tert, --Cod_tert	char	13
				'', --Factura	char	20
				@contcasa, --Contractul	char	20
				GETDATE(), --Data_facturii	datetime	8
				'', --Loc_munca	char	9
				'', --Comanda	char	13
				'', --Gestiune_primitoare	char	9
				'', --Valuta	char	3
				'', --Curs	float	8
				'', --Valoare	float	8
				'', --Valoare_valuta	float	8
				'', --Tva_11	float	8
				'', --Tva_22	float	8
				'', --Cont_beneficiar	char	13
				'' --Discount	real	4
			end  --/*SP
			exec wTipFormular @sesiune, @paramXmlStringSp
		end --SP*/
	   --raiserror('S-a inregistrat incasarea in lei!',16,1)        
	   SELECT 'S-a generat cu succes documentul de plata stornare AP'+RTRIM(@numar)+' din data de  '+LTRIM(CONVERT(VARCHAR(20),@data,103))
			+' pe contul '+rtrim(@contcasa) AS textMesaj, 'Info' as titluMesaj  for xml raw, root('Mesaje') 
	end        
		
	--commit tran yso_wOPPlataStornare
end try 
begin catch 
	IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'yso_wOPPlataStornare')            
		ROLLBACK TRANSACTION yso_wOPPlataStornare
    declare @eroare varchar(200) 
	set @eroare='yso_wOPPlataStornare: '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
