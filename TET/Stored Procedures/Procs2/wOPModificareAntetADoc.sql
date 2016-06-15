--***
/* descriere... */ --select * from adoc
create procedure [dbo].[wOPModificareAntetADoc](@sesiune varchar(50), @parXML xml) 
as     
begin
	declare @tip char(2), @numar char(8), @data datetime,@tert char(13),@data_scadentei datetime,@n_numar varchar(20),@n_tert varchar(13),@n_data datetime,
		@n_tip varchar(2), @jurnal varchar(3),@eroare xml, @mesaj varchar(254),@userASiS varchar(13),@sub varchar(9),
		@o_numar char(8), @o_data datetime,@o_tert char(13),@o_data_scadentei datetime,@o_jurnal varchar(3),
		@sql_adoc nvarchar(max) ,@sql_update_adoc nvarchar(max),@sql_where_adoc nvarchar(max),@sql nvarchar(max),
		@sql_pozadoc nvarchar(max) ,@sql_update_pozadoc nvarchar(max),@sql_where_pozadoc nvarchar(max)
	        
	begin try
		--exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
		exec luare_date_par 'GE','SUBPRO',0,0,@sub output
		
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		
		select 
			@tip= tip, 
			@numar=numar, @o_numar=o_numar,
			@data =data,  @o_data =o_data,
			@tert=tert, @o_tert=o_tert,
			@data_scadentei=datascad, @o_data_scadentei=o_datascad,
			@jurnal=jurnal,@o_jurnal=o_jurnal,
			@n_numar =n_numar,
			@n_tert= n_tert,
			@n_data= n_data,
			@n_tip= n_tip
		 
		from OPENXML(@iDoc, '/parametri')
		WITH 
		(
			tip char(2) '@tip', o_tip char(2) '@o_tip',
			numar char(8) '@numar',o_numar char(8) '@o_numar',
			data datetime '@data',o_data datetime '@o_data',
			tert char(13) '@tert',o_tert char(13) '@o_tert',
			datascad datetime '@datascadentei',o_datascad datetime '@o_datascadentei',
			jurnal varchar(3) '@jurnal',o_jurnal varchar(3) '@o_jurnal',
			
			n_numar varchar(20)'@n_numar',
			n_tert varchar(13)'@n_tert',
			n_data datetime '@n_data',
			n_tip varchar(2) '@n_tip'
			
		)
		exec sp_xml_removedocument @iDoc
		if not exists (select 1 from terti where tert=@tert)
			raiserror('Tertul introdus nu exista in baza de date!!',11,1)
			
		set @sql_update_adoc='Subunitate=@sub'+char(13)+
			--(case when @numar<>@o_numar then ',Numar_document=@numar'+char(13) else '' end)+
			(case when @tert<>@o_tert then ',Tert=@tert'+char(13) else '' end)+
			--(case when @data<>@o_data then ',Data=@data'+char(13) else '' end)+
			(case when @jurnal<>@o_jurnal then ',Jurnal=@jurnal'+char(13) else '' end)

		set @sql_where_adoc='WHERE Subunitate=@sub and tip=@tip and Numar_document=@numar and data=@data'	
		set @sql_adoc=case when @sql_update_adoc<>'' then 'UPDATE adoc SET '+@sql_update_adoc+' '+@sql_where_adoc else '' end
		
		set @sql_update_pozadoc='Subunitate=@sub'+char(13)+
			(case when @numar<>@o_numar then ',Numar_document=@numar'+char(13) else '' end)+
			(case when @tert<>@o_tert then ',Tert=@tert'+char(13) else '' end)+
			(case when @data<>@o_data then ',Data=@data'+char(13) else '' end)+
			(case when @data_scadentei<>@o_data_scadentei then ',Data_scad=@data_scadentei'+char(13) else '' end)
				
		set @sql_where_pozadoc='WHERE Subunitate=@sub and tip=@tip and Numar_document=@o_numar and data=@o_data and tert=@o_tert'	
		set @sql_pozadoc=case when @sql_update_pozadoc<>'' then 'UPDATE pozadoc SET '+@sql_update_pozadoc+' '+@sql_where_pozadoc else '' end 
		 
		
		set @sql=@sql_pozadoc+char(13)+char(13)+@sql_adoc
		--print @sql
			
		if isnull(@sql,'')<>''
			exec sp_executesql @statement=@sql, @params=N'@sub as varchar(9), @numar as varchar(8), @tert as varchar(13), 
				@data datetime, @data_scadentei as datetime, @tip as varchar(2), @o_numar varchar(8), @o_data datetime, 
				@o_tert as varchar(13),@jurnal as varchar(3)',
				@numar=@numar, @tert=@tert, @data=@data, @data_scadentei= @data_scadentei, @tip=@tip,@sub=@sub, @o_numar=@o_numar, @o_data=@o_data, 
				@o_tert=@o_tert, @jurnal=@jurnal	
		
		if (@numar<>@o_numar and isnull(@numar,'')<>'' and ISNULL(@o_numar,'')<>'')
			or (@data<>@o_data and isnull(@data,'')<>'' and ISNULL(@o_data,'')<>'')
			delete from adoc where subunitate=@sub and tip=@tip and Numar_document=@o_numar and data=@o_data
		
		select 'Datele de pe antet au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
	end try
	begin catch
	set @mesaj = ERROR_MESSAGE()
	end catch	

	if LEN(@mesaj)>0
	begin		
		raiserror(@mesaj, 11, 1)
	end		
end
--select * from doc where tip='Ap'
