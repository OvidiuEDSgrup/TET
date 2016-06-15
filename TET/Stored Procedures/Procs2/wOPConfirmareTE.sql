--***
create procedure wOPConfirmareTE @sesiune varchar(50), @parXML xml                
as              
begin try 
	declare 
	@subunitate char(9),@tip char(2),@numar varchar(20), @userASiS varchar(20), @gestiune char(13),@numarTE varchar(20),@dataTE datetime,
	@datacharTE char(10), @err int, @eroare varchar(200), @codbare char(1),@data datetime,@gestiunetmp varchar(13), @coduridebare int, @iadocfisc int,
	@detalii XML, @locmdest varchar(9), @gestiunedest varchar(9), @pragmatic int, @ortoprofil int, @docgen varchar(20), @datagen datetime

	set @numar = ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), '')                
	set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')  
	set @dataTE = @parXML.value('(/parametri/@dataTE)[1]', 'datetime')
	set @numarTE = ISNULL(@parXML.value('(/parametri/@numarconf)[1]', 'varchar(20)'), '')	--	citit @numarconf (la DRDP se utiliza).
	set @locmdest = ISNULL(@parXML.value('(/parametri/@lmdest)[1]', 'varchar(20)'),'')
	set @tip = 'TE'
	set @datacharTE=convert(char(10),GETDATE(),101)
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	exec luare_date_par 'GE', 'CODBARA', @coduridebare OUTPUT, 0, ''
	exec luare_date_par 'GE', 'IADOCFISC', @iadocfisc OUTPUT, 0, ''
	exec luare_date_par 'GE', 'PRAGMATIC', @pragmatic OUTPUT, 0, ''
	exec luare_date_par 'SP', 'ORTO', @ortoprofil OUTPUT, 0, ''
  
	--exec luare_date_par 'UC', 'TEACCODI', @TEACCODI output, 0, ''
	--if exists (select * from par where Tip_parametru = 'UC' and left(Parametru,1) = 'T')            
	--	 set @codbare = (select Val_logica from par where  Tip_parametru = 'GE' and Parametru = 'CODBARA')            
	--else            
	--	 set @codbare = 0	

	begin transaction confTE
		declare @NrDocFisc int, @fXML xml 
		if @pragmatic=0 -- luam numar din plaja, nu mai punem I ca sufix. 
		begin      
			if @numarTE=''	-- Daca s-a completat in macheta il pastram.
			begin
				set @fXML = '<row/>'            
				set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')            
				set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')            
				set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')            
				exec wIauNrDocFiscale @fXML, @NrDocFisc output         
		--if ISNULL(@NrDocFisc, 0)<>0            
		--  set @numarTE='I'+LTrim(RTrim(CONVERT(char(20), @NrDocFisc)))--+'I'      
				set @numarTE=LTrim(RTrim(CONVERT(char(20), @NrDocFisc)))
			end
		end      
		else 
		 --set @numarTE=RTRIM(@numar)+'I'      
			set @numarTE=right(rtrim(@numar),7)+'I'
	
		set @gestiunedest=(select Contractul from doc where subunitate=@subunitate and tip=@tip and Numar=@numar and data=@data and Contractul<>'')      
		if not exists (select 1 from doc where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@data)
			raiserror('Numarul nu exista pentru data introdusa! Operatie de transfer anulata!',16,1)
		if /*exists (select 1 from pozdoc where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@data and stare in (4,6)) 
			or*/ exists (select 1 from doc where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@data --and stare in (4,6) 
				AND	detalii.value('(/*/@numar_dest)[1]','varchar(20)') IS NOT NULL AND detalii.value('(/*/@data_dest)[1]','datetime') IS NOT NULL)   
			begin
				select @docgen=detalii.value('(/*/@numar_dest)[1]','varchar(20)'), @datagen=detalii.value('(/*/@data_dest)[1]','datetime') 
					from doc where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@data --and stare in (4,6)
				set @eroare= 'Documentul a fost deja confirmat cu numarul '+@docgen+' din '+convert(char(10),@datagen,103)+'! Operatia a fost anulata!'
				raiserror(@eroare,16,1)
			end
		if @numar=''
			raiserror('Trebuie sa introduceti numarul documentului pe care il veti confirma!' ,16,1)
		if @gestiunedest is null
			raiserror('Documentul nu are o gestiune destinatara presetata! Operatie de transfer anulata!',16,1) 
		--validare gestiune destinatara:
		if exists (select valoare from fPropUtiliz(@sesiune) where cod_proprietate='GESTIUNE' and valoare<>'') 
				and not exists (select valoare from fPropUtiliz(@sesiune) where cod_proprietate='GESTIUNE' and valoare=@gestiunedest) 
			raiserror('Utilizatorul nu are dreptul de transfer pentru gestiunea destinatara!',16,1)             
		if @locmdest=''	--	daca s-a completat in macheta se pastreaza cel introdus, altfel se merge pe regulile de mai jos
		begin
			set @locmdest=(select top 1 Loc_munca from doc where subunitate=@subunitate and tip=@tip and Numar=@numar and data=@data and Contractul<>'') -- loc munca initial - nu trebuie pastrat!
			set @locmdest =isnull((select g.Loc_de_munca from gestcor g where g.Gestiune=@gestiunedest and g.loc_de_munca<>''),@locmdest)-- loc munca specific gestiunii
			if exists (select 1 from lmfiltrare where utilizator=@userASiS) and not exists (select 1 from lmfiltrare where utilizator=@userASiS and cod=@locmdest) -- daca nu poate fi atribuit acest loc de munca:
				set @locmdest=isnull((select top 1 cod from lmfiltrare l where l.utilizator=@userASiS),@locmdest) 
		end

		declare @input XML
		if @dataTE is null
			set @dataTE=convert(datetime,convert(char(10),GETDATE(),110),110)
		set @input=(select rtrim(@subunitate) as '@subunitate','TE' as '@tip',
			@numarTE as '@numar', @dataTE as '@data',
				(select Gestiune_primitoare as '@gestiune',[Contract] as '@gestprim',
				cod as '@cod', convert(decimal(12,5),pret_de_stoc) as '@pstoc', convert(decimal(12,5),Pret_cu_amanuntul) as '@pamanunt',
				convert(decimal(12,3),cantitate) as '@cantitate', rtrim(grupa) as '@codintrare', rtrim(cont_corespondent) as '@contstoc', 
				isnull((select g.Cont_contabil_specific from gestiuni g where g.subunitate=@subunitate and g.cod_gestiune=[Contract] and g.Cont_contabil_specific<>''),Cont_de_stoc) as '@contcorespondent', 
				@locmdest as '@lm', (select rtrim(Loc_de_munca) as lmpred for xml raw,type) 'detalii'
				from pozdoc       
				where Subunitate = @subunitate and pozdoc.tip='TE' and numar=@numar and data=@data
				for xml Path,type)
			 for xml Path,type)
	
		declare @randuriafectate int

		select @randuriafectate=COUNT(*)
				from pozdoc       
				where Subunitate = @subunitate and pozdoc.tip='TE' and numar=@numar and data=@data

		if @randuriafectate=0
		begin
			select 'Nu s-au preluat pozitii de pe documentul selectat!' as textMesaj for xml raw, root('Mesaje')
			return
		end
		exec wScriuPozdoc @sesiune,@input
    
		select top 1 @detalii=detalii from doc where Subunitate = @subunitate and tip='TE' and numar=@numar and data=@data 

		/** Daca nu a existat pana acuma nimic in detalii **/
		if @detalii is null
			set @detalii = ( select rtrim(@numarTE) numar_dest, @datacharTE data_dest  for xml RAW)
		else
		begin
			/** Daca exista detalii, dar fara atributul numar_dest **/
			if @detalii.value('(/*/@numar_dest)[1]','varchar(20)') IS NULL
				set @detalii.modify ('insert attribute numar_dest{sql:variable("@numarTE")} into (/row)[1]')
			else
			/** Daca exista detalii si atributul numar_dest, doar il actualizam **/
				set @detalii.modify('replace value of (/row/@numar_dest)[1] with sql:variable("@numarTE")')
			/** Daca exista detalii, dar fara atributul data_dest **/
			if @detalii.value('(/*/@data_dest)[1]','datetime') IS NULL
				set @detalii.modify ('insert attribute data_dest{sql:variable("@datacharTE")} into (/row)[1]')
			/** Daca exista detalii si atributul data_dest, doar o actualizam **/
			else
				set @detalii.modify('replace value of (/row/@data_dest)[1] with sql:variable("@datacharTE")')
		end

		/** Actulizarea detaliilor in DOC **/
		update top(1) doc set detalii=@detalii where Subunitate = @subunitate and tip='TE' and numar=@numar and data=@data 

		--update pozdoc             
		--	set Stare = case when (Stare in (3,5)) then 4 when (Stare = 2) then 6 else Stare end, 
		--	Barcod = (case when @coduridebare=1 then Barcod else @numarTE end)
		--	where Subunitate = @subunitate and pozdoc.tip='TE' and Numar=@numar and data=@data

		-- codul de intrare primitor sa fie unic:
		if @ortoprofil=0
			update pozdoc             
				set grupa = 'TI'+ltrim(str(idPozdoc))
				where Subunitate = @subunitate and pozdoc.tip='TE' and Numar=@numarTE and data=@dataTE

		-- trecerea comenzii sursa in starea 4=confirmat:
		update c
		set c.Stare='4' -- ar trebui pusa din setari UC
		from con c, pozdoc pd  
		where c.subunitate=pd.Subunitate and c.contract=pd.Factura and   
			c.subunitate=@subunitate and c.Tip='BK' and pd.Tip='TE'
			and pd.Numar=@numar and pd.Data=@data
	
		if exists (select 1 from sysobjects where [type]='P' and [name]='wOPConfirmareTESP')
			exec wOPConfirmareTESP @sesiune=@sesiune, @parXML=@parXML
		commit tran confTE

		select 'S-a generat documentul TE cu numarul '+rtrim(@numarTE)+' si data '+convert(char(10),@dataTE,103) as textMesaj for xml raw, root('Mesaje')
end try

begin catch 
	if @@trancount>0 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'confTE')
			ROLLBACK TRAN confTE
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
