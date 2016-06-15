--***
create procedure inregPI @dataj datetime, @datas datetime, @ctdoc varchar(40)='', @nrdoc char(10)='', 
@jurndoc char(3)=''
as 
begin


declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar char(10),@gdata datetime,
@sub char(9),@tip char(2),@numar char(10),@data datetime,
@ct varchar(40),@ctcor varchar(40),@ctt varchar(40),/*@atrct float,@atrctcor float,*/@fact char(20),@tert char(13),
@suma float, @sumavaluta float, @cotatva float, @sumatva float, @expl char(50), 
@AchitFact float, @tiptva float, @sumadifcurs float, @ctDif varchar(40), 
@nrpozitie int,@valuta char(3),@curs float,@lm char(9),@com char(40),@jurnal char(3),
@subunitate char(9),@bugetari int, @invdifcursneg int, @ignor4428 int, 
@cttvaded varchar(40), @cttvacol varchar(40), @cttvaneex varchar(40), @ctChTVANeded varchar(40), --@TVAnedStoc int, 
@gct varchar(40),@glm char(9),@gcom char(40),@gjurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@Sumam float,@Sumavalutam float,@explm char(50),@userASiS char(10), @tipct char(1)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
exec luare_date_par 'GE','INVDIFINR',@invdifcursneg output,0,''
exec luare_date_par 'GE','NEEXAV',@ignor4428 output,0,''
exec luare_date_par 'GE','CNEEXREC',0,0,@Cttvaneex output
exec luare_date_par 'GE','CDTVA',0,0,@Cttvaded output
exec luare_date_par 'GE','CCTVA',0,0,@cttvacol output
exec luare_date_par 'GE','CCTVANED',0,0,@CtChTVANeded output
--exec luare_date_par 'GE','TVANEDST',@TVAnedStoc output,0,''
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate and tip_document='PI' and numar_document 
	between RTRIM(@ctdoc) and RTRIM(@ctdoc)+(case when @ctdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas

declare tmpinregPI cursor for
select 
p.Subunitate, p.Cont, p.Data, p.Numar, p.Plata_incasare, p.Tert, p.Factura, p.Cont_corespondent, 
p.Suma, p.Valuta, p.Curs, p.Suma_valuta, p.Curs_la_valuta_facturii, p.TVA11, p.TVA22, p.Explicatii, 
p.Loc_de_munca, p.Comanda, p.Numar_pozitie, p.Cont_dif, p.Suma_dif, p.Achit_fact, 
p.Jurnal, isnull(c.Tip_cont,'')
FROM pozplin p 
left outer join conturi c on p.subunitate = c.subunitate and p.Cont_corespondent = c.cont 
WHERE p.subunitate=@subunitate and p.data between @dataj and @datas 
and (@ctdoc='' or p.Cont=@ctdoc) and (@nrdoc='' or p.Numar=@nrdoc) 
and (@jurndoc='' or p.Jurnal=@jurndoc) 
ORDER BY p.subunitate, p.cont, p.data, p.Numar_pozitie, p.numar

open tmpinregPI
fetch next from tmpinregPI into @Sub, @Ct, @Data, @Numar, @Tip, @Tert, @Fact, 
		@Ctcor, @suma, @Valuta, @Curs, @sumavaluta, @tiptva, @cotatva, @sumatva, 
		@expl, @Lm, @Com, @Nrpozitie, @CtDif, @sumadifcurs, @AchitFact, 
		@Jurnal, @tipct--, @atrct, @atrctcor
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @gsub=@sub
	set @gtip=@tip
	set @gct=@ct
	set @gdata=@data
	set @glm=@lm
	set @gcom=@com
	set @gjurnal=@jurnal

	while @gsub=@sub and @gtip=@tip and @gct=@ct and @gdata=@data and @gfetch=0
	BEGIN
	set @ctdeb=(case when left(@tip,1)='I' then @ct else @ctcor end)
	set @ctcred=(case when left(@tip,1)='I' then @ctcor else @ct end)
	set @Sumam=dbo.rot_val(@suma-(case when @bugetari=1 and @CtDif<>'' and @tip='IB' and 
		LEFT(@ct,3)='102' then 0 else (case when RIGHT(@tip,1)='D' OR @tip='PR' OR @tip='IR' 
		then 0 else @sumatva end)+(case when (@sumadifcurs>0 or @invdifcursneg=1) and 
		(@bugetari=0 or @bugetari=1 and @CtDif<>'' and @tip='IB' and LEFT(@ct,3)='102') 
		then @sumadifcurs else 0 end) end), 2)
	set @Sumavalutam=dbo.rot_val(@sumavaluta, 2)
	set @explm=left(@tip+' '+RTRIM(@numar)+' '+(case when @valuta='' then '' else 
		RTRIM(@valuta)+' ' end)+(case when @fact='' then '' else 
		'fact. '+RTRIM(@fact)+' ' end)+@expl,50)
	if @suma<0 and (@tip='PC' and (LEFT(@ctdeb,1)='7' OR LEFT(@ctdeb,1)='6' and @tipct='P') OR @tip='IC' and (LEFT(@ctcred,1)='6' or LEFT(@ctcred,1)='7' and @tipct='A'))
	begin
		set @ctt=@ctdeb
		set @ctdeb=@ctcred
		set @ctcred=@ctt
		set @sumam=-@sumam
		set @sumavaluta=-@sumavaluta
	end
	exec scriuPozincon @subunitate=@sub, @Tip_document='PI', @Numar_document=@ct, 
		@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@Sumam, 
		@Valuta=@valuta, @Curs=@curs, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
		@Utilizator=@userASiS, @Numar_pozitie=@nrpozitie, @Loc_de_munca=@lm, 
		@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
	--TVA
	if right(@tip,1)<>'D' and not (@tip='IC' and @tiptva=2)
		begin
		set @ctdeb=(case when @tip='IR' then @cttvaneex when @tip='IC' and @tiptva<>1 
			or @tip='IB' then @ct else @cttvaded end)
		set @ctcred=(case when @tip='PR' then @cttvaneex when @tip in ('IC','IB','IR') 
			or @tip='PC' and @tiptva=1 then @cttvacol else @ct end)
		set @Sumam=dbo.rot_val(@sumatva, 2)
		set @Sumavalutam=0 --dbo.rot_val(0, 2)
		set @explm=left(@tip+' '+RTRIM(@numar)+' '+(case when @valuta='' then '' else 
			RTRIM(@valuta)+' ' end)+(case when @fact='' then '' else 
			'fact. '+RTRIM(@fact)+' ' end)+@expl,50)
		exec scriuPozincon @subunitate=@sub, @Tip_document='PI', @Numar_document=@ct, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@Sumam, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=@nrpozitie, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end

	if @tip='PC' and (@tiptva=3 or @CtChTVANeded<>'' and @tiptva=2) and @sumatva<>0
		begin
		set @ctdeb=(case when @tiptva=3 then @ctcor else @ctChTVANeded end)
		set @ctcred=@cttvaded
		set @Sumam=dbo.rot_val(@sumatva, 2)
		set @Sumavalutam=0 --dbo.rot_val(0, 2)
		set @explm=left(@tip+' '+RTRIM(@numar)+' '+(case when @valuta='' then '' else 
			RTRIM(@valuta)+' ' end)+(case when @fact='' then '' else 
			'fact. '+RTRIM(@fact)+' ' end)+@expl,50)
		exec scriuPozincon @subunitate=@sub, @Tip_document='PI', @Numar_document=@ct, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@Sumam, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=@nrpozitie, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
	--TVA avans
	if (@tip='IB' or @tip='PF') and @ignor4428=0
		begin
		set @ctdeb=(case when @tip='IB' then @cttvaneex else @ctcor end)
		set @ctcred=(case when @tip='PF' then @cttvaneex else @ctcor end)
		set @Sumam=dbo.rot_val(@sumatva, 2)
		set @Sumavalutam=0 --dbo.rot_val(0, 2)
		set @explm=left(@tip+' '+RTRIM(@numar)+' '+(case when @valuta='' then '' else 
			RTRIM(@valuta)+' ' end)+(case when @fact='' then '' else 
			'fact. '+RTRIM(@fact)+' ' end)+@expl,50)
		exec scriuPozincon @subunitate=@sub, @Tip_document='PI', @Numar_document=@ct, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@Sumam, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=@nrpozitie, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
	--Dif. curs
	if not (@bugetari=1 and @ctdif<>'' and @tip='IB' and @sumadifcurs<>0) and @CtDif<>''
		begin
		set @ctdeb=(case when LEFT(@tip,1)='I' then (case when @sumadifcurs>0 then @Ct 
			else @CtDif end) else (case when @sumadifcurs>0 then @CtDif 
			when @invdifcursneg=1 then @ct else @ctcor end) end)
		set @ctcred=(case when LEFT(@tip,1)='I' then (case when @sumadifcurs>0 then @CtDif 
			when @invdifcursneg=1 then @ct else @ctcor end) else (case when @sumadifcurs>0 then @Ct 
			else @CtDif end) end)
		set @Sumam=dbo.rot_val((case when @sumadifcurs<0 then -1 else 1 end)*@sumadifcurs, 2)
		set @Sumavalutam=0 --dbo.rot_val(0, 2)
		set @explm=left(@tip+' '+RTRIM(@numar)+' '+(case when @valuta='' then '' else 
			RTRIM(@valuta)+' ' end)+(case when @fact='' then '' else 
			'fact. '+RTRIM(@fact)+' ' end)+@expl,50)
		exec scriuPozincon @subunitate=@sub, @Tip_document='PI', @Numar_document=@ct, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@Sumam, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavalutam, @Explicatii=@explm, 
			@Utilizator=@userASiS, @Numar_pozitie=@nrpozitie, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
		
	fetch next from tmpinregPI into @Sub, @Ct, @Data, @Numar, @Tip, @Tert, @Fact, 
		@Ctcor, @suma, @Valuta, @Curs, @sumavaluta, @tiptva, @cotatva, @sumatva, 
		@expl, @Lm, @Com, @Nrpozitie, @CtDif, @sumadifcurs, @AchitFact, 
		@Jurnal, @tipct--, @atrct, @atrctcor
	set @gfetch=@@fetch_status
	END
	
end
close tmpinregPI
deallocate tmpinregPI
end
