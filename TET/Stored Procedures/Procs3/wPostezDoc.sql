
CREATE procedure wPostezDoc @sesiune varchar(50), @parXML xml
as
	/** Procedura se apeleaza in momentul in care se inchide o macheta de Document PozDoc 
		in webConfigTipuri coloana ProcInchidereMacheta
	**/
	declare 
		@subunitate varchar(9), @tip varchar(2), @numar varchar(20), @data datetime

	set @subunitate=@parXML.value('(/*/@subunitate)[1]','varchar(9)')
	set @tip=@parXML.value('(/*/@tip)[1]','varchar(2)')
	set @numar=@parXML.value('(/*/@numar)[1]','varchar(20)')
	set @data=@parXML.value('(/*/@data)[1]','datetime')
	
	--if @tip in ('RM','RS','AP','AS','FB','IF','FF','SF')
	--	exec contTVADocument @Subunitate=@subunitate, @Tip=@tip, @Numar=@numar, @Data=@data
	if exists (select 1 from DocDeContat where Subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data)
		exec faInregistrariContabile @dinTabela=0, @Subunitate=@subunitate, @Tip=@tip, @Numar=@numar, @Data=@data

	/*	apelare operatie pt. culegere date Intrastat */
	if @tip in ('RM','AP')
		and exists (select 1 from pozdoc p
					left outer join doc d on d.subunitate=p.subunitate and p.tip=d.tip and p.numar=d.numar and p.data=d.data 
					left outer join tari on tari.cod_tara=isnull(d.detalii.value('/row[1]/@taraexp', 'varchar(20)'),'')
					inner join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
					inner join infotert i on t.subunitate=i.subunitate and t.tert=i.tert and i.identificator=''
					inner join nomencl n on p.cod=n.cod
				where p.Subunitate=@subunitate and p.tip=@tip and p.numar=@numar and p.data=@data 
					and (tari.teritoriu is null and i.zile_inc=1 or tari.teritoriu is not null and isnull(tari.teritoriu,'')='U') 
					and n.tip not in ('R', 'S') and abs(p.pret_valuta)>=0.000001)
	begin
		select 'Date intrastat' nume, 'DO' codmeniu, 'D' tipmacheta, @tip tip, 'IS' subtip,'O' fel,
			(select @parXML) dateInitializare
		for xml raw('deschideMacheta'), ROOT('Mesaje')

		select 1 areDetaliiXml for xml raw, root('Mesaje')
	end
