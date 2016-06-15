--***
create procedure inregTEAmortizare @dataj datetime, @datas datetime, @nrdoc varchar(20)=''
as 
begin

declare @gfetch int,@gsub char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,@sub char(9),@Bugetari int,
@tip char(2),@numar varchar(20),@data datetime,@ctstoc varchar(40),@ctamortiz varchar(40),@valamortiz float,
@nrpozitie int,@lm char(9),@com char(40),@jurnal char(3),
@subunitate char(9),@glm char(9),@gcom char(40),@gjurnal char(3),@ctdeb varchar(40),@ctcred varchar(40),
@suma float,@expl char(50), @userASiS char(10), @sql nvarchar(max),@idPozdoc int,@indbug varchar(20)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

IF OBJECT_ID('tempdb..#inregTEamortizare') IS NOT NULL drop table #inregTEamortizare
create table #inregTEamortizare (subunitate varchar(9), tip varchar(2), numar varchar(13), data datetime, gestiune varchar(13), cont_de_stoc varchar(40), 
	cont_amortizare varchar(40), val_amortizata decimal(12,2), numar_pozitie int, loc_de_munca varchar(9), comanda varchar(20), jurnal varchar(3), idPozdoc int)

set @sql='insert into #inregTEamortizare 
		select p.Subunitate, p.Tip, p.Numar, p.Data, p.gestiune, p.Cont_de_stoc, isnull(p.detalii.value('+char(39)+'/row[1]/@contam'+char(39)+','+char(39)+'varchar(40)'+char(39)+'),''''),
		isnull(p.detalii.value('+char(39)+'/row[1]/@valam'+char(39)+','+char(39)+'decimal(12,2)'+char(39)+'),0),
		p.Numar_pozitie,p.Loc_de_munca,p.Comanda,p.Jurnal,p.idPozdoc
		FROM pozdoc p 
		WHERE p.subunitate=@subunitate and p.tip=''TE'' and p.subtip=''TR'' and p.data between @dataj and @datas 
			and (@nrdoc='''' or p.numar=@nrdoc) 
		and isnull(p.detalii.value('+char(39)+'/row[1]/@contam'+char(39)+','+char(39)+'varchar(40)'+char(39)+'),'''')<>'''''

if exists (select 1 from syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'pozdoc' AND sc.NAME = 'detalii')
	exec sp_executesql @statement=@sql, @params=N'@subunitate as varchar(9), @dataj datetime, @datas datetime, @nrdoc as varchar(13)', 
		@subunitate=@subunitate, @dataj=@dataj, @datas=@datas, @nrdoc=@nrdoc

declare tmpinregTEAmortizare cursor for
select Subunitate,Tip,Numar,Data,Cont_de_stoc,cont_amortizare,val_amortizata,
Numar_pozitie,Loc_de_munca,Comanda,Jurnal,idPozdoc
FROM #inregTEamortizare 
ORDER BY subunitate, tip, data, numar, gestiune

open tmpinregTEAmortizare
fetch next from tmpinregTEAmortizare into @Sub,@Tip,@Numar,@Data,
	@Ctstoc,@ctamortiz,@valamortiz,@Nrpozitie,@Lm,@Com,@Jurnal,@idPozdoc
		
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
		--Val. amortizata pt. obiecte de inventar returnate din gestiune de imobilizari
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

			set @ctdeb=@ctamortiz
			set @ctcred=@ctstoc
			set @suma=dbo.rot_val(@valamortiz, 2)
			set @expl='Stornare amortizare'
			exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
				@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
				@Valuta='', @Curs=0, @Suma_valuta=0, @Explicatii=@expl, 
				@Utilizator=@userASiS, @Numar_pozitie=0, @Loc_de_munca=@lm, 
				@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0, @indbug=@indbug
		end
	
		fetch next from tmpinregTEAmortizare into @Sub,@Tip,@Numar,@Data,
			@Ctstoc,@ctamortiz,@valamortiz,@Nrpozitie,@Lm,@Com,@Jurnal,@idPozdoc
		set @gfetch=@@fetch_status
	END
	
end
close tmpinregTEAmortizare
deallocate tmpinregTEAmortizare
end
