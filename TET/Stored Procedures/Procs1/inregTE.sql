--***
create procedure inregTE @dataj datetime, @datas datetime, @nrdoc varchar(20)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,@sub char(9),
@tip char(2),@numar varchar(20),@data datetime,@gest char(9),@tipgest char(1),@ctgest varchar(40),
@gestprim char(13),@tipgestprim char(1),@ctgestprim varchar(40),
@cod char(20),@cant float,@tvanx float,@pretvaluta float,@pretstoc float,
@pretvanz float,@pretampred float,@pretam float,@sumaTVA float,
@tipnom char(1),@contnom varchar(40),@grupanom char(13),
@ctstoc varchar(40),@ctcor varchar(40),--@atr_ct_stoc float,@tip_ct_stoc char(1),@cont_factura varchar(40),
@ctinterm varchar(40),@tert char(13),--@factura char(20),
@dvi char(25),--@den_tert char(30),@t_extern int,
@valuta char(3),@curs float,--@disc float,@proc_vama float,
@lm char(9),@lmprim char(9),@com char(40),@jurnal char(3),
@valpretstoc float,@valpretam float,@valpretampred float,@tvanxpred float,@tvanxprim float,
@supratxvama float,@acccump float,@accdat float,
@subunitate char(9), @invadtvanx int, @rottvanx int, @nrzectvanx int, @categprod int, 
@accprod int, @ctacc varchar(40), @ctchacc varchar(40), @adtvanxavc int, @adtvanxava int, 
@ctprod varchar(40), @anlmctprod int, @ctadaos varchar(40), @angestctadaos int, @angrctadaos int, 
@cttvanx varchar(40), @angestcttvanx int, @ttla int,@ttlr int,
@lmprimTE int, @neinregTEct int, @pasmatex int, 
@glm char(9),@gcom char(40),@gjurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@suma float,@sumavaluta float,@expl char(50),@lmm char(9),
@userASiS char(10)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','INVADDESC',@invadtvanx output,0,''
exec luare_date_par 'GE','ROTUNJTNX',@rottvanx output,@nrzectvanx output,''
--Ghita a zis ca nu mai e cazu' de: if @rottvanx=0 set @nrzectvanx=2 
exec luare_date_par 'GE','CATEGPRO',@categprod output,0,''
exec luare_date_par 'GE','ACCIZE',@accprod output,0,''
exec luare_date_par 'GE','CACCIZE',0,0,@ctacc output
exec luare_date_par 'GE','CCHACCIZE',0,0,@ctchacc output
exec luare_date_par 'GE','ADTAV',@adtvanxavc output,0,''
exec luare_date_par 'GE','ADTAVA',@adtvanxava output,0,''
exec luare_date_par 'GE','CONTP',@anlmctprod output,0,@ctprod output
exec luare_date_par 'GE','CADAOS',@angestctadaos output,@angrctadaos output,@ctadaos output
exec luare_date_par 'GE','CNTVA',@angestcttvanx output,0,@cttvanx output
exec luare_date_par 'GE','TIMBRULIT',@ttla output,0,''
exec luare_date_par 'GE','TIMBRULT2',@ttlr output,0,''
exec luare_date_par 'GE','LMPRIMTE',@lmprimTE output,0,''
exec luare_date_par 'GE','NUCTEGAL',@neinregTEct output,0,''
exec luare_date_par 'SP','PASMATEX',@pasmatex output,0,''
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate and tip_document='TE' and numar_document 
	between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas

declare tmpinregTE cursor for
select p.subunitate, p.tip, p.numar, p.data, max(isnull(n.grupa, '')) as grupa_nom, 
p.gestiune, max(isnull(g1.tip_gestiune, '')) as tip_gest_pred, 
p.gestiune_primitoare, max(isnull(g2.tip_gestiune, '')) as tip_gest_prim, 
p.cont_de_stoc, p.cont_corespondent, p.cont_intermediar, p.valuta, 
p.loc_de_munca, p.comanda, p.tert, p.jurnal, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_de_stoc), 2)) as val_pret_de_stoc, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_cu_amanuntul), 2)) as val_pret_amanunt, 
sum(round(convert(decimal(17,5), p.cantitate*(case when p.valuta='' or p.pret_valuta=0 then 
p.pret_amanunt_predator else p.pret_valuta*p.curs end)), 2)) as val_pret_predator, 
sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), (case when p.valuta='' 
or p.pret_valuta=0 then p.pret_amanunt_predator else p.pret_valuta*p.curs end)*p.tva_neexigibil/
(100.00+p.tva_neexigibil)), @nrzectvanx)), 2)) as val_tva_nx_predator, 
sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), p.pret_cu_amanuntul*
p.tva_neexigibil/(100.00+p.tva_neexigibil)), @nrzectvanx)), 2)) as val_tva_nx_primitor, 
sum(round(convert(decimal(17,5), p.cantitate*p.accize_cumparare), 2)) as val_acc_cump, 
sum(round(convert(decimal(17,5), p.accize_datorate), 2)) as val_acc_dat, 
max((case when isnull(gc.loc_de_munca, '')='' then p.loc_de_munca else gc.loc_de_munca end)) as 
loc_munca_primitor, max(p.curs)
FROM pozdoc p
left outer join nomencl n on p.cod=n.cod 
left outer join gestiuni g1 on g1.subunitate=p.subunitate and g1.cod_gestiune=p.gestiune
left outer join gestiuni g2 on g2.subunitate=p.subunitate and g2.cod_gestiune=p.gestiune_primitoare
left outer join gestcor gc on gc.gestiune=p.gestiune_primitoare
WHERE p.subunitate=@subunitate and p.tip='TE' and p.data between @dataj and @datas 
and (@nrdoc='' or p.numar=@nrdoc) 
GROUP BY p.subunitate, p.tip, p.numar, p.data, p.gestiune, p.gestiune_primitoare, p.cont_de_stoc, 
p.cont_corespondent, p.cont_intermediar, p.valuta, p.loc_de_munca, p.comanda, p.tert, p.jurnal 
ORDER BY p.subunitate, p.tip, p.data, p.numar, p.gestiune, p.gestiune_primitoare 

open tmpinregTE
fetch next from tmpinregTE into @sub,@tip,@numar,@data,@grupanom,@gest,@tipgest,
		@gestprim,@tipgestprim,@ctstoc,@ctcor,@ctinterm,@valuta,@lm,@com,@tert,@jurnal,
		@valpretstoc,@valpretam,@valpretampred,@tvanxpred,@tvanxprim,@acccump,@accdat,@lmprim,@curs
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
	begin
	if rtrim(@ctcor)<>RTRIM((case when @ctinterm='' or @ttlr=1 then @ctstoc else @ctinterm end)) 
		or @neinregTEct=0
		BEGIN
		set @ctdeb=@ctcor
		set @ctcred=(case when @ctinterm='' or @ttlr=1 then @ctstoc else @ctinterm end)
		set @suma=dbo.rot_val((case when @tipgestprim in ('A','V') and LEFT(@tert,3)='348' and 
			(@pasmatex=0 or @valuta<>'') then @valpretampred else @valpretstoc end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)
		set @lmm=(case when @lmprimTE=1 and @ctinterm<>'' then @lmprim else @lm end)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lmm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
				
	if @ctinterm<>'' and @ttlr=0
		BEGIN
		set @ctdeb=(case when @tipgest<>'V' and (left(@ctstoc,3)='345' or @lmprimTE=1 and 
			@ctinterm<>'') then (case when @ctinterm='' then 'A' else @ctinterm end) 
			else @ctstoc end)
		set @ctcred=(case when @tipgest<>'V' and (left(@ctstoc,3)='345' or @lmprimTE=1 and 
			@ctinterm<>'') then @ctstoc when @ctinterm='' then 'A' else @ctinterm end)
		set @suma=dbo.rot_val((case when @tipgest<>'V' and (left(@ctstoc,3)='345' or @lmprimTE=1 and 
			@ctinterm<>'') then 1 else -1 end)*@valpretstoc, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
	--Stornare adaos, TVA neex de la predator
	if @tipgest in ('A','V') and LEFT(@ctstoc,2) in ('35','37') or @tipgestprim in ('A','V') 
		and LEFT(@tert,3)='348' and (@pasmatex=0 or @valuta<>'') and LEFT(@ctstoc,2) in ('33','34')
		BEGIN
		set @ctdeb=(case when @invadtvanx=1 then RTRIM(@cttvanx)+(case when @angestcttvanx=1 then 
			'.'+rtrim(@gest) else '' end) when @tipgest in ('A','V') then @ctstoc else 'XXX' end)
		set @ctcred=(case when @invadtvanx=1 then (case when @tipgest in ('A','V') then @ctstoc 
			else 'XXX' end) else RTRIM(@cttvanx)+(case when @angestcttvanx=1 then 
			'.'+rtrim(@gest) else '' end) end)
		set @suma=dbo.rot_val((case when @invadtvanx=1 then 1 else -1 end)*@tvanxpred, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)
		if left(@tert,3)<>'348' 
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0

		set @ctdeb=(case when left(@tert,3)='348' then RTRIM(@ctprod)+(case when @anlmctprod=1 
			then '.'+rtrim(@lm) else '' end) when @invadtvanx=1 then 
			RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+rtrim(@gest) else '' 
			end)+(case when @angrctadaos=1 then '.'+rtrim(@grupanom) else '' end) 
			when @tipgest in ('A','V') then @ctstoc else 'XXX' end)
		set @ctcred=(case when left(@tert,3)='348' then @tert when @invadtvanx=1 then 
			(case when @tipgest in ('A','V') then @ctstoc else 'XXX' end) else 
			RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+rtrim(@gest) else '' 
			end)+(case when @angrctadaos=1 then '.'+rtrim(@grupanom) else '' end) end)
		set @suma=dbo.rot_val((case when left(@tert,3)='348' or @invadtvanx=1 then 1 else -1 end)*
			(@valpretampred-@valpretstoc-(case when left(@tert,3)='348' then 0 else @tvanxpred 
			end)-(case when @ttlr=1 then @acccump else 0 end)), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0

		set @ctdeb=@ctstoc
		set @ctcred=RTRIM(@ctprod)+(case when @anlmctprod=1 then '.'+rtrim(@lm) else '' end)
		set @suma=dbo.rot_val(@valpretampred-@valpretstoc, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)
		if left(@tert,3)='348' 
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
	--Incarcare adaos, etc. la primitor
	if @tipgestprim in ('A','V') and LEFT(@ctcor,3) in ('371','357','354')
		BEGIN
		set @ctdeb=@ctcor
		set @ctcred=RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+rtrim(@gestprim) 
			else '' end)
		set @suma=dbo.rot_val(@tvanxprim, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
			
		set @ctdeb=@ctcor
		set @ctcred=RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+rtrim(@gestprim) else '' 
			end)+(case when @angrctadaos=1 then '.'+rtrim(@grupanom) else '' end)
		set @suma=dbo.rot_val(@valpretam-@valpretstoc-@tvanxprim-(case when @ttlr=1 then @acccump 
			else 0 end)-(case when @pasmatex=1 and @valuta<>'' then @valpretampred-@valpretstoc 
			else 0 end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
	--Timbru literar din ct. intermed.
	if @ttlr=1 and @ctinterm<>''
		BEGIN
		set @ctdeb=@ctstoc
		set @ctcred=@ctinterm
		set @suma=dbo.rot_val(-@acccump, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)+' timbru literar'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
			
		set @ctdeb=@ctcor
		set @ctcred=@ctinterm
		set @suma=dbo.rot_val(@acccump, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)+' timbru literar'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
	--Accize datorate
	if @accprod=1 and @categprod=1 and @tipgestprim in ('A','V') and @accdat<>0
		BEGIN
		set @ctdeb=@ctchacc
		set @ctcred=@ctacc
		set @suma=dbo.rot_val(@accdat, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='TE '+rTrim (@numar)+' accize'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
				
	fetch next from tmpinregTE into @sub,@tip,@numar,@data,@grupanom,@gest,@tipgest,
		@gestprim,@tipgestprim,@ctstoc,@ctcor,@ctinterm,@valuta,@lm,@com,@tert,@jurnal,
		@valpretstoc,@valpretam,@valpretampred,@tvanxpred,@tvanxprim,@acccump,@accdat,@lmprim,@curs
	set @gfetch=@@fetch_status
	end
	
end
close tmpinregTE
deallocate tmpinregTE
--	daca exista camp detalii, se apeleaza procedura de generare stornare amortizare aferent transferurilor retur de obiecte de inventar
--	in detalii xml din pozdoc se salveaza contul de amortizare si valoarea amortizata
if exists (select 1 from syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'subtip')
	exec inregTEAmortizare @dataj=@dataj, @datas=@datas, @nrdoc=@nrdoc
end
