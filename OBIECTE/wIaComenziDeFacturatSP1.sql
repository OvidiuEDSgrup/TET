drop procedure [dbo].[wIaComenziDeFacturatSP1] 
go
create procedure [dbo].[wIaComenziDeFacturatSP1] @sesiune varchar(50), @parXML xml, @xmlString varchar(max) output
as  
set transaction isolation level read uncommitted
begin try
	
	declare @subunitate varchar(20), @userASiS varchar(20), @gestiune varchar(20), @filtru varchar(100), @tert varchar(100), @categpret int,
		@data datetime
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	exec luare_date_par @tip='GE', @par='SUBPRO', @val_l=null, @val_n=null, @val_a=@subunitate output

	-- in filtru se trimite denumirea tertului.
	set @filtru= isnull(@parXML.value('(/row/@searchText)[1]','varchar(80)'), 
					isnull(@parXML.value('(/row/@filtru)[1]','varchar(80)'),'')) 
		
	set @tert=@parXML.value('(/row/@tert)[1]','varchar(80)')
	
	if isnull(@tert,'')='' -- identific cod tert
		set @tert = isnull(( select RTRIM(tert) from terti where Subunitate=@subunitate and Denumire=@filtru ),'')
	else
		-- sa apara in explicatii
		set @filtru=@filtru+' '+isnull(( select RTRIM(denumire) from terti where Subunitate=@subunitate and tert=@tert ),'')

--/*sp		
	if len(@tert)=0 --or not exists (select * from comenzi where Subunitate='1' and Comanda=@tert)
		return 0; -- daca nu gasesc tert sau comanda lui, nu mai calculez nimic
--sp*/
	set @gestiune='700'
	-- categoria e pret a tertului - daca are
	set @categpret=ISNULL((select sold_ca_beneficiar from terti where Subunitate='1' and tert=@tert),1)
	if @categpret=0
		set @categpret=1
	set @data=convert(datetime, CONVERT(char(10), getdate(),101),101)
	
	declare @coduri table(tert varchar(13), [contract] varchar(20),data varchar(10), cod varchar(20) , denumire varchar(100)
	, um varchar(3), cotatva int, stoc decimal(12,2),cod_intrare char(13), pret float, pret_comlivr float, disc_comlivr float
	, gestpredte varchar(9), gestiune varchar(9)) 	
	
	declare @GESTPV varchar(50)
	set @GESTPV=rtrim(dbo.wfProprietateUtilizator('GESTPV',@userASiS ))
		
	-- aduc toate codurile care sunt pe stoc in gestiune + comanda
	insert into @coduri(tert, [contract], data, cod
		, denumire, um, cotatva
		, stoc, cod_intrare, pret
		, pret_comlivr, disc_comlivr, gestpredte, gestiune)
	select RTRIM(max(pc.tert)), rtrim(s.Contract), convert(varchar(10),max(pc.Data),103), rtrim(s.Cod) as cod
		,rtrim(max(n.Denumire)) as denumire, rtrim(MAX(n.UM)), CONVERT(int, max(n.Cota_TVA))
		,SUM(s.stoc) stoc,max(s.Cod_intrare), s.Pret_cu_amanuntul pret
		,max(pc.Pret) as pret_comlivr, max(pc.Discount) as disc_comlivr
		/*,(select MAX(p.gestiune) from pozdoc p where p.Subunitate=MAX(s.Subunitate) and p.Tip='TE' 
			and p.Gestiune_primitoare=MAX(s.Cod_gestiune) and p.Cod=s.Cod and p.Grupa=MAX(s.Cod_intrare))*/ 
		,@GESTPV as gestpredte
		,s.Cod_gestiune as gestiune
	from stocuri s 
		inner join nomencl n on s.cod=n.cod
		left join pozcon pc on pc.Subunitate=s.Subunitate and pc.Tip='BK' and pc.Contract=s.Contract and pc.Cod=s.Cod
		--left join gestiuni gp on gp.Cod_gestiune=pc.Punct_livrare
	where 
	s.subunitate=@subunitate 
	and s.Cod_gestiune LIKE rtrim(@gestiune)+'%'
	and (s.Locatie=@tert or pc.Tert=@tert)
	and ABS(s.stoc)>0.001
	group by s.Contract, s.cod, s.Pret_cu_amanuntul, s.Cod_gestiune, s.Cod_intrare
	
	--if object_id('coduri_tbl_debug_tmp') is not null
	--	drop table	coduri_tbl_debug_tmp
	declare @codurixml xml=(select * from @coduri for xml raw)
	if @sesiune='' select @xmlString
	-- inserez coduri 
	set @xmlString=@xmlString+ISNULL( 
		(select --top 100 
				-- atribute hardcodate PV
				c.tert,
				c.[contract] as [contract],
				--comanda=RTRIM(c.contract),
				c.data,
				rtrim(c.Cod) as cod, rtrim(c.Denumire) as denumire, 
				(case when ROUND(c.stoc,0)=CONVERT(decimal(12,3),c.stoc) then ltrim(str(c.stoc))
						else LTRIM(CONVERT(decimal(12,3),c.stoc)) end) as cantitate, rtrim(c.um) as um,
				CONVERT(decimal(12,2),c.pret/**(1+convert(decimal(12,2),c.cotaTVA)/100.00)*/) as pretcatalog,
				c.cotatva as cotatva, 0 as discount,
				-- end atribute hardcodate PV
				
				RTRIM(gestiune) as gestiune,
				RTRIM(cod_intrare) as codintrare,
				1 as yso_stocinstalatori,
				convert(decimal(17,5),c.pret_comlivr) as yso_pretcomlivr,
				convert(decimal(12,2),c.disc_comlivr) as yso_disccomlivr,
				c.gestpredte as yso_gestpredte,
				ltrim(@filtru)+isnull('-'+nullif(RTRIM(c.[contract]),'')+'-'+RTRIM(c.data),'') explicatii, @tert comanda_asis,
				CONVERT(decimal(12,2),c.pret) as pret,
				CONVERT(decimal(12,2),c.stoc * c.pret/**(1+convert(decimal(12,2),c.CotaTVA)/100.00)*/) as valoare,
				CONVERT(decimal(12,3),c.stoc) as stocMaxim
				--,'701.AG' as gestiune
			from @coduri c
		/*	inner join preturi p on c.cod=p.Cod_produs and p.um='4' and p.Tip_pret='1' 
				and @data between p.Data_inferioara and p.Data_superioara
				*/
				--inner join pozdoc p on c.cod=p.Cod and p.tip='TE' and p.Comanda=@tert  and p.Gestiune_primitoare=@gestiune
				--and p.Pret_de_stoc=c.pret
				--and p.Grupa=c.cod_intrare
				--and p.Numar in (select top 1  numar from pozdoc where tip='TE' and Gestiune_primitoare=@gestiune and Comanda=@tert order by DATA desc)
				
				--and  substring(p.Cod_intrare,1,4)=substring(c.Cod_intrare,1,4)
			order by c.denumire
			for xml raw
		)+CHAR(13),'')
	if @sesiune='' select @xmlString	
end try
begin catch 
	declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT
	SELECT @ErrorMessage = ERROR_MESSAGE()+'(wIaComenziDeFacturatSP1)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

end catch


