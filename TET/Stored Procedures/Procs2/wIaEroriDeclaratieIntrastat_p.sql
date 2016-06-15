--***
create procedure wIaEroriDeclaratieIntrastat_p @sesiune varchar(50), @parXML XML
as   
/*
	exec wIaEroriDeclaratieIntrastat_p @sesiune=null, @parXML='<row data="06/30/2013" flux="I" />'
*/
begin try
	set transaction isolation level read uncommitted
	declare @tip varchar(2), @data datetime, @dataJos datetime, @dataSus datetime, @flux varchar(10), @denflux varchar(50), @faramesaj int, 
		@utilizator varchar(20), @mesajeroare varchar(500), @rezultat xml, @dincgplus int
		
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
--	citire date din xml
	select 
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),''),
		@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),isnull(@parXML.value('(/row/@datalunii)[1]','datetime'),'1901-01-01')),
		@flux = isnull(@parXML.value('(/row/@flux)[1]','varchar(10)'),'I'),
		@denflux = isnull(@parXML.value('(/row/@denflux)[1]','varchar(50)'),'Introducere'),
		@faramesaj = isnull(@parXML.value('(/row/@faramesaj)[1]','int'),0),
		@dincgplus = isnull(@parXML.value('(/row/@dincgplus)[1]','int'),0)

	select @dataJos = dbo.bom(@data), @dataSus = dbo.eom(@data)
		
	if object_id('tempdb..#erori') IS NOT NULL drop table #erori
	if object_id('tempdb.dbo.#declintrastat') is not null drop table #declintrastat
	if object_id('tempdb.dbo.#gdeclintrastat') is not null drop table #gdeclintrastat

--	tabela temporara in care pun datele negrupate
	create table #declintrastat (tip char(2), numar varchar(20), data datetime, cod varchar(20), cod_vamal varchar(20), cod_NC8 varchar(20), 
		val_facturata float, val_statistica float, masa_neta float, UM2 varchar(20), cant_UM2 float, natura_tranzactie_a varchar(20), natura_tranzactie_b varchar(20), 
		cond_livrare varchar(20), mod_transport varchar(20), tara_tert varchar(20), tara_origine varchar(20), dencodv varchar(80), 
		cif_partener varchar(20), tert varchar(13), punct_livrare varchar(5), factura varchar(20))
--	tabela temporara in care pun datele grupate
	create table #gdeclintrastat (nr_ord int, cod_NC8 varchar(20), val_facturata float, val_statistica float, masa_neta float, UM2 varchar(20), cant_UM2 float, 
		natura_tranzactie_a varchar(20), natura_tranzactie_b varchar(20), cond_livrare varchar(20), mod_transport varchar(20), tara_tert varchar(20), tara_origine varchar(20), dencodv varchar(80), 
		cif_partener varchar(20), tert varchar(13), punct_livrare varchar(5), factura varchar(20))

	insert into #declintrastat
	exec rapDeclaratieIntrastat @datajos=@datajos, @datasus=@datasus, @flux=@flux, @tipdecl='N', @faraGrupare='1'

	insert into #gdeclintrastat
	exec rapDeclaratieIntrastat @datajos=@datajos, @datasus=@datasus, @flux=@flux, @tipdecl='N', @faraGrupare='0'
	
	select tip, numar, data, cod, camp, valoare
	into #erori
	from (select tip, numar, data, cod, cod_vamal, cod_NC8, natura_tranzactie_a, cond_livrare, mod_transport, tara_tert, tara_origine, cif_partener from #declintrastat) a
	unpivot 
	(valoare for camp in (cod_vamal, cod_NC8, natura_tranzactie_a, cond_livrare, mod_transport, tara_tert, tara_origine, cif_partener)) as unpvt; /** folosind operatorul unpivot se aduc toate valorile intr-o singura coloana, detaliere erori */

	alter table #erori add explicatii varchar(500)

	update #erori set explicatii=(case when camp='cod_NC8' and valoare='' then 'Cod NC8 necompletat' 
		when camp='natura_tranzactie_a' and valoare='' then 'Natura tranzactiei (A) necompletata'
		when camp='cond_livrare' and valoare='' then 'Conditii de livrare necompletate'
		when camp='mod_transport' and valoare='' then 'Mod transport necompletat'
		when camp='tara_tert' and valoare='' then 'Tara de '+(case when @flux='I' then 'expediere' else 'destinatie' end)+' necompletata!'
		when camp='tara_tert' and valoare<>'' and not exists (select 1 from tari t where t.cod_tara=valoare) then 'Tara de '+(case when @flux='I' then 'expediere' else 'destinatie' end)+' incorecta!'
		when camp='tara_origine' and valoare='' then 'Tara de origine necompletata!' 
		when camp='tara_origine' and valoare<>'' and not exists (select 1 from tari t where t.cod_tara=valoare) then 'Tara de origine incorecta!'
		when camp='cif_partener' and year(@data)>=2015 and valoare='' then 'CIF partener necompletat!' else '' end)

	insert into #erori
	select tip as tipdoc, numar, data, cod, 'cantitate UM2', convert(char(15),cant_um2), 'Cantitate negativa sau nula in UM suplimentara'
	from #declintrastat
	where UM2<>'' and UM2<>'-' and cant_UM2<0
	union all 
	select tip as tipdoc, numar, data, cod, 'masa neta', convert(char(15),masa_neta), 'Masa neta nula'
	from #declintrastat
	where masa_neta=0
	union all 
	select tip as tipdoc, numar, data, cod, 'natura_tranzactie_b', natura_tranzactie_b, 'Natura tranzactiei (B) necompletata'
	from #declintrastat
	where natura_tranzactie_a in ('1','2','3') and natura_tranzactie_b=''
	union all 
	select '' as tipdoc, '' as numar, '01/01/1901' as data, cod_NC8 as cod, 'val_facturata', convert(char(15),val_facturata), 'Valoare facturata negativa pe cod nom. combinat'
	from #gdeclintrastat
	where natura_tranzactie_a in ('1','2','3') and natura_tranzactie_b=''
	delete from #erori where explicatii=''

--	returnare date
	if @dincgplus=0
	begin
		select @rezultat=
		(select tip as tip, numar as numar, convert(char(10),data,101) as data, rtrim(cod) as cod, explicatii as explicatii
		from #erori 
		for xml raw )

		SELECT dbo.fDenumireLuna(@datasus) AS numeluna, convert(char(4),year(@datasus)) AS an, @denflux as denflux
		FOR XML RAW, ROOT('Date')

		if @rezultat is null 
		begin
			select 1 as inchideFereastra for xml raw,root('Mesaje')	
			if @faramesaj=0
				select 'Declaratia intrastat nu are erori!' as textMesaj, 'Mesaj' as titluMesaj for xml raw, root('Mesaje')
		end
		else 
			SELECT (SELECT @rezultat)  
				FOR XML PATH('DateGrid'), ROOT('Mesaje')
	end
	else
	begin
		if object_id('tempdb..#EroriIntrastatPlus') is not null
			insert into #EroriIntrastatPlus (tip, numar, data, cod, explicatii)
			select tip, numar, data, cod, explicatii
			from #erori
		else
			select tip, numar, data, cod, explicatii
			from #erori
	end
end try

begin catch
	set @mesajeroare='wIaEroriDeclaratieIntrastat_p (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+ERROR_MESSAGE()
	raiserror(@mesajeroare, 16, 1)
end catch

if object_id('tempdb..#erori') IS NOT NULL drop table #erori
if object_id('tempdb.dbo.#declintrastat') is not null drop table #declintrastat
if object_id('tempdb.dbo.#gdeclintrastat') is not null drop table #gdeclintrastat


