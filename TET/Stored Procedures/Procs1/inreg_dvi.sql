--***
create procedure inreg_dvi @sub char(9), @tip char(2), @numar varchar(20), @data datetime, @gasit_dvi bit, 
@ct_deb_tva_vama varchar(40), @nr_poz_doc int, @locm char(9), @comanda char(40), @jurnal char(3), @utilizator char(10) 
as begin

declare @gfetch int, @tert_cif char(13), @cont_cif varchar(40),
@tva_cif float,
@tert_vama char(13), @cont_vama varchar(40), @cont_tert_vama varchar(40), @cont_com_vama varchar(40), @cont_fact_tva varchar(40),
@suma_vama float, @dif_vama float, @suma_com_vama float, @dif_com_vama float, @val_accize_import float, @dif_accize_vama char(13),
@tva_ded_vama float, @cont_suprataxe varchar(40), @suma_suprataxe float, @cont_vama_suprataxe varchar(40),
@fact_comis char(20), @tip_tva_dvi float, @den_tert_vama char(30), @den_tert_cif char(30), 
@cont_deb varchar(40), @cont_cred varchar(40), @suma_poz float, @explic_poz char(50), @nr_pozitie int, 
@ct_tva_ded varchar(40), @ct_tva_col varchar(40), @cu_ct_fact_vama_DVI bit, @sp_ELCOND bit, @acc_imp_dvi bit, @fara_com bit, 
@CtChTVANed varchar(40)

exec luare_date_par 'GE','CDTVA',0,0,@ct_tva_ded output
exec luare_date_par 'GE','CCTVA',0,0,@ct_tva_col output
exec luare_date_par 'GE','CONTFV', @cu_ct_fact_vama_DVI output, 0, ''
exec luare_date_par 'GE','ELCOND', @sp_ELCOND output, 0, ''
exec luare_date_par 'GE','ACCIMP',@acc_imp_dvi output,0,''
exec luare_date_par 'GE','FARACOMV',@fara_com output,0,''
exec luare_date_par 'GE','CCTVANED', 0, 0, @CtChTVANed output

 select top 1 
 @tert_cif=b.tert_cif, @cont_cif=b.cont_cif, @tva_cif=b.tva_cif, @tert_vama=b.tert_vama, @cont_vama=b.cont_vama, @cont_tert_vama=b.cont_tert_vama, @cont_com_vama=b.cont_com_vam, 
 @cont_fact_tva=b.cont_factura_tva, @suma_vama=b.suma_vama, @dif_vama=b.dif_vama, @suma_com_vama=b.suma_com_vam, @dif_com_vama=b.dif_com_vam, @val_accize_import=b.valoare_accize, 
 @dif_accize_vama=b.tva_11, @tva_ded_vama=b.tva_22, @cont_suprataxe=b.cont_suprataxe, @suma_suprataxe=b.suma_suprataxe, @cont_vama_suprataxe=b.cont_vama_suprataxe, @fact_comis=b.factura_comis, 
 @tip_tva_dvi=b.total_vama, @den_tert_vama=isnull(t2.denumire, ''), @den_tert_cif=isnull(t3.denumire, '') 
 from dvi b 
 left outer join terti t2 on t2.subunitate=b.subunitate and t2.tert=isnull(b.tert_vama, '')
 left outer join terti t3 on t3.subunitate=b.subunitate and t3.tert=isnull(b.tert_cif, '')
 where b.subunitate=@sub and b.numar_receptie=@numar and b.data_DVI=@data


 if (@cont_cif<>'') begin --TVA CIF
  set @cont_deb=@ct_tva_ded
  set @cont_cred=@cont_cif
  set @suma_poz=dbo.rot_val(@tva_cif, 2)
  set @explic_poz=RTrim(@den_tert_cif)+' DVI - C.I.F.'
  set @nr_pozitie=@nr_poz_doc+80
  exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
 end
 if (@fact_comis in ('', 'D')) begin 
  --tva (ded) vama
  set @cont_deb=@ct_deb_tva_vama
  set @cont_cred=(case when dbo.rot_val(@tip_tva_dvi,0)=1 then @ct_tva_col when @cont_fact_tva<>'' then @cont_fact_tva else @cont_tert_vama end)
  set @suma_poz=dbo.rot_val(@tva_ded_vama, 2)
  set @explic_poz=RTrim(@den_tert_vama)+' DVI - TVA vama'
  set @nr_pozitie=@nr_poz_doc+10
  exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
  --chelt. tva neded. vama
  if @CtChTVANed<>'' and @tip_tva_dvi=2 begin
   set @cont_deb=@CtChTVANed
   set @cont_cred=@ct_deb_tva_vama
   set @explic_poz=RTrim(@den_tert_vama)+' DVI - chelt. TVA vama'
   set @nr_pozitie=@nr_poz_doc+14
   exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
  end
  if (@cont_fact_tva<>'' and @cont_tert_vama<>'' /*and @cu_ct_fact_vama_DVI=1*/ and  @cont_fact_tva<>@cont_tert_vama and dbo.rot_val(@tip_tva_dvi, 0)<>1) begin
   set @cont_deb=@cont_fact_tva
   set @cont_cred=@cont_tert_vama
   set @suma_poz=dbo.rot_val(@tva_ded_vama, 2)
   set @explic_poz=RTrim(@den_tert_vama)+' DVI - TVA vama'
   set @nr_pozitie=@nr_poz_doc+814
   exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
  end
  if @cont_vama<>'' and @cont_tert_vama<>'' and /*(@cu_ct_fact_vama_DVI=1 or*/ @cont_vama<>@cont_tert_vama begin
   --taxe vamale credit
   set @cont_deb=@cont_vama
   set @cont_cred=@cont_tert_vama
   set @suma_poz=dbo.rot_val(@suma_vama+@dif_vama, 2)
   set @explic_poz=RTrim(@den_tert_vama)+' DVI - taxe vamale'
   set @nr_pozitie=@nr_poz_doc+90
   exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
   if @fara_com=0 /*and @cu_ct_fact_vama_DVI=1*/ and @cont_com_vama<>@cont_tert_vama begin
    --comision vamal credit
    set @cont_deb=@cont_com_vama
    set @cont_cred=@cont_tert_vama
    set @suma_poz=dbo.rot_val(@suma_com_vama+@dif_com_vama, 2)
    set @explic_poz=RTrim(@den_tert_vama)+' DVI - comision vamal'
    set @nr_pozitie=@nr_poz_doc+100
    exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
   end
   if (@acc_imp_dvi=1 and @sp_ELCOND=0) begin
    --accize credit
    set @cont_deb=@cont_vama_suprataxe
    set @cont_cred=@cont_tert_vama
    set @suma_poz=dbo.rot_val(@val_accize_import+@dif_accize_vama, 2)
    set @explic_poz=RTrim(@den_tert_vama)+' DVI - accize'
    set @nr_pozitie=@nr_poz_doc+111
    exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
   end
  end
  --suprataxe vamale
  set @cont_deb=@cont_suprataxe
  set @cont_cred=@cont_vama_suprataxe
  set @suma_poz=dbo.rot_val(@suma_suprataxe, 2)
  set @explic_poz=RTrim(@den_tert_vama)+' DVI - suprataxe vamale'
  set @nr_pozitie=@nr_poz_doc+212
  exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
  if (@cu_ct_fact_vama_DVI=1 and @cont_tert_vama<>'') begin
   set @cont_deb=@cont_vama_suprataxe
   set @cont_cred=@cont_tert_vama
   set @suma_poz=dbo.rot_val(@suma_suprataxe, 2)
   set @explic_poz=RTrim(@den_tert_vama)+' DVI - suprataxe vamale'
   set @nr_pozitie=@nr_poz_doc+313
   exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
  end
 end
end
