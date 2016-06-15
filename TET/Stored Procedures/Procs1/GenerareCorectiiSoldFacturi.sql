--***
create procedure GenerareCorectiiSoldFacturi @tipfact char(2)='B',@soldfact float=0.01,
@datacorectii datetime,@nrcorectii char(20)='CORB',@ctcorectii varchar(40)='473',@jurnalcorectii char(3)='',
@stergerecorectii int,@generarecorectii int,@lmfiltru char(9)='',@tertfiltru char(13)='',
@ctfactfiltru varchar(40)='',@parXML XML=''
as 
BEGIN
begin try
	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end

	declare @sub char(9),@cttvaded varchar(40),@cttvacol varchar(40),@userASiS char(10)

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','CDTVA',0,0,@cttvaded output
	exec luare_date_par 'GE','CCTVA',0,0,@cttvacol output
	set @userASiS = isnull(dbo.fIaUtilizator(null),'')

	if @stergerecorectii=1
	begin
		delete from pozadoc where subunitate=@sub and numar_document=@nrcorectii and data=@datacorectii 
			and tip='F'+@tipfact and (@tertfiltru='' or tert=@tertfiltru) 
			and (@lmfiltru='' or loc_munca like rtrim(@lmfiltru)+'%')
			and (@ctfactfiltru='' or @tipfact='B' and cont_deb like RTrim(@ctfactfiltru)+'%' 
			or @tipfact='F' and cont_cred like RTrim(@ctfactfiltru)+'%')

		delete from adoc where subunitate=@sub and numar_document=@nrcorectii and data=@datacorectii 
			and tip='F'+@tipfact and (@tertfiltru='' or tert=@tertfiltru) and not exists (select 1 from pozadoc where 
			pozadoc.subunitate=adoc.subunitate and pozadoc.tip=adoc.tip 
			and pozadoc.numar_document=adoc.numar_document and pozadoc.data=adoc.data) 
	end

	if @generarecorectii=1
	begin
		CREATE TABLE #TMPPADOC (
			[Subunitate] [char] (9) NOT NULL ,
			[Numar_document] [char] (8) NOT NULL ,
			[Data] [datetime] NOT NULL ,
			[Tert] [char] (13) NOT NULL ,
			[Tip] [char] (2) NOT NULL ,
			[Factura_stinga] [char] (20) NOT NULL ,
			[Factura_dreapta] [char] (20) NOT NULL ,
			[Cont_deb] [char] (40) NOT NULL ,
			[Cont_cred] [char] (40) NOT NULL ,
			[Suma] [float] NOT NULL ,
			[TVA11] [float] NOT NULL ,
			[TVA22] [float] NOT NULL ,
			[Utilizator] [char] (10) NOT NULL ,
			[Data_operarii] [datetime] NOT NULL ,
			[Ora_operarii] [char] (6) NOT NULL ,
			[Numar_pozitie] [int] IDENTITY NOT NULL ,
			[Tert_beneficiar] [char] (13) NOT NULL ,
			[Explicatii] [char] (50) NOT NULL ,
			[Valuta] [char] (3) NOT NULL ,
			[Curs] [float] NOT NULL ,
			[Suma_valuta] [float] NOT NULL ,
			[Cont_dif] [char] (40) NOT NULL ,
			[suma_dif] [float] NOT NULL ,
			[Loc_munca] [char] (9) NOT NULL ,
			[Comanda] [char] (40) NOT NULL ,
			[Data_fact] [datetime] NOT NULL ,
			[Data_scad] [datetime] NOT NULL ,
			[Stare] [smallint] NOT NULL ,
			[Achit_fact] [float] NOT NULL ,
			[Dif_TVA] [float] NOT NULL ,
			[Jurnal] [char] (3) NOT NULL )

		insert into #TMPPADOC
		(Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, 
		Cont_cred, Suma,TVA11, TVA22, Utilizator, Data_operarii, Ora_operarii, Tert_beneficiar, 
		Explicatii, Valuta, Curs, Suma_valuta, Cont_dif, suma_dif,	Loc_munca, Comanda, Data_fact, 
		Data_scad, Stare, Achit_fact, Dif_TVA, Jurnal)
		select @sub,@nrcorectii,@datacorectii,tert,'F'+@tipfact,(CASE WHEN @tipfact='B' THEN factura 
		ELSE '' END),(CASE WHEN @tipfact='F' THEN FACTURA ELSE '' END),(CASE WHEN @tipfact='B' 
		THEN CONT_DE_TERT ELSE @ctcorectii END),(CASE WHEN @tipfact='B' THEN @ctcorectii ELSE 
		cont_DE_TERT END),-SOLD,0,0,@userASiS,convert(datetime,convert(char(10),getdate(),104),104),
		replace(convert(char(8), getdate(), 114),':',''),(CASE WHEN @tipfact='B' THEN @cttvacol ELSE 
		@cttvaded END),'Corectii facturi sold mic','',0,0,'',0,loc_de_munca,'',@datacorectii,@datacorectii,0,0,0,
		@jurnalcorectii
		from facturi 
		where tip=(case when @tipfact='B' then 0x46 else 0x54 end) 
		and abs(round(convert(decimal(17,5), sold),2))>=0.01 
		and abs(round(convert(decimal(17,5), sold),2))<=abs(@soldfact) and (@tertfiltru='' or tert=@tertfiltru) 
		and (@lmfiltru='' or loc_de_munca like rtrim(@lmfiltru)+'%')
		and (@ctfactfiltru='' or cont_de_tert like RTrim(@ctfactfiltru)+'%')

		declare @pozitiemax int
		set @pozitiemax=isnull((select max(numar_pozitie) from pozadoc where subunitate=@sub 
		and numar_document=@nrcorectii and data=@datacorectii),0)

		INSERT INTO POZADOC
		(Subunitate,Numar_document,Data,Tert,Tip,Factura_stinga,Factura_dreapta,Cont_deb,Cont_cred,
		Suma,TVA11,TVA22,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Tert_beneficiar,
		Explicatii,Valuta,Curs,Suma_valuta,Cont_dif,suma_dif,Loc_munca,Comanda,Data_fact,Data_scad,
		Stare,Achit_fact,Dif_TVA,Jurnal)
		SELECT Subunitate,Numar_document,Data,Tert,Tip,Factura_stinga,Factura_dreapta,Cont_deb,
		Cont_cred,Suma,TVA11,TVA22, Utilizator,Data_operarii,Ora_operarii,Numar_pozitie+@pozitiemax,
		Tert_beneficiar,Explicatii,Valuta,Curs,Suma_valuta,Cont_dif,suma_dif, Loc_munca,Comanda,
		Data_fact,Data_scad,Stare,Achit_fact,Dif_TVA,Jurnal FROM #TMPPADOC

		DROP TABLE #TMPPADOC
	end
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
END
