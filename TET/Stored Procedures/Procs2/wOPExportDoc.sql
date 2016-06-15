
create procedure wOPExportDoc @sesiune varchar(50), @parXML xml
as
declare @mesaj varchar(500)

begin try
	declare @numar varchar(10), @data datetime, @tert varchar(20), @dentert varchar(100), @CUIbeneficiar varchar(20),
			@factura varchar(20), @datafacturii datetime, @datascadentei datetime,
			@fisier varchar(255), @pozxml xml, @xml xml, @expeditor varchar(20)

	set @numar = @parXML.value('(/row/@numar)[1]','varchar(10)')
	set @data = @parXML.value('(/row/@data)[1]','datetime')
	set @tert = @parXML.value('(/row/@tert)[1]','varchar(20)')
	set @factura = @parXML.value('(/row/@factura)[1]','varchar(20)')
	set @datafacturii = @parXML.value('(/row/@datafacturii)[1]','datetime')
	set @datascadentei = @parXML.value('(/row/@datascadentei)[1]','datetime')
	
	set @expeditor= rtrim((select Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CODFISC'))
	set @CUIbeneficiar = rtrim((select top 1 Cod_fiscal from terti where Tert=@tert))

	set @pozxml = (select	rtrim(p.Cod) as cod ,
							rtrim(n.Denumire) as denumire,
							convert(decimal(18,3),p.Cantitate) as cantitate, 
							convert(decimal(18,5),p.Pret_valuta) as pretfaraTVA, 
							convert(decimal(18,2),p.TVA_deductibil) as TVApepozitie
					from pozdoc p
					inner join nomencl n on p.Cod=n.Cod
					where Numar=@numar
					for xml raw('pozitie'))

	set @xml = (select	newid() as GUID,
						@expeditor as CUIfurnizor, 
						@CUIbeneficiar as CUIbeneficiar,
						@data as data,
						@factura as factura, 
						@datafacturii as datafacturii,
						@datascadentei as datascadentei,
						@pozxml
				for xml raw('factura'))

	delete tabelXML where sesiune=@sesiune
	insert into tabelXML(sesiune, date) select @sesiune, @xml

	declare @cmdShellCommand varchar(3000), @caleform varchar(1000)
	select @caleform=rtrim(val_alfanumerica)+(case when left(reverse(rtrim(val_alfanumerica)),1)='\' then '' else '\' end)
		from par where tip_parametru='AR' and parametru='caleform'
	set @cmdShellCommand = 'bcp "select replace(convert(varchar(max),date),''>'',''>''+char(10)) from ' + db_name() + '.dbo.tabelXML where sesiune='''+rtrim(@sesiune)+'''" queryout '+@caleform + @numar + '.xml -c -T -r \n -S ' + convert(varchar(1000),serverproperty('ServerName'))
	exec xp_cmdshell @cmdShellCommand
	
	select @numar + '.xml' as fisier, 'wTipFormular' as numeProcedura
		for xml raw, root('Mesaje')
end try

begin catch
	set @mesaj = error_message() + ' (wOPExportDoc)'
	raiserror(@mesaj, 11, 1)
end catch
