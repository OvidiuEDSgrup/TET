--***
create procedure inregAvize @dataj datetime,@datas datetime,@tipdoc char(2)='AP',@nrdoc varchar(20)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,@sub char(9),@Bugetari int,
@tip char(2),@numar varchar(20),@data datetime,@gest char(9),@tipgest char(1),@ctgest varchar(40),
@gestprim varchar(40),@cod char(20),@cant float,@tvanx float,@pretvaluta float,@pretstoc float,
@pretvanz float,@pretampred float,@pretam float,@sumaTVA float,
@tipnom char(1),@contnom varchar(40),@grupanom char(13),
@ctstoc varchar(40),@atrctstoc float,--@tip_ct_stoc char(1),@cont_factura varchar(40),
@ctcor varchar(40),@ctinterm varchar(40),@tert char(13),--@factura char(20),
@dvi char(25),--@den_tert char(30),@t_extern int,
@valuta char(3),@curs float,--@disc float,@proc_vama float,
@lm char(9),@lmprim char(9),@com char(40),@jurnal char(3),
@valpretstoc float,@valpretam float,@valpretampred float,@tvanxpred float,@tvanxprim float,
@suprataxe float,@acccump float,@accdat float,@dentert char(30),@tertext int,
@ctfact varchar(40),@ctven varchar(40),@tipctven char(1),
@barcod char(30),@grupa char(13),@procvama float,@locatie char(30),
@valleidinvaluta float,@valpretvanz float,@valdisc float,@tvaded float,
@valvaluta float,@suprataxevaluta float,@valvalutainv float,
@tvanxpretvanz float,@contract char(20),
@subunitate char(9), @rottvanx int, @nrzectvanx int, @rotvalav int,@nrzec int, @serotpv int, @rotpret float, 
@discinv int, @discsep int, @compfixapret int, @ttla int, @accprod int, @categprod int, 
@adtvanxavc int,@numaiAC int,@adtvanxava int, @ctadaos varchar(40),@angestctadaos int,@angrctadaos int, 
@cttvaded varchar(40),@cttvacol varchar(40),@cttvanxrecav varchar(40),@cttvanx varchar(40),@angestcttvanx int, 
@ctdisc varchar(40),@angestctdisc int, @ignor4428Avans int, @ignor4428DocFF int, -- ignor inreg 4428 la doc. fara factura
@inregdifpretprod int,@ct348 varchar(40),@faradif345 int,@faradescA int,@venfact8033 int,
@docsch int,@excavdocsch int,@custcls35 int,@custcls8 int,@ctrezrep varchar(40),
@pasmatex int,@ortoprofil int,@unicarm int,@genisa int,
@glm char(9),@gcom char(40),@gjurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@suma float,@sumavaluta float,@expl char(50),
@valutam char(3),@cursm float,@inversare int,@vallei float,@userASiS char(10),@idPozdoc int,@indbug varchar(20)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
exec luare_date_par 'GE','ROTUNJTNX',@rottvanx output,@nrzectvanx output,''
--Ghita a zis ca nu mai e cazu' de: if @rottvanx=0 set @nrzectvanx=2 
exec luare_date_par 'GE','ROTUNJ',@rotvalav output,@nrzec output,''
if @rotvalav=0 set @nrzec=2
-- citesc parametrii de rotunjire pret lei din pret valuta
exec luare_date_par 'GE','ROTPRET',@serotpv output,@rotpret output,''
if isnull(@rotpret,0)=0 
	set @rotpret=0.01

exec luare_date_par 'GE','INVDISCAP',@discinv output,0,''
exec luare_date_par 'GE','DISCSEP',@discsep output,0,''
exec luare_date_par 'GE','COMPPRET',@compfixapret output,0,''
exec luare_date_par 'GE','CATEGPRO',@categprod output,0,''
exec luare_date_par 'GE','ACCIZE',@accprod output,0,''
exec luare_date_par 'GE','ADTAV',@adtvanxavc output,@numaiAC output,''
exec luare_date_par 'GE','ADTAVA',@adtvanxava output,0,''
exec luare_date_par 'GE','CADAOS',@angestctadaos output,@angrctadaos output,@ctadaos output
exec luare_date_par 'GE','CNTVA',@angestcttvanx output,0,@cttvanx output
exec luare_date_par 'GE','CONTDISC',@angestctdisc output,0,@ctdisc output
exec luare_date_par 'GE','TIMBRULIT',@ttla output,0,''
exec luare_date_par 'GE','CDTVA',0,0,@cttvaded output
exec luare_date_par 'GE','CCTVA',0,0,@cttvacol output
exec luare_date_par 'GE','CNEEXREC',0,0,@Cttvanxrecav output
exec luare_date_par 'GE','NEEXAV',@ignor4428Avans output,0,''
exec luare_date_par 'GE','NEEXDOCFF',@ignor4428DocFF output,0,''
exec luare_date_par 'GE','CONT348',@inregdifpretprod output,0,@ct348 output
exec luare_date_par 'GE','DIF345',@faradif345 output,0,''
exec luare_date_par 'GE','FARADESC',@faradescA output,0,''
exec luare_date_par 'GE','CONTV8',@venfact8033 output,0,''
exec luare_date_par 'GE','DOCPESCH',@docsch output,@excavdocsch output,''
exec luare_date_par 'GE','STCUST35',@custcls35 output,0,''
exec luare_date_par 'GE','STCUST8',@custcls8 output,0,''
exec luare_date_par 'MF','CTREZREP',0,0,@ctrezrep output
exec luare_date_par 'SP','PASMATEX',@pasmatex output,0,''
exec luare_date_par 'SP','ORTO',@ortoprofil output,0,''
exec luare_date_par 'SP','UNICARM',@unicarm output,0,''
exec luare_date_par 'SP','GENISA',@genisa output,0,''
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate in (@subunitate,'INTRASTAT') and tip_document=@tipdoc and numar_document 
	between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas

declare tmpinregAvize cursor for
select p.subunitate, p.tip, p.data, p.numar, p.gestiune, 
max(isnull(g.tip_gestiune, '')) as tip_gestiune, 
p.tert, max(isnull(t.denumire, '')) as den_tert, isnull(t.tert_extern, 0) as tert_extern, 
p.cont_factura, p.valuta, p.curs, 
p.cont_de_stoc, max(isnull(cs.sold_credit, 0)) as atrib_ct_stoc, 
p.cont_corespondent, p.cont_intermediar, p.cont_venituri, max(isnull(cv.tip_cont, '')), 
p.gestiune_primitoare, p.numar_DVI, p.barcod, p.loc_de_munca, p.comanda, 
p.grupa, p.jurnal, p.procent_vama, p.locatie, 
max(isnull(n.tip, '')) as tip_nom, max(isnull(n.grupa, '')) as grupa_nom, 
sum(round(convert(decimal(17,5), p.cantitate*(case when p.valuta='' then p.pret_valuta else (case when @serotpv=1 then round(p.curs*p.pret_valuta/@rotpret,0)*@rotpret else p.curs*p.pret_valuta end)  end)), @nrzec)) as val_lei_din_valuta, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_vanzare), @nrzec)) as val_pret_vanzare, 
-- Am modificat modul de calcul al discountului (sa nu tina cont de procentul de discount ci de preturi).
/*sum(round(convert(decimal(17,5), p.cantitate*(case when p.valuta='' then 1 else p.curs end)
*p.pret_valuta*round(convert(decimal(17,5), (case when @discinv=0 then p.discount 
else (1.00-100.00/(100.00+p.discount))*100.00 end)), 2)/100), @nrzec)) as val_discount,*/
sum(round(convert(decimal(17,5), p.cantitate*((case when p.valuta='' then p.pret_valuta else (case when @serotpv=1 then round(p.curs*p.pret_valuta/@rotpret,0)*@rotpret else p.curs*p.pret_valuta end)  end)-p.pret_vanzare)), @nrzec)) as val_discount,
sum(round(convert(decimal(17,5), p.tva_deductibil), 2)) as val_tva_deductibil, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_de_stoc), 2)) as val_pret_stoc, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_cu_amanuntul), 2)) as val_pret_amanunt, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_amanunt_predator), 2)) as val_pret_am_pred, 
sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), 
p.pret_amanunt_predator*p.tva_neexigibil/(100+p.tva_neexigibil)), @nrzectvanx)), 2)) 
as val_tva_neexigibil, 
sum(round(convert(decimal(17,5), p.accize_datorate), 2)) as val_accize_datorate, 
sum(round(convert(decimal(30,5), p.cantitate*p.accize_cumparare), 2)) as val_accize_cumparare, 
sum(round(convert(decimal(17,5), p.cantitate*(p.pret_valuta*(1-round(convert(decimal(17,5), 
	(case when @discsep=1 and not (@custcls35=1 and left(p.cont_corespondent, 2)='35' or @custcls8=1 and left(p.cont_corespondent, 1)='8') then 0 when @discinv=0 then p.discount else (1.00-100.00/(100.00+p.discount))*100.00 end)), 2)/100)
		+(case when @compfixapret=1 and n.tip<>'F' then p.suprataxe_vama/1000 else 0 end))), 2)) as val_valuta, 
sum(round(convert(decimal(17,5), p.cantitate*(p.pret_valuta*(1-round(convert(decimal(17,5), 
(case when @discinv=0 then p.discount else (1.00-100.00/(100.00+p.discount))*100.00 end)), 2)/100)
+p.suprataxe_vama/1000)), 2)) as val_valuta_suprataxe, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_valuta*(1-round(convert(decimal(17,5), 
(case when @discinv=0 then p.discount else (1.00-100.00/(100.00+p.discount))*100.00 end)), 2)
/100)), 2)) as val_valuta_inversare, 
sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), 
p.pret_vanzare*p.cota_tva/100), @nrzectvanx)), 2)) as val_tva_neex_pvanzare,
sum(round(convert(decimal(17,5), p.cantitate*p.suprataxe_vama), 2)) as val_suprataxe, p.contract, max(p.idPozdoc) as idPozdoc
FROM pozdoc p 
left outer join gestiuni g on p.subunitate = g.subunitate and p.gestiune = g.cod_gestiune 
left outer join nomencl n on p.cod = n.cod 
left outer join terti t on p.subunitate = t.subunitate and p.tert = t.tert 
left outer join conturi cs on p.subunitate = cs.subunitate and p.cont_de_stoc = cs.cont 
left outer join conturi cv on p.subunitate = cv.subunitate and p.cont_venituri = cv.cont 
WHERE p.subunitate=@subunitate and p.tip=@tipdoc and p.data between @dataj and @datas 
	and (@nrdoc='' or p.numar=@nrdoc) 
GROUP BY p.subunitate, p.tip, p.data, p.numar, p.gestiune, p.tert, isnull(t.tert_extern, 0), 
p.cont_factura, p.valuta, p.curs, p.cont_de_stoc, p.cont_corespondent, 
p.cont_intermediar, p.cont_venituri, p.gestiune_primitoare, p.numar_DVI, p.barcod, 
p.loc_de_munca, p.comanda, p.grupa, p.jurnal, p.procent_vama, p.locatie, p.contract
ORDER BY p.subunitate, p.tip, p.data, p.numar, p.gestiune 

open tmpinregAvize
fetch next from tmpinregAvize into @sub,@tip,@data,@numar,@gest,@tipgest,@tert,@dentert,
			@tertext,@ctfact,@valuta,@curs,@ctstoc,@atrctstoc,@ctcor,@ctinterm,@ctven,@tipctven,
			@gestprim,@dvi,@barcod,@lm,@com,@grupa,@jurnal,@procvama,@locatie,@tipnom,@grupanom,
			@valleidinvaluta,@valpretvanz,@valdisc,@tvaded,@valpretstoc,@valpretam,@valpretampred,
			@tvanx,@accdat,@acccump,@valvaluta,@suprataxevaluta,@valvalutainv,
			@tvanxpretvanz,@suprataxe,@contract,@idPozdoc
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @gsub=@sub
	set @gtip=@tip
	set @gnumar=@numar
	set @gdata=@data
	set @glm=@lm
	set @gcom=@com
	set @gjurnal=@jurnal

	while @gsub=@sub and @gtip=@tip and @gnumar=@numar and @gdata=@data and @gfetch=0
	BEGIN
		set @indbug=''
		if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
		begin
			if object_id('tempdb..#indbugPozitieDoc') is not null
				drop table #indbugPozitieDoc
	
			select '' as furn_benef, 'pozdoc' as tabela, @idPozdoc as idPozitieDoc, convert(varchar(20),'') as indbug 
			into #indbugPozitieDoc 
			exec indbugPozitieDocument @sesiune=null, @parXML=null
			select @indbug=isnull(ib.indbug,'')
			from #indbugPozitieDoc ib where ib.idPozitieDoc=@idPozdoc
		end

		set @inversare=(case when @tipnom='S' and (left(@ctven,1)='6' OR left(@ctven,1)='7' and 
			@tipctven='A') then 1 else 0 end)
		if LEFT(@ctstoc,1)<>'8' or @venfact8033=1 or @tipnom='F'
		Begin -- gen. inregistrari factura
		--Val. factura
		set @vallei=ROUND((case when @discsep=1 and not (@custcls35=1 and left(@ctcor,2)='35' or @custcls8=1 and left(@ctcor,1)='8') then @valleidinvaluta else @valpretvanz end),@nrzec)
		set @ctdeb=@ctfact
		set @ctcred=@ctven
		set @suma=dbo.rot_val(@vallei-(case when @tipnom<>'S' and @tipgest<>'V' and (@ttla=1 
				OR @accprod=1) and @tipnom<>'F' and @tip='AP' then @accdat else 0 end), 2)
		set @expl='Venit '+@dentert
		set @valutam=(case when @tertext=1 then @valuta else '' end)
		set @cursm=(case when @tertext=1 and @valuta<>'' then @curs else 0 end)
		set @sumavaluta=dbo.rot_val((case when @tertext=1 and @valuta<>'' then (case when @tipnom<>'S' and @tipgest<>'V' and (@ttla=1 OR @accprod=1) and @tipnom<>'F' and @tip='AP' and @curs<>0 then @valvaluta-@accdat/@curs 
				else @valvaluta end) else 0 end), 2)
		if @inversare=1 
		begin
			set @ctdeb=@ctven
			set @ctcred=@ctfact
			set @suma=-@suma
			set @expl='Chelt. discount '+@dentert
			set @sumavaluta=-@sumavaluta
		end
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		--Discount separat
		if @discsep=1 and not (@custcls35=1 and left(@ctcor,2)='35' or @custcls8=1 and left(@ctcor,1)='8')
		begin
			set @ctdeb=rtrim(@ctdisc)+(case when @angestctdisc=1 then '.'+rtrim(@gest) else '' end)
			set @ctcred=@ctfact
			set @suma=dbo.rot_val(@valdisc, @nrzec)
			set @expl='Discount '+@dentert
			set @valutam=(case when @tertext=1 then @valuta else '' end)
			set @cursm=(case when @tertext=1 and @valuta<>'' then @curs else 0 end)
			set @sumavaluta=dbo.rot_val((case when @tertext=1 and @valuta<>'' and @curs>0 then 
				@valdisc/@curs else 0 end), @nrzec)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
		--Val. TVA
		if @docsch=1 and @excavdocsch=0 and @tip<>'AS' or @unicarm=1 or @genisa=1 or @procvama<>2
		begin
			set @ctdeb=(case when @docsch=1 and @excavdocsch=0 and @tip<>'AS' or @unicarm=1 or 
				@genisa=1 or @procvama=0 then @ctfact else @cttvaded end)
			set @ctcred=(case when LEFT(@ctfact,3)='418' or LEFT(@grupa,4)='4428' then (case when 
				not (substring(@grupa,2,1)='.' OR LEN(RTRIM(@grupa))<3 or LEFT(@grupa,3)='***') 
				then @grupa else @cttvanxrecav end) when substring(@grupa,2,1)='.' OR 
				LEN(RTRIM(@grupa))<3 or LEFT(@grupa,3)='***' then @cttvacol else @grupa end)
			set @suma=dbo.rot_val(@tvaded, 2)
			set @expl='Colectare TVA '+@dentert
			set @valutam=(case when @tertext=1 then @valuta else '' end)
			set @cursm=(case when @tertext=1 and @valuta<>'' then @curs else 0 end)
			set @sumavaluta=dbo.rot_val((case when @tertext=1 and @valuta<>'' and @curs>0 then 
				@tvaded/@curs else 0 end), 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
		--TVA in avans
		if (@ignor4428Avans=0 and left(@ctstoc,3) in ('419','451') or @ignor4428DocFF=0 and left(@ctstoc,3) like '418%') 
			and (@docsch=1 and @excavdocsch=0 and @tip<>'AS' or @unicarm=1 or @genisa=1 or @procvama=0) and @atrctstoc=2
		begin
			set @ctdeb=@cttvanxrecav
			set @ctcred=@ctstoc
			set @suma=dbo.rot_val(@tvaded, 2)
			set @expl=''
			set @valutam=(case when @tertext=1 then @valuta else '' end)
			set @cursm=(case when @tertext=1 and @valuta<>'' then @curs else 0 end)
			set @sumavaluta=dbo.rot_val((case when @tertext=1 and @valuta<>'' and @curs>0 then 
				@tvaded/@curs else 0 end), 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
		End -- gen. inregistrari factura
		
		--Desc. stoc
		if @tipnom<>'S' and @tipgest<>'V' and not (@faradescA=1 and @tipgest='A')
		Begin
		if @ctinterm<>@ctstoc and @ctinterm<>''
		begin
			set @ctdeb=(case when LEFT(@ctstoc,1)='8' then 'X' when @ortoprofil=1 and 
				LEFT(@ctstoc,2) IN ('33','34') and @inregdifpretprod=1 then @ctcor 
				else @ctinterm end)
			set @ctcred=@ctstoc
			set @suma=dbo.rot_val((case when LEFT(@ctstoc,1)='8' then @valpretam 
				else @valpretstoc end), 2)
			set @expl='Pozitie intermediara'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
				
		if 0=0
		begin
			set @ctdeb=(case when @tipnom='S' then 'X' else @ctcor end)
			set @ctcred=(case when @ctinterm='' then @ctstoc else @ctinterm end)
			set @suma=dbo.rot_val((case when @inregdifpretprod=1 and @tip='AP' and @pasmatex=0 and 
				LEFT(@ctstoc,2) in ('33','34','35') and @faradif345=0 then @valpretvanz 
				else @valpretstoc end), 2)
			set @expl='Descarcare in pret de stoc'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
				
		--345=711 pt. AP cu ct. stoc 331 (ORTOPROFIL)
		if @ortoprofil=1 and @inregdifpretprod=1 and LEFT(@ctstoc,2) in ('33','34') 
			and @ctinterm<>@ctstoc and @ctinterm<>''
		begin
			set @ctdeb=@ctinterm
			set @ctcred=@ctcor
			set @suma=dbo.rot_val(@valpretvanz, 2)
			set @expl='Pozitie intermediara'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
		if @tipgest='V' or @tipgest='A' and not (@inregdifpretprod=1 and LEFT(@ctstoc,3)='354') 
			or @adtvanxavc=1 and @tipgest='C' and LEFT(@ctstoc,3)='371' and @numaiAC=0
		begin
			set @ctdeb=RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+rtrim(@gest)
				else '' end)
			set @ctcred=@ctstoc
			set @suma=dbo.rot_val((case when @adtvanxavc=1 and @tipgest='C' or @adtvanxava=1 and 
				@tipgest='A' then ROUND(@tvanxpretvanz,2) else ROUND(@tvanx,2) end), 2)
			set @expl='Descarcare TVA neexigibil'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
		if @tipgest='V' or @tipgest='A' and not (@inregdifpretprod=1 and LEFT(@ctstoc,3)='354') 
			or @adtvanxavc=1 and @tipgest='C' and LEFT(@ctstoc,3)='371' and @numaiAC=0
		begin
			set @ctdeb=RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+rtrim(@gest) else '' 
				end)+(case when @angrctadaos=1 then '.'+rtrim(@grupanom) else '' end)
			set @ctcred=@ctstoc
			set @suma=dbo.rot_val((case when @adtvanxavc=1 and @tipgest='C' or @adtvanxava=1 and 
				@tipgest='A' then @valpretvanz+@tvaded-@valpretstoc-@tvanxpretvanz else 
				@valpretampred-@valpretstoc-ROUND(@tvanx,2) end), 2)
			set @expl='Descarcare adaos'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
		if (@tipgest='C' and @adtvanxavc=1 and @numaiAC=0 or @tipgest='A' and @adtvanxava=1) 
			and LEFT(@ctstoc,3)='371'
		begin
			set @ctdeb=@ctstoc
			set @ctcred=RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+rtrim(@gest) 
				else '' end)
			set @suma=dbo.rot_val(ROUND(@tvanxpretvanz,2)-(case when @adtvanxava=1 and @tipgest='A' 
				then ROUND(@tvanx,2) else 0 end), 2)
			set @expl='Incarcare TVA neexigibil'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
		if (@tipgest='C' and @adtvanxavc=1 and @numaiAC=0 or @tipgest='A' and @adtvanxava=1) and 
		LEFT(@ctstoc,3)='371'
		begin
			set @ctdeb=@ctstoc
			set @ctcred=RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+rtrim(@gest) else '' 
				end)+(case when @angrctadaos=1 then '.'+rtrim(@grupanom) else '' end)
			set @suma=dbo.rot_val(@valpretvanz+@tvaded-@valpretstoc-@tvanxpretvanz-(case when 
				@tipgest='A' and @adtvanxava=1 then @valpretampred-@valpretstoc-ROUND(@tvanx,2) 
				else 0 end), 2)
			set @expl='Incarcare adaos'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
		--Diferente de pret la produse (prin contul 348)
		if @pasmatex=0 and @inregdifpretprod=1 and @tip='AP' 
			and (LEFT(@ctstoc,2)='33' or LEFT(@ctstoc,2)='34' or 90=0 and LEFT(@ctstoc,3)='357') and @faradif345=0
		begin
			set @ctdeb=(case when @ortoprofil=1 and LEFT(@ctstoc,2) in ('33','34') then @ct348 
				else @ctstoc end)
			set @ctcred=@ctcor
			set @suma=dbo.rot_val(@valpretvanz-@valpretstoc, 2)
			set @expl='Diferente de pret'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
		if @pasmatex=0 and @inregdifpretprod=1 and @tip='AP' 
			and (LEFT(@ctstoc,2)='33' or LEFT(@ctstoc,2)='34' or 90=0 and LEFT(@ctstoc,3)='357')
		begin
			set @ctdeb=@ctcor
			set @ctcred=@ct348
			set @suma=dbo.rot_val(@valpretvanz-@valpretstoc, 2)
			set @expl='Diferente de pret'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
		End
		--Accize produse sau timbru lit.
		if (@tipnom<>'S' and @tipgest<>'V' and (@ttla=1 or @accprod=1) or @tipnom='F') and @tip='AP'
		begin
			set @ctdeb=(case when @tipnom='F' then @gestprim when @ttla=1 OR @accprod=1 then 
				@ctfact else 'YYY' end)
			set @ctcred=@dvi
			set @suma=dbo.rot_val((case when @accprod=1 and @categprod=1 OR @tipnom='F' then 
				@accdat else round(@acccump,2) end), 2)
			set @expl=(case when @tipnom='F' then 'Stornare amortizare' when @ttla=1 then 
				'Timbru literar' else 'Accize' end)
			set @valutam=(case when @tertext=1 and @valuta<>'' then @valuta else '' end)
			set @cursm=(case when @tertext=1 and @valuta<>'' then @curs else 0 end)
			set @sumavaluta=dbo.rot_val((case when @tertext=1 and @valuta<>'' then @accdat/@curs 
				else 0 end), 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
				
		--8045 CR pentru mfixe
		if @tipnom='F' and left(@barcod,1)='8' and @acccump<>0 and @jurnal='MFX'
		begin
			set @ctdeb=''
			set @ctcred=@barcod
			set @suma=dbo.rot_val(@acccump, 2)
			set @expl='Amortizare af. grd. neutilizare'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
				
		--rezultat reportat am. istorica mfixe
		if @tipnom='F' and @ctrezrep<>'' and @suprataxe<>0 and @jurnal='MFX'
		begin
			set @ctdeb=@locatie
			set @ctcred=@contract
			set @suma=dbo.rot_val(@suprataxe, 2)
			set @expl='Rezerve reev.sau rezultat rep.'
			set @valutam=''
			set @cursm=0
			set @sumavaluta=0 --dbo.rot_val(0, 2)
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
				
		fetch next from tmpinregAvize into @sub,@tip,@data,@numar,@gest,@tipgest,@tert,@dentert,
			@tertext,@ctfact,@valuta,@curs,@ctstoc,@atrctstoc,@ctcor,@ctinterm,@ctven,@tipctven,
			@gestprim,@dvi,@barcod,@lm,@com,@grupa,@jurnal,@procvama,@locatie,@tipnom,@grupanom,
			@valleidinvaluta,@valpretvanz,@valdisc,@tvaded,@valpretstoc,@valpretam,@valpretampred,
			@tvanx,@accdat,@acccump,@valvaluta,@suprataxevaluta,@valvalutainv,
			@tvanxpretvanz,@suprataxe,@contract,@idPozdoc
		set @gfetch=@@fetch_status
	END
	
end
close tmpinregAvize
deallocate tmpinregAvize
end
