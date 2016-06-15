
/* descriere... */
CREATE procedure [dbo].[wOPModificareAntetDoc] @sesiune varchar(50), @parXML xml
as     
begin
		
	declare @tip char(2), @numar varchar(20),@o_numar varchar(20), @data datetime, @o_data datetime, @gestiune varchar(9), @o_gestiune varchar(9),
		@gestiune_primitoare char(13), @tert varchar(13), @o_tert varchar(13), @factura varchar(20), @o_factura varchar(20), @data_facturii datetime, @tiptert int, @o_tiptert int, 
		@data_scadentei datetime, @o_data_scadentei datetime, @lm varchar(9), @o_lm varchar(9), @indbug varchar(20),@o_indbug varchar(20),@o_explicatii char(25),
		@cota_TVA float,@tipTVA int,@o_tipTVA int, @comanda char(20),@o_comanda char(20), @cont_de_stoc varchar(40),@o_cont_de_stoc varchar(40),@o_valuta char(3), @o_curs float,@o_data_facturii datetime,
		@valuta char(3), @curs float, @contract varchar(20),@o_contract varchar(20),@n_numar varchar(20),@n_tert varchar(13),@n_data datetime,@n_tip varchar(2),
		@explicatii char(25), @cont_factura varchar(40), @o_cont_factura varchar(40),@discount float,  @o_discount float,@punct_livrare char(5), @o_punct_livrare char(5), 
		@numardvi varchar(30), @o_numardvi varchar(30), 
		@cont_corespondent varchar(40),@categpret int,@o_categpret int,@cont_venituri varchar(40), @TVAnx float, @jurnalProprietate varchar(3),
		@sub char(9),@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20),
		@categPretProprietate varchar(20), @stare int,	@eroare xml, @mesaj varchar(254), @Bugetari int,@NrAvizeUnitar int,
		@sql_doc nvarchar(max),@sql_update_doc nvarchar(max),@sql_where_doc nvarchar(max),@sql nvarchar(max),@o_gestiune_primitoare varchar(13),
		@jurnal char(3),@o_jurnal char(3), @detalii XML, 
		@cont_TVA varchar(40), --Utilizat pentru inceput la DRDP Cluj pentru a completa un alt cont de TVA pe document (in pozdoc.detalii).
		@sql_pozdoc nvarchar(max),@sql_update_pozdoc nvarchar(max),@sql_where_pozdoc nvarchar(max), 
		@sql_dvi nvarchar(max),@sql_update_dvi nvarchar(max),@sql_where_dvi nvarchar(max), @tip_doc varchar(2)
	             
	begin try
	begin tran
		if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareAntetDocSP')
			exec wOPModificareAntetDocSP @sesiune=@sesiune, @parXML=@parXML output

		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
		exec luare_date_par 'GE','SUBPRO',0,0,@sub output
		exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
		
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		
		select 
			@tip= tip, 
			@numar=numar, @o_numar=o_numar,
			@data =data, @o_data =o_data,
			@gestiune=gestiune ,@o_gestiune=o_gestiune ,
			@gestiune_primitoare=gestiune_primitoare_antet ,@o_gestiune_primitoare=o_gestiune_primitoare_antet, 
			@tert=tert,@o_tert=o_tert, 
			@factura=factura, @o_factura=o_factura,
			@data_facturii=datafact,@o_data_facturii=o_datafact,
			@data_scadentei=datascad,@o_data_scadentei=o_datascad,  
			@lm=lm, @o_lm=o_lm,
			@tipTVA=tip_TVA, @o_tipTVA=o_tip_TVA, 
			@comanda=comanda, @o_comanda=o_comanda,
			@indbug=indbug, @o_indbug=o_indbug,
			@valuta=valuta, @o_valuta=o_valuta, 
			@curs=curs, @o_curs=o_curs, 
			@contract=contract , @o_contract=o_contract , 
			@explicatii=explicatii, @o_explicatii=o_explicatii, 
			@cont_factura=cont_factura,@o_cont_factura=o_cont_factura,
			@cont_de_stoc=cont_de_stoc,@o_cont_de_stoc=o_cont_de_stoc,
			@discount=discount, @o_discount=o_discount, 
			@punct_livrare=punct_livrare_antet, @o_punct_livrare=o_punct_livrare_antet,
			@numardvi=numardvi, @o_numardvi=o_numardvi,
			@cont_corespondent=cont_corespondent_antet, 
			@categpret=categpret, @o_categpret=o_categpret, 
			@cont_venituri=cont_venituri_antet, 
			@TVAnx=tva_neexigibil_antet,
			@n_numar =n_numar,
			@n_tert= n_tert,
			@n_data= n_data,
			@n_tip= n_tip
			,@jurnal=jurnal
			,@o_jurnal=o_jurnal
			,@detalii=detalii
			,@cont_TVA=cont_TVA
		 
		from OPENXML(@iDoc, '/parametri')
		WITH 
		(
			tip char(2) '@tip', 
			numar varchar(20) '@numar',o_numar varchar(20) '@o_numar',
			tert varchar(13) '@tert',o_tert varchar(13) '@o_tert',
			gestiune varchar(9) '@gestiune',o_gestiune varchar(9) '@o_gestiune',
			data datetime '@data',o_data datetime '@o_data',
			factura varchar(20) '@factura',o_factura varchar(20) '@o_factura',
			contract varchar(20) '@contract',o_contract varchar(20) '@o_contract', 
			lm varchar(9) '@lm',o_lm varchar(9) '@o_lm',
			comanda char(20) '@comanda',o_comanda char(20) '@o_comanda',
			indbug char(20) '@indbug', o_indbug char(20) '@o_indbug', 
			categpret char(5) '@categpret',o_categpret char(5) '@o_categpret',
			explicatii varchar(30) '@explicatii', o_explicatii varchar(30) '@o_explicatii', 
			valuta char(3) '@valuta',o_valuta char(3) '@o_valuta',
			curs float '@curs',o_curs float '@o_curs',
			discount float '@discount',o_discount float '@o_discount',
			cont_factura varchar(40) '@contfactura', o_cont_factura varchar(40) '@o_contfactura', 
			datafact datetime '@datafacturii',o_datafact datetime '@o_datafacturii',
			datascad datetime '@datascadentei',o_datascad datetime '@o_datascadentei',
			cont_de_stoc varchar(40) '@cont_stoc',  o_cont_de_stoc varchar(40) '@o_cont_stoc',  
			
			gestiune_primitoare_antet char(13) '@gestprim',	o_gestiune_primitoare_antet char(13) '@o_gestprim',
			cont_corespondent_antet varchar(40) '@contcorespondent', 
			cont_venituri_antet varchar(40) '@contvenituri', 
			
			punct_livrare_antet char(5) '@punctlivrare',
			o_punct_livrare_antet char(5) '@o_punctlivrare',
			numardvi varchar(30) '@numardvi',o_numardvi varchar(30) '@o_numardvi',
			tva_neexigibil_antet float '@tvaneexigibil',
			
			nume_delegat char(30) '@numedelegat', 
			serie_buletin char(10) '@seriabuletin', 
			numar_buletin char(10) '@numarbuletin', 
			eliberat_buletin char(30) '@eliberat', 
			mijloc_transport char(30) '@mijloctp', 
			nr_mijloc_transport char(20) '@nrmijloctp', 
			data_expedierii datetime '@dataexpedierii', 
			ora_expedierii char(6) '@oraexpedierii', 
			observatii char(200) '@observatii', 
			punct_livrare_expeditie char(5) '@punctlivrareexped', 
			tip_TVA int '@tiptva', 	o_tip_TVA int '@o_tiptva',	
			
			n_numar varchar(20)'@n_numar',
			n_tert varchar(13)'@n_tert',
			n_data datetime '@n_data',
			n_tip varchar(2) '@n_tip'
			,jurnal char(3) '@jurnal'
			,o_jurnal char(3) '@o_jurnal'
			,detalii xml 'detalii/row'
			,cont_TVA varchar(40) 'detalii/row/@cont_tva'
		)
		exec sp_xml_removedocument @iDoc 

		/* Variabila folosita pt. filtrarea tipului de document in tabelele doc/pozdoc, pentru ca sa nu facem multe case-uri */
		select @tip_doc=(case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)

		if not exists (select 1 from gestiuni where Cod_gestiune=@gestiune) and isnull(@gestiune,'')<>''
			raiserror('Gestiunea introdusa nu exista in baza de date!!',11,1)
		if not exists (select cod from lm where cod=@lm) and isnull(@lm ,'')<>''
			raiserror('Locul de munca introdus nu exista in baza de date!!',11,1)	
		if not exists (select 1 from indbug where indbug=@indbug) and isnull(@indbug,'')<>'' and @Bugetari=1
			raiserror('Indicatorul bugetar introdus nu exista in baza de date!!',11,1)
		if not exists (select 1 from terti where tert=@tert) and isnull(@tert,'')<>'' and @tip_doc not in ('TE','AI','AE')
			raiserror('Tertul introdus nu exista in baza de date!!',11,1)
		if not exists (select 1 from conturi where cont=@cont_factura) and isnull(@cont_factura,'')<>'' and @tip_doc not in ('TE') --or not exists (select 1 from conturi where cont=@cont_stoc)
			raiserror('Contul introdus nu exista in baza de date!!',11,1)
		if @o_numardvi<>'' and @numardvi=''
			raiserror('Receptia este cu DVI. Numar DVI nu poate fi necompletat!',11,1)	

		/*	Pentru receptii cu DVI, trebuie verificat daca s-a schimbat tertul de pe receptie (se trece de pe un tert extern pe unul intern).*/
		if @tip='RM' and @numardvi<>'' and @tert<>@o_tert
		begin
			select @tiptert=zile_inc from infotert where subunitate=@sub and tert=@tert and identificator=''
			select @o_tiptert=zile_inc from infotert where subunitate=@sub and tert=@o_tert and identificator=''

			if @tiptert=0 and @tiptert<>@o_tiptert 
			begin
				if exists (select 1 from dvi where Subunitate=@sub and Numar_DVI=(case when @numardvi<>@o_numardvi and isnull(@numardvi,'')<>'' then @o_numardvi else @numardvi end) 
						and Data_receptiei=@data and Numar_receptie=@numar and (Valoare_CIF<>0 or Suma_vama<>0 or TVA_22<>0))
					raiserror ('Aceasta receptie este cu DVI. S-a incercat completarea unui tert intern pe aceasta receptie. Completati valori 0 pe DVI si apoi modificati tertul!',11,1)
				else 
				begin
					delete from dvi 
					where Subunitate=@sub and Numar_DVI=(case when @numardvi<>@o_numardvi and isnull(@numardvi,'')<>'' then @o_numardvi else @numardvi end) and Data_receptiei=@data and Numar_receptie=@numar
					select 'S-a sters DVI-ul asociat acestei receptii!' as textMesaj, 'Modificare antet' as titluMesaj 
					for xml raw, root('Mesaje')
				end
			end
		end
		
		if (@numar<>@o_numar and isnull(@numar,'')<>'' and ISNULL(@o_numar,'')<>'')
			or (@data<>@o_data and isnull(@data,'')<>'' and ISNULL(@o_data,'')<>'')
			update pozdoc 
			set numar=@numar, data=@data
			where subunitate=@sub 
				and tip='RP' 
				and Numar=@o_numar and data=@o_data

		set @sql_update_doc='Subunitate=@sub'+char(13)+
			--(case when @numar<>@o_numar then ',Numar=@numar'+char(13) else '' end)+
			(case when @tert<>@o_tert then ',Cod_tert=@tert'+char(13) else '' end)+
			(case when @gestiune<>@o_gestiune then ',Cod_gestiune=@gestiune'+char(13) else '' end)+
			--(case when @data<>@o_data then ',Data=@data'+char(13) else '' end)+
			(case when @factura<>@o_factura then ',Factura=@factura'+char(13) else '' end)+
			(case when @contract<>@o_contract then ',Contractul=@contract'+char(13) else '' end)+
			(case when @lm<>@o_lm then ',Loc_munca=@lm'+char(13) else '' end)+
			(case when @comanda<>@o_comanda then ',Comanda=convert(char(20),@comanda)+substring(Comanda,21,20)'+char(13) else '' end)+
			(case when @indbug<>@o_indbug then ',Comanda=left(Comanda,20)+convert(char(20),@indbug)'+char(13) else '' end)+
			(case when @tip_doc in ('AP', 'AS', 'AC', 'TE') and @categpret<>@o_categpret then ',Discount_suma=@categpret'+char(13) else '' end)+
			(case when @tip_doc in ('AP','AS','RS') and @explicatii<>@o_explicatii then ',Numar_DVI=@explicatii'+char(13) else '' end)+
			(case when @valuta<>@o_valuta then ',Valuta=@valuta'+char(13) else '' end)+
			(case when @curs<>@o_curs then ',Curs=@curs'+char(13) else '' end)+
			(case when @discount<>@o_discount then ',Discount_p=@discount'+char(13) else '' end)+
			(case when @cont_factura<>@o_cont_factura then ',Cont_factura=@cont_factura'+char(13) else '' end)+
			(case when @data_facturii<>@o_data_facturii then ',Data_facturii=@data_facturii'+char(13) else '' end)+
			(case when @data_scadentei<>@o_data_scadentei then ',Data_scadentei=@data_scadentei'+char(13) else '' end)+
			--(case when @numar<>@o_numar or @data<>@o_data then ',Valoare=0'+char(13) else '' end)+
			--(case when @numar<>@o_numar or @data<>@o_data then ',Tva_22=0'+char(13) else '' end)
			(case when (@gestiune_primitoare<>@o_gestiune_primitoare OR @punct_livrare <> @o_punct_livrare) and @tip_doc in ('AP','AS','RM','RS') 
				then ',Gestiune_primitoare=@punct_livrare' when @tip='TE' then ',Gestiune_primitoare=@gestiune_primitoare'+char(13) else '' end)
			+(case when @tip_doc='RM' and @numardvi<>@o_numardvi and isnull(@numardvi,'')<>'' then ',Numar_DVI=@numardvi'+char(13) else '' end)
			+(case when @jurnal<>@o_jurnal then ',jurnal=@jurnal' else '' end)
			+(case when @tipTVA<>@o_tipTVA then ',Cota_TVA=@tipTVA' else '' end)
			+ ',detalii=@detalii'
		set @sql_where_doc='WHERE Subunitate=@sub and tip=@tip_doc and numar=@numar and data=@data'+ case when @tip='RC' then ' and jurnal=''RC''' else '' end
		set @sql_doc=case when @sql_update_doc<>'' then 'UPDATE doc SET '+@sql_update_doc+' '+@sql_where_doc else '' end		


		set @sql_update_pozdoc='Subunitate=@sub'+char(13)+	 
			(case when @numar<>@o_numar then ',Numar=@numar'+char(13) else '' end)+
			(case when @tert<>@o_tert then ',Tert=@tert'+char(13) else '' end)+
			(case when @gestiune<>@o_gestiune then ',Gestiune=@gestiune'+char(13) else '' end)+
			(case when @data<>@o_data then ',Data=@data'+char(13) else '' end)+
			(case when @factura<>@o_factura then ',Factura=@factura'+char(13) else '' end)+
			(case when @contract<>@o_contract then ',Contract=@contract'+char(13) else '' end)+
			(case when @lm<>@o_lm then ',Loc_de_munca=@lm'+char(13) else '' end)+
			(case when @comanda<>@o_comanda then ',Comanda=convert(char(20),@comanda)+substring(Comanda,21,20)'+char(13) else '' end)+
			(case when @indbug<>@o_indbug then ',Comanda=left(Comanda,20)+convert(char(20),@indbug)'+char(13) else '' end)+
			(case when @tip_doc in ('AP', 'AS', 'AC', 'TE') and @categpret<>@o_categpret then ',Accize_cumparare=@categpret'+char(13) else '' end)+		
			(case when @valuta<>@o_valuta then ',Valuta=@valuta'+char(13) else '' end)+
			(case when @curs<>@o_curs then ',Curs=@curs, pret_vanzare=round(pret_valuta*@curs*(1-discount/100),5), tva_deductibil=round(round(cantitate*pret_valuta*(1-discount/100)*cota_tva/100.0,2)*@curs,2)'+char(13) else '' end)+
			(case when @discount<>@o_discount then ',Discount=@discount, pret_vanzare=round(pret_valuta*(1-'+convert(varchar(10), convert(decimal(15,2),@discount))+'/100),5), 
				tva_deductibil=round(round(cantitate*pret_valuta*(1-'+convert(varchar(10), convert(decimal(15,2),@discount))+'/100)*cota_tva/100.0,2),2)'+char(13) else '' end)+
			(case when @data_facturii<>@o_data_facturii then ',Data_facturii=@data_facturii'+char(13) else '' end)+
			(case when @data_scadentei<>@o_data_scadentei then ',Data_scadentei=@data_scadentei'+char(13) else '' end)+	
			(case when @tip_doc in ('AP', 'AS', 'AC') then ',Numar_DVI=rtrim(LEFT(Numar_DVI,13))+space(13-len(rtrim(LEFT(Numar_DVI,13))))+@punct_livrare'+char(13) else '' end)+
			(case when @cont_de_stoc<>@o_cont_de_stoc then ',Cont_de_stoc=@cont_de_stoc'+char(13) else '' end)+	
			(case when @cont_factura<>@o_cont_factura then ',Cont_factura=@cont_factura'+char(13) else '' end)+
			(case when @gestiune_primitoare<>@o_gestiune_primitoare and @tip_doc in ('TE') then ',Gestiune_primitoare=@gestiune_primitoare'+char(13) else '' end)
			+(case when @tip_doc='RM' and @numardvi<>@o_numardvi and isnull(@numardvi,'')<>'' then ',Numar_DVI=@numardvi'+char(13) else '' end)
			+(case when @jurnal<>@o_jurnal then ',jurnal=@jurnal' else '' end)
			+(case when @tipTVA<>@o_tipTVA then ',Procent_vama=@tipTVA' else '' end)
		
		set @sql_where_pozdoc='WHERE Subunitate=@sub and tip=@tip_doc and numar=@o_numar /* de ce? and tert=@o_tert */and data=@o_data'	+
			+ case when @tip='RC' then ' and jurnal=''RC''' else '' end	
		set @sql_pozdoc=case when @sql_update_pozdoc<>'' then 'UPDATE pozdoc SET '+@sql_update_pozdoc+' '+@sql_where_pozdoc else '' end		
		
		set @sql=@sql_pozdoc+char(13)+char(13)+@sql_doc


		if isnull(@sql,'')<>''
			exec sp_executesql @statement=@sql, @params=N'@sub as varchar(9), @numar as varchar(20), @tert as varchar(13), @gestiune as varchar(9), 
				@contract as varchar(20), @lm as varchar(9), @comanda as char(20), @indbug as varchar(20), @categpret as int, @explicatii as char(25),
				@data datetime, @factura as varchar(20),@data_facturii as datetime, @data_scadentei as datetime, @valuta as char(3), @curs as float, 
				@cont_factura as varchar(40),@tip as varchar(2), @tip_doc as varchar(2), @o_numar varchar(20), @o_data datetime, @discount as float, @punct_livrare as varchar(5), 
				@o_tert as varchar(13),@cont_de_stoc as varchar(40),@gestiune_primitoare as varchar(13),@jurnal char(3), @tipTVA int, @o_tipTVA int,
				@numardvi varchar(30), @detalii xml',                				
				@numar=@numar, @tert=@tert, @gestiune=@gestiune, @data=@data,@factura=@factura,@contract=@contract,@lm=@lm,@comanda=@comanda,@indbug=@indbug,
				@categpret= @categpret,@explicatii=@explicatii,@valuta=@valuta,@curs=@curs,@discount=@discount,@cont_factura=@cont_factura,
				@data_scadentei= @data_scadentei, @tip=@tip,@tip_doc=@tip_doc,@sub=@sub, @o_numar=@o_numar, @o_data=@o_data, @data_facturii=@data_facturii,
				@punct_livrare=@punct_livrare, @o_tert=@o_tert, @cont_de_stoc=@cont_de_stoc,@gestiune_primitoare=@gestiune_primitoare,@jurnal=@jurnal,
				@tipTVA=@tipTVA, @o_tipTVA=@o_tipTVA, @numardvi=@numardvi, @detalii=@detalii

		/*	Completare cont TVA exceptie in pozdoc.detalii */
		if @cont_TVA is not null
		begin
			update pozdoc 
			set detalii.modify('replace value of (/row/@cont_tva)[1] with sql:variable("@cont_tva")')
			where Subunitate=@sub and tip=@tip_doc and numar=@o_numar and data=@o_data and (@tip<>'RC' or jurnal='RC')
				and detalii.value('(/row/@cont_tva)[1]','varchar(40)') is not null 

			update pozdoc set detalii='<row/>'
			where Subunitate=@sub and tip=@tip_doc and numar=@o_numar and data=@o_data and (@tip<>'RC' or jurnal='RC')
				and @cont_TVA<>''

			update pozdoc 
			set detalii.modify('insert attribute cont_tva {sql:variable("@cont_TVA")} into (/row)[1]') 
			where Subunitate=@sub and tip=@tip_doc and numar=@o_numar and data=@o_data and (@tip<>'RC' or jurnal='RC')
				and detalii.value('(/row/@cont_tva)[1]','varchar(40)') is null and @cont_TVA<>''
		end
			
		-- daca a reusit inlocuirea sa stearga documentul anterior
		if (@numar<>@o_numar and isnull(@numar,'')<>'' and ISNULL(@o_numar,'')<>'')
			or (@data<>@o_data and isnull(@data,'')<>'' and ISNULL(@o_data,'')<>'')
			delete from doc 
			where subunitate=@sub 
				and tip=@tip_doc 
				and Numar=@o_numar and data=@o_data
				and (Jurnal='RC' or @tip<>'RC')

		--	modificare numar receptie / data receptie / numar DVI in tabela DVI.
		if @tip_doc='RM' and isnull(@numardvi,'')<>''
		begin
			set @sql_update_dvi='Subunitate=@sub'+char(13)+	 
				(case when @numar<>@o_numar then ',Numar_receptie=@numar'+char(13) else '' end)+
				(case when @data<>@o_data then ',Data_DVI=@data'+char(13) else '' end)+
				(case when @numardvi<>@o_numardvi then ',Numar_DVI=@numardvi'+char(13) else '' end)
	
			set @sql_where_dvi='WHERE Subunitate=@sub and numar_dvi=@o_numardvi and numar_receptie=@o_numar and Data_DVI=@o_data'
			set @sql_dvi=(case when @sql_update_dvi<>'' then 'UPDATE dvi SET '+@sql_update_dvi+' '+@sql_where_dvi else '' end)
		
			if isnull(@sql_dvi,'')<>''
				exec sp_executesql @statement=@sql_dvi, @params=N'@sub as varchar(9), @numar as varchar(20), @o_numar as varchar(20), @data datetime, @o_data datetime, 
					@numardvi varchar(30), @o_numardvi varchar(30)',
					@sub=@sub, @numar=@numar, @o_numar=@o_numar, @data=@data, @o_data=@o_data, @numardvi=@numardvi, @o_numardvi=@o_numardvi
		end

		if exists (select 1 from DocDeContat where Subunitate=@sub and Tip=@tip and Numar=@o_numar and Data=@o_data)
			exec faInregistrariContabile @dinTabela=0, @Subunitate=@sub, @Tip=@tip, @Numar=@o_numar, @Data=@o_data
		
		if exists (select 1 from DocDeContat where Subunitate=@sub and Tip=@tip and Numar=@numar and Data=@data)
			exec faInregistrariContabile @dinTabela=0, @Subunitate=@sub, @Tip=@tip, @Numar=@numar, @Data=@data
		
		if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareAntetDocSP1')
			exec wOPModificareAntetDocSP1 @sesiune=@sesiune, @parXML=@parXML 	
		
		commit tran
		select 'Datele de pe antet au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
			
			
		declare @xml xml
		set @xml=convert(xml,'<row tip="'+@tip+'" numar="'+@numar+'" data="'+convert(varchar(10),@data,126)+'"/>')			
		exec wIadoc @sesiune=@sesiune, @parXML=@xml
	end try
	
	begin catch
		set @mesaj = ERROR_MESSAGE()
		rollback tran
	end catch
	
	if LEN(@mesaj)>0
	begin
		if @iDoc is not null		
			exec sp_xml_removedocument @iDoc 
		raiserror(@mesaj, 11, 1)
	end		
end
