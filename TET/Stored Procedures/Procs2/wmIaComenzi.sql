--***
CREATE procedure wmIaComenzi @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmIaComenziSP' and type='P')
begin
	exec wmIaComenziSP @sesiune, @parXML 
	return -1
end

	/* Citesc din commited deoarece se apeleaza proc. si dupa scriere comenzi **/
	set transaction isolation level READ COMMITTED
	declare 
		@utilizator varchar(100),@subunitate varchar(9),@stare varchar(10), @tert varchar(30), @idPunctLivrare varchar(100),
		@stareBkFacturabil varchar(20), @nrComenzi int, @rasp varchar(max), @date xml, @actiuni xml, @gestiune varchar(50),
		@areGestProp bit, @tipdetalii varchar(50), @meniuDetalii varchar(50), @procDetalii varchar(255),
		@faraFiltruUtilizator varchar(50), @viewNeimportant char(1), @gestiuneDepozitBK varchar(20)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	if @utilizator is null
		return -1

	/** Citire date din par */
	select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @subunitate end),
			@stareBkFacturabil=(case when Parametru='STBKFACT' then rtrim(Val_alfanumerica) else @stareBkFacturabil end)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru = 'STBKFACT')

	/** Se filtreaza pe tert/pct liv. cand se apeleaza din meniul tertului */
	select	@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
			@stare=isnull(@parXML.value('(/row/@stare)[1]','varchar(20)'),'0'),
			@gestiune=isnull(@parXML.value('(/row/@gestiune)[1]','varchar(20)'),''),
			@gestiuneDepozitBK= @parXML.value('(/*/@gestiuneDepozitBK)[1]','varchar(20)'),
			@faraFiltruUtilizator=isnull(@parXML.value('(/row/@wmIaComenzi.faraFiltruUtilizator)[1]','varchar(20)'),'0'),
			@viewNeimportant=@parXML.value('(/row/@wmIaComenzi.viewNeimportant)[1]','varchar(20)'),
			@procDetalii=isnull(@parXML.value('(/row/@wmIaComenzi.procdetalii)[1]', 'varchar(50)'),'wmComandaLivrare'),
			@tipdetalii=@parXML.value('(/row/@wmIaComenzi.tipdetalii)[1]', 'varchar(50)'), 
			@meniuDetalii=@parXML.value('(/row/@wmIaComenzi.meniuDetalii)[1]', 'varchar(50)')
			
	declare @gestProp table(gest varchar(50))
	insert into @gestProp(gest)
	select rtrim(p.Valoare)
	from proprietati p
	where p.Tip='UTILIZATOR' and p.Tip='GESTIUNE' and p.Cod=@utilizator and p.Valoare<>''
	
	set @areGestProp = (case when exists (select * from @gestProp) then 1 else 0 end)
	
	set @actiuni=(select * from 
						(select '<NOUPJ>' as comanda,'Comanda noua' as denumire,'assets/Imagini/Meniu/comanda.png' as poza,'0x0000ff' as culoare
						where @stare='0') actunificate 
		for xml raw,type)
	set @date=
	(	select top 100 
			rtrim(c.idContract) as comanda, 
			rtrim(case when @tert is not null then RTRIM(max('Comanda ' +c.numar)) when max(c.Explicatii)!='' then rtrim(max(c.Explicatii)) 
					else rtrim(ISNULL(max(t.denumire),isnull(rtrim(max(gestPrim.Denumire_gestiune)),RTRIM(max('Comanda ' +c.numar))))) end) as denumire, 
			LTRIM(str(isnull(count(pc.cantitate),0)))+' pozitii: '+rtrim(convert(decimal(12,2),isnull(sum(pc.Cantitate*pc.Pret*(1-pc.discount/100)),0)))+' LEI'  as info,
			isnull(@tert, rtrim(max(c.Tert))) tert, ISNULL(@idPunctLivrare,ISNULL(rtrim(max(c.Punct_livrare)),'')) pctliv
		from Contracte c
		left JOIN PozContracte pc on c.idContract=pc.idContract AND c.tip='CL' 
		INNER JOIN 
		(
			select 
				jc.idContract,jc.stare, jc.utilizator, RANK() OVER (partition by idcontract order by jc.data desc, jc.idJurnal desc) rc
			from JurnalContracte jc 
		) stari on stari.rc='1' AND stari.utilizator=@utilizator and stari.stare=@stare and stari.idContract=c.idContract
		left outer join terti t on c.Tert=t.Tert and t.subunitate=@subunitate
		left outer join gestiuni gestPrim on gestPrim.Cod_gestiune=c.gestiune_primitoare and gestPrim.subunitate=@subunitate
		left join @gestProp gp on gp.gest=c.gestiune
		where (@tert is null or c.Tert=@tert)
		and (@gestiune='' or c.gestiune=@gestiune )
		and (@areGestProp=0 or gp.gest is not null )
		and (@gestiuneDepozitBK IS null or c.gestiune=@gestiuneDepozitBK)
		-- aici va trebuig gandit un filtru... eventual cele realizate sa nu le mai aduca
		group by c.idContract
		order by c.idcontract desc
		for xml raw
	)
	/** Selectul care populeaza view-ul din mobile **/
	select @actiuni, @date for xml path('Date')

	select 
		'Comenzi '+(case @stare when '0' then 'deschise' when @stareBkFacturabil then 'de facturat' else 'in stare '+@stare end) as titlu,
		0 as areSearch, '1' toateAtr, @procDetalii as _procdetalii, @tipdetalii _tipdetalii, dbo.f_wmIaForm(@meniuDetalii) form,
		@viewNeimportant _neimportant
	for xml raw,Root('Mesaje')
