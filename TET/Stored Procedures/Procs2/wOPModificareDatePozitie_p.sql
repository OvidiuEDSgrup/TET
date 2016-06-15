create procedure wOPModificareDatePozitie_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDatePozitie_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDatePozitie_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @numar varchar(30), @data datetime, @tip varchar(2), @numar_pozitie int, @cod varchar(20), @idpozdoc int
	--,	@sumaTVA float, @cotatva decimal(5,2), @stare int, @pvaluta decimal(17,5),
	--@dencod varchar(60), @dentert varchar(50),@pamanunt decimal(12,2), @gestiune varchar(20), @tert varchar(30)
	
	select 
		@numar=@parXML.value('(/row/@numar)[1]','varchar(30)'),
		@numar_pozitie=@parXML.value('(/row/row/@numarpozitie)[1]','int'),
		@data=@parXML.value('(/row/@data)[1]','datetime'),
		@tip=@parXML.value('(/row/@tip)[1]','varchar(2)'),
		--@cotatva=@parXML.value('(/row/@cotatva)[1]','decimal(5,2)'),
		--@sumaTVA=@parXML.value('(/row/@sumaTVA)[1]','float'),
		@cod=isnull(@parXML.value('(/row/row/@cod)[1]','varchar(20)'),''),
		@idpozdoc=@parXML.value('(/row/row/@idpozdoc)[1]','int')
		--, @tert=@parXML.value('(/row/@tert)[1]','varchar(30)'),
		--@gestiune=isnull(@parXML.value('(/row/row/@gestiune)[1]','varchar(20)'),'')

	if @cod=''
	begin
		raiserror( 'Operatie de modificare date pozitie nepermisa pe antetul documentului, selectati o pozitie din document!',11,1)
	end  

	if @idpozdoc is null
	begin
		raiserror( 'Procedura "wIaPozdoc (sau wIaPozdocSP)" nu returneaza "idpozdoc". Modificati procedura pentru a returna "idpozdoc"!',11,1)
	end  
	
	select rtrim(p.Numar) numar , rtrim(p.Tert) tert, RTRIM(t.Denumire) dentert, convert(varchar(30),@data,101) data, p.numar_pozitie numarpozitie, 
		p.Tip tip, convert(decimal(12,2),p.TVA_deductibil) sumaTVA, convert(varchar(5),convert(decimal(5,2),p.cota_tva)) cotatva, convert(decimal(5, 2), p.discount) as discount,
		rtrim(p.gestiune) gestiune, rtrim(g.Denumire_gestiune) dengestiune, rtrim(p.Cod) cod, RTRIM(n.Denumire) dencod, rtrim(p.Cod_intrare) codintrare, 
		convert(decimal(12,2),p.Pret_cu_amanuntul) pamanunt, convert(decimal(17,5),p.Pret_valuta) pvaluta,
		rtrim(p.Cont_de_stoc) as contstoc, rtrim(p.Cont_de_stoc)+' - '+RTRIM(cs.Denumire_cont) as dencontstoc,
		rtrim(p.Cont_corespondent) as contcorespondent, rtrim(p.Cont_corespondent)+' - '+RTRIM(cc.Denumire_cont) as dencontcorespondent,
		rtrim(p.Cont_intermediar) as contintermediar, rtrim(p.Cont_intermediar)+' - '+RTRIM(ci.Denumire_cont) as dencontintermediar,
		rtrim(p.Cont_factura) as contfactura, rtrim(p.Cont_factura)+' - '+RTRIM(cf.Denumire_cont) as dencontfactura,
		rtrim(p.Cont_venituri) as contvenituri, rtrim(p.Cont_venituri)+' - '+RTRIM(cv.Denumire_cont) as dencontvenituri,
		RTRIM(RIGHT(comanda,20)) as indbug, --indicatorul bugetar se tine in ultimele 20 de caractere ale campului comanda din pozdoc
		convert(char(1),p.Procent_vama) as tiptva, p.idpozdoc, 
		p.detalii
	from pozdoc p
		left join nomencl n on n.Cod=p.Cod 
		left join conturi cs on cs.Cont=p.Cont_de_stoc
		left join conturi cc on cc.Cont=p.Cont_corespondent
		left join conturi ci on ci.Cont=p.Cont_intermediar
		left join conturi cf on cf.Cont=p.Cont_factura
		left join conturi cv on cf.Cont=p.Cont_venituri
		left join terti t on t.Tert=p.Tert
		left join gestiuni g on g.cod_gestiune=p.gestiune
	where p.idPozdoc=@idpozdoc
	for xml raw

	select 1 as areDetaliiXml for xml raw, root('Mesaje')
end try 

begin catch
	declare @error varchar(500)
	set @error='(wOPModificareDatePozitie_p:) '+ ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@error,16,1)
end catch
