--***
Create procedure genAnexaDeclaratieIntrastat
	(@sesiune varchar(50)=''
	,@datajos datetime, @datasus datetime
	,@flux char(1)		--> @Flux = I -> Introducere; E -> Expediere
	,@tipdecl char(1)	--> @tipdecl = N -> Noua; R -> Rectificativa; U -> Nula
	,@nume_persct varchar(200), @prenume_persct varchar(200), @functie_persct varchar(100), @telefon_persct varchar(30), @fax_persct varchar(30), @email_persct varchar(100)
	,@dinRia int=1
	,@caleFisier varchar(300)	--> calea completa, incluzand fisierul; daca fisierul nu este dat se creeaza unul in functie de data, tip si cod fiscal firma
	)
as
declare @eroare varchar(2000)
set @eroare=''
begin try
	declare @an char(4), @cui varchar(100), @den varchar(100), @anluna varchar(20), @dataexport varchar(30), @fluxXML varchar(20), @tipdeclXML varchar(20), 
		@versTari varchar(20), @versTariUE varchar(20), @versCoduriNomencl varchar(20), @versModTransp varchar(20), @versCondLivr varchar(20), 
		@versNaturaTranzA varchar(20), @versNaturaTranzB varchar(20), @versJudete varchar(20), @versLocalit varchar(20), @versUM varchar(20)

	set @an=convert(char(4),year(@datasus))
	set @anluna=@an+'-'+replace(Str(month(@datasus),2),' ','0')
	set @dataexport=rtrim(convert(char(19),getDate(),126)+'.000+02:00')

	select 
		@cui=replace(replace(
			max(case when tip_parametru='GE' and parametru='CODFISC' then rtrim(val_alfanumerica) else '' end),'RO',''),'R','')
		,@den=max(case when tip_parametru='GE' and parametru='NUME' then rtrim(val_alfanumerica) else '' end)
	from par where tip_parametru='GE' and parametru in ('CODFISC','NUME','TELFAX','FAX','EMAIL')
	set @cui=replicate(0,10-len(rtrim(@cui)))+rtrim(@cui)

	select @versTari='2007', @versTariUE='2007', @versCoduriNomencl=@an, @versModTransp='2005', 
		@versCondLivr=(case when @an<2010 then '2005' else 2011 end), 
		@versNaturaTranzA=(case when @an<2010 then '2005' else 2010/*@an*/ end), @versNaturaTranzB=(case when @an<2010 then '2005' else 2010/*@an*/ end), 
		@versJudete='1', @versLocalit='06/2006', @versUM='1'

	if object_id('tempdb.dbo.#intrastat') is not null drop table #intrastat

--	formare cale fisier / nume fisier
	declare @continutXml xml, @continutXmlAntet1 varchar(max), @continutXmlAntet2 varchar(max), @continutXmlDate varchar(max), @continutXmlChar varchar(max), 
		@fisier varchar(100), @pozSeparator int, @caleCompletaFisier varchar(300)
	select	@pozSeparator=len(@caleFisier)-charindex('\',reverse(@caleFisier))
			,@caleCompletaFisier=@caleFisier
	select	@fisier=substring(@caleFisier,@pozSeparator+2,len(@caleFisier)-@pozseparator+1)
			,@caleFisier=substring(@caleFisier,1,@pozseparator)

	if len(rtrim(@fisier))=0	--<<	Aici se compune numele fisierului, daca a fost omis
		select @fisier=rtrim(@cui)+'_'+(case when @flux='I' then 'A' else 'D' end)+
				+(case when @tipdecl='R' then 'R' when @tipdecl='U' then 'N' else '' end)+'_'+@an+rtrim(convert(varchar(2),month(@datasus)))
				
	if left(right(@fisier,4),1)<>'.' select @fisier=@fisier+'.xml'

	select @fluxXML=(case when @flux='I' then 'Arrival' else 'Dispatch' end), @tipdeclXML=(case when @tipdecl='N' then 'New' when @tipdecl='R' then 'Revised' else 'Nill' end)

--	formare continut XML pentru generare fisier
	set @continutXmlAntet1=
		N'<Ins'+rtrim(@tipdeclXML)+rtrim(@fluxXML)
			+' xmlns="http://www.intrastat.ro/xml/InsSchema" SchemaVersion="1.0">
			<InsCodeVersions> <CountryVer>'+rtrim(@versTari)+'</CountryVer> 
			<EuCountryVer>'+rtrim(@versTariUE)+'</EuCountryVer>
			<CnVer>'+rtrim(@versCoduriNomencl)+'</CnVer>
			<ModeOfTransportVer>'+rtrim(@versModTransp)+'</ModeOfTransportVer>
			<DeliveryTermsVer>'+rtrim(@versCondLivr)+'</DeliveryTermsVer>
			<NatureOfTransactionAVer>'+rtrim(@versNaturaTranzA)+'</NatureOfTransactionAVer>
			<NatureOfTransactionBVer>'+rtrim(@versNaturaTranzB)+'</NatureOfTransactionBVer>
			<CountyVer>'+rtrim(@versJudete)+'</CountyVer>
			<LocalityVer>'+rtrim(@versLocalit)+'</LocalityVer>
			<UnitVer>'+rtrim(@versUM)+'</UnitVer> </InsCodeVersions>
		<InsDeclarationHeader> <VatNr>'+rtrim(@Cui)+'</VatNr> <FirmName>'+rtrim(@den)+'</FirmName> 
			<RefPeriod>'+rtrim(@anluna)+'</RefPeriod> <CreateDt>'+rtrim(@dataexport)+'</CreateDt> 
			<ContactPerson> <LastName>'+rtrim(@nume_persct)+'</LastName> 
				<FirstName>'+rtrim(@prenume_persct)+'</FirstName> <Email>'+rtrim(@email_persct)+'</Email> 
				<Phone>'+rtrim(@telefon_persct)+'</Phone> <Fax>'+rtrim(@fax_persct)+'</Fax> 
				<Position>'+rtrim(@functie_persct)+'</Position> </ContactPerson> </InsDeclarationHeader>'
	set @continutXmlAntet2='</Ins'+rtrim(@tipdeclXML)+rtrim(@fluxXML)+'>'
/*
	create table #intrstat (nr_ord int, cod_NC8 varchar(20), val_facturata decimal(15,3), val_statistica decimal(15,3), masa_neta decimal(17,5), 
		UM2 varchar(20), cant_UM2 decimal(17,5), natura_tranzactie_a varchar(20), natura_tranzactie_b varchar(20), cond_livrare varchar(20), mod_transport varchar(20), 
		tara_tert varchar(20), tara_origine varchar(20), dencodv varchar(80))
	
	insert into #intrstat--*/
	
	if object_id('tempdb..#intrastat') is null
	begin
		create table #intrastat (nr_ord int)
		exec rapDeclaratieIntrastat_tabela
	end

	exec rapDeclaratieIntrastat @datajos, @datasus, @flux, @tipdecl, @tabela=1

	set @continutXMLDate=''
	if @tipdecl<>'U'
		set @continutXMLDate= (select rtrim(nr_ord) as '@OrderNr', rtrim(cod_NC8) as Cn8Code,
			convert(decimal(12),val_facturata) as InvoiceValue, 
			(case when convert(decimal(12),val_statistica)<>0 then convert(decimal(12),val_statistica) end) as StatisticalValue, convert(decimal(12),masa_neta) as NetMass, 
			rtrim(natura_tranzactie_a) as NatureOfTransactionACode, (case when rtrim(natura_tranzactie_b)<>'' then rtrim(natura_tranzactie_a)+'.'+rtrim(natura_tranzactie_b) end) as NatureOfTransactionBCode, 
			rtrim(cond_livrare) as DeliveryTermsCode, rtrim(mod_transport) as ModeOfTransportCode, 
			(case when @flux='I' or @flux='E' and @an>=2015 then rtrim(tara_origine) end) as CountryOfOrigin, 
			(select 
				rtrim(UM2) as SupplUnitCode, convert(decimal(12),cant_UM2) as QtyInSupplUnits where UM2<>'' and UM2<>'-' for xml path('InsSupplUnitsInfo'), type),
			/*(case when UM2<>'' then (select 
				rtrim(UM2) as SupplUnitCode, convert(decimal(12),cant_UM2) as QtyInSupplUnits for xml path('InsSupplUnitsInfo'), type) end) as UM2,*/
			(case when @flux='I' then rtrim(tara_tert) end) as CountryOfConsignment, 
			(case when @flux='E' then rtrim(tara_tert) end) as CountryOfDestination, 
			(case when @flux='E' and @an>=2015 then rtrim(tara_tert) end) as PartnerCountryCode, 
			(case when @flux='E' and @an>=2015 then rtrim(cif_partener) end) as PartnerVatNr
		from #intrastat for XML path('InsArrivalItem')/*, Elements XSINIL*/)
	
	if @continutXMLDate<>''
		set @continutXMLDate=replace(@continutXMLDate,'InsArrivalItem','Ins'+rtrim(@fluxXML)+'Item')
			
	set @continutXml=CONVERT(XML, @continutXmlAntet1 + @continutXMLDate + @continutXmlAntet2)

--/*--> urmeaza scrierea fizica a fisierului:
--	encoding="UTF-8" 
	select @continutXmlChar='<?xml version="1.0" ?>'+char(10)+convert(varchar(max),@continutXml)

	if (@dinRia=1)
	begin
		if OBJECT_ID('tempdb..##IntrastatoutputXML') is not null
			drop table ##IntrastatoutputXML
		create table ##IntrastatoutputXML (valoare varchar(max), id int identity)
		insert into ##IntrastatoutputXML
		select @continutXmlChar as valoare
		exec salvareFisier @codXML='', @caleFisier=@caleFisier, @numeFisier=@fisier, @numeTabelDate='##IntrastatoutputXML'
	end
	else
	begin
		if OBJECT_ID('tempdb..##tmpdecl') is not null
			drop table ##tmpdecl
		--insert into ##tmpdecl values(@continutXmlChar)
		select @continutXmlChar as coloana into ##tmpdecl
		declare @nServer varchar(1000), @comandaBCP varchar(4000) /* comanda trebuie sa ramana varchar(4000) sau mai mica... */
		set @nServer=convert(varchar(1000),serverproperty('ServerName'))
		set @comandaBCP='bcp "select coloana from ##tmpdecl'+'" queryout "'+@caleCompletaFisier+'" -T -c -r -t -C UTF-8 -S '+@nServer
		declare @raspunsCmd int, @msgeroare varchar(1000)
		exec @raspunsCmd = xp_cmdshell @comandaBCP
		if @raspunsCmd != 0 /* xp_cmdshell returneaza 0 daca nu au fost erori, sau altfel, codul de eroare */
		begin
			set @msgeroare = 'Eroare la scrierea formularului pe hard-disk in locatia: '+ ( 
				case len(@Fisier) when 0 then 'NEDEFINIT' else @caleCompletaFisier end )
			raiserror (@msgeroare ,11 ,1)
		end
		else	/* trimit numele fisierului generat */ 
			select @fisier as fisier, 'wTipFormular' as numeProcedura for xml raw
	end

	declare @parXMLVies xml, @detalii xml
	/*	Apelare procedura de validare terti in Vies. */
	if @dinRia=1 and exists (select * from sysobjects where name ='ValidareDateDinVies') and exists (select 1 from #intrastat)
	begin
		set @parXMLVies=(select @dinRia as dinRia for xml raw)
		IF OBJECT_ID('tempdb..#tertiVies') IS NOT NULL
			drop table #tertiVies

		create table #tertiVies (tert varchar(20))
		exec CreazaDiezTerti @numeTabela='#tertiVies'
		insert into #tertiVies (tert)
		select distinct tert
		from #intrastat 
		exec ValidareDateDinVies @sesiune=null, @parXML=@parXMLVies
		--set @detalii=(select rtrim(tert) as tert, rtrim(requestIdentifier) as requestIdentifier from #tertiVies for xml raw)
	end

--	salvez declaratia ca si continut in tabela declaratii
	if exists (select * from sysobjects where name ='scriuDeclaratii' and xtype='P')
	begin
		declare @coddecl varchar(20), @totalmasaneta decimal(12,2), @valfacturata decimal(12,2)
		set @coddecl='INTRASTAT_'+@flux
		select @valfacturata=sum(val_facturata), @totalmasaneta=sum(masa_neta)
		from #intrastat
		set @detalii=(select @flux as flux, @valfacturata as valfacturata, @totalmasaneta as totalmasaneta for xml raw)
		exec scriuDeclaratii @cod=@coddecl, @tip=@tipdecl, @data=@datasus, @detalii=@detalii, @continut=@continutXmlChar
	end

	--*/
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (genAnexaDeclaratieIntrastat)'
	raiserror(@eroare, 16, 1) 
end catch
/*
	exec genAnexaDeclIntrastat @sesiune='', @datajos='06/01/2013', @datasus='06/30/2013', @flux='I', @tipdecl='N', @nume_declar='Pop', @prenume_declar='Florin', @functie_declar='Director economic',
	@dinRia=1, @caleFisier='D:\fisiere\0018140767_A_20136.xml'
*/
