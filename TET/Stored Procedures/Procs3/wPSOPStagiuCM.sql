/* operatie pt. vizualizare stagiu concediu medical */
create procedure wPSOPStagiuCM (@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(10), @tip varchar(1), @formular varchar(13), @Data datetime, 
		@marca varchar(6), @tip_diagnostic varchar(2), @Data_inceput datetime, 
		@inXML varchar(1), @mesaj varchar(254)
begin try
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

select	@formular = isnull(@parXML.value('(/parametri/@formular)[1]','varchar(13)'),''),	
		@data = isnull(@parXML.value('(/parametri/@data)[1]','datetime'),0),
		@marca = isnull(@parXML.value('(/parametri/@marca)[1]', 'varchar(6)'),0),	
		@tip_diagnostic = isnull(@parXML.value('(/parametri/@tipconcediu)[1]', 'varchar(2)'),0),	
		@data_inceput = isnull(@parXML.value('(/parametri/@datainceput)[1]', 'datetime'),0),	
		@inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)')

if @formular=''
	select @tip='W', @formular='ADEVCM'
		
  --formular
    delete from avnefac where terminal=@utilizator
	insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul, 
	Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22, 
	Cont_beneficiar,Discount) 
	values (@utilizator,'1','AD',@marca,'',@data,'',@tip_diagnostic,'', 
	@data_inceput,'','','','',0,0,0,0,0,'',0) 
    
    --declare @DelayLength char(8)= '00:00:01'
   -- WAITFOR delay @DelayLength
    declare @paramXmlString varchar(max)
    set @paramXmlString= (select @tip as tip, @formular as nrform,0 as scriuavnefac,1 as debug,
    @data as data, rtrim(@marca) as numar, rtrim(@tip_diagnostic) as factura, @data_inceput as data_facturii, @inXML as inXML for xml raw )
	--select @paramXmlString
    exec wTipFormular @sesiune, @paramXmlString	
   
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end


