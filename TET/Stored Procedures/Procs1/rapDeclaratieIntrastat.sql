--***
Create procedure rapDeclaratieIntrastat
	@datajos datetime, @datasus datetime, 
	@flux char(1)='I',		--	@Flux = I -> Introducere; E -> Expediere
	@tipdecl char(1)='N',	--	@tipdecl = N -> Noua; R -> Rectificativa; U -> Nula
	@faraGrupare char(1)='',	--	@faraGrupare='1' - afisare date negrupate
	@tabela bit=0	-->	0 = datele raman in tabela #intrastat, fara a fi selectate (pt utilizare ulterioara); 1 = datele se selecteaza la sfarsit
as
declare @eroare varchar(2000)
set @eroare=''
begin try
	declare @sub varchar(9), @UrmarireCantSec int, @ValidareTara int

	select @sub=max(case when tip_parametru='GE' and parametru='SUBPRO' then rtrim(val_alfanumerica) else '' end)
		,@UrmarireCantSec=max(case when tip_parametru='GE' and parametru='URMCANT2' then val_logica else 0 end)	
		,@ValidareTara=max(case when parametru='TARATERTI' then cast(val_logica as int) else 0 end)
	from par where tip_parametru='GE' and parametru in ('SUBPRO','URMCANT2','TARATERTI')

--	if object_id('tempdb.dbo.#intrastat') is not null drop table #intrastat
	if object_id('tempdb.dbo.#gintrastat') is not null drop table #gintrastat
	if object_id('tempdb.dbo.#pozdocIntrastat') is not null drop table #pozdocIntrastat

	if object_id('tempdb..#intrastat') is null
	begin
		create table #intrastat (nr_ord int)
		exec rapDeclaratieIntrastat_tabela
	end

	/*	Selectez datele in #pozdocIntrastat pentru a citi din pozdoc.detalii. Altfel join-ul pe codvama cu isnull(pozdoc.detalii, nomencl.detalii, nomencl.tip_echipament) dureaza mult. */
	select p.*, 
		isnull(nullif(p.detalii.value('/row[1]/@codvama','varchar(20)'),''),isnull(nullif(n.detalii.value('/row[1]/@codvama','varchar(20)'),''),substring(n.tip_echipament,2,20))) as cod_vamal,
		isnull(nullif(d.detalii.value('/row[1]/@taraexp', 'varchar(20)'),''),isnull(intst.cont_intermediar,'')) as tara_tert
	into #pozdocIntrastat
	from pozdoc p
		left outer join doc d on d.subunitate=p.subunitate and p.tip=d.tip and p.numar=d.numar and p.data=d.data 
		left outer join pozdoc intst on intst.subunitate='INTRASTAT' and p.tip=intst.tip and p.numar=intst.numar and p.data=intst.data and intst.numar_pozitie=0
		inner join nomencl n on p.cod=n.cod
	WHERE @tipdecl<>'U' and p.subunitate=@sub and p.tip=(case when @flux='I' then 'RM' else 'AP' end) and p.data between @datajos and @datasus
		and n.tip not in ('R', 'S') and abs(p.pret_valuta)>=0.000001 /*and (p.tip<>'RM' or p.numar_DVI='')*/
	
	insert into #intrastat(tip, numar, data, cod, cod_vamal, cod_NC8, 
		val_facturata, val_statistica, masa_neta, UM2, cant_UM2, natura_tranzactie_a, natura_tranzactie_b, cond_livrare, mod_transport, 
		tara_tert, tara_origine, dencodv, cif_partener, tert, punct_livrare, factura, cantitate)
		
	select p.tip, p.numar, p.data, p.cod, p.cod_vamal as cod_vamal, rtrim(isnull(c.alfa1,'')) as cod_NC8,
	round(convert(decimal(15,3), p.cantitate*(case when p.tip='RM' then p.pret_valuta*(case when p.valuta<>'' then p.curs else 1 end)*(1.00+p.discount/100.00) else p.pret_vanzare end)), 2) as val_facturata,
	round(convert(decimal(15,3), p.cantitate*(case when p.tip='RM' then p.pret_valuta*(case when p.valuta<>'' then p.curs else 1 end)*(1.00+p.discount/100.00) else p.pret_vanzare end)
		*(1+(case when isnull(tot.total_facturat,0)<>0 then isnull(d.detalii.value('/row[1]/@valprestari', 'float'),isnull(intst.pret_valuta,0))/tot.total_facturat else 0 end))), 2) as val_statistica,
	round(convert(decimal(17,5), (case when isnull(p.detalii.value('/row[1]/@masaneta', 'float'),0)<>0 then isnull(p.detalii.value('/row[1]/@masaneta', 'float'),0) 
		else (p.cantitate*n.greutate_specifica) end)), 3) as masa_neta,
	isnull(c.Alfa2,'') as UM2, (case when isnull(c.Alfa2,'')<>'' then round(convert(decimal(17,5), (case when @UrmarireCantSec=1 and n.UM_1<>'' and RTrim(n.UM_2)='Y' then p.suprataxe_vama
		else p.cantitate end)), 3) else 0 end) as cant_UM2,
	isnull(d.detalii.value('/row[1]/@nattranza', 'varchar(20)'),isnull(intst.gestiune,'')) as natura_tranzactie_a, 
	isnull(d.detalii.value('/row[1]/@nattranzb', 'varchar(20)'),isnull(intst.gestiune_primitoare,'')) as natura_tranzactie_b, 
	isnull(d.detalii.value('/row[1]/@condlivr', 'varchar(20)'),isnull(intst.cont_corespondent,'')) as cond_livrare, 
	isnull(d.detalii.value('/row[1]/@modtransp', 'varchar(20)'),isnull(intst.cont_de_stoc,'')) as mod_transport,
	(case when p.tara_tert='' then t.judet else p.tara_tert end) as tara_tert, 
	(case	when @flux='I' then isnull(nullif(p.detalii.value('/row[1]/@taraorigine', 'varchar(20)'),''),isnull(n.detalii.value('/row[1]/@tara', 'varchar(20)'),isnull(pp.UM_secundara,''))) 
			when @flux='E' and year(@datasus)>=2015 then 'RO' else '' end) as tara_origine, 
	rtrim(isnull(c.denumire,'<FARA CODVAM>')) as dencodv, 
	rtrim(ltrim(isnull((case when left(t.cod_fiscal,2)=(case when @ValidareTara=1 then isnull(t.Judet,'') else isnull(tt.cod_tara,'') end) then SUBSTRING(t.cod_fiscal,3,14) else t.cod_fiscal end),''))) as cif_partener, 
--	stuff(t.Cod_fiscal, 1, patindex('%[0-9]%', t.Cod_fiscal)-1, '') as cif_partener, 
	p.tert, (case when p.tip in ('AP','AS') then substring(p.numar_dvi,14,5) else '' end) as punct_livrare, p.factura, p.cantitate
	FROM #pozdocIntrastat p
		left outer join doc d on d.subunitate=p.subunitate and p.tip=d.tip and p.numar=d.numar and p.data=d.data 
		left outer join pozdoc intst on intst.subunitate='INTRASTAT' and p.tip=intst.tip and p.numar=intst.numar and p.data=intst.data and intst.numar_pozitie=0
		left outer join tari on tari.cod_tara=p.tara_tert
		left outer join (select p.subunitate, p.tip, p.numar, p.data, /*abs*/(sum(round(convert(decimal(15,3), p.cantitate*(case when p.tip='RM' then p.pret_valuta*(case when p.valuta<>'' then p.curs else 1 end)
				*(1.00+p.discount/100.00) else p.pret_vanzare end)), 2))) as total_facturat 
			from pozdoc p inner join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
				inner join infotert i on t.subunitate=i.subunitate and t.tert=i.tert and i.identificator=''
				inner join nomencl n on p.cod=n.cod where p.subunitate=@sub and p.tip=(case when @flux='I' then 'RM' else 'AP' end) and p.data between @datajos and @datasus 
					and /*i.zile_inc=1 and */n.tip not in ('R', 'S') group by p.subunitate, p.tip, p.numar, p.data) tot on tot.subunitate=p.subunitate and tot.tip=p.tip and tot.numar=p.numar and tot.data=p.data
		inner join terti t on p.subunitate=t.subunitate and p.tert=t.tert
		inner join infotert i on t.subunitate=i.subunitate and t.tert=i.tert and i.identificator=''
		inner join nomencl n on p.cod=n.cod
		left join ppreturi pp on pp.cod_resursa=p.cod and pp.tip_resursa='I' and pp.tert='' and pp.Data_pretului='01/01/1901'
		left outer join codvama c on c.cod=p.cod_vamal
		left outer join tari tt on tt.denumire=t.judet
	where (tari.teritoriu is null and i.zile_inc=1 or tari.teritoriu is not null and isnull(tari.teritoriu,'')='U') 


	/* SP care sa permita alterarea tabelei #intrastat. Parametru @faraGrupare va trebui sa fie de tip output. Se poate face @faraGrupare=1 si nu se vor grupa datele pe cod_NC8  */ 
	if exists (select 1 from sysobjects where [type]='P' and [name]='rapDeclaratieIntrastatSP')
		exec rapDeclaratieIntrastatSP @datajos=@datajos, @datasus=@datasus, @flux=@flux, @tipdecl=@tipdecl, @faraGrupare=@faraGrupare output, @tabela=@tabela

	/*	Inversare semn valori pentru retururi.	Si daca procedura se apeleaza dinspre afisare erori. 
		Totusi daca procedura se apeleaza dinspre afisare erori sau raport, sumele sa fie cu semn, astfel incat totalul din raport sa poate fi corelat cu jurnalele de TVA. */
	if @tabela=1
		update #intrastat
		set masa_neta=masa_neta*sign(masa_neta),
			cant_UM2=cant_UM2*sign(cant_UM2),
			val_facturata=val_facturata*sign(val_facturata),
			val_statistica=val_statistica*sign(val_statistica)
		where natura_tranzactie_a='2'
	
	if @faraGrupare=''
	begin
		insert into #intrastat(nr_ord, cod_NC8, val_facturata, val_statistica, masa_neta, UM2, cant_UM2,
			natura_tranzactie_a, natura_tranzactie_b, cond_livrare, mod_transport, tara_tert, tara_origine, dencodv, cif_partener, tert, punct_livrare, factura)
		select row_number() over (order by newid()) as nr_ord, cod_NC8, 
			sum(val_facturata) as val_facturata, sum(val_statistica) as val_statistica, 
			sum(masa_neta) as masa_neta, max(UM2) as UM2, sum(cant_UM2) as cant_UM2, 
			natura_tranzactie_a, natura_tranzactie_b, cond_livrare, mod_transport, tara_tert, tara_origine, 
			max(dencodv) as dencodv, cif_partener, tert, max(punct_livrare), max(factura)
		--into #gintrastat
		from #intrastat
		group by cod_NC8, natura_tranzactie_a, natura_tranzactie_b, cond_livrare, mod_transport, tara_tert, tara_origine, cif_partener, tert

		update #intrastat
		set masa_neta=(case when abs(masa_neta) between 0.001 and 1 then 1*sign(masa_neta) else round(masa_neta,0) end),
			cant_UM2=round(cant_UM2, 0),
			val_facturata=round(val_facturata,0),
			val_statistica=round(val_statistica,0)

		delete #intrastat where nr_ord is null
		
		if @tabela=0
		select nr_ord, cod_NC8, val_facturata, val_statistica, masa_neta, UM2, cant_UM2, natura_tranzactie_a, natura_tranzactie_b, cond_livrare, mod_transport, tara_tert, tara_origine, dencodv, 
			cif_partener, tert, punct_livrare, factura
		from #intrastat
		Order by tara_tert, tara_origine, cif_partener, tert, cod_NC8, natura_tranzactie_a, natura_tranzactie_b, cond_livrare, mod_transport
	end
	if @faraGrupare='1' and @tabela=0		--	@faraGrupare='1' atunci cand se apeleaza procedura dinspre operatia de afisare a erorilor
		select tip, numar, data, cod, cod_vamal, cod_NC8, val_facturata, val_statistica, masa_neta, UM2, cant_UM2, natura_tranzactie_a, natura_tranzactie_b, 
			cond_livrare, mod_transport, tara_tert, tara_origine, dencodv, cif_partener, tert, punct_livrare, factura
		from #intrastat

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapDeclaratieIntrastat)'
	raiserror(@eroare, 16, 1) 
end catch
/*
	exec rapDeclaratieIntrastat	@datajos='03/01/2015', @datasus='04/30/2015', @flux='I', @tipdecl='N' 
*/
