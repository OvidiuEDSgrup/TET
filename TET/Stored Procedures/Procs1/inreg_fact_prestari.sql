--***
create procedure inreg_fact_prestari @sub char(9), @tip char(2), @numar varchar(20), @data datetime, @pt_TVA bit, 
@ct_stoc_doc varchar(40), @acc_cump_doc float, @acc_dat_doc float, 
@total_prestari float, @total_asycuda float, @locm char(9), @comanda char(40), @jurnal char(3), 
@utilizator char(10), @gasit_DVI bit, @nr_poz_doc int, @nr_poz_RP int output 
as begin 
	
declare @tip_prestare char(2), @cont_factura varchar(40), @pret_valuta float, @suma_tva float, @supratx_vama float, 
	@cont_interm varchar(40), @cont_ven varchar(40), @proc_vama float, @den_tert char(30), @tert_extern int, @valuta char(3), @curs float, @suma_valuta float, @tva_valuta float, 
	@gfetch int, @ct_cred_poz varchar(40), @suma_poz float, @suma_valuta_poz float, @suma_tva_valuta_poz float, @explic_poz char(50), @nr_pozitie int, @note_receptii bit
declare @ct_tva_col varchar(40), @CtChTVANed varchar(40), @sp_ELCOND bit 

set @note_receptii = (case when @gasit_DVI=1 or 1=1 then 1 else 0 end)

exec luare_date_par 'GE', 'CCTVA', 0, 0, @ct_tva_col output
exec luare_date_par 'GE', 'CCTVANED', 0, 0, @CtChTVANed output
exec luare_date_par 'GE', 'ELCOND', @sp_ELCOND output, 0, ''

declare tmpprest cursor for 
	select p.tip, p.cont_factura, p.pret_valuta, p.tva_deductibil, p.suprataxe_vama, p.cont_intermediar, 
	p.cont_venituri, p.procent_vama, isnull(t.denumire, '') as den_tert, isnull(t.tert_extern, 0) as tert_extern,
	p.valuta, p.curs, p.pret_de_stoc, (case when p.valuta<>'' and isnumeric(p.grupa)=1 then convert(float, p.grupa) else 0 end)
	from pozdoc p left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
	where p.subunitate=@sub and p.tip in ('RP', 'RZ') and p.numar=@numar and p.data=@data and p.gestiune_primitoare='' 
open tmpprest 
fetch next from tmpprest into @tip_prestare, @cont_factura, @pret_valuta, @suma_tva, @supratx_vama, @cont_interm, @cont_ven, @proc_vama, @den_tert, @tert_extern, @valuta, @curs, @suma_valuta, @tva_valuta
set @gfetch=@@fetch_status 
while @gfetch=0 begin 
	set @nr_poz_RP = @nr_poz_RP + 1 
	if @pt_TVA = 0 begin 
		if abs(@total_prestari)<0.01 set @suma_poz=0
		else set @suma_poz = dbo.rot_val(@acc_dat_doc*@pret_valuta/@total_prestari - (case when @sp_ELCOND=1 and @total_asycuda<>0 then @acc_cump_doc*@supratx_vama/@total_asycuda else 0 end), 2) 
		if @valuta<>'' and @curs<>0 and @tert_extern=1
			set @suma_valuta_poz = dbo.rot_val(@suma_poz/@curs, 2)
		else begin
			set @suma_valuta_poz = 0
			set @valuta = ''
			set @curs = 0
		end
		set @explic_poz = (case when @tip_prestare='RZ' then 'Prestari proprii' else RTrim(@den_tert) + ' prestator' end)
		set @nr_pozitie = @nr_poz_doc + 200 + @nr_poz_RP 
		exec scriuPozincon @sub,@tip,@numar,@data,@ct_stoc_doc,@cont_factura,@suma_poz,@valuta,@curs,@suma_valuta_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@note_receptii
		if (@sp_ELCOND=1) begin
			if abs(@total_asycuda)<0.01 set @suma_poz=0
			else set @suma_poz = (case when @total_asycuda<>0 then dbo.rot_val(@acc_cump_doc*@supratx_vama/@total_asycuda, 2) else 0 end)
			if @valuta<>'' and @curs<>0 and @tert_extern=1
				set @suma_valuta_poz = dbo.rot_val(@suma_poz/@curs, 2)
			else begin
				set @suma_valuta_poz = 0
				set @valuta = ''
				set @curs = 0
			end
			set @explic_poz = RTrim(@den_tert) + ' asycuda' 
			set @nr_pozitie = @nr_poz_doc + 250 + @nr_poz_RP 
			exec scriuPozincon @sub,@tip,@numar,@data,@ct_stoc_doc,@cont_interm,@suma_poz,@valuta,@curs,@suma_valuta_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@note_receptii
		end
	end 
	else begin 
		if @valuta<>'' and @curs<>0 and @tert_extern=1
			set @suma_tva_valuta_poz = @tva_valuta
		else begin
			set @suma_tva_valuta_poz = 0
			set @valuta = ''
			set @curs = 0
		end
		set @ct_cred_poz = (case when dbo.rot_val(@proc_vama,0)=1 then @ct_tva_col else @cont_factura end)
		set @explic_poz = RTrim(@den_tert) + ' TVA prestator' 
		set @nr_pozitie = @nr_poz_doc + 300 + @nr_poz_RP 
		exec scriuPozincon @sub,@tip,@numar,@data,@cont_ven,@ct_cred_poz,@suma_tva,@valuta,@curs,@suma_tva_valuta_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@note_receptii
		if @proc_vama=2 and @CtChTVANed<>'' begin
			--cheltuieli TVA nedeductibil
			set @explic_poz = RTrim(@den_tert) + ' chelt. TVA prestator' 
			set @nr_pozitie = @nr_poz_doc + 305 + @nr_poz_RP 
			exec scriuPozincon @sub,@tip,@numar,@data,@CtChTVANed,@cont_ven,@suma_tva,@valuta,@curs,@suma_tva_valuta_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@note_receptii
		end
		if (@sp_ELCOND=1) begin
			if @valuta<>'' and @curs<>0 and @tert_extern=1
				set @suma_tva_valuta_poz = dbo.rot_val(@supratx_vama/@curs, 2)
			else begin
				set @suma_tva_valuta_poz = 0
				set @valuta = ''
				set @curs = 0
			end
			set @explic_poz = RTrim(@den_tert) + ' asycuda' 
			set @nr_pozitie = @nr_poz_doc + 350 + @nr_poz_RP 
			exec scriuPozincon @sub,@tip,@numar,@data,@cont_interm,@cont_factura,@supratx_vama,@valuta,@curs,@suma_tva_valuta_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@note_receptii
		end
	end 
	
	fetch next from tmpprest into @tip_prestare, @cont_factura, @pret_valuta, @suma_tva, @supratx_vama, @cont_interm, @cont_ven, @proc_vama, @den_tert, @tert_extern, @valuta, @curs, @suma_valuta, @tva_valuta
	set @gfetch=@@fetch_status 
end 

close tmpprest 
deallocate tmpprest 
end 
