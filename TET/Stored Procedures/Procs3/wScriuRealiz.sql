--***
create procedure  wScriuRealiz  @sesiune varchar(50), @parXML xml 
as
declare @realizare float,@termen datetime,@dentert varchar(20),@contract varchar(20),@planificat float, @tipDoc varchar(2),@data datetime,
	@cod varchar(20), @val2 float, @subtip varchar(2), @anulare int ,@stare varchar(1),@realizat float,@facturat float,@tert varchar(13),
	@data_jos datetime,@data_sus datetime,@proces_verbal varchar(13),@data_pv datetime,@explicatii varchar(170), @factureaza int, @fstare varchar(10),
	@cautare varchar(50),@realizare_curenta float


begin try  
	declare @iDoc int 
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	select @realizare=isnull(realizare,0),@realizare_curenta=isnull(realizare_curenta,0),@proces_verbal=upper(proces_verbal),@explicatii=upper(explicatii),@data_pv=data_pv,
		@termen=termen ,@contract=upper(Contract),@planificat=planificat, @cod=upper(cod), 
		@anulare=anulare, @stare=stare,@facturat=facturat,@realizat=realizat,@tipDoc =tipDoc,@tert=upper(tert),@data=data,@data_jos=data_jos,
		@data_sus=data_sus,@factureaza=isnull(factureaza,0), @subtip=subtip,@cautare=isnull(cautare,'')
	from OPENXML(@iDoc, '/row/row')
	WITH 
		(	
			realizare float '@realizare', --realizarea introdusa pe macheta
			realizare_curenta float '@realizare_curenta', --cantitate pentru refacturare termen
			proces_verbal varchar(13) '@proces_verbal',--proces verbal
			explicatii varchar(170) '@explicatii',
			data_pv	datetime '@data_pv',--data proces verbal
			termen datetime '@termen',
			contract varchar(20)'@contract',
			anulare int'@anulare',
			cod varchar(20)'@cod',
			planificat float '@planificat' ,--campul cantitate
			stare varchar(1)'@stare',
			realizat float '@realizat', --campul val1
			facturat float '@facturat', --campul catitate_realizata
			tipDoc varchar(2) '@tipDoc',
			tert varchar(13) '@tert',
			cautare varchar(50) '../@_cautare',
			data datetime '@data',
			data_jos datetime '../@datajos',
			data_sus datetime '../@datasus',
			factureaza int '@factureaza',
			subtip varchar(2)'@subtip'
		 )
/* atributul factureaza specific drdp*/
	if isnull(@anulare,9)<>9 
		set @subtip='KA'
  
 	if @subtip='KA'
	begin
		if (@stare='F')
			 raiserror('wScriuRealiz(termene):Cantitatea realizata nu se poate anula in stare F-Facturat',16,1)
	     
		select @val2=val2 from termene  
		   where Termen=@termen and Contract=@contract and Cod=@cod
		if @val2<>1
			select 'wScriuRealiz(termene):Nu era completata cantitatea realizata' as textMesaj, 'Informare' as titluMesaj for xml raw, root('Mesaje')
		else
			update termene 
				set Val1=0, Val2=0
			   where Termen=@termen and Contract=@contract and Cod=@cod
	end
	else
		begin		
		   /* if (@stare='F' and (@facturat>=@planificat))
				raiserror('Nu se mai pot adauga realizari pe acest termen intrucat s-a facturat deja o cantitate mai mare decat cantitatea planificata!!',11,1)*/
		
			if @stare='F'--daca a fost facturat, cand se adauga realizare noua,aceasta se aduna la cantitatea deja facturata
				update termene set Val1=Cant_realizata+@realizare , Val2=1, 
					Explicatii=isnull(convert(char(30),convert(char(10),@data_pv,101)+'-'+@proces_verbal)+(case when isnull(@explicatii,'')=''then  SUBSTRING(explicatii,31,170)else @explicatii end),'') 
				where Termen=@termen and Contract=@contract and cod=@cod
			
			else  --altfel se face simplu update pe camp val1 cu noua valoare
				  --var @factureaza va updata campul val1 cu cantitatea stabilita in contract(DRDP)
				update termene 	set Val1=(case when @factureaza=1 then cantitate else case when isnull(@realizare_curenta,0)<>0 then  Val1+@realizare_curenta else @realizare end end), Val2=1, 
					Explicatii=(case when @factureaza=0 then convert(char(30),convert(char(10),@data_pv,101)+'-'+@proces_verbal)+(case when isnull(@explicatii,'')=''then  SUBSTRING(explicatii,31,170)else @explicatii end) else '' end) 
				where Termen=@termen and Contract=@contract and cod=@cod
				update termene 	set Explicatii=(case when @factureaza=0 then isnull(convert(varchar(10),@data_pv,101)+'-'+@proces_verbal+SUBSTRING(explicatii,31,170) ,'') else '' end)
					where Contract=@contract and termen between @data_jos and @data_sus and rtrim(SUBSTRING(Explicatii,1,30))=''		
	
		end	
			
	declare @docXMLIaPozRealizari xml
	set @docXMLIaPozRealizari = '<row tipDoc="' + rtrim(@tipDoc) 
	+ '" numar="' + rtrim(@contract) + '" tert="' + rtrim(@tert)+ '" _cautare="' + rtrim(@cautare)+'" datajos="' + convert(char(10), @data_jos, 101)+'" datasus="' + convert(char(10), @data_sus, 101)+ '" data="' + convert(char(10), @data, 101)+'"/>'
	exec wIaPozRealiz @sesiune=@sesiune, @parXML=@docXMLIaPozRealizari 
	exec sp_xml_removedocument @iDoc 
end try  
begin catch  
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
--sp_help termene
