--***
create procedure GenerareCorectiiSoldDeconturi @tipdec char(2)='T',@solddec float=0.01,
@datacorectii datetime,@idcorectii char(20)='CORT',@ctcorectii varchar(40)='473',@stergerecorectii int=0,
@generarecorectii int=1,@marcafiltru char(13)='',@parXML XML=''
as 
BEGIN
begin try
	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end

	declare @sub char(9),@cotatva float,@userASiS char(10)

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','COTATVA',0,@cotatva output,''
	set @userASiS = isnull(dbo.fIaUtilizator(null),'')

	/*if @stergerecorectii=1 --nu se face stergere, fiindca nu se pot diferentia de alte poz.din pozplin
	begin
		delete from pozplin where subunitate=@sub and Cont_corespondent=@ctcorectii and 
			data=@datacorectii and plata_incasare='PD'	and (@marcafiltru='' or Cont_dif=@marcafiltru) 
			and cont in (select conturi.cont from conturi where conturi.subunitate=@sub 
			and conturi.sold_credit=9) --and explicatii like RTrim(@idcorectii)+'%'
	end*/

	if @generarecorectii=1
	begin
		CREATE TABLE #tmppozplindec (
			[Subunitate] [char](9) NOT NULL,
			[Cont] [char](40) NOT NULL,
			[Data] [datetime] NOT NULL,
			[Numar] [char](10) NOT NULL,
			[Plata_incasare] [char](2) NOT NULL,
			[Tert] [char](13) NOT NULL,
			[Factura] [char](20) NOT NULL,
			[Cont_corespondent] [char](40) NOT NULL,
			[Suma] [float] NOT NULL,
			[Valuta] [char](3) NOT NULL,
			[Curs] [float] NOT NULL,
			[Suma_valuta] [float] NOT NULL,
			[Curs_la_valuta_facturii] [float] NOT NULL,
			[TVA11] [float] NOT NULL,
			[TVA22] [float] NOT NULL,
			[Explicatii] [char](50) NOT NULL,
			[Loc_de_munca] [char](9) NOT NULL,
			[Comanda] [char](40) NOT NULL,
			[Utilizator] [char](10) NOT NULL,
			[Data_operarii] [datetime] NOT NULL,
			[Ora_operarii] [char](6) NOT NULL,
			[Numar_pozitie] [int] identity NOT NULL,
			[Cont_dif] [char](40) NOT NULL,
			[Suma_dif] [float] NOT NULL,
			[Achit_fact] [float] NOT NULL,
			[Jurnal] [char](3) NOT NULL,
			[Marca] [varchar](6),
			[Decont] [varchar](20))

		insert into #tmppozplindec (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
			Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, 
			TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, 
			Cont_dif, Suma_dif, Achit_fact, Jurnal, Marca, Decont)
			select @sub,cont,@datacorectii,decont,'PD','',
			'',@ctcorectii,sold,valuta,curs,0,curs,@cotatva,0,left(explicatii,50),loc_de_munca,comanda,
			@userASiS,convert(datetime, convert(char(10), getdate(), 104), 104),
			replace(convert(char(8), getdate(), 114),':',''),'',0,curs,'', Marca, Decont
			from deconturi 
			where Subunitate=@sub and tip=@tipdec and abs(round(convert(decimal(17,5), sold),2))>=0.01 
			and abs(round(convert(decimal(17,5), sold),2))<=abs(@solddec) 
			and (@marcafiltru='' or Marca=@marcafiltru) --and (@ctcorectiifact='' or cont_de_tert like RTrim(@ctcorectiifact)+'%')

		/*declare @nrpozitiemax int
		set @nrpozitiemax=isnull((select max(numar_pozitie) from pozplin where subunitate=@sub 
			and cont= and numar=@numar and data=@datacorectii),0)*/

		INSERT INTO pozplin (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
			Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, 
			TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, 
			Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal, Marca, Decont)
		SELECT Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
			Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, 
			TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, 
			Numar_pozitie/*+@nrpozitiemax*/, Cont_dif, Suma_dif, Achit_fact, Jurnal, Marca, Decont 
		FROM #tmppozplindec

		DROP TABLE #tmppozplindec
	end
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
END
