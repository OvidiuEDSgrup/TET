--***
create procedure inregAD @dataj datetime, @datas datetime, @nrdoc char(8)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar char(8),@gdata datetime,
@sub char(9),@tip char(2),@numar char(8),@data datetime,@factst char(20),@factdr char(20),
@ctdeb varchar(40),@ctcred varchar(40),/*@atrct float,@atrctcor float,*/@tert char(13), @TLI int, 
@suma float, @sumavaluta float, @cotatva float, @sumatva float, @expl char(50), 
@achitfact float, @tiptva float, @diftva float,@sumadifcurs float,@ctdif varchar(40),
@nrpozitie int,@valuta char(3),@curs float,@lm char(9),@com char(40),@jurnal char(3),
@cursfactdr float,@tipctdeb char(1),@tipctcred char(1),@tertbenef char(13),@DataFact datetime, 
@subunitate char(9),@IFN int,@LeasingRom int,@ignor4428 int,@docdef int,@docdefie int,
@cttvaded varchar(40), @cttvacol varchar(40), @cttvaneex varchar(40), @ctChTVANeded varchar(40),--@TVAnedStoc int, 
@cttvaneexTLIFurn varchar(40), @cttvaneexTLIBen varchar(40), 
@faradifcurs int,@glm char(9),@gcom char(40),@gjurnal char(3),@invFFFB int,
@valutam char(3),@cursm float,@ctdebm varchar(40),@ctcredm varchar(40),@sumam float,
@sumavalutam float,@explm char(50),@userASiS char(10)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','IFN',@IFN output,0,''
exec luare_date_par 'GE','LRMZ',@LeasingRom output,0,''
exec luare_date_par 'GE','DOCDEF',@docdef output,0,''
exec luare_date_par 'GE','DOCDEFIE',@docdefie output,0,''
exec luare_date_par 'GE','NEEXAV',@ignor4428 output,0,''
exec luare_date_par 'GE','CNEEXREC',0,0,@Cttvaneex output
exec luare_date_par 'GE','CNTLIFURN',0,0,@cttvaneexTLIFurn output
exec luare_date_par 'GE','CNTLIBEN',0,0,@cttvaneexTLIBen output
exec luare_date_par 'GE','CDTVA',0,0,@Cttvaded output
exec luare_date_par 'GE','CCTVA',0,0,@cttvacol output
exec luare_date_par 'GE','CCTVANED',0,0,@CtChTVANeded output
--exec luare_date_par 'GE','TVANEDST',@TVAnedStoc output,0,''
set @faradifcurs=1
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate 
	and tip_document in ('CO','C3','CB','CF','IF','SF','FB','FF') and numar_document 
	between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end)
	and data between @dataj and @datas

declare tmpinregAD cursor for
select p.Subunitate, p.Numar_document, p.Data, p.Tert, p.Tip, p.Factura_stinga, p.Factura_dreapta,
p.Cont_deb, p.Cont_cred, p.Suma, p.TVA11, p.TVA22, p.Numar_pozitie, p.Tert_beneficiar, 
p.Explicatii, p.Valuta, p.Curs, p.Suma_valuta, p.Cont_dif, p.suma_dif, 
p.Loc_munca, p.Comanda, p.Data_fact, /*p.Data_scad, */p.stare, p.Achit_fact, p.Dif_TVA, 
p.Jurnal, isnull(f1.Curs,0), isnull(c1.Tip_cont,''), isnull(c2.Tip_cont,'')
FROM pozadoc p 
	left outer join facturi f1 on p.subunitate = f1.subunitate and f1.Tip=0x46
		and p.Factura_dreapta = f1.Factura and p.tert = f1.tert 
	left outer join conturi c1 on p.subunitate = c1.subunitate and p.Cont_deb = c1.cont 
	left outer join conturi c2 on p.subunitate = c2.subunitate and p.Cont_cred = c2.cont 
WHERE p.subunitate=@subunitate and p.data between @dataj and @datas 
	and (@nrdoc='' or p.Numar_document=@nrdoc) 
ORDER BY p.subunitate, p.data, p.Numar_document, p.Numar_pozitie

open tmpinregAD
fetch next from tmpinregAD into @Sub, @Numar, @Data, @Tert, @Tip, 
			@Factst, @Factdr, @CtDeb, @CtCred, @suma, @cotatva, @sumatva, 
			@Nrpozitie, @TertBenef, @expl, @Valuta, @Curs, @sumavaluta, @CtDif, 
			@sumadifcurs, @LM, @Com, @DataFact, /*@DataScad, */@tiptva, @AchitFact, @DifTVA, 
			@Jurnal, @cursfactdr, @tipctdeb, @tipctcred--, @atrct, @atrctcor
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
	set @TLI=0
	if @tip='SF' or @tip='IF'
	begin
/*
		select isnull(tvatf.tip_tva,isnull(tvat.tip_tva,isnull(tvatb.tip_tva,'P'))) as tip_tva,
			row_number() over (partition by f.tert,f.factura order by isnull(tvatf.dela,isnull(tvat.dela,isnull(tvatb.dela,'01/01/1901'))) desc) as ranc
		into #facturi_cu_TLI
		from (select @tert tert, (case when @tip='SF' then @factdr else @factst end) factura) f
		inner join facturi fct on f.tert=fct.tert and f.factura=fct.factura
		left outer join TvaPeTerti tvatb on tvatb.tipf='B' and tvatb.tert is null and fct.data>=tvatb.dela
		left outer join TvaPeTerti tvat on tvat.tipf='F' and tvat.tert=f.tert and isnull(tvat.factura,'')='' and fct.data>=tvat.dela
		left outer join TvaPeTerti tvatf on tvatf.tipf=(case when @tip='SF' then 'F' else 'B' end) and tvatf.Tert=f.tert and tvatf.factura=f.factura
		where fct.data>'2012-12-31'
		delete from #facturi_cu_TLI where not (ranc=1 and tip_tva='I')
*/		
--Lucian: utilizam procedura tipTVAFacturi (in locul selectului de mai sus) care stabileste tipul de TVA al facturii
		select '' as tip,(case when fct.tip=0x54 then 'F' else 'B' end) as tipf,f.tert,f.factura,@DataFact as data,
			(case when @tip in ('SF','FF') then @CtCred else @CtDeb end) as cont,'' as tip_tva			
		into #facturi_cu_TLI
		from (select @tert tert, (case when @tip='SF' then @factdr else @factst end) factura) f
		inner join facturi fct on f.tert=fct.tert and f.factura=fct.factura
		exec tipTVAFacturi @dataJos=@dataj, @dataSus=@datas
		delete from #facturi_cu_TLI where not (tip_tva='I')
		if exists (select 1 from #facturi_cu_TLI)
			set @TLI=1
		drop table #facturi_cu_TLI
	end

	set @invFFFB=(case when /*@suma<0 and*/ (@tip='FF' and (LEFT(@ctdeb,1)='7' OR LEFT(@ctdeb,1)='6' 
		and @tipctdeb='P') OR @tip='FB' and (LEFT(@ctcred,1)='6' or LEFT(@ctcred,1)='7' and 
		@tipctcred='A')) then 1 else 0 end)
		
	if not (@tip='CO' and @ctdeb='' and @ctcred='') and (case when (@tip='FF' OR @tip='FB') and 
	@suma=0 and @sumavaluta=0 then 'YY1' else @ctcred end)<>(case when (@tip='FF' OR @tip='FB') 
	and @suma=0 and @sumavaluta=0 then 'XX1' else @ctdeb end)
	begin
		set @ctdebm=(case when (@tip='FF' OR @tip='FB') and @suma=0 and @sumavaluta=0 then 
			'XX1' when @invFFFB=1 then @ctcred when @tip='FF' and @ctdif<>'' then 
			@ctdif else @ctdeb end)
		set @ctcredm=(case when (@tip='FF' OR @tip='FB') and @suma=0 and @sumavaluta=0 then 
			'YY1' when @invFFFB=1 then (case when @tip='FF' and @ctdif<>'' then 
			@ctdif else @ctdeb end) else @ctcred end)
		set @sumam=dbo.rot_val((@suma+(case when @tip='SF' and LEFT(@ctdeb,3)<>'308' then 
			@sumatva else 0 end)-(case when @tip='SF' then @diftva else 0 end)-
			(case when (@tip='CF' or @tip='SF' or @tip='CO') and (LEFT(@ctdif,1)='6' or 
			LEFT(@ctdif,3)='308') OR (@tip='CB' or @tip='IF') and LEFT(@ctdif,1)='7' then 
			@sumadifcurs else 0 end))*(case when @invFFFB=1 then -1 else 1 end), 2)
		set @sumavalutam=dbo.rot_val((case when @tip='CB' and @IFN=1 and @faradifcurs=1 then 
			(case when @sumavaluta<>0 then @sumavaluta else @achitfact end) else 
			(@sumavaluta+(case when @tip='IF' and @curs>0 then @sumatva/@curs else 0 end))*
			(case when @invFFFB=1 then -1 else 1 end) end), 2)
		set @explm=left(@expl,30)
		set @valutam=@valuta
		set @cursm=@curs
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdebm, @Cont_creditor=@ctcredm, @Suma=@sumam, 
			@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	end
	--Poz. intermediara FF
	if @tip='FF' and @ctdif<>''
	begin
		set @ctdebm=(case when @invFFFB=1 then @ctdif else @ctdeb end)
		set @ctcredm=(case when @invFFFB=1 then @ctdeb else @ctdif end)
		set @sumam=dbo.rot_val((case when @invFFFB=1 then -1 else 1 end)*@suma, 2)
		set @sumavalutam=dbo.rot_val((case when @invFFFB=1 then -1 else 1 end)*@sumavaluta, 2)
		set @explm=left(@expl,30)
		set @valutam=@valuta
		set @cursm=@curs
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdebm, @Cont_creditor=@ctcredm, @Suma=@sumam, 
			@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	end
	--Dif. curs valutar
	if @sumadifcurs<>0
	begin
		set @ctdebm=(case when LEFT(@ctdif,1)='6' or LEFT(@ctdif,3)='308' then @ctdif 
			else @ctdeb end)
		set @ctcredm=(case when LEFT(@ctdif,1)='7' then @ctdif else @ctcred end)
		set @sumam=dbo.rot_val(@sumadifcurs, 2)
		set @sumavalutam=0 --dbo.rot_val(0, 2)
		set @explm=left(@expl,30)
		set @valutam=''
		set @cursm=0
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdebm, @Cont_creditor=@ctcredm, @Suma=@sumam, 
			@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	end
	--TVA
	if not (@tip='CB' or @tip='CF') and not ((@tip='FB' or @tip='IF') and @tiptva=2 and (@docdef=0 or @docdefie=1))
	begin
		set @ctdebm=(case when @tip='SF' or @tip='FF' or (@tip='IF' or @tip='FB') and @tiptva=1 and (@docdef=0 or @docdefie=1) 
						then (case when @tip='FF' and @tertbenef<>'' then @tertbenef when @tip='FF' and LEFT(@ctcred,3)='408' then @cttvaneex 
								when @tip='SF' and @TLI=1 and @tiptva=0 then @cttvaneexTLIFurn else @cttvaded end) 
						when LEFT(@ctdeb,3)='419' and @tip<>'FB' then @cttvacol else @ctdeb end)
		set @ctcredm=(case when (@tip='SF' or @tip='FF') and @tiptva=1 and (@docdef=0 or @docdefie=1) then @cttvacol 
						when @tip='SF' or @tip='FF' then @ctcred when @tip='FB' and @tertbenef<>'' then @tertbenef 
						when LEFT(@ctdeb,3)='419' or @tip='FB' and LEFT(@ctdeb,3)='418' then @cttvaneex 
						when @tip='IF' and @TLI=1 and @tiptva=0 then @cttvaneexTLIBen else @cttvacol end)
		-- la SF este doar diferenta de TVA, la rest e chiar suma TVA
		set @sumam=dbo.rot_val((case when @tip='SF' then @diftva else @sumatva end), 2)
		set @sumavalutam=dbo.rot_val((case when @tip='FF' or @tip='FB' then @diftva else 0 end), 2)
		set @explm=left(@expl,30)
		set @valutam=(case when @tip='FF' or @tip='FB' then @valuta else '' end)
		set @cursm=(case when @tip='FF' or @tip='FB' then @curs else 0 end)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdebm, @Cont_creditor=@ctcredm, @Suma=@sumam, 
			@Valuta=@valutam, @Curs=@cursm, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	end
		
	if not (@tip='FB' or @tip='FF')
	begin
		set @ctdebm=(case when @tip='SF' and @TLI=1 and @tiptva=0 then @cttvaneexTLIFurn 
						when @tip='SF' or @tip='CF' then @cttvaded when @tip='CB' and @ignor4428=1 then @ctdeb else @cttvaneex end)
		-- Ghita, 30.05.2013: in linia de mai jos am pus pt. Rematinvest "OR @tip='SF' and @tiptva=1 and (@docdef=0 or @docdefie=1)" pentru a obtine 4426=4427 la TVA cu taxare inversa
		-- Totusi, este un conflict intre TVA neex. pe receptia in 408 si taxarea inversa, normal ar trebui sa am 4426=4427 si 408=4428 - poate ar trebui studiat.
		set @ctcredm=(case when @tip='CB' OR @tip='SF' and @tiptva=1 and (@docdef=0 or @docdefie=1) then @cttvacol 
						when @tip='IF' or @tip='CF' and @ignor4428=1 OR @tip='SF' and LEFT(@ctdeb,3)='308' then @ctcred 
						when @tip='IF' and @TLI=1 and @tiptva=0 then @cttvaneexTLIBen else @cttvaneex end)
		-- la SF/IF este TVA de exigibilizat, la CF/CB este suma TVA
		set @sumam=dbo.rot_val((case when @tip='CF' or @tip='CB' then -1 else 1 end)*@sumatva-(case when @tip='SF' or @tip='IF' then @diftva else 0 end), 2)
		set @sumavalutam=0 --dbo.rot_val(0, 2)
		set @explm=left(@expl,30)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdebm, @Cont_creditor=@ctcredm, @Suma=@sumam, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	end		
	if (@tip in ('FF','SF') and @tiptva=2 and @CtChTVANeded<>'' or @tip='FF' and @tiptva=3) and @sumatva<>0
	begin
		set @ctdebm=(case when @tip='FF' and @tiptva=3 then @ctdeb else @ctChTVANeded end)
		set @ctcredm=(case when @tip='FF' and @tertbenef<>'' then @tertbenef when @tip='FF' and left(@ctcred,3)='408' then @cttvaneex else @cttvaded end)
		-- trecere TVA pe nedeductibil
		set @sumam=dbo.rot_val(@sumatva, 2)
		set @sumavalutam=dbo.rot_val((case when @tip='FF' then @diftva else 0 end), 2)
		set @explm=left(@expl,30)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdebm, @Cont_creditor=@ctcredm, @Suma=@sumam, 
			@Valuta=@valuta, @Curs=@curs, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	end
		
	--Nota 472.tert=706 pt. Leasing Rom
	if @LeasingRom=1 and @tip='IF'
	begin
		set @ctdebm='472.'+@tert
		set @ctcredm='706.1'
		set @sumam=dbo.rot_val((case when @valuta='' then @suma else @sumavaluta*@cursfactdr 
			end), 2)
		set @sumavalutam=0 --dbo.rot_val(0, 2)
		set @explm=left(@expl,30)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdebm, @Cont_creditor=@ctcredm, @Suma=@sumam, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	end
		
	fetch next from tmpinregAD into @Sub, @Numar, @Data, @Tert, @Tip, 
			@Factst, @Factdr, @CtDeb, @CtCred, @suma, @cotatva, @sumatva, 
			@Nrpozitie, @TertBenef, @expl, @Valuta, @Curs, @sumavaluta, @CtDif, 
			@sumadifcurs, @LM, @Com, @DataFact, /*@DataScad, */@tiptva, @AchitFact, @DifTVA, 
			@Jurnal, @cursfactdr, @tipctdeb, @tipctcred--, @atrct, @atrctcor
	set @gfetch=@@fetch_status
	END
	
end
close tmpinregAD
deallocate tmpinregAD
end
--	apelare procedura specifica
if exists (select * from sysobjects where name ='inregADSP')
	exec inregADSP @dataj=@dataj, @datas=@datas, @nrdoc=@nrdoc
