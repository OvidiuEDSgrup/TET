--***
create procedure inregPP @dataj datetime, @datas datetime, @nrdoc varchar(20)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,@sub char(9),
@tip char(2),@numar varchar(20),@data datetime,@gest char(9),@tipgest char(1),@ctgest varchar(40),
@cant float,@pretstoc float,@grupanom char(13),@dennom char(80),
@ctstoc varchar(40),@ctcor varchar(40),--@atr_ct_stoc float,@tip_ct_stoc char(1),@cont_factura varchar(40),
@ctinterm varchar(40),--@tert char(13),@factura char(20),
@gestprim char(13),@dvi char(25),--@den_tert char(30),@t_extern int,
@valuta char(3),@curs float,--@disc float,@proc_vama float,
@lm char(9),@com char(40),@jurnal char(3),
@valpretstoc float,@valpretam float,@tvanxpretam float,@valpretampred float,@tvanxpred float,
@supratxvama float,@acccump float,@accdat float,
@subunitate char(9),@rottvanx int, @nrzectvanx int, @accprod int, @adtvanxavc int, 
@adtvanxava int, @ctadaos varchar(40), @angestctadaos int, @angrctadaos int, 
@cttvanx varchar(40), @angestcttvanx int, @ttla int,
@glm char(9),@gcom char(40),@gjurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@suma float,@sumavaluta float,@expl char(50),@userASiS char(10)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate and tip_document='PP' and numar_document 
	between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas

declare tmpinregPP cursor for
select p.subunitate, p.tip, p.data, p.numar, p.gestiune, isnull(g.tip_gestiune, '') 
as tip_gestiune, isnull(g.cont_contabil_specific, '') as cont_specific, 
p.cont_de_stoc, p.cont_corespondent, p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, 
p.loc_de_munca, p.comanda, n.grupa, p.jurnal, 
p.valuta, p.curs, p.cantitate, p.pret_de_stoc, isnull(n.denumire,'')
FROM pozdoc p 
left outer join gestiuni g on p.subunitate = g.subunitate and p.gestiune = g.cod_gestiune 
left outer join nomencl n on p.cod = n.cod 
--left outer join terti t on p.subunitate = t.subunitate and p.tert = t.tert 
left outer join conturi c on p.subunitate = c.subunitate and p.cont_de_stoc = c.cont 
WHERE p.subunitate=@subunitate and p.tip='PP' and p.data between @dataj and @datas 
and (@nrdoc='' or p.numar=@nrdoc) 
/*GROUP BY p.subunitate, p.tip, p.data, p.numar, p.gestiune, p.cont_de_stoc, p.cont_corespondent, 
p.cont_intermediar, p.gestiune_primitoare, p.numar_DVI, p.loc_de_munca, p.comanda, n.grupa, 
p.jurnal*/ 
ORDER BY p.subunitate, p.tip, p.data, p.numar, p.gestiune

open tmpinregPP
fetch next from tmpinregPP into @sub,@tip,@data,@numar,@gest,@tipgest,@ctgest,@ctstoc,
		@ctcor,@ctinterm,@gestprim,@dvi,@lm,@com,@grupanom,@jurnal,
		--@valpretstoc,@valpretam,@tvanxpretam,@valpretampred,@tvanxpred,@supratxvama,@acccump,
		@Valuta,@Curs,@cant,@pretstoc,@dennom
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
		set @ctdeb=@ctstoc
		set @ctcred=@ctcor
		set @suma=dbo.rot_val(@pretstoc*@cant, 2)
		set @sumavaluta=0 --dbo.rot_val(0, 2)
		set @expl=Left(@dennom,50)
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta='', @Curs=0, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		END
				
	fetch next from tmpinregPP into @sub,@tip,@data,@numar,@gest,@tipgest,@ctgest,@ctstoc,
		@ctcor,@ctinterm,@gestprim,@dvi,@lm,@com,@grupanom,@jurnal,
		--@valpretstoc,@valpretam,@tvanxpretam,@valpretampred,@tvanxpred,@supratxvama,@acccump,
		@Valuta,@Curs,@cant,@pretstoc,@dennom
	set @gfetch=@@fetch_status
	end
	
end
close tmpinregPP
deallocate tmpinregPP
end
