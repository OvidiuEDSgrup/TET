--***
create procedure inregAI @dataj datetime, @datas datetime, @nrdoc varchar(20)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,@sub char(9),@Bugetari int,
@tip char(2),@numar varchar(20),@data datetime,@gest char(9),@tipgest char(1),@ctgest varchar(40),
@cod char(20),@cant float,@pretstoc float,@pretampred float,@pretvaluta float,
@pretvanz float,@pretam float,@cotaTVA float,@sumaTVA float,@tvanx float,@adaos float,
@tipnom char(1),@dennom char(80),@ctnom varchar(40),@grupanom char(13),
@grupa char(13),@tipmisc char(1),@ctstoc varchar(40),@tipctstoc char(1),@atrctstoc float,
@ctcor varchar(40),@ctven varchar(40),@ctinterm varchar(40),@ctfact varchar(40),
@fact char(20),@datafact datetime,@datascad datetime,@tert char(13),--@tiptert int,
@gestprim varchar(40),@dvi char(25),@locatie char(30),@barcod char(30),@nrpozitie int,@stare int,
@dataexp datetime,@valuta char(3),@curs float,@disc float,@procvama float,@suprataxevama float,
@acccump float,@accdat float,@lm char(9),@com char(40),@contr char(20),@jurnal char(3),
@subunitate char(9),@difpretprod int,@Cttvaded varchar(40),
@rottvanx int, @nrzectvanx int, @ctrezrep varchar(40),@invamreev int,
@glm char(9),@gcom char(40),@gjurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@suma float,@sumavaluta float,@expl char(50),@userASiS char(10),@idPozdoc int,@indbug varchar(20)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
exec luare_date_par 'GE','CONT348',@difpretprod output,0,''
exec luare_date_par 'GE','ROTUNJTNX',@rottvanx output,@nrzectvanx output,''
--Ghita a zis ca nu mai e cazu' de: if @rottvanx=0 set @nrzectvanx=2 
exec luare_date_par 'GE','CDTVA',0,0,@Cttvaded output
exec luare_date_par 'MF','CTREZREP',0,0,@ctrezrep output
exec luare_date_par 'MF','INVCTREEV',@invamreev output,0,''
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate and tip_document='AI' and numar_document 
	between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas

declare tmpinregAI cursor for
select p.Subunitate,p.Tip,p.Numar,p.Cod,p.Data,p.Gestiune,p.Cantitate,p.Pret_valuta,p.Pret_de_stoc,
p.Adaos,p.Pret_vanzare,p.Pret_cu_amanuntul,p.TVA_deductibil,p.Cota_TVA,
p.Cont_de_stoc,p.Cont_corespondent,p.TVA_neexigibil,
p.Pret_amanunt_predator,p.Tip_miscare,p.Locatie,p.Data_expirarii,p.Numar_pozitie,p.Loc_de_munca,
p.Comanda,p.Barcod,p.Cont_intermediar,p.Cont_venituri,p.Discount,p.Tert,p.Factura,
p.Gestiune_primitoare,p.Numar_DVI,p.Stare,p.Grupa,p.Cont_factura,
p.Valuta,(case when p.Valuta<>'' or 0=0 then p.Curs else 0 end),p.Data_facturii,
p.Data_scadentei,p.Procent_vama,p.Suprataxe_vama,p.Accize_cumparare,p.Accize_datorate,
p.Contract,p.Jurnal,isnull(g.tip_gestiune, ''), isnull(g.cont_contabil_specific, ''), 
isnull(n.tip,''), isnull(n.denumire,''), isnull(n.cont,''), isnull(n.grupa,''), 
isnull(c1.tip_cont,''), isnull(c1.sold_credit,0), p.idPozdoc
FROM pozdoc p 
left outer join gestiuni g on p.subunitate = g.subunitate and p.gestiune = g.cod_gestiune 
left outer join nomencl n on p.cod = n.cod 
--left outer join terti t on p.subunitate = t.subunitate and p.tert = t.tert 
left outer join conturi c1 on p.subunitate = c1.subunitate and p.cont_de_stoc = c1.cont 
WHERE p.subunitate=@subunitate and p.tip='AI' and p.data between @dataj and @datas 
and (@nrdoc='' or p.numar=@nrdoc) 
/*GROUP BY p.subunitate, p.tip, p.data, p.numar, p.gestiune, p.cont_de_stoc, p.cont_corespondent, 
p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, p.loc_de_munca, p.comanda, n.grupa, 
p.jurnal*/ 
ORDER BY p.subunitate, p.tip, p.data, p.numar, p.gestiune

open tmpinregAI
fetch next from tmpinregAI into @Sub,@Tip,@Numar,@Cod,@Data,@Gest,@Cant,@Pretvaluta,@Pretstoc,
		@Adaos,@Pretvanz,@Pretam,@sumaTVA,@CotaTVA,@Ctstoc,@Ctcor,@TVAnx,
		@Pretampred,@Tipmisc,@Locatie,@Dataexp,@Nrpozitie,@Lm,
		@Com,@Barcod,@Ctinterm,@Ctven,@Disc,@Tert,@Fact,
		@Gestprim,@DVI,@Stare,@Grupa,@Ctfact,@Valuta,@Curs,@Datafact,
		@Datascad,@Procvama,@Suprataxevama,@Acccump,@Accdat,
		@Contr,@Jurnal,@tipgest,@ctgest,@tipnom,@dennom,@ctnom,@grupanom,
		@tipctstoc,@atrctstoc,@idPozdoc
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
	if 0=0
		begin
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

		if @valuta='' set @curs=0
		set @ctdeb=(case when @fact='MRE' and @tipnom='F' and @cant*@pretstoc<0 
			and @jurnal='MFX' and @invamreev=0 then @ctcor else @ctstoc end)
		set @ctcred=(case when @fact='MRE' and @tipnom='F' and @cant*@pretstoc<0 
			and @jurnal='MFX' and @invamreev=0 then @ctstoc else @ctcor end)
		set @suma=dbo.rot_val(@cant*(case when @fact='MRE' and @tipnom='F' and @cant*@pretstoc<0 
			and @jurnal='MFX' and @invamreev=0 then -@pretstoc when @difpretprod=1 then (case when 
			LEFT(@ctstoc,3)='354' then @pretam else @pretstoc end) else @pretstoc end)-(case when 
			@fact='MRE' and @tipnom='F' and @jurnal='MFX' and @invamreev=1 then @accdat 
			else 0 end), 2)
		set @sumavaluta=dbo.rot_val((case when @valuta<>'' and @curs>0 
			then @cant*(case when @difpretprod=1 then (case when LEFT(@ctstoc,3)='354' 
			then @pretam else @pretstoc end) else @pretstoc end)/(case when @curs>0 then @curs 
			else 1 end) else 0 end), 2)
		set @expl='AI '+rtrim(@numar)+(case when left(@fact,8)+@contr<>'' then ': ' 
			else '' end)+left(@fact,8)+@contr
		if @ctcred like '6%'
		begin
			set @ctnom=@ctcred
			set @ctcred=@ctdeb
			set @ctdeb=@ctnom
			set @suma=-@suma
			set @sumavaluta=-@sumavaluta
		end
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta=@Valuta, @Curs=@Curs, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
		
	if @sumaTVA<>0
		begin
		set @ctdeb=@cttvaded
		set @ctcred=@ctinterm
		set @suma=dbo.rot_val(@sumaTVA, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TVA deductibil AI nr. '+@numar
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
		
	if left(@ctstoc,1)<>'8' and @tipgest in ('A','V') and not (@difpretprod=1 and 
		left(@ctstoc,3)='354') and LEFT(@ctstoc,2) in ('35','37')
		begin
		set @ctdeb=@ctstoc
		set @ctcred=@ctfact
		set @suma=dbo.rot_val(@cant*round(@pretam*@tvanx/(100+@tvanx),@nrzectvanx), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='AI '+rtrim(@numar)+(case when @fact+@contr<>'' then ': ' else '' end)+@fact+@contr
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
			
		set @ctdeb=@ctstoc
		set @ctcred=@gestprim
		set @suma=dbo.rot_val(round(@cant*@pretam,2)-round(@cant*(case when @difpretprod=1 
			and @tipnom<>'F' and LEFT(@ctstoc,3)='371' then @suprataxevama else @pretstoc end),2)-
			round(@cant*round(@pretam*@tvanx/(100+@tvanx),@nrzectvanx),2), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='AI '+rtrim(@numar)+(case when @fact+@contr<>'' then ': ' else '' end)+@fact+@contr
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
	--DB 8045 pt. mfixe
	if @tipnom='F' and LEFT(@barcod,1)='8' and @acccump<>0 and @jurnal='MFX'
		begin
		set @ctdeb=@barcod
		set @ctcred=''
		set @suma=dbo.rot_val(@acccump, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Amortizare af. grd. neutilizare'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
	--Val. amortizata pt. mfixe
	if @tipnom='F' and @accdat<>0 and @jurnal='MFX'
		begin
		set @ctdeb=(case when @fact='MRE' and @tipnom='F' and @jurnal='MFX' and @invamreev=1 
			then @ctcor else @gestprim end)
		set @ctcred=(case when @fact='MRE' and @tipnom='F' and @jurnal='MFX' and @invamreev=1 
			then @gestprim else @ctfact end)
		set @suma=dbo.rot_val((case when @fact='MRE' and @tipnom='F' and @jurnal='MFX' and 
			@invamreev=1 then -1 else 1 end)*@accdat, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Val. amortizata'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
	--Ajustari mfixe
	if @tipnom='F' and @suprataxevama<>0 and @jurnal='MFX'
		begin
		set @ctdeb=@tert
		set @ctcred=@ctven
		set @suma=dbo.rot_val(@suprataxevama, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Rezerve din reev. sau ajustari'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
	--Rezerve mfixe ct. 106
	if @tipnom='F' and @pretampred<>0 and @jurnal='MFX'
		begin
		set @ctdeb=@ctcor
		set @ctcred=@ctrezrep
		set @suma=dbo.rot_val(@cant*@pretampred, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Rezerve'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
	
	fetch next from tmpinregAI into @Sub,@Tip,@Numar,@Cod,@Data,@Gest,@Cant,@Pretvaluta,@Pretstoc,
		@Adaos,@Pretvanz,@Pretam,@sumaTVA,@CotaTVA,@Ctstoc,@Ctcor,@TVAnx,
		@Pretampred,@Tipmisc,@Locatie,@Dataexp,@Nrpozitie,@Lm,
		@Com,@Barcod,@Ctinterm,@Ctven,@Disc,@Tert,@Fact,
		@Gestprim,@DVI,@Stare,@Grupa,@Ctfact,@Valuta,@Curs,@Datafact,
		@Datascad,@Procvama,@Suprataxevama,@Acccump,@Accdat,
		@Contr,@Jurnal,@tipgest,@ctgest,@tipnom,@dennom,@ctnom,@grupanom,
		@tipctstoc,@atrctstoc,@idPozdoc
	set @gfetch=@@fetch_status
	END
	
end
close tmpinregAI
deallocate tmpinregAI
--	apelare procedura specifica
if exists (select * from sysobjects where name ='inregAISP')
	exec inregAISP @dataj=@dataj, @datas=@datas, @nrdoc=@nrdoc
end
