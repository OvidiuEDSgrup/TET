--***
/* descriere... */
create procedure [dbo].[yso_wOPModificareAntetDoc](@sesiune varchar(50), @parXML xml) 
as     
begin
	
	declare @tip char(2), @numar varchar(8),@o_numar varchar(8), @data datetime, @o_data datetime,@gestiune varchar(9), @o_gestiune varchar(9),
		@gestiune_primitoare char(13), @tert varchar(13),@o_tert varchar(13), @factura varchar(20), @o_factura varchar(20),@data_facturii datetime, 
		@data_scadentei datetime,@o_data_scadentei datetime, @lm varchar(9),  @o_lm varchar(9), @indbug varchar(20),@o_indbug varchar(20),@o_explicatii char(25),
		@cota_TVA float,@tipTVA int,@o_tipTVA int, @comanda char(20),@o_comanda char(20), @cont_de_stoc char(13),@o_cont_de_stoc char(13),@o_valuta char(3), @o_curs float,@o_data_facturii datetime,
		@valuta char(3), @curs float, @contract varchar(20),@o_contract varchar(20),@n_numar varchar(20),@n_tert varchar(13),@n_data datetime,@n_tip varchar(2),
		@explicatii char(25), @cont_factura char(13), @o_cont_factura char(13),@discount float,  @o_discount float,@punct_livrare char(5), 
		@cont_corespondent char(13),@categpret int,@o_categpret int,@cont_venituri char(13), @TVAnx float, @jurnalProprietate varchar(3),
		@sub char(9),@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20),
		@categPretProprietate varchar(20), @stare int,	@eroare xml, @mesaj varchar(254), @Bugetari int,@NrAvizeUnitar int,
		@sql_doc nvarchar(max) ,@sql_update_doc nvarchar(max),@sql_where_doc nvarchar(max),@sql nvarchar(max),@o_gestiune_primitoare varchar(13),
		@sql_pozdoc nvarchar(max) ,@sql_update_pozdoc nvarchar(max),@sql_where_pozdoc nvarchar(max),@jurnal char(3),@o_jurnal char(3)
	             
	begin try
--/*sp
		declare @procid int=@@procid, @objname sysname
		set @objname=object_name(@procid)
		EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
	
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
			@punct_livrare=punct_livrare_antet, 
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
		 
		from OPENXML(@iDoc, '/parametri')
		WITH 
		(
			tip char(2) '@tip', 
			numar varchar(8) '@numar',o_numar varchar(8) '@o_numar',
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
			cont_factura varchar(13) '@contfactura', o_cont_factura varchar(13) '@o_contfactura', 
			datafact datetime '@datafacturii',o_datafact datetime '@o_datafacturii',
			datascad datetime '@datascadentei',o_datascad datetime '@o_datascadentei',
			cont_de_stoc varchar(13) '@cont_stoc',  o_cont_de_stoc varchar(13) '@o_cont_stoc',  
			
			gestiune_primitoare_antet char(13) '@gestprim',	o_gestiune_primitoare_antet char(13) '@o_gestprim',
			cont_corespondent_antet char(13) '@contcorespondent', 
			cont_venituri_antet char(13) '@contvenituri', 
			
			punct_livrare_antet char(5) '@punctlivrare',
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
		)
		exec sp_xml_removedocument @iDoc 

		if not exists (select 1 from gestiuni where Cod_gestiune=@gestiune) and isnull(@gestiune,'')<>''
			raiserror('Gestiunea introdusa nu exista in baza de date!!',11,1)
		if not exists (select cod from lm where cod=@lm) and isnull(@lm ,'')<>''
			raiserror('Locul de munca introdus nu exista in baza de date!!',11,1)	
		if not exists (select 1 from indbug where indbug=@indbug) and isnull(@indbug,'')<>'' and @Bugetari=1
			raiserror('Indicatorul bugetar introdus nu exista in baza de date!!',11,1)
		if not exists (select 1 from terti where tert=@tert) and isnull(@tert,'')<>'' and @tip not in ('TE','AI','AE')
			raiserror('Tertul introdus nu exista in baza de date!!',11,1)
		if not exists (select 1 from conturi where cont=@cont_factura) and isnull(@cont_factura,'')<>'' and @tip not in ('TE') --or not exists (select 1 from conturi where cont=@cont_stoc)
			raiserror('Contul introdus nu exista in baza de date!!',11,1)					
		
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
			(case when @tip in ('AP', 'AS', 'AC', 'TE') and @categpret<>@o_categpret then ',Discount_suma=@categpret'+char(13) else '' end)+
			(case when @tip in ('AP','AS','RS') and @explicatii<>@o_explicatii then ',Numar_DVI=@explicatii'+char(13) else '' end)+
			(case when @valuta<>@o_valuta then ',Valuta=@valuta'+char(13) else '' end)+
			(case when @curs<>@o_curs then ',Curs=@curs'+char(13) else '' end)+
			(case when @discount<>@o_discount then ',Discount_p=@discount'+char(13) else '' end)+
			(case when @cont_factura<>@o_cont_factura then ',Cont_factura=@cont_factura'+char(13) else '' end)+
			(case when @data_facturii<>@o_data_facturii then ',Data_facturii=@data_facturii'+char(13) else '' end)+
			(case when @data_scadentei<>@o_data_scadentei then ',Data_scadentei=@data_scadentei'+char(13) else '' end)+
			--(case when @numar<>@o_numar or @data<>@o_data then ',Valoare=0'+char(13) else '' end)+
			--(case when @numar<>@o_numar or @data<>@o_data then ',Tva_22=0'+char(13) else '' end)
			(case when @gestiune_primitoare<>@o_gestiune_primitoare and @tip in ('TE') then ',Gestiune_primitoare=@gestiune_primitoare'+char(13) else '' end)
			+(case when @jurnal<>@o_jurnal then ',jurnal=@jurnal' else '' end)
			+(case when @tipTVA<>@o_tipTVA then ',Cota_TVA=@tipTVA' else '' end)
			
		set @sql_where_doc='WHERE Subunitate=@sub and tip=(case when @tip=''RC'' then ''RM'' else @tip end) and numar=@numar and data=@data'+ case when @tip='RC' then ' and jurnal=''RC''' else '' end
		set @sql_doc=case when @sql_update_doc<>'' then 'UPDATE doc SET '+@sql_update_doc+' '+@sql_where_doc else '' end		
		--print @sql_doc

		
		set @sql_update_pozdoc='Subunitate=@sub'+char(13)+	 
			(case when @numar<>@o_numar then ',Numar=@numar'+char(13) else '' end)+
			(case when @tert<>@o_tert then ',Tert=@tert'+char(13) else '' end)+
			(case when @gestiune<>@o_gestiune then ',Gestiune=@gestiune'+char(13) else '' end)+
			(case when @data<>@o_data then ',Data=@data'+char(13) else '' end)+
			(case when @factura<>@o_factura then ',Factura=@factura'+char(13) else '' end)+
			(case when @contract<>@o_contract then ',Contractul=@contract'+char(13) else '' end)+
			(case when @lm<>@o_lm then ',Loc_de_munca=@lm'+char(13) else '' end)+
			(case when @comanda<>@o_comanda then ',Comanda=convert(char(20),@comanda)+substring(Comanda,21,20)'+char(13) else '' end)+
			(case when @indbug<>@o_indbug then ',Comanda=left(Comanda,20)+convert(char(20),@indbug)'+char(13) else '' end)+
			(case when @tip in ('AP', 'AS', 'AC', 'TE') and @categpret<>@o_categpret then ',Accize_cumparare=@categpret'+char(13) else '' end)+		
			(case when @discount<>@o_discount then ',Discount=@discount 
			,Pret_vanzare= round(Pret_valuta * (CASE WHEN valuta<>'''' THEN Curs ELSE 1 END)*( 1 - @discount / 100 ),2)
			,Pret_cu_amanuntul= round(convert(DECIMAL(17,5), convert(DECIMAL(15,5),
				round(Pret_valuta * (CASE WHEN valuta<>'''' THEN Curs ELSE 1 END)*( 1 - @discount / 100 ),2)
					)*(1+ Cota_TVA)/100),5)
			,Tva_deductibil= round(convert(DECIMAL(17, 4), Cantitate * 
				round(Pret_valuta * (CASE WHEN valuta<>'''' THEN Curs ELSE 1 END)*( 1 - @discount / 100 ),2) 
					* (CASE WHEN Procent_vama = 2 THEN 0 ELSE Cota_TVA END) / 100), 2)
					'+char(13) else '' end)+ 
			(case when @data_facturii<>@o_data_facturii then ',Data_facturii=@data_facturii'+char(13) else '' end)+
			(case when @data_scadentei<>@o_data_scadentei then ',Data_scadentei=@data_scadentei'+char(13) else '' end)+	
			(case when @tip in ('AP', 'AS', 'AC') then ',Numar_DVI=LEFT(Numar_DVI,13)+@punct_livrare'+char(13) else '' end)+
			(case when @cont_de_stoc<>@o_cont_de_stoc then ',Cont_de_stoc=@cont_de_stoc'+char(13) else '' end)+	
			(case when @cont_factura<>@o_cont_factura then ',Cont_factura=@cont_factura'+char(13) else '' end)+
			(case when @gestiune_primitoare<>@o_gestiune_primitoare and @tip in ('TE') then ',Gestiune_primitoare=@gestiune_primitoare'+char(13) else '' end)
			+(case when @jurnal<>@o_jurnal then ',jurnal=@jurnal' else '' end)
			+(case when @tipTVA<>@o_tipTVA then ',Procent_vama=@tipTVA' else '' end)
		
		set @sql_where_pozdoc='WHERE Subunitate=@sub and tip=(case when @tip=''RC'' then ''RM'' else @tip end) and numar=@o_numar and tert=@o_tert and data=@o_data'	+
			+ case when @tip='RC' then ' and jurnal=''RC''' else '' end	
		set @sql_pozdoc=case when @sql_update_pozdoc<>'' then 'UPDATE pozdoc SET '+@sql_update_pozdoc+' '+@sql_where_pozdoc else '' end		
		--print @sql_pozdoc
		
		
		/*if isnull(@sql_pozdoc,'')<>''
			exec sp_executesql @statement=@sql_pozdoc, @params=N'@sub as varchar(9),@numar as varchar(8), @tert as varchar(13), @data datetime, @factura as varchar(20), 
				@gestiune as varchar(9), @lm as varchar(9), @comanda as char(20), @indbug as varchar(20), @categpret as int, @contract as varchar(20),
				@discount as float, @data_facturii as datetime, @data_scadentei as datetime, @tip as varchar(2), @cont_factura varchar(13), 
				@punct_livrare as varchar(5),@o_numar as varchar(8), @o_data as datetime, @o_tert as varchar(13), @cont_de_stoc as varchar(13)',
				@numar=@numar, @tert=@tert, @gestiune=@gestiune, @data=@data, @factura=@factura,@contract=@contract,@lm=@lm,@comanda=@comanda,@indbug=@indbug,
				@categpret= @categpret,@discount=@discount,@cont_factura=@cont_factura,@data_facturii=@data_facturii,@o_tert=@o_tert,
				@data_scadentei= @data_scadentei, @tip=@tip, @punct_livrare=@punct_livrare,@sub=@sub,@o_numar=@o_numar, @o_data=@o_data	,
				@cont_de_stoc=@cont_de_stoc	*/	
		
		
		/*if isnull(@sql_doc,'')<>''
			exec sp_executesql @statement=@sql_doc, @params=N'@sub as varchar(9), @numar as varchar(8), @tert as varchar(13), @gestiune as varchar(9), 
				@contract as varchar(20), @lm as varchar(9), @comanda as char(20), @indbug as varchar(20), @categpret as int, @explicatii as char(25),
				@data datetime, @factura as varchar(20),@data_facturii as datetime, @data_scadentei as datetime, @valuta as char(3), @curs as float, 
				@cont_factura as char(13),@tip as varchar(2), @o_numar varchar(8), @o_data datetime, @discount as float',				
				@numar=@numar, @tert=@tert, @gestiune=@gestiune, @data=@data,@factura=@factura,@contract=@contract,@lm=@lm,@comanda=@comanda,@indbug=@indbug,
				@categpret= @categpret,@explicatii=@explicatii,@valuta=@valuta,@curs=@curs,@discount=@discount,@cont_factura=@cont_factura,
				@data_scadentei= @data_scadentei, @tip=@tip,@sub=@sub, @o_numar=@o_numar, @o_data=@o_data, @data_facturii=@data_facturii*/					
		
		
		set @sql=@sql_pozdoc+char(13)+char(13)+@sql_doc
		--print @sql
		
		if isnull(@sql,'')<>''
			exec sp_executesql @statement=@sql, @params=N'@sub as varchar(9), @numar as varchar(8), @tert as varchar(13), @gestiune as varchar(9), 
				@contract as varchar(20), @lm as varchar(9), @comanda as char(20), @indbug as varchar(20), @categpret as int, @explicatii as char(25),
				@data datetime, @factura as varchar(20),@data_facturii as datetime, @data_scadentei as datetime, @valuta as char(3), @curs as float, 
				@cont_factura as char(13),@tip as varchar(2), @o_numar varchar(8), @o_data datetime, @discount as float, @punct_livrare as varchar(5),
				@o_tert as varchar(13),@cont_de_stoc as varchar(13),@gestiune_primitoare as varchar(13),@jurnal char(3), @tipTVA int, @o_tipTVA int',                				
				@numar=@numar, @tert=@tert, @gestiune=@gestiune, @data=@data,@factura=@factura,@contract=@contract,@lm=@lm,@comanda=@comanda,@indbug=@indbug,
				@categpret= @categpret,@explicatii=@explicatii,@valuta=@valuta,@curs=@curs,@discount=@discount,@cont_factura=@cont_factura,
				@data_scadentei= @data_scadentei, @tip=@tip,@sub=@sub, @o_numar=@o_numar, @o_data=@o_data, @data_facturii=@data_facturii,
				@punct_livrare=@punct_livrare, @o_tert=@o_tert, @cont_de_stoc=@cont_de_stoc,@gestiune_primitoare=@gestiune_primitoare,@jurnal=@jurnal,
				@tipTVA=@tipTVA, @o_tipTVA=@o_tipTVA
		
		if (@numar<>@o_numar and isnull(@numar,'')<>'' and ISNULL(@o_numar,'')<>'')
			or (@data<>@o_data and isnull(@data,'')<>'' and ISNULL(@o_data,'')<>'')
			delete from doc 
			where subunitate=@sub 
				and tip=(case when @tip='RC' then 'RM' else @tip end) 
				and Numar=@o_numar and data=@o_data
				and (Jurnal='RC' or @tip<>'RC')
			
		select 'Datele de pe antet au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
	end try
	
	begin catch
		set @mesaj = ERROR_MESSAGE()--+' '+@sql
		print @sql
	end catch
	
	if LEN(@mesaj)>0
	begin		
		exec sp_xml_removedocument @iDoc 
		raiserror(@mesaj, 11, 1)
	end		
end
