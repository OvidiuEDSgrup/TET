--***
create procedure wOPGenerareFacturiPenDobFinale @sesiune varchar(50), @parXML xml 
as     
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareFacturiPenDobFinaleSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenerareFacturiPenDobFinaleSP @sesiune, @parXML output
	return @returnValue
end

declare @mesaj varchar(500),@tert varchar(13),@contract varchar(20),@tip_penalizare varchar(2),@data_penalizare_jos datetime,@tip_generare int,
	@utilizator varchar(20),@sub varchar(9),@NrAvizeUnitar int,@tip_pen_gen varchar(1),@gen_dob int,@gen_pen int,@data_facturare datetime,
	@formular varchar(13),@inXML varchar(1),@primulnumar varchar(13),@iteratie int,@genFormular int,@data_penalizare_sus datetime,
	@data_scadentei datetime,@termenscadenta int,@observatii varchar(250),@formularAnexa varchar(13)
begin try		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''
	select 
		@tert=upper(ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), '')),
		@contract=upper(ISNULL(@parXML.value('(/parametri/@contract)[1]', 'varchar(20)'), '')),
		@observatii=ISNULL(@parXML.value('(/parametri/@observatii)[1]', 'varchar(250)'), ''),
		@data_penalizare_jos = isnull(@parXML.value('(/parametri/@data_penalizare_jos)[1]','datetime'),'1901-01-01'),
		@data_penalizare_sus = isnull(@parXML.value('(/parametri/@data_penalizare_sus)[1]','datetime'),'2901-01-01'),
		@data_facturare = isnull(@parXML.value('(/parametri/@data_facturare)[1]','datetime'),'1901-01-01'),
		@data_scadentei = isnull(@parXML.value('(/parametri/@data_scadentei)[1]','datetime'),'1901-01-01'),
		@gen_dob=ISNULL(@parXML.value('(/parametri/@gen_dob)[1]', 'int'), '0'),
		@gen_pen=ISNULL(@parXML.value('(/parametri/@gen_pen)[1]', 'int'), '0'),
		@formular = isnull(@parXML.value('(/parametri/@formular)[1]','varchar(13)'),''),
		@formularAnexa = isnull(@parXML.value('(/parametri/@formularAnexa)[1]','varchar(13)'),''),
		@genFormular = isnull(@parXML.value('(/parametri/@genFormular)[1]','int'),''),
		@tip_generare=ISNULL(@parXML.value('(/parametri/@tip_generare)[1]', 'int'), 0)
			-- 0-> generare facturi de penalitati si dobanzi separat
			-- 1-> generare pe penalitati si dobanzi pe o singura factura
			-- 2-> generare penalitati si dobanzi pe factura de servicii ->nu este tratata inca
		--@tip_pen_gen=ISNULL(@parXML.value('(/parametri/@tip_pen_gen)[1]', 'varchar(1)'), '')
			
	set @tip_pen_gen =case when @gen_dob=1 and @gen_pen=1 then '' else case when @gen_dob=1 and @gen_pen=0 then 'D' else 
		case when @gen_dob=0 and @gen_pen=1 then 'P' else 'X' end end end
	
--select @tert,@contract,@data_penalizare_jos,@data_penalizare_sus,@data_facturare,@gen_dob,@gen_pen,@tip_generare
	
	
	declare @coddob varchar(20),@cont_fact_penalizdob varchar(20),@indbugdob varchar(20),@cont_de_stocdob varchar(20)
	exec luare_date_par 'UC', 'CODDOB', 0, 0, @coddob output
	if ISNULL(@coddob,'')=''
		raiserror('Pentru generarea facturilor de dobanzi este necesara setarea codului de nomenclator corespunzator!(par->UC,CODDOB)',11,1)	

	exec luare_date_par 'UC', 'CONTDOB', 0, 0, @cont_fact_penalizdob output
	if ISNULL(@cont_fact_penalizdob,'')=''
		raiserror('Pentru generarea facturilor de dobanzi este necesara setarea contului de tert corespunzator!(par->UC,CONTDOB)',11,1)	
		
	exec luare_date_par 'UC', 'INDBUGDOB', 0, 0, @indbugdob output
	if ISNULL(@indbugdob,'')=''
		set @indbugdob='1 0 0133205001'
			
	--set @cont_de_stocdob=isnull((select max(cont) from nomencl where cod=@coddob), '70851')
	
	declare @codpen varchar(20),@cont_fact_penalizpen varchar(20),@indbugpen varchar(20),@cont_de_stocpen varchar(20)
		exec luare_date_par 'UC', 'CODPEN', 0, 0, @codpen output
	if ISNULL(@codpen,'')=''
		raiserror('Pentru generarea facturilor de penalitati este necesara setarea codului de nomenclator corespunzator!(par->UC,CODPEN)',11,1)		

	exec luare_date_par 'UC', 'CONTPEN', 0, 0, @cont_fact_penalizpen output
	if ISNULL(@cont_fact_penalizpen,'')=''
		raiserror('Pentru generarea facturilor de penalitati este necesara setarea contului de tert corespunzator!(par->UC,CONTPEN)',11,1) 
		
	exec luare_date_par 'UC', 'INDBUGPEN', 0, 0, @indbugpen output
	if ISNULL(@indbugpen,'')=''
		set @indbugpen='1 0 0133205001'
			
	--set @cont_de_stocpen=isnull((select max(cont) from nomencl where cod=@codpen), '70851')
	
	declare @contractC varchar(20),@tertC varchar(13),@lmC varchar(13),@tip_penC varchar(1),@punct_livrareC varchar(13)
	set @iteratie=0
	declare facturi_crs cursor for	
	select rtrim(p.tert),rtrim(isnull(p.punct_livrare,'')),rtrim(p.loc_de_munca),(case when @tip_generare=0 then p.tip_penalizare else convert(varchar,p.valid) end)
	from penalizarifact p			
	where (p.Tert=@tert or ISNULL(@tert,'')='')
	    and p.valid=1
	    and p.Stare<>'F'
		and (p.Contract_coresp= @contract or ISNULL(@contract,'')='')
		and (p.tip_penalizare= @tip_pen_gen or ISNULL(@tip_pen_gen,'')='')
		and (p.Data_penalizare between @data_penalizare_jos and @data_penalizare_sus) 		
	group by p.Tert,/*p.Contract_coresp*/p.punct_livrare,p.Loc_de_munca,(case when @tip_generare=0 then p.tip_penalizare else convert(varchar,p.valid) end)	
		
	open facturi_crs
	fetch next from facturi_crs into @tertC,@punct_livrareC,@lmC,@tip_penC 			
		
	while @@fetch_status = 0
	begin
		--luare numar din plaja de as 
		declare @numar varchar(20),@factura varchar(20)
		declare @NrDocFisc int, @fXML xml, @tipPentruNr varchar(2)
		set @tipPentruNr='AS' 
		
		if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP')
		begin	
			declare @inputSP XMl
				set @inputSP=
					(select top 1 rtrim(@sub) as '@subunitate','AS' as '@tip', rtrim(@lmC) as '@lm' for xml Path,type)
				exec wScriuPozdocSP @sesiune, @inputSP output	
				
			set @numar=isnull(@inputSP.value('(/row/@numar)[1]', 'varchar(8)'),'')
			set @factura=isnull(@inputSP.value('(/row/@factura)[1]', 'varchar(20)'),'')		
		end
		else
			if isnull(@numar,'')=''
			begin
				if @NrAvizeUnitar=1
					set @tipPentruNr='AP' 
				set @fXML = '<row/>'
				set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
				set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
				set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
				set @fXML.modify ('insert attribute lm {sql:variable("@lmC")} into (/row)[1]')
				--set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
				
				exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
				
				if ISNULL(@NrDocFisc, 0)<>0
				begin
					set @numar=LTrim(RTrim(CONVERT(char(8), @NrDocFisc)))
					set @factura=@numar
				end
				if isnull(@numar,'')='' 
					raiserror('Pe acest tip de document(AS) nu au fost definite plaje de numere!! ',11,1)
			end
		
		set @iteratie=@iteratie+1	
		
		if @iteratie=1
			set @primulnumar=@numar
				
		if @data_scadentei=@data_facturare
		begin  
			set @termenscadenta=isnull((select discount from infotert where subunitate=@sub and tert=@tert and Identificator=''),0)  
			set @data_scadentei=DATEADD(d,@termenscadenta,@data_facturare)  
		end 
				
		declare @input XMl	
		set @input=(select top 1 rtrim(@sub) as '@subunitate','AS' as '@tip',convert(char(10),@data_facturare,101) as '@data',
					/*@contractC as '@contract',*/ @tertC as '@tert', @lmC as '@lm'	,@tip_penC as '@tip_penC',@numar as '@numar',
					@factura as '@factura',	ISNULL(@punct_livrareC,'') as '@punctlivrare', convert(char(10),@data_scadentei,101) as '@datascadentei',
				
				(select case when r.tip_penalizare='P' then rtrim(@codpen) else rtrim(@coddob) end as '@cod',
					1 as '@cantitate',
					CONVERT(decimal(17,3),sum(r.Suma_penalizare)) as '@pvaluta',@factura as '@factura',
					CONVERT(decimal(17,3),sum(r.Suma_penalizare)) as '@pvanzare',
					CONVERT(decimal(17,3),sum(r.Suma_penalizare)) as '@pamanunt','APBK' as '@codintrare',
					isnull((select max(rtrim(cont)) from nomencl where cod=(case when r.tip_penalizare='P' then rtrim(@codpen) else rtrim(@coddob) end)), '7086') as '@contstoc',
					(case when r.tip_penalizare='P' then rtrim(@cont_fact_penalizpen) else rtrim(@cont_fact_penalizdob) end) as '@contcorespondent', 
					r.Loc_de_munca as '@lm',(case when r.tip_penalizare='P' then 'Penalitati' else 'Dobanzi' end) as '@barcod',
					(case when r.tip_penalizare='P' then rtrim(@cont_fact_penalizpen) else rtrim(@cont_fact_penalizdob) end) as '@contfactura',
					ISNULL(@punct_livrareC,'') as '@punctlivrare'
					
				from penalizarifact r	
				where r.Tert=@tertC
					and r.punct_livrare= @punct_livrareC 
					and (r.Data_penalizare between @data_penalizare_jos and @data_penalizare_sus)
					and (r.tip_penalizare=@tip_penC or @tip_generare<>0)
					and (r.tip_penalizare=@tip_pen_gen or @tip_pen_gen='')
					and r.loc_de_munca=@lmC
					and r.valid=1
					and r.Stare<>'F'
				group by r.Tert,/*r.Contract_coresp*/r.punct_livrare,r.Loc_de_munca,r.tip_penalizare
				for XML path,type)
				
			for xml Path,type)
		 
		--select CONVERT(varchar(max),@input)
		exec wScriuPozdoc @sesiune,@input
		
		update penalizarifact set stare='F',-- au fost facturate
			factura_generata=@factura, data_factura_generata=@data_facturare
		where (tip_penalizare=@tip_penC or @tip_generare<>0)
			and (tip_penalizare=@tip_pen_gen or @tip_pen_gen='')
			and tert=@tertC
			and loc_de_munca=@lmC
			and punct_livrare= @punct_livrareC 
			and (Data_penalizare between @data_penalizare_jos and @data_penalizare_sus)
			and stare<>'F'
			and valid=1
			and ISNULL(factura_generata,'')=''
		
		--scriere in anexadoc	
		delete anexadoc where Numar=@numar and data=@data_facturare  
		insert into anexadoc   
			(Subunitate,Tip,Numar,Data,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,Numarul_mijlocului,
			Data_expedierii,Ora_expedierii,Observatii,Punct_livrare,Tip_anexa)
		select @sub,'AS',@numar,@data_facturare,'','','','','','',  
			@data_facturare,'',@observatii,@punct_livrareC,1	
			
		--scriere in anexafac
		delete anexafac where Numar_factura=@factura   
		insert into anexafac  
			(Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,Numarul_mijlocului,
			Data_expedierii,Ora_expedierii,Observatii)
		select @sub,@factura,'','','','','','',  
			@data_facturare,'',@observatii
			
		if isnull(@numar,'')<>'' and ISNULL(@formular,'')<>'' and @genFormular=1
		begin
			delete from avnefac where terminal=@utilizator
			insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul, 
				Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22, 
				Cont_beneficiar,Discount) 
			values (@utilizator,'1','AS',@numar,'',@data_facturare,@tert,@numar,'', 
				getdate(),'','','','',0,0,0,0,0,'',0) 
		
			declare @p2 xml,@paramXmlString varchar(max)
			set @paramXmlString= 
			(select 'AS' as tip, @formular as nrform,@tert as tert, rtrim(@numar) as numar, rtrim(@factura) as factura, @data_facturare as data, 
				@inXML as inXML,0 as scriuavnefac, 'AS'+rtrim(@numar)+'Factura' as numefisier for xml raw )
			exec wTipFormular @sesiune, @paramXmlString
			
			if ISNULL(@formularAnexa,'')<>''
				set @paramXmlString= 
					(select 'AS' as tip, @formularAnexa as nrform, @tert as tert, rtrim(@numar) as numar, rtrim(@factura) as factura, @data_facturare as data, 
						@inXML as inXML,0 as scriuavnefac, 'AS'+rtrim(@numar)+'Anexa' as numefisier for xml raw )
				exec wTipFormular @sesiune, @paramXmlString
		end		
		
		fetch next from facturi_crs into @tertC,@punct_livrareC,@lmC,@tip_penC 			
	end
	
	declare @mesrap varchar(250)
	if @numar=@primulnumar and isnull(@numar,'')<>''
	begin 
		--select 'S-a generat factura cu numarul '+ rtrim(@factura)+'!!' as textMesaj for xml raw, root('Mesaje')
		set @mesrap='S-a generat factura cu numarul '+ rtrim(@factura)+'!!'
	end	
	else
		if @numar<>@primulnumar and isnull(@numar,'')<>'' and isnull(@primulnumar,'')<>''
		begin
			--select 'Generarea a fost efectuata cu succes. Au fost generate '+ convert(varchar,@iteratie)+' facturi ('+@primulnumar+' - '+@numar+')!!' as textMesaj for xml raw, root('Mesaje')
			set @mesrap='Generarea a fost efectuata cu succes. Au fost generate '+ convert(varchar,@iteratie)+' facturi ('+@primulnumar+' - '+@numar+')!!'
		end	
		else		
		begin
			--select 'Verificati penalitatile/dobanzile, Nu au fost generate facturi!!' as textMesaj for xml raw, root('Mesaje')	
			set @mesrap='Verificati penalitatile/dobanzile, Nu au fost generate facturi!!'
		end	
	
	if ISNULL(@mesrap,'')<>''
	begin
		select @mesrap as mesaj--sa trimita mesaj in raport
		select @mesrap as textMesaj for xml raw, root('Mesaje')-- sa trimita mesaj in frame
	end	
	
	begin try 
		close facturi_crs 
	end try 
	begin catch end catch
	begin try 
		deallocate facturi_crs 
	end try 
	begin catch end catch	
	
end try
begin catch
	set @mesaj='wOPGenerareFacturiPenDobFinale: '+ERROR_MESSAGE()
end catch
declare @cursorStatus int
set @cursorStatus=(select max(convert(int,is_open)) from sys.dm_exec_cursors(0) where name='facturi_crs' and session_id=@@SPID )
if @cursorStatus=1
	close facturi_crs
if @cursorStatus is not null
	deallocate facturi_crs
if LEN(@mesaj)>0
begin
	select @mesaj as mesaj
	raiserror(@mesaj, 11, 1)
end	
--select * from pozdoc where tip='TE' order by data desc

--parametrii necesari facturare penalitati
/*
insert into par select 'UC','CODDOB','Cod de facturare dobanzi',0,0,'1001001972'
insert into par select 'UC','CODPEN','Cod de facturare penalitati',0,0,'1001001971'

insert into par select 'UC','CONTDOB','Cont terti facturare dobanzi',0,0,'4111'
insert into par select 'UC','CONTPEN','Cont terti facturare pen',0,0,'4111'

alter table penalizarifact
add punct_livrare varchar(13)
*/
