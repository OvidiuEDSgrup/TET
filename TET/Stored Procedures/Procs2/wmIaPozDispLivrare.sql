/*

*/
CREATE PROCEDURE wmIaPozDispLivrare @sesiune varchar(50), @parXML xml
AS
set transaction isolation level read uncommitted
begin try
	if exists (select 1 from sysobjects where [type]='P' and [name]='wmIaPozDispLivrareSP')
	begin 
		declare @returnValue int
		exec @returnValue = wmIaPozDispLivrareSP @sesiune=@sesiune, @parXML=@parXML output
		if @parXML is null
			return @returnValue
	end

	declare @tipdisp varchar(50), @utilizator varchar(50), @mesaj varchar(1000), @culoarePozNeatinsa varchar(50), @culoareFinalizata varchar(50), 
		@culoareSupracantitate varchar(50), @culoareInLucru varchar(50), @culoareScanare varchar(50), @idDisp int, @searchText varchar(100), 
		@gestiune varchar(50), @tert varchar(50), @gestPrim varchar(50), @xmlPoz xml, @xmlAdaugPoz xml, @xmlSchimbGestiune xml, @xmlSchimbGestPrim xml, @xmlSchimbTert xml,
		@xmlInchideDisp xml, @descriereDisp varchar(500), @stareDisp varchar(50)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	select	@tipdisp = @parXML.value('(/*/@tipdisp)[1]', 'varchar(50)'),
			@idDisp = isnull(@parXML.value('(/*/@iddisp)[1]', 'int'),0),
			@searchText = '%' + ISNULL(REPLACE(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'),' ', '%') ,'') + '%'
	
	-- daca nu exista @idDisp in xml, apelam procedura care se ocupa de antet
	if @idDisp=0
	begin
		exec wmScriuAntetDispLivrare @sesiune=@sesiune, @parXML=@parXML output
		set @idDisp = isnull(@parXML.value('(/*/@iddisp)[1]', 'int'),0)
		
		-- daca procedura nu creaza un antet nou, nu mai fac nimic - se face din acea procedura.
		if @iddisp=0
			return 0
	end
	
	if not exists (select * from AntDisp where idDisp = @idDisp)
		raiserror('Dispozitia aleasa nu exista in baza de date.',16,1)
	
	-- citesc date de antet
	select	@stareDisp = a.stare,
			@gestiune = a.detalii.value('(/*/@gestiune)[1]', 'varchar(50)'),
			@tert = a.detalii.value('(/*/@tert)[1]', 'varchar(50)'),
			@gestPrim = a.detalii.value('(/*/@gestprim)[1]', 'varchar(50)')
	from AntDisp a
	where a.idDisp = @idDisp
	
	select	@culoarePozNeatinsa = '0x000000', 
			@culoareFinalizata = '0xC3C3C3', 
			@culoareSupracantitate = '0x8A0808', --'0x660033', 
			@culoareInLucru = '0xF9BB00', 
			@culoareScanare = '0x66FF33'

	-- inseram aici toate liniile necesare din PozDispOp si PozDispScan, pentru ordonare ulterioara
	declare @pozitii table(cod varchar(20), denumire varchar(100), info varchar(200), culoare varchar(50), 
		stare int, iddisp int, idpoz int, idpozscan int, codbare varchar(50), actiune varchar(100), form xml, poza varchar(500))
	
	-- inserez toate codurile de pe dispozitie, filtrate dupa @searchText
	insert into @pozitii(cod, denumire, info, culoare, stare, /*codbare, */iddisp, idpoz, actiune, poza)
		select 
			po.cod as cod, 
			rtrim(n.Denumire) as denumire,  
			ltrim(isnull(str(ps.cantitate, 10, 2 ), '0')) + (case when po.cantitate is null then '' else ' / ' + ltrim(isnull(str(po.cantitate, 10, 2),'0')) end)
				+' '+rtrim(n.UM)/*+' scanate'*/ as info,
			(case	when isnull(ps.cantitate,0) = 0 then @culoarePozNeatinsa
					when ps.cantitate = po.cantitate then @culoareFinalizata
					when ps.cantitate > po.cantitate then @culoareSupracantitate
					else @culoareInLucru
				end) as culoare, 
			(case	when isnull(ps.cantitate,0) = 0 then 0 -- neatins
					when isnull(ps.cantitate,0) < po.cantitate then -1 -- in lucru
					when isnull(ps.cantitate,0) = po.cantitate then 9 -- finalizat
					when isnull(ps.cantitate,0) > po.cantitate then 3 -- supra-cantitate
					else 0 -- nu ar trebui sa ajunga aici
				end) as stare, 
			--@codcitit as codBare,
			@idDisp, 
			po.idPoz, 
			/*null*/'back(0)' actiune,
			'assets/Imagini/Meniu/Decontari.png' poza
		from PozDispOp po
		inner join nomencl n on po.cod = n.Cod
		outer apply (select idpoz, sum(cantitate) cantitate from pozdispscan ps where ps.idPoz=po.idPoz group by idPoz) ps 
		where	po.idDisp = @idDisp 
				and (n.denumire like @searchText or po.cod like @searchText)
				--and (@codScanat is null or po.cod = @codScanat)
	
	-- inserez linii cu pozitiile scanate pe terminalul mobil
	-- se insereaza doar liniile aferente pozitiilor filtrate mai sus
	insert into @pozitii(cod, denumire, info, culoare, stare, codbare, iddisp, idpoz, idpozscan, form)
		select po.cod as cod, 
			convert(varchar(30),ps.cantitate) + ' ' + rtrim(n.um) + ' ' + (case tipPozitie when 'cantOk' then 'ok' when 'cantSp' then 'spart' else '' end) as denumire,
			ps.detalii.value('/row[1]/@info', 'varchar(50)') as info,
			(case	when po.culoare=@culoareFinalizata then @culoareFinalizata 
					when tipPozitie is null then @culoareScanare 
					else @culoarePozNeatinsa end) as culoare,
			po.stare as stare,
			codbare as codBare,
			@idDisp, 
			po.idPoz, 
			ps.idPozScan, 
			dbo.f_wmIaForm(case tipPozitie when 'cantOk' then 'WO' when 'cantSp' then 'WS' else null end) as form
		from PozDispScan ps
		inner join @pozitii po on ps.idPoz=po.idPoz
		inner join nomencl n on po.cod = n.Cod
	
	if @stareDisp = 'Finalizata' -- momentan, daca e finalizata comanda, nu permit modificari pe dispozitie, ci doar consultare.
		update @pozitii set actiune='back(0)'
	
	set @xmlPoz = 
	(select *
		from @pozitii p
		order by p.idpoz, idpozscan
		for xml raw)
	
	set @xmlInchideDisp = (select 'Inchide dispozitie' denumire, 'assets/Imagini/Meniu/Realizari.png' as poza, 'wmInchideDispLivrare' as procdetalii, 'C' _tipdetalii for xml raw)
	
	set @xmlAdaugPoz = (select 'Adaugare cod nou' denumire, 'assets/Imagini/Meniu/AdaugProdus32.png' as poza, 'wmAlegCodDispLivrare' as procdetalii, 'C' _tipdetalii for xml raw)
	
	set @xmlSchimbGestiune = 
		(select 'Schimbare gestiune' denumire, @gestiune+' - '+rtrim(g.Denumire_gestiune) as info,
				'assets/Imagini/Meniu/Utilaje.png' as poza, '' gestiune, 1 _toateAtr, 
				'wmIaPozDispLivrare' as [wmSchimbGestiuneDispozitie.procdetalii],
				'wmSchimbGestiuneDispozitie' as procdetalii, 'C' _tipdetalii 
			from gestiuni g where g.Cod_gestiune=@gestiune and g.Subunitate='1'
			for xml raw)
	
	if @tipdisp ='AP'
		set @xmlSchimbTert = 
			(select 
				(select @tert+' - '+RTRIM(t.Denumire) from terti t where t.tert=@tert and t.Subunitate='1') as info,
					'Schimbare tert' denumire, 'assets/Imagini/Meniu/Utilaje.png' as poza, 'wmSchimbTertDispozitie' as procdetalii, 'C' _tipdetalii 
				for xml raw)
	
	if @tipdisp ='TE'
		set @xmlSchimbGestPrim = 
			(select (select @gestPrim+' - '+rtrim(g.Denumire_gestiune) from gestiuni g where g.Cod_gestiune=@gestPrim and g.Subunitate='1') as info,
					'Schimbare gestiune primitoare' denumire, 
					'assets/Imagini/Meniu/Utilaje.png' as poza, '' gestprim, 1 _toateAtr, 
					'@gestprim' [wmSchimbGestiuneDispozitie.numeAtr],
					'wmSchimbGestiuneDispozitie' as procdetalii, 'C' _tipdetalii 
				for xml raw)
	
	if @stareDisp = 'Finalizata'
		select @xmlInchideDisp=null, @xmlAdaugPoz=null, @xmlSchimbGestiune=null, @xmlSchimbTert=null, @xmlSchimbGestPrim=null
	
	select @xmlInchideDisp, @xmlAdaugPoz, @xmlPoz, @xmlSchimbGestiune, @xmlSchimbTert, @xmlSchimbGestPrim
	for xml raw('Date')
	
	select @descriereDisp = descriere from AntDisp where idDisp=@idDisp
	select 'Dispozitia '+@descriereDisp as titlu, dbo.f_wmIaForm('DL') form, 'wmScriuPozDispLivrare' _procdetalii, 'D' _tipdetalii
	for xml raw, root('Mesaje')
	
end try
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wmIaPozDispLivrare)'
END CATCH

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 11, 1)

/*

select * from pozdispop
select * from pozdispscan

*/
