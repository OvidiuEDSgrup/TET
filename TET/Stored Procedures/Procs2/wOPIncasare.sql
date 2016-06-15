
create procedure wOPIncasare (@sesiune varchar(50), @parXML xml) 
as             
begin try           
	declare 
		@tert varchar(20), @factura varchar(20), @valoare float, @data datetime, @contcasa varchar(40), @lm varchar(9), @comanda varchar(20), @userASIS varchar(20),
		@formular varchar(20),@generare int, @faramesaje bit, @xml_incasare XML, @chitanta varchar(8)
	
	SELECT
		@tert=isnull(@parXML.value('(*/@tert)[1]','varchar(20)'),''),    
		@factura=isnull(@parXML.value('(*/@factura)[1]','varchar(20)'),''), 
		@chitanta=isnull(@parXML.value('(*/@chitanta)[1]','varchar(8)'),''), 
		@valoare=isnull(@parXML.value('(*/@valoare)[1]','decimal(10,2)'),0),     
		@data =isnull(@parXML.value('(*/@data)[1]','datetime'),''),       
		@lm=isnull(@parXML.value('(*/@lm)[1]','varchar(9)'),''),         
		@comanda=isnull(@parXML.value('(*/@comanda)[1]','varchar(20)'),''),				
		@contcasa=@parXML.value('(*/@contcasa)[1]','varchar(40)'),
		@generare=ISNULL(@parXML.value('(*/@generare)[1]', 'int'), 0),
		@formular=ISNULL(@parXML.value('(*/@formular)[1]', 'varchar(20)'), '') ,
		@faramesaje=isnull(@parXML.value('(*/@faramesaje)[1]','bit'),0)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	if ISNULL(@contcasa,'')=''
		select top 1 @contcasa=RTRIM(valoare) from proprietati where Tip='UTILIZATOR' and Cod_proprietate='CONTCASA' and Cod=@userASiS
	
	if @contcasa=''        
		raiserror('Nu s-a putut determina contul de casa pentru incasare (utilizatorul nu are proprietatea CONTCASA si contul nu s-a introdus in clar)!',16,1)      
	if substring(@contcasa,1,4)not in ('5311','5125')     
		raiserror('Factura e in lei, deci contul de casa trebuie sa fie 5311 / 5125 sau analitice ale lui!',16,1)    
		
	
	declare 
		@fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20), @NumarDocPrimit int,@idPlajaPrimit int,@serieprimita varchar(20)
			
	if isnull(@chitanta,'')=''
	begin
		select top 1 @tipPentruNr='RE'	
		
		set @lm = (case when @lm is null then '' else @LM end)
		SELECT @fXML= (select @tipPentruNr tip,'IB' subtip, @lm lm,'PI' meniu, @userASIS utilizator for xml raw, type)

				
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output, @Numar=@NumarDocPrimit output, @idPlaja=@idPlajaPrimit output, @serie=@serieprimita OUTPUT
	end
	else
		set @NrDocPrimit=@chitanta

	set @xml_incasare=
		(select	
			@contcasa cont, @data data, 'RE' tip,
			(select
				@NrDocPrimit numar, @tert tert, @factura factura,  'IB' subtip, @valoare suma for xml raw, type
			)
		 for xml raw
		)

	exec wScriuPlin @sesiune=@sesiune, @parXML=@xml_incasare
	
	if @generare=1 and isnull(@formular,'')<>''
		begin			
			set @parXML= 
				(select 
					'RE' as tip, @formular as nrform, convert(varchar(10),@data,101) data, @contcasa cont,
					(select
						rtrim(@factura) as factura, @data as data, @NrDocPrimit numar, @tert as tert
					for xml raw,type )
				for xml raw)
			exec wTipFormular @sesiune=@sesiune,@parXML=@parXML
		end

		    
	if @faramesaje=0
		select 'S-a inregistrat incasarea facturii!' as textMesaj, 'Info' as titluMesaj for xml raw, root('Mesaje')        
	        
	
	if exists (select 1 from DocDeContat where Subunitate='1' and Tip='PI' and Numar=@contcasa and Data=@data)
		exec faInregistrariContabile @dinTabela=0, @Subunitate='1',@Tip='PI',@Numar=@contcasa, @Data=@data
end try
begin catch 
    declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 16, 1) 
end catch
