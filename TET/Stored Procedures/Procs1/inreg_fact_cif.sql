--***
create procedure inreg_fact_cif @sub char(9), @tip char(2), @numar varchar(20), @data datetime, @pt_TVA bit, 
@ct_deb_netva varchar(40), @pret_vanzare_doc float, @total_cif float, @locm char(9), @comanda char(40), @jurnal char(3), 
@utilizator char(10), @gasit_DVI bit, @nr_poz_doc int, @nr_poz_RQ int output 
as begin 
 
declare @cont_factura varchar(40), @pret_valuta float, @valuta char(3), @curs float, @pret_de_stoc float, @suma_tva float, 
 @cont_ven varchar(40), @den_tert char(30), @t_extern bit, 
 @gfetch int, @suma_poz float, @valuta_poz char(3), @curs_poz float, @suma_val_poz float, 
 @explic_poz char(50), @nr_pozitie int 

declare tmpcif cursor for 
 select p.cont_factura, p.pret_valuta, p.valuta, p.curs, p.pret_de_stoc, p.tva_deductibil, 
  p.cont_venituri, isnull(t.denumire, '') as den_tert, isnull(t.tert_extern, 0) as tert_extern 
 from pozdoc p left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
 where p.subunitate=@sub and p.tip='RQ' and p.numar=@numar and p.data=@data 
open tmpcif 
fetch next from tmpcif into @cont_factura, @pret_valuta, @valuta, @curs, @pret_de_stoc, @suma_tva, @cont_ven, @den_tert, @t_extern 
set @gfetch=@@fetch_status 
while @gfetch=0 begin 
 set @nr_poz_RQ = @nr_poz_RQ + 1 
 if @pt_TVA = 0 begin 
  set @suma_poz = dbo.rot_val(@pret_vanzare_doc * @pret_de_stoc / @total_cif, 2) 
  set @explic_poz = RTrim(@den_tert) + ' - DVI C.I.F.' 
  set @valuta_poz = (case when @t_extern=1 and @valuta<>'' then @valuta else '' end) 
  set @curs_poz = (case when @t_extern=1 and @valuta<>'' then @curs else '' end) 
  set @suma_val_poz = dbo.rot_val(@pret_vanzare_doc * @pret_valuta / @total_cif, 2) 
  set @nr_pozitie = @nr_poz_doc + 400 + @nr_poz_RQ 
  exec scriuPozincon @sub,@tip,@numar,@data,@ct_deb_netva,@cont_factura,@suma_poz,@valuta_poz,@curs_poz,@suma_val_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
 end 
 else begin 
  set @explic_poz = RTrim(@den_tert) + ' - TVA C.I.F.' 
  set @nr_pozitie = @nr_poz_doc + 450 + @nr_poz_RQ 
  exec scriuPozincon @sub,@tip,@numar,@data,@cont_ven,@cont_factura,@suma_tva,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
 end 
 
 fetch next from tmpcif into @cont_factura, @pret_valuta, @valuta, @curs, @pret_de_stoc, @suma_tva, @cont_ven, @den_tert, @t_extern 
 set @gfetch=@@fetch_status 
end 

close tmpcif 
deallocate tmpcif 
end 
