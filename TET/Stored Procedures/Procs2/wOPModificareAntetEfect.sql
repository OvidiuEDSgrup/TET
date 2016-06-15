--***
/* descriere... */
create procedure wOPModificareAntetEfect (@sesiune varchar(50), @parXML xml) 
as     
begin
	
	declare @serieefect varchar(20), @numarefect varchar(20), @contbctert varchar(35), @bancatert varchar(20),
		@userASiS varchar(20), @sub varchar(9), @tip varchar(2), @efect varchar(20), @o_efect varchar(20), @data datetime, @o_data datetime,
		@tert varchar(13), @o_tert varchar(13), @cont varchar(40), @o_cont varchar(40), 
		@dataefect datetime, @o_dataefect datetime, @datascadentei datetime, @o_datascadentei datetime,
		@o_contbctert varchar(35), @o_serieefect varchar(20), @o_numarefect varchar(20), @o_bancatert varchar(20),
		@sql_update_efect nvarchar(max), @sql_where_efect nvarchar(max), @tipefect varchar(1), @mesaj varchar(250)
	             
	begin try
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
		exec luare_date_par 'GE','SUBPRO',0,0,@sub output
		
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		
		select 
			@tip= tip, 
			@tipefect= tipefect, 
			@efect=efect, @o_efect=o_efect,
			@data =data, @o_data =o_data,
			@tert=tert, @o_tert=o_tert, 
			@cont=cont, @o_cont=o_cont, 
			@dataefect=detalii.value('(/row/@dataefect)[1]','datetime'), @o_dataefect=o_detalii.value('(/row/@dataefect)[1]','datetime'),
			@datascadentei=detalii.value('(/row/@datascad)[1]','datetime'), @o_datascadentei=o_detalii.value('(/row/@datascad)[1]','datetime'),
			@contbctert=detalii.value('(/row/@contbctert)[1]','varchar(50)'), @o_contbctert=o_detalii.value('(/row/@contbctert)[1]','varchar(50)'),
			@serieefect=detalii.value('(/row/@serieefect)[1]','varchar(20)'), @o_serieefect=o_detalii.value('(/row/@serieefect)[1]','varchar(20)'),
			@numarefect=detalii.value('(/row/@numarefect)[1]','varchar(20)'), @o_numarefect=o_detalii.value('(/row/@numarefect)[1]','varchar(20)'),
			@bancatert=detalii.value('(/row/@bancatert)[1]','varchar(50)'), @o_bancatert=o_detalii.value('(/row/@bancatert)[1]','varchar(50)')
			
		from OPENXML(@iDoc, '/parametri')
		WITH 
		(
			detalii xml 'detalii/row',
			o_detalii xml 'o_detalii/row',
			tip char(2) '@tip', 
			tipefect char(2) '@tipefect', 
			efect varchar(20) '@efect',o_efect varchar(20) '@o_efect',
			tert varchar(13) '@tert',o_tert varchar(13) '@o_tert',
			data datetime '@data',o_data datetime '@o_data',
			cont varchar(40) '@cont',	o_cont varchar(40) '@cont'/*,
			dataefect datetime '@dataefect', o_dataefect datetime '@o_dataefect',	--cred ca e data efect (CEC) din macheta de efect (nu cred ca e --data la care beneficiarul a facut plata(se ia in calcul la calculul penalitatilor))
			serieefect varchar(5) '@serieefect', o_serieefect varchar(5) '@o_serieefect',	--campul serieefect din pozplin.detalii, utilizat pentru seria efectelor
			numarefect varchar(20) '@numarefect',o_numarefect varchar(20) '@o_numarefect',	--campul numarefect din pozplin.detalii, utilizat pentru numarul efectelor
			contbctert varchar(35) '@contbctert',o_contbctert varchar(35) '@o_contbctert',	--campul contbctert din pozplin.detalii, utilizat pentru contul efectelor
			bancatert varchar(20) '@bancatert', o_bancatert varchar(20) '@o_bancatert'	--campul bancatert din pozplin.detalii, utilizat pentru banca emitenta pentru efecte*/
		)
		exec sp_xml_removedocument @iDoc 

		if not exists (select 1 from terti where tert=@tert) and isnull(@tert,'')<>'' 
			raiserror('Tertul introdus nu exista in baza de date!!',11,1)
		if not exists (select 1 from conturi where cont=@cont) and isnull(@cont,'')<>''
			raiserror('Contul introdus nu exista in baza de date!!',11,1)					

	declare crsptAntetEfecte cursor for
		select idPozPlin, detalii
		FROM pozplin p
		where p.Subunitate=@sub
			and p.Cont=@o_cont
			and p.Data=@o_data
			and p.Tert=@o_tert
			and p.efect=@efect
			and left(p.Plata_incasare,1)=@tipefect					
	
	declare @ft int, @idPozPlin int, @parXMLDetalii xml, @detalii xml
	open crsptAntetEfecte
	fetch next from crsptAntetEfecte into @idPozPlin, @detalii
	set @ft=@@fetch_status
	while @ft = 0
	begin
		if @dataefect<>isnull(@o_dataefect,'01/01/1901') and isnull(@dataefect,'01/01/1901')<>'01/01/1901'
		begin
			set @parXMLDetalii=(select 'dataefect' as atribut, convert(char(10),@dataefect,101) as valoare for xml raw)
			exec ActualizareInXml @parXML=@parXMLDetalii, @detalii=@detalii output
		end
		if @datascadentei<>isnull(@o_datascadentei,'01/01/1901') and isnull(@datascadentei,'01/01/1901')<>'01/01/1901'
		begin
			set @parXMLDetalii=(select 'datascad' as atribut, convert(char(10),@datascadentei,101) as valoare for xml raw)
			exec ActualizareInXml @parXML=@parXMLDetalii, @detalii=@detalii output
		end
		if isnull(@serieefect,'')<>isnull(@o_serieefect,'')
		begin
			set @parXMLDetalii=(select 'serieefect' as atribut, rtrim(@serieefect) as valoare for xml raw)
			exec ActualizareInXml @parXML=@parXMLDetalii, @detalii=@detalii output
		end
		if isnull(@numarefect,'')<>isnull(@o_numarefect,'') 
		begin
			set @parXMLDetalii=(select 'numarefect' as atribut, rtrim(@numarefect)  as valoare for xml raw)
			exec ActualizareInXml @parXML=@parXMLDetalii, @detalii=@detalii output
		end
		if isnull(@bancatert,'')<>isnull(@o_bancatert,'')
		begin
			set @parXMLDetalii=(select 'bancatert' as atribut, rtrim(@bancatert)  as valoare for xml raw)
			exec ActualizareInXml @parXML=@parXMLDetalii, @detalii=@detalii output
		end
		if isnull(@contbctert,'')<>isnull(@o_contbctert,'')
		begin
			set @parXMLDetalii=(select 'contbctert' as atribut, rtrim(@contbctert) as valoare for xml raw)
			exec ActualizareInXml @parXML=@parXMLDetalii, @detalii=@detalii output
		end

		update Pozplin set detalii=@detalii, 
			efect=(case when @efect<>@o_efect then @efect else efect end),
			tert=(case when @tert<>@o_tert then @tert else tert end)
		where idPozPlin=@idPozPlin

		fetch next from crsptAntetEfecte into @idPozPlin, @detalii
		set @ft=@@fetch_status
	end
	close crsptAntetEfecte 
	deallocate crsptAntetEfecte 

		select 'Datele efectului au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
	end try
	
	begin catch
		set @mesaj = ERROR_MESSAGE()+' (wOPModificareAntetEfect)'
	end catch
	
	if LEN(@mesaj)>0
	begin		
		exec sp_xml_removedocument @iDoc 
		raiserror(@mesaj, 11, 1)
	end		
end
