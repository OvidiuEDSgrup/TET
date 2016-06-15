create procedure wOPGenFisierPlati @sesiune varchar(50), @parXML xml  
as   
 declare @sterginvalid bit ,@path varchar(max), @calefisier varchar(max), @tipDoc varchar(2), @factura varchar(20), @inXML xml,
		 @datadoc datetime, @nrdoc varchar(20), @datascad datetime, @tertinvalid varchar(20), @fctinvalida varchar(20),@nrordin varchar(50)
         ,@nrOP varchar(20), @factcrs varchar(20), @tertcrs varchar(20)
 select @sterginvalid=ISNULL(@parXML.value('(/parametri/@sterginvalid)[1]', 'bit'), 0),
		@path=ISNULL(@parXML.value('(/parametri/@path)[1]', 'varchar(max)'), ''),
		@tipDoc=isnull(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),
		@factura=isnull(@parXML.value('(/parametri/@numar)[1]', 'varchar(8)'), ''),
		@inXML=isnull(@parXML.value('(/parametri/@inXML)[1]','varchar(1)'),0),
		@datadoc=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'1901-01-01'),
		@nrdoc=isnull(@parXML.value('(/parametri/@numar)[1]', 'varchar(50)'), ''),
		@nrordin=isnull(@parXML.value('(/parametri/@nrop)[1]', 'varchar(8)'), '')
		
		
begin try
        -------------------sterg documente invalide (cele care au suma de platit=0 si nu sunt pe formular )din generareplati----------
      if @nrdoc=''
         raiserror ('Selectati o pozitie',16,1) 
      if @sterginvalid=1
          delete from generareplati where Numar_document=@nrdoc and val1<0.01 or Banca_beneficiar='' or IBAN_beneficiar=''
	  if @path=''
        raiserror('Completati numele fisierului impreuna cu extensia lui',16,1)
        -------- verific daca s-a introdus extensia documentului----------
      if CHARINDEX('.',@path,1)=0
        raiserror('Introduceti extensia documentului',16,1)
     ---------------din numefisier alcatuit de genul:'\\aswcj\publicftp\silviu.txt' separ nume fiseir de cale fisier----------
        declare @lungimefisier int, @lungimecale varchar(50), @lungimecalefisier int,@calefisierdreapta varchar(50),
		@fisierintors varchar(50),@lungimefisierintors int, @fisier varchar(50)
		
		if CHARINDEX ('\',@path,1)=0
		  set @fisier=@path
        else
         begin
		--------reverse de cale -------------------------------
        set @calefisierdreapta=REVERSE(@path)
        --------stabilesc lungimea fisierului text fara cale--------------
        set @lungimefisier= cast(CHARINDEX('\',@calefisierdreapta,1)-1 as int)
        --------scot fisierul din tot path-ul-----------------------------
		set @fisierintors=SUBSTRING(@calefisierdreapta,1,@lungimefisier)
		--------il aduc la forma normala----------------------------------
		set @fisier=REVERSE(@fisierintors)
		set @lungimefisier=len(@fisier)
		set @lungimecalefisier=LEN(@path)-@lungimefisier
		--------scot forma finala a path-ului fara numele fisierului pentru a-l introduce in caleform-------------------
		set @calefisier=left(@path,@lungimecalefisier)
		if not exists (select 1 from par where Tip_parametru='AR' and Parametru='FISPLATI')
		  insert into par values('AR','FISPLATI','Form din wOPGenFisPlati',0,0,@path)
        else
          update par set val_alfanumerica=@path where Tip_parametru='AR' and Parametru='FISPLATI'
        end
      ---atasez un numar OP pentru fiecare factura valida-----------------
     declare crsordin cursor for
	  select numar_ordin,tert from generareplati where numar_document=@nrdoc and data=@datadoc and val1>=0.01 and banca_beneficiar<>'' and iban_beneficiar<>''
	  open crsordin  
	  fetch next from crsordin into @nrOP,@tertcrs
	   while @@FETCH_STATUS=0
	   begin
	    if @nrOP=''
	    begin
	    update g set Numar_ordin=@nrordin from generareplati g where numar_document=@nrdoc and tert=@tertcrs and val1>=0.01 and banca_beneficiar<>'' and iban_beneficiar<>'' --and stare='0'
	    set @nrordin=@nrordin+1
        end
	  fetch next from crsordin into @nrOP,@tertcrs
	  end
	  close crsordin
	  deallocate crsordin
	     
     declare @p2 xml,@paramXmlString varchar(max)
        ----------apelare wTipFormular date+ nume fisier+calefisier------------------
	 set @paramXmlString= (select @tipDoc as tip,  'BT' as nrform, rtrim(@factura) as numar, 
	                       @datadoc as data, @fisier as numefisier, @calefisier as directoroutput,  @inXML as inXML for xml raw )
	 exec wTipFormular @sesiune, @paramXmlString
	 -------------dupa generare fisier plati trec OP in stare generat-----
	 
	 update generareplati set Stare='1' where Numar_document=@nrdoc and Data=@datadoc and stare=0
   if @calefisier is null 	 
		set @calefisier= (select val_alfanumerica from par where Tip_parametru='AR' and Parametru='CALEFORM')
    select 'S-a generat fisierul de plati cu numele '+@fisier+' salvat in calea:'+@calefisier+'!' as textMesaj for xml raw, root('Mesaje')
    
 declare @docXMLIaPozGP xml  
 set @docXMLIaPozGP = '<row numar="' + rtrim(@nrdoc) + '" data="' + convert(varchar(20), @datadoc, 101)+'"/>'  
 select @docXMLIaPozGP
 exec wIaPozGP @sesiune=@sesiune, @parXML=@docXMLIaPozGP   
end try
begin catch
    declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch


