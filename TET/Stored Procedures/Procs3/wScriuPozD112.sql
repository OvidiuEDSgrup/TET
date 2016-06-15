--***
create procedure wScriuPozD112 (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozD112SP')
begin
	declare @returnValue int
	exec @returnValue=wScriuPozD112SP @sesiune, @parXML output
	return @returnValue
end

begin try
	declare @subtip varchar(2), @userASiS char(10), @mesaj varchar(80), @iDoc int, @rootDoc varchar(20), 
		@datalunii datetime, @lm varchar(9), @LMUtilizator varchar(9), @multiFirma int, @docXMLIaPozD112 xml
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	select  @subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),'')
			, @datalunii=@parXML.value('(/row/@datalunii)[1]','datetime')
	set @rootDoc='/row/row' 
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		select @LMUtilizator=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS

	if @subtip in ('CE') 
	Begin
--	citire date din gridul de operatii pt. editare sectiune AsiguratE (date detaliate privind impozitul pe venit)
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#D112AsiguratE3') IS NOT NULL DROP TABLE #D112AsiguratE3

		SELECT data, isnull(_update,0) as _update, cnpasig, E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16, idPozitie
		INTO #D112AsiguratE3
		FROM OPENXML(@iDoc, @rootDoc)
		WITH
		(
			data datetime '../@datalunii'
			,_update int '@update'
			,cnpasig varchar(13) '@cnpasig'
			,E3_1 varchar(10) '@E3_1'
			,E3_2 varchar(10) '@E3_2'
			,E3_3 varchar(10) '@E3_3'
			,E3_4 varchar(10) '@E3_4'
			,E3_5 varchar(10) '@E3_5'
			,E3_6 varchar(10) '@E3_6'
			,E3_7 varchar(10) '@E3_7'
			,E3_8 varchar(10) '@E3_8'
			,E3_9 varchar(10) '@E3_9'
			,E3_10 varchar(10) '@E3_10'
			,E3_11 varchar(10) '@E3_11'
			,E3_12 varchar(10) '@E3_12'
			,E3_13 varchar(10) '@E3_13'
			,E3_14 varchar(10) '@E3_14'
			,E3_15 varchar(10) '@E3_15'
			,E3_16 varchar(10) '@E3_16'
			,idPozitie int '@idPozitie'
		)
		EXEC sp_xml_removedocument @iDoc 

		if exists (select 1 from #D112AsiguratE3 where cnpAsig='')
			raiserror('CNP necompletat!',11,1)

--	actualizez datele din tabela D112AsiguratE3 cu valorile din grid (daca s-au modificat)
		if exists (select 1 from #D112AsiguratE3 where _update=1)
			update e set e.E3_5=x.E3_5, e.E3_6=x.E3_6, e.E3_7=x.E3_7, e.E3_8=x.E3_8, e.E3_9=x.E3_9, e.E3_10=x.E3_10, 
				e.E3_11=x.E3_11, e.E3_12=x.E3_12, e.E3_13=x.E3_13, e.E3_14=x.E3_14, e.E3_15=x.E3_15, e.E3_16=x.E3_16
			from D112AsiguratE3 e 
				left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=e.Loc_de_munca
				, #D112AsiguratE3 x
			where (@multifirma=0 or lu.Cod is not null) 
				and e.Data=@datalunii and e.cnpAsig=x.cnpAsig and e.idPozitie=x.idPozitie
		else
			insert into D112AsiguratE3 (Data, Loc_de_munca, cnpAsig, E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16)
			select @datalunii, @lmUtilizator, cnpAsig, 
				E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16
			from #D112AsiguratE3 a
	End

	set @docXMLIaPozD112='<row datalunii="'+convert(char(10),@datalunii,101)+'"/>'
	exec wIaPozD112 @sesiune=@sesiune, @parXML=@docXMLIaPozD112

end try
begin catch
	set @mesaj=' (wScriuPozD112): '+ERROR_MESSAGE()
	raiserror(@mesaj,11,1)
end catch
