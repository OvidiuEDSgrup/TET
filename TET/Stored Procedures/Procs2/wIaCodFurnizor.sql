--***
Create procedure wIaCodFurnizor  @sesiune varchar(30), @parXML XML
as
	begin
	declare 
		@cod varchar(20),@cautare varchar(100)
	set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
	set @cautare=@parXML.value('(/row/@_cautare)[1]','varchar(100)')
	set @cautare='%'+isnull(@cautare,'')+'%'

	IF OBJECT_ID('tempdb..#furnizori_cod') is not null
		drop table #furnizori_cod

	CREATE table #furnizori_cod 
		(tert varchar(20), pret float, data_pret datetime, cod_special varchar(20), nr_zile_livrare int, cant_minima float, tip varchar(1), prioritate int)

	/** Se iau furnizorii codului din PPRETURI  **/
	insert into #furnizori_cod (tert, pret, data_pret, cod_special,nr_zile_livrare, cant_minima, tip, prioritate)

	select 
		RTRIM(p.tert), rtrim(p.pret), p.Data_pretului, RTRIM(p.codfurn), RTRIM(p.nr_zile_livrare), RTRIM(p.cant_minima), 'P', p.prioritate
	from ppreturi p
	where p.Cod_resursa=@cod and Tip_resursa='C'

	IF EXISTS (SELECT * FROM sys.objects WHERE NAME = 'Contracte' AND type = 'U') and EXISTS (SELECT * FROM sys.objects WHERE NAME = 'PozContracte' AND type = 'U')
	begin
		/** Se iau furnizorii codului din Contracte furnizor  **/
		insert into #furnizori_cod (tert, pret, data_pret, cod_special,nr_zile_livrare, cant_minima, tip)
		select 
			c.tert, pc.pret, c.data,pc.cod_specific,isnull(pc.detalii.value('(/*/@nr_zile_livrare)[1]','int'),0),isnull(pc.detalii.value('(/*/@cant_minima)[1]','int'),0),'C'
		from Contracte c
		JOIN PozContracte pc on c.tip='CF' and c.idContract=pc.idContract and pc.cod=@cod
	end

	select 
		fc.tert tert, convert(decimal(15,2),fc.pret) pstoc, convert(varchar(10), fc.data_pret,101) datapret, RTRIM(fc.cod_special) codf,
		fc.nr_zile_livrare nrzilelivr, convert(decimal(15,2),fc.cant_minima) cantmin, RTRIM(t.denumire) dentert, fc.tip tip_sursa,
		(CASE fc.tip WHEN 'P' then 'Adaugat' when 'C' then 'Contract furn.'  end ) den_tip_sursa, fc.prioritate prioritate
	from #furnizori_cod fc
	JOIN terti t ON t.tert=fc.tert
	where rtrim(t.Denumire) like @cautare or @cautare=''
	order BY  ISNULL(fc.prioritate, 99) asc
	for xml raw,ROOT('Date')
end 
