--***

create procedure wmFactureazaComanda @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmFactureazaComandaSP' and type='P')
begin
	exec wmFactureazaComandaSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
begin try
	declare 
		@utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @stareBkFacturabil varchar(20),
		@idpunctlivrare varchar(100), @comanda varchar(100), @eroare varchar(4000), @data datetime, @IesFaraStoc bit, 
		@tipGestiune varchar(10),@xml xml, @NrDocFisc varchar(10), @stare varchar(20), @gestiune varchar(20), @lm varchar(20), @numedelegat varchar(80),
		@codFormular varchar(100)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	select @codFormular= isnull(rtrim(dbo.wfProprietateUtilizator('FormAP', @utilizator)),'')
	if @codFormular=''
		raiserror('Formularul folosit la tiparire factura nu este configurat! Verificati proprietatea FormAP pe utilizatorul curent.',11,1)

	
	select	@tert=@parXML.value('(/row/@tert)[1]','varchar(20)'),
			@idPunctLivrare=@parXML.value('(/row/@pctliv)[1]','varchar(100)'),
			@comanda=@parXML.value('(/row/@comanda)[1]','varchar(20)')

	/** Citire date din par */
	select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @subunitate end),
			@IesFaraStoc=(case when Parametru='FARASTOC' then Val_logica else @IesFaraStoc end),
			@stareBkFacturabil=(case when Parametru='STBKFACT' then rtrim(Val_alfanumerica) else @stareBkFacturabil end)
	from par
	where (Tip_parametru='GE' and Parametru in ('SUBPRO', 'FARASTOC')) or (Tip_parametru='UC' and Parametru = 'STBKFACT')
	
	/** Citesc date din antet **/
	select top 1 @gestiune=cst.gestiune, @tert=cst.tert, @data=cst.data, @stare=cst.stare, @lm=cst.loc_de_munca
	from (
			select
				jc.stare, jc.utilizator, RANK() over (order by jc.data desc, jc.idJurnal desc) rn,
				c.*
			from Contracte c
			JOIN JurnalContracte jc on jc.idContract=c.idContract and tip='CL' and c.idContract=@comanda
		) cst where	cst.rn='1' and cst.utilizator=@utilizator 

	if @stare=0
	BEGIN
		declare @definitivare xml
		set @definitivare=
		(
			select @comanda idContract for xml RAW
		)

		exec wOPDefinitivareContract @sesiune=@sesiune, @parXML=@definitivare
	end

	/** nume delegat=nume user logat **/
	select @numedelegat=rtrim(u.Nume) from utilizatori u where u.ID=@utilizator
	select @tipGestiune=rtrim(g.Tip_gestiune) from gestiuni g where g.Cod_gestiune=@gestiune
	
	/** Verificare stocuri */
	if @IesFaraStoc=0
	begin
		create table #wmFactureazaComanda_tmpStoc(cod varchar(20) primary key, cantitate float, cantitate_disponibila float)
		
		insert #wmFactureazaComanda_tmpStoc(cod, cantitate, cantitate_disponibila)
		select p.cod, sum(p.cantitate), isnull((select SUM(s.stoc) from stocuri s where s.Subunitate=@subunitate and s.Tip_gestiune=@tipGestiune
			and s.Cod_gestiune=@gestiune and s.Cod=p.cod and s.Stoc>0.0009),0)
		from PozContracte p 
		where p.idContract=@comanda and p.cantitate>0.001
		group by p.cod

		if exists (select 1 from #wmFactureazaComanda_tmpStoc where cantitate_disponibila-cantitate<0)
		begin
			if @eroare is not null
				set @eroare=@eroare+CHAR(13)
			select @eroare=isnull(@eroare+' ,', 'Stoc indisponibil pentru produsele: ') + RTRIM(n.denumire) 
			from #wmFactureazaComanda_tmpStoc t 
			inner join nomencl n on t.cod=n.Cod
			where t.cantitate_disponibila-t.cantitate<0
			
			raiserror (@eroare, 11, 1)
		end
	end
	
	/** iau numar document */
	--set @xml= (select 'AP' tip, @utilizator utilizator for xml raw)
	--exec wIauNrDocFiscale @parxml=@xml, @NrDoc=@NrDocFisc output

	-- generare AP
	set @xml = 
		(
			select 
				@comanda idContract, @gestiune gestiune,  @tert tert, @lm lm,convert(varchar,@data,101) data,
				@numedelegat numedelegat, rtrim(dbo.wfProprietateUtilizator('NrAuto',@utilizator)) nrmijloctransport,
				dbo.wfProprietateUtilizator('SerieCI',@utilizator) seriabuletin,'' mijloctransport,
				rtrim(dbo.wfProprietateUtilizator('NumarCI',@utilizator)) numarbuletin,
				rtrim(dbo.wfProprietateUtilizator('EliberatCI',@utilizator)) eliberat,				
				'Factura generata din ASiSmobile' observatii, 1 fara_mesaj,
				(
					select
						idPozContract idPozContract, RTRIM(cod) cod, convert(decimal(15,3),cantitate) as defacturat, convert(decimal(15,3),cantitate) as rezervat, @gestiune as gestiune
					from PozContracte where idContract=@comanda
					for xml RAW, root('DateGrid'), type
				)
			for xml raw
		)
	exec wOPGenerareFactura @sesiune=@sesiune, @parXML=@xml OUTPUT

	/** Iau numarul documentului (s-a luat numar din plaja in interiorul procedurii ... ) **/
	set @NrDocFisc = @xml.value('(/*/@numar)[1]','varchar(20)')

	/* Tiparire factura **/
	set @xml = (select @NrDocFisc numar, @data data for xml raw)
	exec wmTiparesteFactura @sesiune=@sesiune, @parXML=@xml
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wmFactureazaComanda)'
end catch	

begin try 
	if OBJECT_ID('#wmFactureazaComanda_tmpStoc') is not null
		drop table #wmFactureazaComanda_tmpStoc
end try 
begin catch end catch

if len(@eroare)>0
	raiserror(@eroare, 16, 1) 

select 
	'Tiparire factura: '+convert(varchar(30),@NrDocFisc) as titlu, '@numar' numeatr, 0 as areSearch
for xml raw,Root('Mesaje')   


