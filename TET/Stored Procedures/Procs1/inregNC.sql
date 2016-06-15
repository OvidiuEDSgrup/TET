--***
create procedure inregNC @dataj datetime, @datas datetime, @tipdoc char(2)='NC', @nrdoc char(13)=''
as 

declare @subunitate char(9),@gfetch int,@gsub char(9),@gtip char(2),@gnumar char(13),
@gdata datetime,@glm char(9),@gcom char(40),@gjurnal char(3),
@sub char(9),@tip char(2),@numar char(13),@data datetime,@tert char(13),
@valuta char(3),@curs float,@lm char(9),@com char(40),@jurnal char(3),
@ctdeb varchar(40),@ctcred varchar(40),@suma float,@sumavaluta float,@expl char(50),@nrpozitie int,
@userASiS char(10)

exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
set @userASiS = isnull(dbo.fIaUtilizator(null),'')

delete from pozincon where subunitate=@subunitate 
	and (isnull(@tipdoc,'')='' and tip_document in ('IC','MA','ME','MI','MM','NC','DP','AL','AO','PS','UA') or Tip_document=@tipdoc) 
	and numar_document between RTRIM(@nrdoc) and RTRIM(@nrdoc)+(case when @nrdoc<>'' then '' else 'zzzzzzzzzzzzz' end) 
	and data between @dataj and @datas 

if isnull(@tipdoc,'') in ('PS','MA','IC') -- nota de salarii sau nota de amortizare se adauga in intregime. Am adaugat si notele de inchidere - optimizare pentru inchidere conturi.
	insert into pozincon
		(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, 
		Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
		Loc_de_munca, Comanda, Jurnal) 
		select Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, 
		Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Nr_pozitie, 
		Loc_munca, Comanda, Jurnal 
		from pozncon
		WHERE subunitate=@subunitate and data between @dataj and @datas 
			and (@nrdoc='' or tip=@tipdoc) and (@nrdoc='' or numar=@nrdoc) 
else
begin
declare tmpinregNC cursor for
select Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, 
Valuta, Curs, Suma_valuta, Explicatii, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal
FROM pozncon p 
WHERE p.subunitate=@subunitate and p.Tip<>'RM' and p.data between @dataj and @datas 
	and (@nrdoc='' or p.tip=@tipdoc) and (@nrdoc='' or p.numar=@nrdoc) 
ORDER BY p.subunitate, p.tip, p.data, p.numar

open tmpinregNC
fetch next from tmpinregNC into @sub,@tip,@numar,@data,@ctdeb,@ctcred,@suma,
		@Valuta,@Curs,@sumavaluta,@expl,@nrpozitie,@lm,@com,@tert,@jurnal
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
		/*set @suma=dbo.rot_val(@suma, 2)
		set @sumavaluta=dbo.rot_val(@sumavaluta, 2)*/
		exec scriuPozincon @subunitate=@sub, @Tip_document=@tip, @Numar_document=@numar, 
			@Data=@data, @Cont_debitor=@ctdeb, @Cont_creditor=@ctcred, @Suma=@suma, 
			@Valuta=@Valuta, @Curs=@Curs, @Suma_valuta=@Sumavaluta, @Explicatii=@expl, 
			@Utilizator=@userASiS, @Numar_pozitie=@nrpozitie, @Loc_de_munca=@lm, 
			@Comanda=@com, @Jurnal=@Jurnal, @note_receptii=0
		end
				
	fetch next from tmpinregNC into @sub,@tip,@numar,@data,@ctdeb,@ctcred,@suma,
		@Valuta,@Curs,@sumavaluta,@expl,@nrpozitie,@lm,@com,@tert,@jurnal
	set @gfetch=@@fetch_status
	END
	
end
close tmpinregNC
deallocate tmpinregNC
end
--	apelare procedura specifica
if exists (select * from sysobjects where name ='inregNCSP')
	exec inregNCSP @dataj=@dataj, @datas=@datas, @tipdoc=@tipdoc, @nrdoc=@nrdoc
