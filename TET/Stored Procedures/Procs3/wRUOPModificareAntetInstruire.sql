--***
/* descriere... */ --select * from RU_instruiri
create procedure dbo.wRUOPModificareAntetInstruire (@sesiune varchar(50), @parXML xml) 
as     
begin
	declare @tip varchar(2), @id_instruire int, @data datetime, @data_inceput datetime, @data_sfarsit datetime, @id_curs int, @tiptrainer char(2), @trainer char(50), @tiplocatie varchar(2), @locatie varchar(13), 
	@o_data datetime, @o_data_inceput datetime, @o_data_sfarsit datetime, @o_id_curs int, @o_tiptrainer char(2), @o_trainer char(50), @o_tiplocatie varchar(2), @o_locatie varchar(13), 
	@comanda varchar(20), @o_comanda varchar(20), @eroare xml, @mesaj varchar(254), @userASiS varchar(13), @sub varchar(9), 
	@sql_instruiri nvarchar(max), @sql_update_instruiri nvarchar(max), @sql_where_instruiri nvarchar(max), @sql nvarchar(max)
			        
	begin try
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
		exec luare_date_par 'GE','SUBPRO',0,0,@sub output
		
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		
		select 
			@tip= tip, @id_instruire=id_instruire, 
			@data=data, @o_data=o_data, @data_inceput=data_inceput, @o_data_inceput=isnull(o_data_inceput,''), @data_sfarsit=data_sfarsit, @o_data_sfarsit=isnull(o_data_sfarsit,''),
			@id_curs=id_curs, @o_id_curs=isnull(o_id_curs,0), @tiptrainer=tiptrainer, @o_tiptrainer=isnull(o_tiptrainer,''), @trainer=trainer, @o_trainer=isnull(o_trainer,''), 
			@tiplocatie=tiplocatie, @o_tiplocatie=isnull(o_tiplocatie,''), @locatie=locatie, @o_locatie=isnull(o_locatie,''), @comanda=comanda, @o_comanda=isnull(o_comanda,'')
		from OPENXML(@iDoc, '/parametri')
		WITH 
		(
			tip char(2) '@tip', o_tip char(2) '@o_tip',
			id_instruire int '@id_instruire', data datetime '@data', o_data datetime '@o_data', 
			data_inceput datetime '@data_inceput', o_data_inceput datetime '@o_data_inceput',
			data_sfarsit datetime '@data_sfarsit', o_data_sfarsit datetime '@o_data_sfarsit',
			id_curs int '@id_curs', o_id_curs int '@o_id_curs', tiptrainer char(2) '@tiptrainer', o_tiptrainer char(2) '@o_tiptrainer', trainer varchar(20) '@trainer', o_trainer varchar(20) '@o_trainer', 
			tiplocatie char(2) '@tiplocatie', o_tiplocatie char(2) '@o_tiplocatie', locatie varchar(20) '@locatie', o_locatie varchar(20) '@o_locatie',
			comanda varchar(20) '@comanda', o_comanda varchar(20) '@o_comanda'
		)
		exec sp_xml_removedocument @iDoc
		if not exists (select 1 from RU_cursuri where ID_curs=@id_curs)
			raiserror('Cursul introdus nu exista in baza de date!!',11,1)
		if @comanda<>'' and not exists (select 1 from comenzi where Subunitate=@sub and Comanda=@comanda)
			raiserror('Comanda introdusa nu exista in baza de date!!',11,1)

		set @sql_update_instruiri='Numar_fisa=@id_instruire'+char(13)+
			(case when @data<>@o_data then ', Data=@data'+char(13) else '' end)+
			(case when @data_inceput<>@o_data_inceput then ', Data_inceput=@data_inceput'+char(13) else '' end)+
			(case when @data_sfarsit<>@o_data_sfarsit then ', Data_sfarsit=@data_sfarsit'+char(13) else '' end)+			
			(case when @id_curs<>@o_id_curs then ', ID_curs=@id_curs'+char(13) else '' end)+
			(case when @tiptrainer<>@o_tiptrainer then ', Tip_trainer=@tiptrainer'+char(13) else '' end)+
			(case when @trainer<>@o_trainer then ', Trainer=@trainer'+char(13) else '' end)+
			(case when @tiplocatie<>@o_tiplocatie then ', Tip_locatie=@tiplocatie'+char(13) else '' end)+
			(case when @locatie<>@o_locatie then ', Locatie=@locatie'+char(13) else '' end)+
			(case when @comanda<>@o_comanda then ', Comanda=@comanda'+char(13) else '' end)

		set @sql_where_instruiri='WHERE ID_instruire=@id_instruire'	
		set @sql_instruiri=case when @sql_update_instruiri<>'' then 'UPDATE RU_instruiri SET '+@sql_update_instruiri+' '+@sql_where_instruiri else '' end
		
		set @sql=@sql_instruiri
		print @sql

		if isnull(@sql,'')<>''
			exec sp_executesql @statement=@sql, @params=N'@sub as varchar(9), @id_instruire as int, @data datetime, @data_inceput as datetime, @data_sfarsit as datetime, 
				@id_curs as int, @tiptrainer as char(2), @trainer as varchar(20), @tiplocatie as char(2), @locatie as varchar(20), @comanda varchar(20), 
				@o_data datetime, @o_data_inceput as datetime, @o_data_sfarsit as datetime, @o_id_curs as int, @o_tiptrainer as varchar(2), @o_trainer as varchar(20), 
				@o_tiplocatie as varchar(2), @o_locatie as varchar(20), @o_comanda varchar(20)',
				@sub=@sub, @id_instruire=@id_instruire, @data=@data, @data_inceput=@data_inceput, @data_sfarsit=@data_sfarsit, @id_curs=@id_curs, @tiptrainer=@tiptrainer, @trainer=@trainer, 
				@tiplocatie=@tiplocatie, @locatie=@locatie, @comanda=@comanda, @o_data=@o_data, @o_data_inceput=@o_data_inceput, @o_data_sfarsit=@o_data_sfarsit, @o_id_curs=@o_id_curs, 
				@o_tiptrainer=@o_tiptrainer, @o_trainer=@o_trainer, @o_tiplocatie=@o_tiplocatie, @o_locatie=@o_locatie, @o_comanda=@o_comanda
		
		select 'Datele de pe antet instruire au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
	end try

	begin catch
		set @mesaj = '(wRUOPModificareAntetInstruire) '+ERROR_MESSAGE()
	end catch	

	if LEN(@mesaj)>0
	begin		
		raiserror(@mesaj, 11, 1)
	end		
end
