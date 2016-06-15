

create procedure wIaSituatieRezervari @sesiune varchar(50),@parXML XML      
as

	declare
		@cuGestRez bit, @gest_rez varchar(20), @f_cod varchar(20), @f_denumire varchar(100), @f_tert varchar(100), @f_gestiune varchar(100), @f_comanda varchar(100),
		@f_lm varchar(100)

	exec luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@cuGestRez output, @val_n=NULL, @val_a=@gest_rez output

	/*
	if isnull(@cuGestRez,0)=0
		raiserror('Parametrul REZSTOCBK nu este configurat sa foloseasca gestiune de rezervari.',16,1)
	*/

	select
		@f_cod = @parXML.value('(/row/@f_cod)[1]','varchar(20)'),
		@f_denumire = '%' + replace(isnull(@parXML.value('(/row/@f_denumire)[1]','varchar(100)'),''),' ','%') + '%',
		@f_tert = '%' + replace(isnull(@parXML.value('(/row/@f_tert)[1]','varchar(100)'),''),' ','%') + '%',
		@f_gestiune = '%' + replace(isnull(@parXML.value('(/row/@f_gestiune)[1]','varchar(100)'),''),' ','%') + '%',
		@f_comanda = '%' + replace(isnull(@parXML.value('(/row/@f_comanda)[1]','varchar(100)'),''),' ','%') + '%',
		@f_lm = '%' + replace(isnull(@parXML.value('(/row/@f_lm)[1]','varchar(100)'),''),' ','%') + '%'

	select top 100
		p.idPozDoc,
		rtrim(p.cod) as cod,
		rtrim(n.denumire) as denumire,
		convert(decimal(15,2),p.Pret_de_stoc) as pret,
		convert(decimal(15,2),p.Cantitate) as cantitate,
		rtrim(n.UM) as um,
		convert(varchar(10),p.data,101) as data,
		rtrim(isnull(t.denumire,'')) as tert,
		rtrim(g.Denumire_gestiune) as gestiune,
		rtrim(c.numar) as comanda
	from pozdoc p
		inner join nomencl n on p.cod=n.cod
		inner join LegaturiContracte lc on p.idPozDoc=lc.idPozDoc
		inner join PozContracte pc on lc.idPozContract=pc.idPozContract
		inner join Contracte c on c.idContract=pc.idContract
		left join lm l on l.Cod=c.loc_de_munca
		left join terti t on p.Subunitate=t.Subunitate and t.tert=c.tert
		left join Gestiuni g on g.subunitate=p.Subunitate and g.Cod_gestiune=pc.detalii.value('(/row/@gestiune)[1]','varchar(20)')
	where p.Gestiune_primitoare=@gest_rez
		and (@f_cod is null or p.cod like '%' + @f_cod + '%')
		and (n.Denumire like @f_denumire)
		and (ISNULL(t.Denumire,'') like @f_tert)
		and (isnull(g.denumire_gestiune,'') like @f_gestiune)
		and (c.numar like @f_comanda)
		and (isnull(c.loc_de_munca,'') like @f_lm or isnull(l.denumire,'') like @f_lm)
	order by p.data desc, p.Cod
	for xml raw, root('Date')
	
