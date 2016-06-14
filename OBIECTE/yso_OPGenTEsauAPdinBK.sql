if exists (select * from sysobjects where name ='yso_wOPGenTEsauAPdinBK')
drop procedure yso_wOPGenTEsauAPdinBK
go
--***
create procedure [dbo].[yso_wOPGenTEsauAPdinBK] @sesiune varchar(50), @parXML xml 
as      
declare @Numar char(8) ,@GestPrim varchar(9),@PretAmPrim varchar(20),@CategPret int,@LM char(9),@LMdinBK char(9),@Stare int,
		@Utilizator char(10),@sub varchar(10),@ftert varchar(20),@fcontract varchar(20),@fdata datetime,@gestiune varchar(20),
		@tip varchar(2),@datadoc datetime,@observatii varchar(200),@nrmijtransp varchar(13),@serieCI varchar(50), @numarCI varchar(50), 
		@eliberatCI varchar(50), @eroare nvarchar(2048), @err int, @gesttr varchar(20),@faraMesaje bit, @input xml, @numedelegat varchar(100),
		@GestDest varchar(20), @cod varchar(30)--/*sp
		,@aviznefacturat bit

--/*sp
declare @procid int=@@procid, @objname sysname
set @objname=object_name(@procid)
EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output        

select	@Stare=ISNULL(@parXML.value('(/*/@stare)[1]', 'varchar(20)'), ''),
		@fcontract=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), ''),
		@ftert=upper(ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(20)'), '')),
		@fdata=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), ''),
		@gestiune=ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), ''),
		@GestPrim=ISNULL(@parXML.value('(/*/@gestprim)[1]', 'varchar(20)'), ''),
		@gesttr=ISNULL(@parXML.value('(/*/@gesttr)[1]', 'varchar(20)'), ''),
		@numar=upper(ISNULL(@parXML.value('(/*/@numardoc)[1]', 'varchar(20)'), '')), -- numarul documentului generat. Daca nu se trimite, se genereaza din plaja.
		@datadoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'varchar(20)'), ''),
		@LMdinBK=ISNULL(@parXML.value('(/*/@lm)[1]', 'varchar(20)'), ''),
		@numedelegat=upper(ISNULL(@parXML.value('(/*/@numedelegat)[1]', 'varchar(50)'), '')),
		@nrmijtransp=upper(ISNULL(@parXML.value('(/*/@nrmijltransp)[1]', 'varchar(50)'), '')),
		@serieCI=upper(ISNULL(@parXML.value('(/*/@serieci)[1]', 'varchar(50)'), '')),
		@numarCI=upper(ISNULL(@parXML.value('(/*/@numarci)[1]', 'varchar(50)'), '')),
		@eliberatCI=upper(ISNULL(@parXML.value('(/*/@eliberatci)[1]', 'varchar(50)'), '')),
		@observatii=upper(ISNULL(@parXML.value('(/*/@observatii)[1]', 'varchar(50)'), '')),
		@faraMesaje=ISNULL(@parXML.value('(/*/@faramesaje)[1]', 'bit'), 0) --/*sp flag folosit daca nu vrem afisarea de mesaje din procedura
		,@aviznefacturat=ISNULL(@parXML.value('(/*/@aviznefacturat)[1]', 'bit'), 0)


exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

set @lm=(select top 1 valoare from proprietati where tip='UTILIZATOR' and cod=@Utilizator and cod_proprietate='LOCMUNCA' and valoare<>'')
	if @LM is null
		set @lm=ISNULL(nullif((select MAX(Loc_de_munca) from gestcor where Gestiune=@gestiune),''),@LMdinBK)

begin try  
    if @numedelegat=''
       raiserror('Numele delegatului nu este introdus',16,1)
    if @nrmijtransp=''
       raiserror('Numarul mijlocului de transport nu este introdus',16,1)   
    if @gesttr<>'' and @ftert<>'' and @GestPrim='' and @Stare ='1'
      raiserror('Nu este permisa completarea gestiunii de transport in cazul in care comanda este facuta de un client!',16,1)
    else if @GestPrim<>'' and @Stare='1' --and (@ftert<>'' or @ftert='')
			  set @tip='TE'
	else if @GestPrim<>'' and @Stare='4' and @ftert=''
		raiserror('Document deja transferat! Nu se poate genera transfer!',16,1)
 	-- in functie de completare gest. primitoare si stare: AP, TE sau mesaj de eroare
    else if (@GestPrim<>'' or @GestPrim='') and @Stare in ('4','1') and @ftert<>'' --and (@GestPrim='' or @GestPrim<>'')
             set @tip='AP'  
    else if @GestPrim='' and @ftert=''
         raiserror('Document invalid , nu se poate genera transfer/factura deoarece nu este completata gestiunea prim/tert!Operatie anulata!',16,1) 
    else if @stare in ('6') --and (@GestPrim<>'' or @gestprim='') and (@ftert<>'' or @ftert='') 
         raiserror('Document in stare 6-Realizat, Nu se poate genera transfer/factura! ',16,1)
    else if @stare=0
      raiserror('Nu se poate genera un transfer/factura pentru comenzi in stare operat!',16,1)
    else 
      raiserror('Nu se poate genera un transfer/factura',16,1)
      
    if @GestTr<>''
		begin
			  set @GestDest=@GestPrim 
			  set @GestPrim=@gesttr
		end
	else 
	    set @gestdest=isnull(@gestdest,'')
	
	if @tip<>'TE'
		raiserror('Operatia poate genera doar un document de transfer! Pt factura sau aviz nefacturat va rog sa folositi "Generare factura"',11,1)
	    
	if @tip='TE' 
		if not exists (select 1 from pozcon p 
				inner join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert
			where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and 
					con.stare ='1' --and p.tert=@ftert and p.data=@fdata 
				and abs(p.Cantitate-p.Pret_promotional)>=0.001) -- Pret_promotional este refolosit pt. cant. transferata 
			raiserror('Comanda selectata nu are pozitii de transferat - nu se poate genera un document de transfer',16,1)
	else -- 'AP'
		if not exists (select 1 from pozcon p 
				inner join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert
			where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and con.stare in ('1','4') --and p.tert=@ftert and p.data=@fdata 
				and abs(p.Cantitate-p.cant_realizata)>=0.001) 
			raiserror('Comanda selectata nu are pozitii de facturat - nu se poate genera un aviz',16,1)

--/*startsp								
	declare @codstocinsuficient varchar(20), @stocinsuficient float, @msgErr nvarchar(2048)
			,@lRezStocBK bit, @cListaGestRezStocBK CHAR(200)
	EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

	select @msgErr=isnull(@msgErr+CHAR(13),'')+RTRIM(max(n.denumire))+' ('+RTRIM(p.Cod)+')'
			+', lipsa: '+ rtrim(CONVERT(decimal(10,2),MAX(p.Cantitate)-SUM(isnull(s.Stoc,0))))
	FROM pozcon p 
		inner join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert and c.Data=p.Data
		left join nomencl n on n.Cod=p.Cod
		left JOIN stocuri s 
			ON p.Subunitate=s.Subunitate and p.Cod=s.Cod and s.Stoc>=0.001
				and (s.Cod_gestiune=p.Factura and c.Stare='1' or s.Cod_gestiune=c.Cod_dobanda and c.Stare='4')
	WHERE p.Subunitate=@Sub and p.Tip='BK' and p.Contract=@fcontract and p.Data=@fdata and p.Tert=@ftert
		AND n.Tip<>'S'
		AND (s.Stoc is null 
			or s.Tip_gestiune NOT IN ('F','T') and (s.contract=p.contract 
				or s.contract<>p.contract 
					and (@lRezStocBK=0 or CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')<=0)))
	GROUP BY p.Cod
	having SUM(isnull(s.Stoc,0))<MAX(p.Cantitate)-max(p.Cant_realizata)
	
	if len(@msgErr)>0
	begin
		set @msgErr='Stoc insuficient la articolele: '++CHAR(13)+@msgErr	
		raiserror(@msgErr,16,1)
	end
	
	declare @valFactura float=0, @soldmaxim float, @sold float, @zileScadDepasite bit
	
	select	@valFactura = 
		sum(round(round(convert(decimal(17,5),p.pret*(1-p.discount/100)*(1-isnull(pe.pret,0)/100)*(1-isnull(pe.cantitate,0)/100))
		*(1+(p.cota_tva-case when isnull(gp.tip_gestiune,'') in ('A','V') then p.cota_tva else 0 end)/100),2)
		*(p.Cantitate-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end)),2))
	from pozcon p 
		left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
		left outer join gestiuni gp on gp.cod_gestiune = p.Punct_livrare
	where p.Subunitate=@sub and p.Tip='BK' and p.Contract=@fcontract and p.Data=@fdata and p.Tert=@ftert	 
	
	if @valFactura > 0.001
	begin
		declare @xml xml
		set @xml=(select @ftert tert for xml raw)
		exec wIaSoldTert @sesiune='', @parXML=@xml output
		
		-- procedura returneaza null daca nu trebuie validat soldul
		if @xml is not null
		begin 
			select	@sold=@xml.value('(/row/@sold)[1]','float'),
					@soldmaxim=@xml.value('(/row/@soldmaxim)[1]','float'),
					@zileScadDepasite= @xml.value('(/row/@zilescadentadepasite)[1]','bit')
			
			if @zileScadDepasite=1
				set @msgErr = isnull(@msgErr+CHAR(13),'')+'Tertul are facturi cu scadenta depasita.'
			
			if @xml.value('(/row/@soldmaxim)[1]','float') is not null and @sold+@valFactura>@soldmaxim
				set @msgErr = isnull(@msgErr+CHAR(13),'')+'Generarea facturii ar cauza depasirea soldului maxim pentru acest tert.'
					+CHAR(13)+ 'Soldul maxim permis este '+ CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'
					+CHAR(13)+ 'Soldul anterior este '+ CONVERT(varchar(30), convert(decimal(12,2), @sold)) + ' RON.'
					+CHAR(13)+ 'Valoarea pozitiei (modificarii) curente '+ CONVERT(varchar(30), convert(decimal(12,2), @valFactura)) + ' RON.'
			
			if len(@msgErr)>0
			begin
				raiserror(@msgErr,11,1)
			end
		end
	end
	
	if object_id('temdb..#expeditie') is not null
		drop table #expeditie
	
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='NUMEDELEGAT', Valoare=@numedelegat into #expeditie 
	where @numedelegat<>'' union all
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='SERIECI', Valoare=@serieCI where @serieCI<>'' union all
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='NUMARCI', Valoare=@numarCI where @numarCI<>'' union all
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='ELIBERATCI', Valoare=@eliberatCI where @eliberatCI<>'' union all
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='MRMIJTRANSP', Valoare=@nrmijtransp where @nrmijtransp<>'' union all
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='OBSERVATII', Valoare=@observatii where @observatii<>'' 
	
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
--stopsp*/
	
	if @numar=''
	begin 
		declare @fXML xml, @NrDocFisc varchar(10)--/*sp
			,@tipPentruNr varchar(2)--sp*/
		set @tipPentruNr=@tip 
		if @aviznefacturat=1
			set @tipPentruNr='AN' 
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"O"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocFisc output
		set @Numar=@NrDocFisc
	end
	if @tip='TE' -- anexadoc
	    if not exists (select 1 from anexadoc where Subunitate=@sub and tip=@tip and numar=@numar and Data=@datadoc)
			insert anexadoc
				(Subunitate, Tip, Numar, Data, Numele_delegatului, Seria_buletin, Numar_buletin, 
				Eliberat, Mijloc_de_transport, Numarul_mijlocului, Data_expedierii, Ora_expedierii, 
				Observatii, Punct_livrare, Tip_anexa)
			values (@sub, @tip, @numar, @datadoc, @numedelegat, @serieCI, @numarCI, @eliberatCI, 
				'', @nrmijtransp, '', '', @observatii, '', '')
		else--/*sp
			update anexadoc
			set Numele_delegatului=@numedelegat, Seria_buletin=@serieCI, Numar_buletin=@numarCI
				,Eliberat=@eliberatCI, Mijloc_de_transport='', Numarul_mijlocului=@nrmijtransp, Data_expedierii=@datadoc, Ora_expedierii='' 
				,Observatii=@observatii, Punct_livrare=''
			where Subunitate=@sub and Tip=@tip and Numar=@numar and Data=@datadoc and Tip_anexa='' --sp*/
	
	else -- 'AP': anexafac
	    if not exists (select 1 from anexafac where Subunitate=@sub and Numar_factura=@numar)
			insert anexafac
			(Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,
				Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii)
			values (@sub, @numar, @numedelegat, @serieCI, @numarCI, @eliberatCI, '', 
			        @nrmijtransp, @datadoc, '', @observatii)   
		else --/*sp
			update anexafac
			set Numele_delegatului=@numedelegat,Seria_buletin=@serieCI,Numar_buletin=@numarCI,Eliberat=@eliberatCI
				,Mijloc_de_transport='',Numarul_mijlocului=@nrmijtransp,Data_expedierii=@datadoc,Ora_expedierii='',Observatii=@observatii
			where Subunitate=@sub and Numar_factura=@numar --sp*/
	
	    select	@CategPret = isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' 
								and cod= (case when @tip='TE' then @GestPrim else @gestiune end)), 1)
				
	if @tip='TE' 
	begin			
		if ISNULL(@ftert,'')<>''
			if not exists (select 1 from comenzi c where c.Comanda=@ftert)
				insert comenzi (Subunitate,Tip_comanda,Comanda,Descriere,Beneficiar,Art_calc_benef,Comanda_beneficiar,Loc_de_munca_beneficiar
					,Data_inchiderii,Data_lansarii,Grup_de_comenzi,Loc_de_munca,Starea_comenzii,Numar_de_inventar,detalii)
				select top 1 t.Subunitate,'P',t.Tert,t.Denumire,t.Tert,'','',''
					,GETDATE(),GETDATE(),0,@lm,'L','',null from terti t where t.Tert=@ftert
		set @input=(select top 1	rtrim(@sub) as '@subunitate',@tip as '@tip', @numar as '@numar', convert(varchar(20),@datadoc,101) as '@data',
									@gestiune as '@gestiune', @GestPrim as '@gestprim', @GestDest as '@contract',
									@categpret as '@categpret', @lm as '@lm', @fcontract as '@factura',RTRIM(@ftert) as '@comanda',
					(select			rtrim(p.cod) as '@cod', rtrim(p.cantitate) as '@cantitate', 
									--isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and 
									--						um=@CategPret order by data_inferioara desc)),0) as '@pamanunt', 
									rtrim(convert(decimal(17,5),p.pret*(1+p.Cota_TVA/100) )) as '@pamanunt',
									con.valuta as '@valuta',convert(varchar(20),con.curs) as '@curs', @lm as '@lm'
--/*startsp
									,rtrim(convert(decimal(7,2),p.Discount)) as '@discount', RTRIM(p.Tert) as '@comanda'
									--, RTRIM(p.Tert) as '@locatie'
--stopsp*/									 
								from pozcon p 
								left outer join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert
								left outer join terti tr on tr.subunitate=p.subunitate and tr.tert=p.tert
								where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and (p.tert='' or p.tert=@ftert)and p.data=@fdata
								and abs(p.Cantitate-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end))>0.001
								order by --p.cant_aprobata-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end),p.Pret
								p.Numar_pozitie
							for xml PATH, TYPE)
							for XML PATH, type)
		exec wScriuPozdoc @sesiune,@input
	end	 
	else-- pt AP
	begin--/*sp
		declare @zilescadenta int=0
		select @zilescadenta=nullif(c.scadenta,0) from con c where c.Subunitate=@sub and c.tip='BK' and c.contract=@fcontract 
			and (c.tert='' or c.tert=@ftert )and c.data=@fdata
		if @zilescadenta is null 
			select @zilescadenta=convert(int, isnull(it.discount, 0)) 
			from terti t inner join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator='' 
			where t.Subunitate=@sub and t.tert=@ftert 
		set @zilescadenta=ISNULL(@zilescadenta,0)--sp*/
		set @input=(select top 1	rtrim(@sub) as '@subunitate',@tip as '@tip' ,@ftert as '@tert',/*sp*/@zilescadenta as '@zilescadenta',/*sp*/
						@numar as '@numar', convert(varchar(20),@datadoc,101) as '@data', @categpret as '@categpret',
						@LMdinBK as '@lm'
						,CASE @Stare when '1' then @gestiune when '4' then @GestPrim else @gestiune end as '@gestiune'
						,@fcontract as '@contract',--/*sp
						@aviznefacturat as '@aviznefacturat', --sp*/
						(select rtrim(convert(decimal(17,5),p.pret)) as '@pvaluta', con.valuta as '@valuta',convert(varchar(20),con.curs) as '@curs',
							--convert(varchar(20),p.suma_tva) as '@sumatva', 
							@LMdinBK as '@lm',
							--isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and 
							--									um=@CategPret order by data_inferioara desc)),0) as '@pamanunt',
							rtrim(p.cod) as '@cod', rtrim(p.cantitate) as '@cantitate',@fcontract as '@contract'
	--/*startsp						
							,p.Discount as '@discount'--, RTRIM(p.Tert) as '@comanda'
--stopsp*/
					from pozcon p 
						left outer join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert
						left outer join terti tr on tr.subunitate=p.subunitate and tr.tert=p.tert
						where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and (p.tert='' or p.tert=@ftert )and p.data=@fdata
							and abs(p.Cantitate-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end))>=0.001
					order by --p.cant_aprobata-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end),p.Pret
					p.Numar_pozitie
					for xml PATH, TYPE)
				for XML PATH, type)
		exec wScriuPozdoc @sesiune,@input
	end			
	declare @nrPozBK int, @nrPozAPsauTE int
	select @nrPozBK=isnull((select count(distinct p.Cod) from pozcon p 
						left outer join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert
						left outer join terti tr on tr.subunitate=p.subunitate and tr.tert=p.tert
					where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and (p.tert='' or p.tert=@ftert )and p.data=@fdata),0),
						
			@nrPozAPsauTE=(select count(distinct cod) from pozdoc where subunitate = @sub and tip = @tip and numar = @numar and 
								data = @datadoc and (tert = @ftert or @ftert=''))
	/*startsp*/
	if @tip='AP'
		exec ProcGenAPBK 'AP',@numar,@datadoc
	/*stopsp*/
	if @faraMesaje!=1
	begin
		if @nrPozAPsauTE=0 -- n-a generat nici o pozitie 
			select 'Nu s-a generat document! Stoc indisponibil!' as textMesaj for xml raw, root('Mesaje')
		else
			if @nrPozAPsauTE=@nrPozBK 
				select 'S-a generat cu succes documentul de tip '+rtrim(case when @tip='TE' then 'TE' else 'AP' end)+' cu numarul '+rtrim(@numar)+' din data de  '+ltrim(convert(varchar(20),@datadoc,103)) as textMesaj for xml raw, root('Mesaje')
			else if @nrPozAPsauTE<@nrPozBK
					select 'S-a generat partial documentul de tip ' +rtrim(case when @tip='TE' then 'TE' else 'AP' end)+ ' cu numarul '+rtrim(@numar)+' din data de  '+ltrim(convert(varchar(20),@datadoc,103)) as textMesaj for xml raw, root('Mesaje')
			
    end
end try 
begin catch 
	set @eroare='(yso_wOPGenTEsauAPdinBK):'+ERROR_MESSAGE() 
		raiserror(@eroare, 16, 1)
end catch 

GO
