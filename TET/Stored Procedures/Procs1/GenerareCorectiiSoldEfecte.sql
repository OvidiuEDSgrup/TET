--***
create procedure GenerareCorectiiSoldEfecte @tipefecte char(2)='P',@soldefecte float=0.01,
@datacorectii datetime,@idcorectii char(20)='CORP',@ctcorectii varchar(40)='473',@stergerecorectii int=0,
@generarecorectii int=1,@tertfiltru char(13)='',@parXML XML=''
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

	if @stergerecorectii=1 
	begin
		delete from pozplin where subunitate=@sub and cont=@ctcorectii and data=@datacorectii and 
			plata_incasare=(case when @tipefecte='P' then 'PD' else 'ID' end) 
			and (@tertfiltru='' or tert=@tertfiltru) and cont_corespondent 
			in (select conturi.cont from conturi where conturi.subunitate=@sub and 
			conturi.sold_credit=8) and explicatii like RTrim(@idcorectii)+'%'
	end

	if @generarecorectii=1
	begin
		CREATE TABLE #tmppozplinef (
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
			[Efect] [varchar](20))

		insert into #tmppozplinef (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
			Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, 
			TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, 
			Cont_dif, Suma_dif, Achit_fact, Jurnal, Efect)
			select @sub,@ctcorectii,@datacorectii,nr_efect,(case when tip='P' then 'PD' else 'ID' end),
			tert,'',cont,sold,valuta,curs,0,curs,@cotatva,0,left(rtrim(@idcorectii)+' '+explicatii,50),
			loc_de_munca,comanda,@userASiS,convert(datetime, convert(char(10), getdate(),104),104),
			replace(convert(char(8), getdate(), 114),':',''),'',0,curs,'',nr_efect
			from efecte 
			where Subunitate=@sub and tip=@tipefecte 
			and abs(round(convert(decimal(17,5),sold),2))>=0.01 
			and abs(round(convert(decimal(17,5), sold),2))<=abs(@soldefecte) 
			and (@tertfiltru='' or tert=@tertfiltru) --and (@ctfact='' or cont_de_tert like RTrim(@ctfact)+'%')

		/*declare @nrpozitiemax int
		set @nrpozitiemax=isnull((select max(numar_pozitie) from pozplin where subunitate=@sub 
			and cont= and numar=@numar and data=@datacorectii),0)*/

		INSERT INTO pozplin (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
			Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, 
			TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, 
			Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal, Efect)
		SELECT Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
			Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, 
			TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, 
			Numar_pozitie/*+@nrpozitiemax*/, Cont_dif, Suma_dif, Achit_fact, Jurnal, Efect
		FROM #tmppozplinef

		DROP TABLE #tmppozplinef
	end
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
END
