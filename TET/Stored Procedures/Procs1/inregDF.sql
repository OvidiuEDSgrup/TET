--***
create procedure inregDF @dataj datetime, @datas datetime, @nrdoc varchar(20)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,@sub char(9),
@tip char(2),@numar varchar(20),@data datetime,@gest char(9),@tipgest char(1),@ctgest varchar(40),
@cod char(20),@cant float,@pretstoc float,@pretampred float,@pretvaluta float,
@pretvanz float,@pretam float,@cotaTVA float,@sumaTVA float,@tvanx float,@adaos float,
@tipnom char(1),@dennom char(80),@ctnom varchar(40),@grupanom char(13),@numesalariat char(50), 
@grupa char(13),@tipmisc char(1),@ctstoc varchar(40),@tipctstoc char(1),@atrctstoc float,
@ctcor varchar(40),@ctven varchar(40),@ctinterm varchar(40),@ctfact varchar(40),
@fact char(20),@datafact datetime,@datascad datetime,@tert char(13),--@tiptert int,
@gestprim varchar(40),@dvi char(25),@locatie char(30),@barcod char(30),@nrpozitie int,@stare int,
@dataexp datetime,@valuta char(3),@curs float,@disc float,@procvama float,@suprataxevama float,
@acccump float,@accdat float,@lm char(9),@com char(40),@contr char(20),@jurnal char(3),
@subunitate char(9),@cuctvenDF int,@ctvenDF varchar(40),@cttvacol varchar(40),
@glm char(9),@gcom char(40),@gjurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@suma float,@sumavaluta float,@expl char(50), @userASiS char(10)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','CTVENDF',@cuctvenDF output,0,@ctvenDF output
exec luare_date_par 'GE','CCTVA',0,0,@cttvacol output
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate and tip_document='DF' and numar_document 
	between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas

declare tmpinregDF cursor for
select p.Subunitate,p.Tip,p.Numar,p.Cod,p.Data,p.Gestiune,p.Cantitate,p.Pret_valuta,p.Pret_de_stoc,
p.Adaos,p.Pret_vanzare,p.Pret_cu_amanuntul,p.TVA_deductibil,p.Cota_TVA,
p.Cont_de_stoc,p.Cont_corespondent,p.TVA_neexigibil,
p.Pret_amanunt_predator,p.Tip_miscare,p.Locatie,p.Data_expirarii,p.Numar_pozitie,p.Loc_de_munca,
p.Comanda,p.Barcod,p.Cont_intermediar,p.Cont_venituri,p.Discount,p.Tert,p.Factura,
p.Gestiune_primitoare,p.Numar_DVI,p.Stare,p.Grupa,p.Cont_factura,p.Valuta,p.Curs,p.Data_facturii,
p.Data_scadentei,p.Procent_vama,p.Suprataxe_vama,p.Accize_cumparare,p.Accize_datorate,
p.Contract,p.Jurnal,isnull(g.tip_gestiune, ''), isnull(g.cont_contabil_specific, ''), 
isnull(n.tip,''), isnull(n.denumire,''), isnull(n.cont,''), isnull(n.grupa,''), 
isnull(c1.tip_cont,''), isnull(c1.sold_credit,0), isnull(s.nume,'')
FROM pozdoc p 
left outer join gestiuni g on p.subunitate = g.subunitate and p.gestiune = g.cod_gestiune 
left outer join nomencl n on p.cod = n.cod 
--left outer join terti t on p.subunitate = t.subunitate and p.tert = t.tert 
left outer join personal s on p.gestiune_primitoare = s.marca 
left outer join conturi c1 on p.subunitate = c1.subunitate and p.cont_de_stoc = c1.cont 
WHERE p.subunitate=@subunitate and p.tip='DF' and p.data between @dataj and @datas 
and (@nrdoc='' or p.numar=@nrdoc) 
/*GROUP BY p.subunitate, p.tip, p.data, p.numar, p.gestiune, p.cont_de_stoc, p.cont_corespondent, 
p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, p.loc_de_munca, p.comanda, n.grupa, 
p.jurnal*/ 
ORDER BY p.subunitate, p.tip, p.data, p.numar, p.gestiune

open tmpinregDF
fetch next from tmpinregDF into @Sub,@Tip,@Numar,@Cod,@Data,@Gest,@Cant,@Pretvaluta,@Pretstoc,
		@Adaos,@Pretvanz,@Pretam,@sumaTVA,@CotaTVA,@Ctstoc,@Ctcor,@TVAnx,
		@Pretampred,@Tipmisc,@Locatie,@Dataexp,@Nrpozitie,@Lm,
		@Com,@Barcod,@Ctinterm,@Ctven,@Disc,@Tert,@Fact,
		@Gestprim,@DVI,@Stare,@Grupa,@Ctfact,@Valuta,@Curs,@Datafact,
		@Datascad,@Procvama,@Suprataxevama,@Acccump,@Accdat,
		@Contr,@Jurnal,@tipgest,@ctgest,@tipnom,@dennom,@ctnom,@grupanom,
		@tipctstoc,@atrctstoc,@numesalariat
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
	if 0=0 or @ctcor<>@ctstoc
		begin
		set @ctdeb=(case when LEFT(@ctstoc,3)='371' and @ctinterm<>'' then @ctinterm 
			when LEFT(@ctcor,1)='8' then @ctven else @ctcor end)
		set @ctcred=@ctstoc
		set @suma=dbo.rot_val(@cant*@pretstoc*(1-(case when @cuctvenDF=1 then 0 
			else @procvama end)/100), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl=(case when @fact+@contr<>'' then @fact+@contr else @numesalariat end) 
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
		
	if left(@ctstoc,3)='371' and @ctinterm<>''
		begin
		set @ctdeb=(case when LEFT(@ctcor,1)='8' then @ctven else @ctcor end)
		set @ctcred=@ctinterm
		set @suma=dbo.rot_val(@cant*@pretstoc*(1-(case when @cuctvenDF=1 then 0 
			else @procvama end)/100), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl=(case when @fact+@contr<>'' then @fact+@contr else @numesalariat end) 
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
		
	if left(@ctcor,1)='8' or @ctven<>'' and @ctinterm<>''
		begin
		set @ctdeb=(case when LEFT(@ctcor,1)='8' then @ctcor else @ctven end)
		set @ctcred=(case when LEFT(@ctcor,1)='8' then '' else @ctinterm end)
		set @suma=dbo.rot_val(@cant*@pretstoc*(1-@procvama/100), 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl=(case when @fact+@contr<>'' then @fact+@contr else @numesalariat end) 
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
		
	if @procvama>0
		begin
		set @ctdeb=@ctfact
		set @ctcred=(case when @cuctvenDF=1 then @ctvenDF else @ctstoc end) 
		set @suma=dbo.rot_val(@cant*@pretstoc*@procvama/100, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl=(case when @fact+@contr<>'' then @fact+@contr else @numesalariat end) 
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0

		set @ctdeb=@ctfact
		set @ctcred=@cttvacol
		set @suma=dbo.rot_val(@cant*@pretstoc*@procvama/100*@cotaTVA/100, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl=(case when @fact+@contr<>'' then @fact+@contr else @numesalariat end) 
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
	
	fetch next from tmpinregDF into @Sub,@Tip,@Numar,@Cod,@Data,@Gest,@Cant,@Pretvaluta,@Pretstoc,
		@Adaos,@Pretvanz,@Pretam,@sumaTVA,@CotaTVA,@Ctstoc,@Ctcor,@TVAnx,
		@Pretampred,@Tipmisc,@Locatie,@Dataexp,@Nrpozitie,@Lm,
		@Com,@Barcod,@Ctinterm,@Ctven,@Disc,@Tert,@Fact,
		@Gestprim,@DVI,@Stare,@Grupa,@Ctfact,@Valuta,@Curs,@Datafact,
		@Datascad,@Procvama,@Suprataxevama,@Acccump,@Accdat,
		@Contr,@Jurnal,@tipgest,@ctgest,@tipnom,@dennom,@ctnom,@grupanom,
		@tipctstoc,@atrctstoc,@numesalariat
	set @gfetch=@@fetch_status
	END
	
end
close tmpinregDF
deallocate tmpinregDF
end
