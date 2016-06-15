---*** 
---***   
create procedure [dbo].[wOPStornareDoc] @sesiune varchar(50), @parXML xml   
as   
begin try   
declare @subunitate char(9),@tip char(2),@numar char(20),@datadoc datetime,@tert char(13), @userASiS varchar(20), @terts varchar(13),   
	@tipstorno char(20), @numarstorno char(20),@gestiune char(13),@datastorno datetime ,@codbare char(1),@lunabloc int,@anulbloc int, @subtip varchar(2),           
	@databloc datetime,@plata_inc char(1),@factura char(20),@facttert varchar(40),@contspgestiune varchar(40),@tipgestiune char(1), @err int, @eroare varchar(254),      
	@NrAvizeUnitar int,@lm varchar(13),@jurnal varchar(3), @categpret varchar(10),@tertDoc varchar(20), @explicatii varchar(50), @numarGenerat varchar(20),@stornaredubla int  
	,@numarcon varchar(30), @cod varchar(20), @codi varchar(20), @numarpoz int,@cantitate decimal(12,2)
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
 
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output        
exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''            
  
select      
	@facttert =ISNULL(@parXML.value('(/parametri/@factura)[1]', 'varchar(40)'), ''),       
	@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(13)'), '') ,        
	@lm=ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(13)'), '') ,          
	@jurnal = ISNULL(@parXML.value('(/parametri/@jurnal)[1]', 'varchar(3)'), '') ,       
	@plata_inc=ISNULL(@parXML.value('(/parametri/@plata_inc)[1]', 'char(1)'), ''),           
	@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), '')  ,        
	@subtip=ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(2)'), ''),                
	@numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'char(20)'), '')   ,           
	@numarcon=ISNULL(@parXML.value('(/parametri/@numarcon)[1]', 'varchar(30)'), '')   ,           
	@datadoc=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),      
	@cod=ISNULL(@parXML.value('(/parametri/row/@cod)[1]', 'varchar(20)'), ''),---stornare la nivel de pozitie
	@codi=ISNULL(@parXML.value('(/parametri/row/@codintrare)[1]', 'varchar(20)'), ''),---stornare la nivel de pozitie      
	@numarpoz=ISNULL(@parXML.value('(/parametri/row/@numarpozitie)[1]', 'int'), 0),---stornare la nivel de pozitie      
	@cantitate=ISNULL(@parXML.value('(/parametri/row/@cantitate)[1]', 'decimal(12,2)'), 0),---stornare la nivel de pozitie      
	--@gestiunedoc=ISNULL(@parXML.value('(/parametri/@gestiune)[1]', 'char(13)'), '') ,      
	@gestiune = ISNULL(@parXML.value('(/parametri/@gestiunea)[1]', 'varchar(13)'), ''),       
	@numarstorno=ISNULL(@parXML.value('(/parametri/@numarstorno)[1]', 'char(20)'), '')   ,            
	@datastorno=ISNULL(@parXML.value('(/parametri/@datastorno)[1]', 'datetime'), ''),        
	@categpret=ISNULL(@parXML.value('(/parametri/@categpret)[1]', 'char(13)'), ''),  
	@stornaredubla=ISNULL(@parXML.value('(/parametri/@stornaredubla)[1]', 'int'), 0) -- parametru care permite stornarea dubla a facturilor    
  
if @tert=''       
	raiserror('wOPStornareDoc: Pentru stornare trebuie introdus client!',16,1)    
if @tip='AC'    
begin      
	set @tertDoc=isnull((select max(tert) from pozdoc where tip='AC' and numar=@numar and data=@datadoc),'')      
	if @tertDoc<>'' and @tertDoc<>@tert      
		raiserror ('wOPStornareDoc: Documentul sursa are tert, trebuie ca tertul existent sa corespunda cu cel din campul client!',16,1)        
end    
set @explicatii='doc sursa '+@numar+' de tip: '+@tip+' data '+CONVERT(char(10),@datadoc,101)         
set @contspgestiune = (select isnull(cont_contabil_specific,'') from gestiuni where subunitate=@subunitate and Cod_gestiune = @gestiune)   
set @tipgestiune = (select isnull(Tip_gestiune,'') from gestiuni where subunitate=@subunitate and Cod_gestiune = @gestiune)      
set @terts=@tert           
               
set @tipstorno=@tip -- tipul documentului generat prin stornare       
if @tip='AC'      
	set @tipstorno='AP'          
      
if exists (select * from par where Tip_parametru = 'GE' and Parametru = 'CODBARA')            
	set @codbare = (select Val_logica from par where  Tip_parametru = 'GE' and Parametru = 'CODBARA')            
else            
	set @codbare = 0            
         
set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)      
set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)      
set @tert=substring(@facttert, CHARINDEX('|',@facttert,1)+1,40)      
set @factura=left(@facttert, CHARINDEX('|',@facttert,1)+1)      
        
if @lunabloc not between 1 and 12 or @anulbloc<=1901       
	set @databloc='01/01/1901'       
else       
	set @databloc=dateadd(month,1,convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))      
      
if @databloc>@datastorno      
	raiserror('wOPStornareDoc: Data storno trebuie sa fie o data ulterioara lunii blocate!',11,1)       
       
if @factura=''       
	raiserror('wOPStornareDoc: Trebuie sa selectati o factura!',11,1)      
------------------tratare in cazul in care nu este permisa stornarea dubla a fact.-----------------------------------------------      
--------- determin daca AC-ul selectat are tert sau nu( caz Pragmatic: unele AC-uri nu au tert.)----
declare @areTert int
if (select COUNT(1) from doc where Subunitate = @subunitate and doc.tip=@tip and Numar = @numar and Data=@datadoc and cod_tert='')<>0
	set @areTert = 0
else 
	set @areTert = 1
-- starile 3 si 5 reprezinta "operat", starea 2 este "definitiv", starile 4 si 6 reprezinta "deja stornat" (din starile 3 si 5 se trece in starea 4, din starea 2 se trece in starea 6)
--if @stornaredubla=0 -- daca nu se permite re-stornarea (implicit)
--begin
--	if (select max (stare) from pozdoc where Subunitate = @subunitate and pozdoc.tip=@tip and Numar = @numar and Data=@datadoc 
--		and (pozdoc.cod=@cod or @cod='') and (Cod_intrare=@codi or @codi='') and (Numar_pozitie=@numarpoz or @numarpoz=0)) in ('4','6') -- pt stornare partiala
--			raiserror('wOPStornareDoc: Factura (pozitia) a fost deja stornata!',16,1) 
--end   

if exists (select 1 from doc where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc --and stare in (4,6) 
		AND	detalii.value('(/*/@numar_storno)[1]','varchar(20)') IS NOT NULL AND detalii.value('(/*/@data_storno)[1]','datetime') IS NOT NULL)   
	begin
		select @numarstorno=detalii.value('(/*/@numar_storno)[1]','varchar(20)'), @datastorno=detalii.value('(/*/@data_storno)[1]','datetime') 
			from doc where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@datadoc --and stare in (4,6)
		set @eroare= 'Documentul a fost deja stornat cu numarul '+@numarstorno+' din '+convert(char(10),@datastorno,103)+'! Operatia a fost anulata!'
		raiserror(@eroare,16,1)
	end   
if isnull(@numarstorno,'')=''       
begin      
	declare @NrDocFisc int, @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20),@idPlajaPrimit int 
	--if @tip='AC' -- and @NrAvizeUnitar=1 
	set @tipPentruNr='AP'  
	set @fXML = '<row/>' 
	set @fXML.modify ('insert attribute codMacheta {"DO"} into (/row)[1]') 
	set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]') 
	set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]') 
	--set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]') 
	--set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]') 
	exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output, @NrDoc=@NrDocPrimit output,@idPlaja=@idPlajaPrimit output      

	if ISNULL(@NrDocFisc, 0)<>0      
		set @numarstorno=LTrim(RTrim(CONVERT(char(20), @NrDocFisc)))      
	else 
		raiserror('wOPStornareDoc: Eroare la generare numar document AP!!',11,1)       
	while exists(select Numar from pozdoc where Numar=@numarstorno and YEAR(data)=YEAR(@datastorno)       
             and ((tip in ('AP','AS') and @NrAvizeUnitar=1) or tip=@tipstorno ))      
	begin      
		exec wIauNrDocFiscale @fXML, @NrDocFisc output 
		if ISNULL(@NrDocFisc, 0)<>0      
			set @numarstorno=LTrim(RTrim(CONVERT(char(20), @NrDocFisc)))      
	end      
end      
else      
if exists (select Numar from pozdoc where Numar=@numarstorno and YEAR(data)=YEAR(@datastorno) and ((tip in ('AP','AS') and @NrAvizeUnitar=1) or tip=@tipstorno ))      
begin      
	raiserror('wOPStornareDoc: Numarul acesta de factura a fost deja utilizat!',11,1)      
end       
	
declare @detalii xml
select top 1 @detalii=detalii from doc where Subunitate = @subunitate and tip=@tip and numar=@numar and data=@datadoc

insert into pozdoc(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,       
	Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,       
	Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,       
	Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,       
	Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,       
	Accize_cumparare,Accize_datorate,Contract,Jurnal)              
select Subunitate,@tipstorno,@numarstorno,pozdoc.cod,@datastorno,     
	(case when @gestiune='' then pozdoc.gestiune else @gestiune end), (case when @numarpoz=0 then -Cantitate else -@cantitate end),Pret_valuta,Pret_de_stoc,Adaos,      
	pozdoc.Pret_vanzare, pozdoc.Pret_cu_amanuntul,-TVA_deductibil,pozdoc.Cota_TVA,@userASiS,            
	convert(datetime,convert(char(10),GETDATE(),110),110),            
	replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''),(case when @gestiune='' or len(cod_intrare)=13 or @tip='AP' and tip_miscare='V' then Cod_intrare else rtrim(Cod_intrare)+'S' end),            
	(case when @gestiune='' or @contspgestiune='' or tip_miscare='V' then pozdoc.cont_de_stoc 
		else (case when left(@contspgestiune,2)='35' and left(nomencl.Cont,3)='345' then '354' else @contspgestiune end) end), 
	Cont_corespondent, TVA_neexigibil, (case when @gestiune='' then pozdoc.Pret_amanunt_predator when @tipgestiune in ('A','V') and left(Cont_de_stoc,3)='371' then isnull((select max(Pret_vanzare) from preturi where Cod_produs=pozdoc.Cod and um='5' and Data_superioara='01/01/2999'),0) else Pret_de_stoc end),      
	Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,pozdoc.Loc_de_munca,Comanda,Barcod, 
	(case when @gestiune='' then pozdoc.cont_intermediar when @contspgestiune<>'' then pozdoc.cont_de_stoc else '' end),          
	Cont_venituri,Discount,@terts,(case when @subtip='TE' then @numarcon else @numarstorno end),Gestiune_primitoare,Numar_DVI,8,
	-- Avizele (cont 418) si AC-urile se storneaza in AP-uri cu cont 4111 si cont TVA 4427:
	pozdoc.Grupa, --(case when Cont_factura like '418%' then '4427' else pozdoc.Grupa end),
	(case when @tip='AC' /*or Cont_factura like '418%'*/ then '4111' else Cont_factura end),
	pozdoc.Valuta,Curs, @datastorno, @datastorno, Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal
from pozdoc       
left outer join nomencl on pozdoc.Cod=nomencl.cod      
where Subunitate = @subunitate and pozdoc.tip=@tip and Numar = @numar and Data=@datadoc 
	and (pozdoc.cod=@cod or @cod='') and (Cod_intrare=@codi or @codi='') and (Numar_pozitie=@numarpoz or @numarpoz=0)
	--and ((pozdoc.stare in (2,3,5,8) and @stornaredubla=0) or @stornaredubla=1 and pozdoc.Stare in (2,3,5,4,6,8))
	--and Cantitate>0 

--> copiez detaliile documentului original pe factura storno:
update d set detalii=@detalii
	from doc d where d.data=@datastorno and d.tip=@tipstorno and d.numar=@numarstorno
--declare @binar varbinary(128)
--set @binar=cast('stornaredocument' as varbinary(128))
--set CONTEXT_INFO @binar

--update pozdoc             
--set Stare = case when Stare in (3,5,8) then 4 when Stare = 2 then 6 else Stare end, 
--	Barcod = case when (@codbare = 0) then @numarstorno else barcod end            
--where Subunitate = @subunitate	and pozdoc.tip=@tip and Numar = @numar and Data=@datadoc 
--	and (cod=@cod or @cod='') and (Cod_intrare=@codi or @codi='') and (Numar_pozitie=@numarpoz or @numarpoz=0)
--	and Numar<>@numarstorno and Data>=@databloc
--	--and barcod='' -- daca aveam ceva in barcod (ex. "sursa") sa nu se suprascrie
--	and (@stornaredubla=0 and stare in (2,3,5,8))
--set CONTEXT_INFO 0x00

declare @datacharstorno varchar(10)
set @datacharstorno=convert(char(10),@datastorno,101)

/** Daca nu a existat pana acuma nimic in detalii **/
if @detalii is null
	set @detalii = ( select rtrim(@numarstorno) numar_storno, @datacharstorno data_storno  for xml RAW)
else
begin
	/** Daca exista detalii, dar fara atributul numar_dest **/
	if @detalii.value('(/*/@numar_storno)[1]','varchar(20)') IS NULL
		set @detalii.modify ('insert attribute numar_storno{sql:variable("@numarstorno")} into (/row)[1]')
	else
	/** Daca exista detalii si atributul numar_dest, doar il actualizam **/
		set @detalii.modify('replace value of (/row/@numar_storno)[1] with sql:variable("@numarstorno")')
	/** Daca exista detalii, dar fara atributul data_dest **/
	if @detalii.value('(/*/@data_storno)[1]','datetime') IS NULL
		set @detalii.modify ('insert attribute data_storno{sql:variable("@datacharstorno")} into (/row)[1]')
	/** Daca exista detalii si atributul data_dest, doar o actualizam **/
	else
		set @detalii.modify('replace value of (/row/@data_storno)[1] with sql:variable("@datacharstorno")')
end

/** Actulizarea detaliilor in DOC **/
update top(1) doc set detalii=@detalii where Subunitate = @subunitate and tip=@tip and numar=@numar and data=@datadoc


if not exists (select 1 from anexadoc where Subunitate=@subunitate and tip=@tip and Numar=@numarstorno and data=@datastorno)    
	insert into anexadoc  
		(Subunitate,Tip,Numar,Data,Numele_delegatului,Seria_buletin,Numar_buletin,  
		Eliberat,Mijloc_de_transport,Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii,Punct_livrare,Tip_anexa)  
	select @subunitate,@tip,@numarstorno,@datastorno,'','','','','','','','',@explicatii,'',''  
else 
	update anexadoc set Observatii=@explicatii where Subunitate=@subunitate and tip=@tip and Numar=@numarstorno and data=@datadoc    

-->generare inregistrari contabile
exec faInregistrariContabile @dinTabela=0, @Subunitate=@subunitate, @Tip=@tipstorno, @Numar=@numarstorno, @Data=@datastorno

---------------------------gen. TE la stornare AC----------------------------------------------------------------------      
if @tip='AC'      
begin      
	set @tipPentruNr='TE'    
	set @fXML = '<row/>'      
	set @fXML.modify ('insert attribute codMacheta {"DO"} into (/row)[1]')      
	set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')      
	set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')      
	exec wIauNrDocFiscale @fXML, @NrDocFisc output      
	if ISNULL(@NrDocFisc, 0)<>0      
		set @numarGenerat=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))      
	else      
		raiserror('wOPStornareDoc: Eroare la generare numar document TE !',16,1)   

	declare @numarpozTE int
	set @numarpozTE=@numarpoz
	if @numarpozTE>0
	begin
		select @numarpozTE=p.Numar_pozitie
		from pozdoc p, pozdoc pAC
		where p.Subunitate = @subunitate and p.tip='TE' and p.Numar = @numar and p.Data=@datadoc  
			and pAC.Subunitate = p.subunitate and pAC.tip='AC' and pAC.Numar = p.numar and pAC.Data=p.data  
			and pAC.cod=p.cod and pAC.Cod_intrare=p.Grupa and pAC.Numar_pozitie=@numarpoz
	end
	
	insert into pozdoc(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,       
		Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,       
		Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,       
		Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,       
		Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,       
		Accize_cumparare,Accize_datorate,Contract,Jurnal)              
	select Subunitate,'TE',@numarGenerat,pozdoc.cod,@datastorno,     
		pozdoc.Gestiune_primitoare,(case when @numarpoz=0 then Cantitate else @cantitate end),Pret_valuta,Pret_de_stoc,Adaos,  
		pozdoc.Pret_vanzare, pozdoc.Pret_amanunt_predator,TVA_deductibil,pozdoc.Cota_TVA,@userASiS,  
		convert(datetime,convert(char(10),GETDATE(),110),110),  
		replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''),pozdoc.grupa,  
		Cont_corespondent, Cont_de_stoc, TVA_neexigibil,pozdoc.Pret_cu_amanuntul,  
		Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,pozdoc.Loc_de_munca,Comanda,Barcod,cont_intermediar,  
		tert,Discount,Cont_venituri,Factura,pozdoc.Gestiune,Cont_factura,  
		3,pozdoc.cod_intrare,Numar_DVI,pozdoc.Valuta,Curs,Data_facturii, Data_scadentei, Procent_vama,Suprataxe_vama,      
		Accize_cumparare,Accize_datorate,Contract,Jurnal     
	from pozdoc
	left outer join nomencl on pozdoc.Cod=nomencl.cod      
	where Subunitate = @subunitate and pozdoc.tip='TE' and Numar = @numar and Data=@datadoc  
		and (pozdoc.cod=@cod or @cod='') and (pozdoc.Grupa=@codi or @codi='') and (Numar_pozitie=@numarpozTE or @numarpozTE=0)
		and ((pozdoc.stare in (3,5,8) and @stornaredubla=0) or @stornaredubla=1 and pozdoc.Stare in (3,5,4,6,8))

	--update pozdoc             
	--set Stare = case when Stare in (3,5) then 4 when Stare = 2 then 6 else Stare end, 
	--	Barcod = case when (@codbare = 0) then @numarstorno else barcod end            
	--where Subunitate = @subunitate	and pozdoc.tip='TE' and Numar = @numar and Data=@datadoc 
	--	and (cod=@cod or @cod='') and (pozdoc.Grupa=@codi or @codi='') and (Numar_pozitie=@numarpozTE or @numarpozTE=0)
	--	and Numar<>@numarstorno and Data>=@databloc
	--	--and barcod='' -- daca aveam ceva in barcod (ex. "sursa") sa nu se suprascrie
	--	and (@stornaredubla=0 and stare in (3,5, 8))

	if not exists (select 1 from anexadoc where Subunitate=@subunitate and tip='TE' and Numar=@numarGenerat and data=@datastorno)    
		insert into anexadoc  
			(Subunitate,Tip,Numar,Data,Numele_delegatului,Seria_buletin,Numar_buletin,  
			Eliberat,Mijloc_de_transport,Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii,Punct_livrare,Tip_anexa)  
		select @subunitate,'TE',@numarGenerat,@datastorno,'','','','','','','','',@explicatii,'',''  
	else 
		update anexadoc set Observatii=@explicatii where Subunitate=@subunitate and tip=@tip and Numar=@numarGenerat and data=@datadoc    

	-->generare inregistrari contabile
	exec faInregistrariContabile @dinTabela=0, @Subunitate=@subunitate, @Tip='TE', @Numar=@numarGenerat, @Data=@datastorno
end       
---------------------------daca exista o comanda de livrare atasata documentului va fi si aceasta stornata--------------------       
     
if @subtip='SK' and exists (select contract from con where subunitate=@subunitate and Contract=@numar and Tert=@terts and Data=@datadoc and Tip='BK')      
begin      
	insert into con (Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Stare,Loc_de_munca,Gestiune,      
		Termen,Scadenta,Discount,Valuta,Curs,      
		Mod_plata,Mod_ambalare,Factura,Total_contractat,Total_TVA,Contract_coresp,Mod_penalizare,      
		Procent_penalizare,Procent_avans,Avans,Nr_rate,Val_reziduala,Sold_initial,Cod_dobanda,Dobanda,Incasat,      
		Responsabil,Responsabil_tert,Explicatii,Data_rezilierii)        
	select Subunitate, tip, @numarstorno, tert, Punct_livrare, @datastorno,0,Loc_de_munca,Gestiune,      
		termen,Scadenta,Discount,Valuta,Curs, Mod_plata,Mod_ambalare,Factura,-Total_contractat,-Total_TVA,Contract_coresp,Mod_penalizare,      
		Procent_penalizare,Procent_avans,Avans,Nr_rate,Val_reziduala,Sold_initial,Cod_dobanda,Dobanda,Incasat,      
		Responsabil,Responsabil_tert,Explicatii,Data_rezilierii      
	from con       
	where Subunitate=@subunitate and tip='BK' and data=@datadoc and Contract=@numar and tert=@terts      
	
	insert into pozcon       
		(Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,      
		Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,      
		Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,      
		Data_operarii,Ora_operarii)       
     select Subunitate,Tip,@numarstorno,Tert,Punct_livrare,@datastorno,Cod,-Cantitate,      
		Pret,Pret_promotional,Discount,termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,      
		Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie, @userASiS,      
		convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', ''))      
	from pozcon      
	where Subunitate=@subunitate and tip='BK' and data=@datadoc and Contract=@numar and tert=@terts      
		and (pozcon.cod=@cod or @cod='')
end 

if (@plata_inc = '1') -- daca s-a bifat "Stornare incasare":  
	INSERT INTO pozplin(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma,   
		Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda,   
		Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal)           
	select Subunitate,Cont,@datastorno, --convert(datetime,convert(char(10),GETDATE(),110),110),      
		rtrim(left(Numar,7))+'S',Plata_incasare,Tert, Factura,Cont_corespondent,-Suma,Valuta,Curs,Suma_valuta,            
		Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,Loc_de_munca,Comanda,@userASiS,            
		convert(datetime,convert(char(10),GETDATE(),110),110),replace((convert(char(9), substring(convert(char(30),GETDATE(),108),1,9))),':',''),            
		Numar_pozitie,Cont_dif,Suma_dif,Achit_fact,Jurnal            
	from pozplin             
	where Plata_incasare in ('IB') and tert = @tert and Factura = @factura     

if isnull(@parXML.value('(/parametri/@faramesaj)[1]','int'),0)=0/*trimit par faramesaj din wScriuPozDP */
begin
	if exists (select Numar from pozdoc where Subunitate = @subunitate and pozdoc.tip=@tipstorno and Numar = @numarstorno and Data=@datastorno)      
	begin
		if @tip='AP'      
			select 'wOPStornareDoc: S-a generat documentul '+rtrim(@tipstorno)+' cu numarul '+rtrim(@numarstorno)+' din data '+convert(char(10),@datastorno,103) as textMesaj for xml raw, root('Mesaje')      
		else if @tip='AC'      
			select 'wOPStornareDoc: S-a generat documentul de tip TE cu numarul '+rtrim(@numarGenerat)+', numarul de tip AP cu numarul '+rtrim(@numarstorno)+' din data '+convert(char(10),@datastorno,103) as textMesaj for xml raw, root('Mesaje')      
	end
else 
	raiserror('wOPStornareDoc: Verificati datele, nu s-a generat nici un document storno! ',11,1)      
end
end try     
  
begin catch        
	/* Daca da eroare la orice pozitie sa stearga ceea ce a facut*/
/*	if @NrDocPrimit is not null and not exists(select 1 from docfiscalerezervate where idPlaja=@idPlajaPrimit)
		insert into docfiscalerezervate(idPlaja,numar,expirala) values (@idPlajaPrimit,@NrDocPrimit,getdate())*/
	set @eroare=ERROR_MESSAGE()   
	raiserror(@eroare, 11, 1)   
end catch 
