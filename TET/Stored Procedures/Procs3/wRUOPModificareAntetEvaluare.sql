--***
/* procedura pt. inlocuirea datelor de pe antetul evaluarilor */ --select * from RU_evaluri
create procedure dbo.wRUOPModificareAntetEvaluare (@sesiune varchar(50), @parXML xml) 
as     
begin
	declare @sub varchar(9), @tip varchar(2), @id_evaluare int, @data datetime, @id_evaluat int, @an_evaluat int, @o_data datetime, @o_id_evaluat int, @o_an_evaluat int, 
	@eroare xml, @mesaj varchar(254), @userASiS varchar(13), @sql_evaluari nvarchar(max), @sql_update_evaluari nvarchar(max), @sql_where_evaluari nvarchar(max), @sql nvarchar(max)
			        
	begin try
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
		exec luare_date_par 'GE','SUBPRO',0,0,@sub output
		
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		
		select 
			@tip= tip, @id_evaluare=id_evaluare, @data=data,  @o_data=o_data, @id_evaluat=id_evaluat, @o_id_evaluat=o_id_evaluat, @an_evaluat=an_evaluat, @o_an_evaluat=o_an_evaluat
		from OPENXML(@iDoc, '/parametri')
		WITH 
		(
			tip char(2) '@tip', o_tip char(2) '@o_tip',
			id_evaluare int '@id_evaluare', data datetime '@data', o_data datetime '@o_data', 
			id_evaluat int '@id_evaluat', o_id_evaluat int '@o_id_evaluat', an_evaluat int '@an_evaluat', o_an_evaluat int '@o_an_evaluat'
		)
		exec sp_xml_removedocument @iDoc
		if not exists (select 1 from RU_persoane where ID_pers=@id_evaluat)
			raiserror('Persoana introdusa nu exista in baza de date!!',11,1)

		set @sql_update_evaluari='Numar_fisa=@id_evaluare'+char(13)+
			(case when @data<>@o_data then ', Data=@data'+char(13) else '' end)+
			(case when @id_evaluat<>@o_id_evaluat then ', ID_evaluat=@id_evaluat'+char(13) else '' end)+
			(case when @an_evaluat<>@o_an_evaluat then ', An_evaluat=@an_evaluat'+char(13) else '' end)

		set @sql_where_evaluari='WHERE id_evaluare=@id_evaluare and tip=@tip'	
		set @sql_evaluari=case when @sql_update_evaluari<>'' then 'UPDATE RU_evaluari SET '+@sql_update_evaluari+' '+@sql_where_evaluari else '' end
		
		set @sql=@sql_evaluari
		print @sql

		if isnull(@sql,'')<>''
			exec sp_executesql @statement=@sql, @params=N'@sub as varchar(9), @tip as char(2), @id_evaluare as int, @data datetime, @id_evaluat as int, @an_evaluat as int, 
				@o_data datetime, @o_id_evaluat as int, @o_an_evaluat as int',
				@sub=@sub, @tip=@tip, @id_evaluare=@id_evaluare, @data=@data, @id_evaluat=@id_evaluat, @an_evaluat=@an_evaluat, @o_data=@o_data, @o_id_evaluat=@o_id_evaluat, @o_an_evaluat=@o_an_evaluat
		
		select 'Datele de pe antet evaluare au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
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
