/* operatie pt. vizualizare formular */
create procedure wOPFormularMF (@sesiune varchar(50), @parXML xml) 
as     
begin
declare @sub varchar(9),@tip varchar(2),@subtip varchar(2),@numar varchar(8),@data datetime,@nrinv varchar(13), 
	@concl varchar(200), @termen datetime, @comisar1 char(15), @comisar2 char(15), 
	@comisar3 char(15), @comisar4 char(15), @tipformular varchar(1), @formular varchar(13), 
	@tipanexadoc varchar(2),@userASiS varchar(10), @inXML varchar(1), @eroare varchar(254), 
	@paramXmlString varchar(max)
begin try
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),  
	@subtip=ISNULL(@parXML.value('(/parametri/row/@subtip)[1]', 'varchar(2)'), ''),          
	@numar=ISNULL(@parXML.value('(/parametri/row/@numar)[1]', 'varchar(8)'), ''),     
	@data=ISNULL(@parXML.value('(/parametri/row/@data)[1]', 'datetime'), '01/01/1901'),
	@nrinv = ISNULL(@parXML.value('(/parametri/row/@nrinv)[1]', 'varchar(13)'), ''), 
	@concl=ISNULL(@parXML.value('(/parametri/@concl)[1]', 'varchar(100)'), 0), 
	@termen=ISNULL(@parXML.value('(/parametri/@termen)[1]', 'datetime'), 0), 
	@comisar1=ISNULL(@parXML.value('(/parametri/@comisar1)[1]', 'varchar(15)'), 0), 
	@comisar2=ISNULL(@parXML.value('(/parametri/@comisar2)[1]', 'varchar(15)'), 0), 
	@comisar3=ISNULL(@parXML.value('(/parametri/@comisar3)[1]', 'varchar(15)'), 0), 
	@comisar4=ISNULL(@parXML.value('(/parametri/@comisar4)[1]', 'varchar(15)'), 0), 
	@tipformular = isnull(@parXML.value('(/parametri/@tipformular)[1]','varchar(1)'),''),	
	@formular = isnull(@parXML.value('(/parametri/@formular)[1]','varchar(13)'),''),	
	@inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)')
if @tipformular='' select @tipformular='X'
if @formular='' select @formular='MF'
select @tipanexadoc=(case right(@tip,1)+@subtip when 'IAF' then '1' when 'IPF' then '2' 
	when 'IPP' then '3' when 'IDO' then '4' when 'IAS' then '5' when 'ISU' then '6' 
	when 'IAL' then '7' else right(@tip,1)+Left(@subtip,1) end)
		
if isnull(@nrinv,'')='' raiserror('Operatia se poate face doar la nivel de pozitie document!',11,1)
if @formular not in (select numar_formular from antform where Tip_formular=@tipformular) 
	raiserror('Formular inexistent sau de alt tip!',11,1)

delete from avnefac where terminal=@userASiS
insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,
	Contractul, Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,
	Valoare_valuta,Tva_11,Tva_22, Cont_beneficiar,Discount) 
	values (@userASiS,@sub,'M'+right(@tip,1),@numar,'',@data,'','','', 
	@data,'','','','',0,0,0,0,0,@nrinv,0)
    
delete from anexadoc where Subunitate=@sub and tip=@tipanexadoc and Numar=@numar and data=@data
insert into anexadoc(Subunitate, Tip, Numar, Data, Numele_delegatului, Seria_buletin, 
	Numar_buletin, Eliberat, Mijloc_de_transport, Numarul_mijlocului, 
	Data_expedierii, Ora_expedierii, Observatii, Punct_livrare, Tip_anexa) 
	values (@sub,@tipanexadoc,@numar,@data,@comisar1+@comisar2,'','',@comisar3+@comisar4,'','', 
	@termen,'',@concl,'','')
    
--declare @DelayLength char(8)= '00:00:01'
--WAITFOR delay @DelayLength
set @paramXmlString= (select @tipformular as tip, @formular as nrform,0 as scriuavnefac,1 as debug,
    @data as data, rtrim(@numar) as numar, rtrim(@nrinv) as Cont_beneficiar, 
    @inXML as inXML for xml raw)
exec wTipFormular @sesiune, @paramXmlString	
   
end try
begin catch
set @eroare = ERROR_MESSAGE()
	raiserror(@eroare, 11, 1)	
end catch	
end
