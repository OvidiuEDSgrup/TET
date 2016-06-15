create procedure wIaPozIncon @sesiune varchar(50),@parXML xml
as
	declare 
		@tipdocument char(2),@nrdocument varchar(40),@data datetime,@subunitate char(9),@utilizator varchar(20),@lista_lm int,
		@tert varchar(13),@efect varchar(20), @tip varchar(2),@numar varchar(40),@decont varchar(40),@marca varchar(6),@tipefect varchar(1), @tipini varchar(2)
	
if OBJECT_ID('wIaPozInconSP') is not null
begin
	exec wIaPozInconSP @sesiune,@parXML
	return
end

	select 	
		@tipdocument=@parXML.value('(/row/@tipdocument)[1]','char(2)'),
		@nrdocument=@parXML.value('(/row/@nrdocument)[1]','varchar(40)'),
		@data=@parXML.value('(/row/@data)[1]','datetime'),
		@tert=@parXML.value('(/row/@tert)[1]','varchar(13)'),
		@efect=@parXML.value('(/row/@efect)[1]','varchar(20)'),
		@marca=@parXML.value('(/row/@marca)[1]','varchar(6)'),
		@decont=@parXML.value('(/row/@decont)[1]','varchar(40)'),
		@tip=@parXML.value('(/row/@tip)[1]','varchar(2)'),  -- tipul din macheta (webconfigtipuri)
		@numar=@parXML.value('(/row/@numar)[1]','varchar(40)'), 
		@tipefect = ISNULL(@parXML.value('(/row/@tipefect)[1]','varchar(1)'), '')-->tipul efectului

	if @tipdocument is null  and @nrdocument is null and @numar is not null
	begin 
		set @tipdocument=@tip
		set @nrdocument=@numar
	end
	set @tipini=@tip

	exec luare_date_par 'GE','SUBPRO',NULL,NULL,@subunitate OUT

	if @tip in ('RC','RF','RA','MF','MR') set @tip='RM'
	if @tip in ('RI','MA') set @tip='AI'	--tip=RI (modificare prin reevaluare in macheta de Documente Imobilizari)
	if @tip in ('AA','AB') set @tip='AP'
	if @tip in ('RE','EF','DE','DR') set @tip='PI'
	/*
	if @tip in ('RM','RS','AP','AS','FB','IF','FF','SF')
		exec contTVADocument @Subunitate=@subunitate, @Tip=@tip, @Numar=@nrdocument, @Data=@data
	*/
	if exists (select 1 from DocDeContat where Subunitate=@subunitate and Tip=@tip and Numar=@nrdocument and Data=@data) 
		exec faInregistrariContabile @dinTabela=0,@Subunitate=@subunitate, @Tip=@tip, @Numar=@nrdocument, @Data=@data

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	select @lista_lm=dbo.f_arelmfiltru(@utilizator)

	select p.Tip_document tipdocument,rtrim(p.Numar_document) nrdocument,CONVERT(char(10),p.Data,101) data
		,rtrim(p.Cont_debitor) contdebitor,rtrim(cd.Denumire_cont) dencontdebitor
		,rtrim(p.Cont_creditor) contcreditor,rtrim(cc.Denumire_cont) dencontcreditor
		,CONVERT(decimal(18,2),p.Suma)suma,rtrim(p.Valuta) valuta,convert(decimal(14, 4), p.curs) curs,convert(decimal(18,2),p.Suma_valuta) sumavaluta
		,RTRIM(p.Explicatii) explicatii,RTRIM(p.Loc_de_munca) lm, RTRIM(p.Loc_de_munca)+'-'+rtrim(lm.Denumire) denlm
		,rtrim(left(p.Comanda,20)) comanda,rtrim(p.indbug) as indbug
		,rtrim(left(p.Comanda,20))+case when rtrim(isnull(c.Descriere,''))<>'' then '-'+rtrim(isnull(c.Descriere,'')) else '' end dencomanda
	from pozincon p
		left outer join conturi cd on p.Subunitate=cd.Subunitate and p.Cont_debitor=cd.Cont
		left outer join conturi cc on p.Subunitate=cc.Subunitate and p.Cont_creditor=cc.Cont
		left outer join lm on lm.Cod=p.Loc_de_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=left(p.Comanda,20)
		left outer join pozplin pp on @tipini in ('EF','DE') and p.Subunitate=pp.Subunitate and p.Data=pp.Data	and p.Numar_document=pp.Cont 
			and p.Numar_pozitie=pp.idPozplin and ((pp.Tert=@tert and @tipini='EF') or (pp.marca=@marca) and @tipini='DE')
			--and (left(pp.Plata_incasare,1)=@tipefect or @tipini<>'EF')
	where p.Subunitate=@subunitate and p.Tip_document=@tipdocument 
		and p.Numar_document=@nrdocument and p.Data=@data 
		and (@tipini<>'EF' or (pp.Tert=@tert and pp.Efect=@efect)) --pt tabul de note contabile de pe efecte
		and (@tipini<>'DE' or (pp.marca=@marca and pp.Decont=@decont)) --pt tabul de note contabile de pe deconturi
		and (@lista_lm=0 or exists (select 1 from lmfiltrare lu where lu.utilizator=@utilizator and lu.cod=p.loc_de_munca))
	for xml raw, root('Date')
