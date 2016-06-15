--***
create procedure inregAC @dataj datetime, @datas datetime, @nrdoc varchar(20)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,@sub char(9),
@tip char(2),@numar varchar(20),@data datetime,@gest char(9),@tipgest char(1),@ctgest varchar(40),
@cod char(20),@cant float,@tvanx float,@pretvaluta float,@pretstoc float,
@pretvanz float,@pretampred float,@pretam float,@sumaTVA float,
@tipnom char(1),@contnom varchar(40),@grupanom char(13),
@ctstoc varchar(40),@ctcor varchar(40),--@atr_ct_stoc float,@tip_ct_stoc char(1),@cont_factura varchar(40),
@ctinterm varchar(40),--@tert varchar(20),@factura char(20),
@gestprim varchar(40),@dvi char(25),--@den_tert char(30),@t_extern int,
@valuta char(3),@curs float,--@disc float,@proc_vama float,
@lm char(9),@com char(40),@jurnal char(3),
@valpretstoc float,@valpretam float,@tvanxpretam float,@valpretampred float,@tvanxpred float,
@supratxvama float,@acccump float,--@accdat float,
@subunitate char(9),@rottvanx int, @nrzectvanx int, @accprod int, @adtvanxavc int, 
@adtvanxava int, @ctadaos varchar(40), @angestctadaos int, @angrctadaos int, 
@cttvanx varchar(40), @angestcttvanx int, @ttla int,
@glm char(9),@gcom char(40),@gjurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@suma float,@sumavaluta float,@expl char(50), @userASiS char(10)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','ROTUNJTNX',@rottvanx output,@nrzectvanx output,''
--Ghita a zis ca nu mai e cazu' de: if @rottvanx=0 set @nrzectvanx=2 
exec luare_date_par 'GE','ACCIZE',@accprod output,0,''
exec luare_date_par 'GE','ADTAV',@adtvanxavc output,0,''
exec luare_date_par 'GE','ADTAVA',@adtvanxava output,0,''
exec luare_date_par 'GE','CADAOS',@angestctadaos output,@angrctadaos output,@ctadaos output
exec luare_date_par 'GE','CNTVA',@angestcttvanx output,0,@cttvanx output
exec luare_date_par 'GE','TIMBRULIT',@ttla output,0,''
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate and tip_document='AC' and numar_document 
	between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas

declare tmpinregAC cursor for
select p.subunitate, p.tip, p.data, p.numar, p.gestiune, max(isnull(g.tip_gestiune, '')) 
as tip_gestiune, max(isnull(g.cont_contabil_specific, '')) as cont_specific, 
p.cont_de_stoc, p.cont_corespondent, p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, 
p.loc_de_munca, p.comanda, n.grupa, p.jurnal, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_de_stoc), 2)) as val_pret_stoc, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_cu_amanuntul), 2)) as val_pret_amanunt, 
sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), 
p.pret_cu_amanuntul*p.cota_tva/(100.00+p.cota_tva)),@nrzectvanx)), 2)) as val_tva_nx_pret_amanunt, 
sum(round(convert(decimal(17,5), p.cantitate*p.pret_amanunt_predator), 2)) 
as val_pret_amanunt_predator, 
sum(round(convert(decimal(17,5), p.cantitate*round(convert(decimal(17,5), 
p.pret_amanunt_predator*p.tva_neexigibil/(100+p.tva_neexigibil)),@nrzectvanx)), 2)) 
as val_tva_nx_pred, 
sum(round(convert(decimal(17,5), p.cantitate*p.suprataxe_vama), 2)) as val_supratx_vama, 
sum(round(convert(decimal(30,5), p.cantitate*p.accize_cumparare), 2)) as val_accize_cumparare, 
max(p.valuta), max(p.curs)
FROM pozdoc p 
left outer join gestiuni g on p.subunitate = g.subunitate and p.gestiune = g.cod_gestiune 
left outer join nomencl n on p.cod = n.cod 
left outer join terti t on p.subunitate = t.subunitate and p.tert = t.tert 
left outer join conturi c on p.subunitate = c.subunitate and p.cont_de_stoc = c.cont 
WHERE p.subunitate=@subunitate and p.tip='AC' and p.data between @dataj and @datas 
and (@nrdoc='' or p.numar=@nrdoc) 
and tip_miscare='E'
GROUP BY p.subunitate, p.tip, p.data, p.numar, p.gestiune, p.cont_de_stoc, p.cont_corespondent, 
p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, p.loc_de_munca, p.comanda, n.grupa, 
p.jurnal 
ORDER BY p.subunitate, p.tip, p.data, p.numar, p.gestiune 

open tmpinregAC
fetch next from tmpinregAC into @sub,@tip,@data,@numar,@gest,@tipgest,@ctgest,@ctstoc,
		@ctcor,@ctinterm,@gestprim,@dvi,@lm,@com,@grupanom,@jurnal,@valpretstoc,@valpretam,
		@tvanxpretam,@valpretampred,@tvanxpred,@supratxvama,@acccump,@Valuta,@Curs
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
	if 0=0 
		BEGIN
		set @ctdeb=@ctinterm
		set @ctcred=@ctstoc
		set @suma=dbo.rot_val((case when @ctinterm=@ctstoc or @ctinterm='' then 0 
			when left(@ctstoc,1)='8' then @valpretam else @valpretstoc end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Pozitie intermediara'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
				
	if 0=0 
		BEGIN
		set @ctdeb=@ctcor
		set @ctcred=(case when @ctinterm='' then @ctstoc else @ctinterm end)
		set @suma=dbo.rot_val((case when left(@ctstoc,1)='8' then @valpretam 
			--when @Modatim=1 and left(@ctgest,3)='371' then @supratxvama
			else @valpretstoc end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Descarcare in pret furnizor'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
		
	if (@tipgest='V' or @tipgest='A' or @adtvanxavc=1 and @tipgest='C') and LEFT(@ctstoc,2) in 
		('35','37')
		BEGIN
		set @ctdeb=RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+rtrim(@gest) else '' end)
		set @ctcred=@ctstoc
		set @suma=dbo.rot_val((case when @adtvanxavc=1 and @tipgest='C' OR @adtvanxava=1 and 
			@tipgest='A' then @tvanxpretam else @tvanxpred end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Descarcare TVA neexigibil'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0

		set @ctdeb=RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+rtrim(@gest) else '' 
			end)+(case when @angrctadaos=1 then '.'+rtrim(@grupanom) else '' end)
		set @ctcred=@ctstoc
		set @suma=dbo.rot_val((case when @adtvanxavc=1 and @tipgest='C' OR @adtvanxava=1 and 
			@tipgest='A' then @valpretam-@valpretstoc-@tvanxpretam else 
			@valpretampred-@valpretstoc-@tvanxpred end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Descarcare adaos'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
				
	if (@adtvanxavc=1 and @tipgest='C' or @adtvanxava=1 and @tipgest='A') and LEFT(@ctstoc,2) in 
		('35','37')
		BEGIN
		set @ctdeb=@ctstoc
		set @ctcred=RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+rtrim(@gest) else '' end)
		set @suma=dbo.rot_val(@tvanxpretam-(case when @adtvanxava=1 and 
			@tipgest='A' then @tvanxpred else 0 end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Incarcare TVA neexigibil'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0

		set @ctdeb=@ctstoc
		set @ctcred=RTRIM(@ctadaos)+(case when @angestctadaos=1 then '.'+rtrim(@gest) else '' 
			end)+(case when @angrctadaos=1 then '.'+rtrim(@grupanom) else '' end)
		set @suma=dbo.rot_val(@valpretam-@valpretstoc-@tvanxpretam-(case when @adtvanxava=1 and 
			@tipgest='A' then @valpretampred-@valpretstoc-@tvanxpred else 0 end), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl='Incarcare adaos'
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
				
	if @ttla=1 or @accprod=1 
		BEGIN
		set @ctdeb=(case when @ttla=1 or @accprod=1 then @gestprim else 'YYY' end)
		set @ctcred=@dvi
		set @suma=dbo.rot_val(@acccump, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl=(case when @ttla=1 then 'Timbru literar' else 'Accize' end)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
				
	fetch next from tmpinregAC into @sub,@tip,@data,@numar,@gest,@tipgest,@ctgest,@ctstoc,
		@ctcor,@ctinterm,@gestprim,@dvi,@lm,@com,@grupanom,@jurnal,@valpretstoc,@valpretam,
		@tvanxpretam,@valpretampred,@tvanxpred,@supratxvama,@acccump,@Valuta,@Curs
	set @gfetch=@@fetch_status
	end
	
end
close tmpinregAC
deallocate tmpinregAC
end
