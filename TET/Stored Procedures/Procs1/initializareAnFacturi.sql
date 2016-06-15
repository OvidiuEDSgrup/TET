--***
create procedure initializareAnFacturi(@data_initializare datetime)
as
begin
	-- exec initializareAnFacturi @data_initializare='2014-01-01'
	begin try
		if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
		begin
			raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa 
				operatia in aceste conditii!',16,1)
			return
		end
		
		declare @sub char(9), @epsilon decimal(6,5), @anulinit int
		set @epsilon=0.001
		set @sub=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' 
			and parametru='SUBPRO'), '')
		set @data_initializare=dbo.boy(@data_initializare)
		set @anulinit=YEAR(@data_initializare)
		
		--exec VerificareIntegritateFacturi @de la Data Implementarii,@data_initializare,0
		--declare @data_implementarii datetime, @nLunaImpl int, @nAnImpl int
		--set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' 
		--		and parametru='ANULIMPL'),0)
		--set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' 
		--		and parametru='LUNAIMPL'),0)
		--set @data_implementarii=convert(varchar(10),@nAnImpl)+'-'+convert(varchar(10),@nLunaImpl)+'-1'
		--set	@data_implementarii=dateadd(d,-1,dateadd(M,1,@data_implementarii))
		-- nu trebuie sa se verifice de la data_implementarii!
		declare @data_inceput datetime, @data_sfarsit datetime
		set	@data_inceput=dateadd(y,-1,@data_initializare)
		set	@data_sfarsit=dateadd(d,-1,@data_initializare)
		-- aici vom renunta:
		exec VerificareIntegritateFacturi @data_inceput, @data_sfarsit, 0

		declare @o_zi_inainte datetime, @parXMLFact xml
		set @o_zi_inainte=dateadd(d,-1,@data_initializare)

		/* se preia in tabela #pfacturi prin procedura pFacturi, in locul functiei fFacturiCen */
		if object_id('tempdb..#pfacturi') is not null 
			drop table #pfacturi
		create table #pfacturi (subunitate varchar(9))
		exec CreazaDiezFacturi @numeTabela='#pfacturi'
		set @parXMLFact=(select '' as furnbenef, null as datajos, @o_zi_inainte as datasus, 1 as cen, @epsilon as soldmin, 0 as semnsold for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact
		
		-- aici vom face dedublare, ca la stocuri

		delete istfact where subunitate=@sub and Data_an=@data_initializare
		
		insert into istfact(Data_an, Subunitate, Loc_de_munca, Tip, Factura, Tert, Data, 
			Data_scadentei, Valoare, TVA_11, TVA_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, 
			Cont_de_tert, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari)
		select @data_initializare Data_an, f.Subunitate, f.Loc_de_munca, (case when f.Tip=0x46 then 'B' else 'F' end),
			f.Factura, f.Tert, f.Data, f.Data_scadentei, f.Valoare, 0, f.tva, f.Valuta, 
			f.Curs, f.Valoare_valuta, f.Achitat, f.Sold, f.cont_factura, f.Achitat_valuta, 
			f.Sold_valuta, f.Comanda, f.Data_ultimei_achitari
		from #pfacturi f
		--from dbo.fFacturiCen('','01/01/1901',@o_zi_inainte,null,null,null,null,null,@epsilon,0, null) f
	end try
	begin catch
		declare @eroare varchar(1000)
		set @eroare='initializareAnFacturi: '+rtrim(ERROR_MESSAGE())
		raiserror(@eroare,16,1)
	end catch
	if isnull(@eroare,'')='' 
			exec setare_par 'GE','ULT_AN_IN','Ultimul an initializare facturi',1,@anulinit,''
end
