--***
create procedure inreg_pozitii_receptii 
@ttla bit,@ttlr bit,@nrzec int,@acc_imp_dvi bit,@inv_rul44 bit,@bugetari bit,
@ct_tva_ded varchar(40),@ct_tva_col varchar(40),@ct_tva_nx varchar(40),@ignor_4428_avans bit,@ignor_4428_docff bit,@nr_zec_nx int,
@sub char(9),@tip char(2),@numar varchar(20),@data datetime,@cod char(20),@gest char(9),@tip_gest char(1),
@cant float,@tva_nx int,@pret_valuta float,@pret_de_stoc float,@tip_nom char(1),@cont_nom varchar(40),@grupa_nom char(13),
@pret_vanzare float,@pret_am_pred float,@pret_amanunt float,@suma_TVA float,@acc_cump float,@acc_dat float,
@cont_de_stoc varchar(40),@atr_ct_stoc float,@tip_ct_stoc char(1),@cont_factura varchar(40),@cont_ven varchar(40),@cont_interm varchar(40),
@tert char(13),@factura char(20),@gest_prim varchar(40),@tip_misc char(1),@nr_dvi char(25),@grupa char(13),@den_tert char(30),@t_extern bit,
@valuta char(3),@curs float,@disc float,@proc_vama float,@supratx_vama float,@locm char(9),@comanda char(40),@jurnal char(3),
@gasit_dvi bit,@tert_cif char(13),@cont_cif varchar(40),@valuta_cif char(3),@curs_cif float,
@tert_vama char(13),@cont_vama varchar(40),@cont_fact_vama varchar(40),@cont_com_vama varchar(40),
@cont_vama_suprataxe varchar(40),@fact_comis char(20),@den_tert_vama char(30),@den_tert_cif char(30),@t_extern_cif bit,
@nr_poz_doc int output,
@utilizator char(10),@fara_com bit,@CtChTVANed varchar(40),@cotaTVA float,@taxe_vama float

as begin

declare @suma_lei_pozitie float,@suma_valuta_pozitie float,
@cont_deb varchar(40),@cont_cred varchar(40),@suma_poz float,@valuta_poz char(3),@curs_poz float,@suma_val_poz float,
@explic_poz char(50),@explic_excep char(50),@nr_pozitie int,@com_poz char(40) 

set @valuta_poz=(case when @t_extern=1 and @valuta<>'' then @valuta else '' end)
set @curs_poz=(case when @t_extern=1 and @valuta<>'' then @curs else 0 end)
set @explic_poz=(case when @tip='RS' and rtrim(@nr_dvi)+left(rtrim(@gest_prim),3) not in ('','378') then rtrim(@nr_dvi)+rtrim(@gest_prim) else @den_tert end)

set @suma_lei_pozitie=dbo.rot_val((case when @pret_valuta=0 then dbo.rot_val(@pret_de_stoc*@cant,@nrzec)-(@pret_vanzare+(case when @tip='RS' or @nr_dvi='' then 0 else @suma_tva end)+@supratx_vama)--+(case when @acc_imp_dvi=1 then @acc_cump else 0 end))+@acc_dat) 
	else dbo.rot_val((@pret_valuta-(case when @gasit_dvi=0 and (@ttla=1 or @ttlr=1) then @acc_cump else 0 end))*(1+(case when @tip='RS' or @nr_dvi='' then (case when abs(@disc+100*@cotaTVA/(100+@cotaTVA))<0.01 then -100*@cotaTVA/(100+@cotaTVA) else @disc end) else 0 end)/100.00)*(case when @valuta<>'' then @curs else 1 end),5)*@cant end),@nrzec)
set @suma_valuta_pozitie=dbo.rot_val((case when @t_extern=1 and @valuta<>'' then @pret_valuta*@cant*(1+@disc/100) else 0 end),2)
if not (@tip_nom='R' and (left(@cont_de_stoc,1)='7' or @inv_rul44=1 and left(@cont_de_stoc,2)='44' or left(@cont_de_stoc,1)='6' /*and @suma_lei_pozitie<0*/ and @tip_ct_stoc='P')) begin
	set @cont_deb=@cont_de_stoc
	set @cont_cred=@cont_factura
	set @com_poz=(case when /*@bugetari*/0=0 or @cont_interm<>'' or @tip_nom='R' or @tip='RS' then @comanda else '' end)
end
else begin
	set @cont_deb=@cont_factura
	set @cont_cred=@cont_de_stoc
	set @suma_lei_pozitie=(-1)*@suma_lei_pozitie
	set @suma_valuta_pozitie=(-1)*@suma_valuta_pozitie
	set @com_poz=@comanda
end
set @suma_poz=@suma_lei_pozitie
set @suma_val_poz=@suma_valuta_pozitie
exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,@valuta_poz,@curs_poz,@suma_val_poz,@explic_poz,@utilizator,@nr_poz_doc output,@locm,@com_poz,@jurnal,@gasit_dvi

if @tert_vama='' 
begin --TVA ded. sau neex. daca 408
	set @cont_deb=(case when @cont_ven='' then (case when left(@cont_factura,3)='408' then @ct_tva_nx else @ct_tva_ded end) else @cont_ven end)
	set @cont_cred=(case when @gasit_dvi=0 and dbo.rot_val(@proc_vama,0)=1 then @ct_tva_col else @cont_factura end)
	set @suma_poz=@suma_tva
	set @suma_val_poz=(case when @curs_poz>0 and @suma_tva<>0 and isnumeric(@grupa)=1 then dbo.rot_val(convert(float,@grupa),2) else 0 end)
	set @nr_pozitie=@nr_poz_doc+(case when @bugetari=1 and @cont_interm<>'' or @tip='RS' then 0 else 901 end)
	exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,@valuta_poz,@curs_poz,@suma_val_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
	
	if @CtChTVANed<>'' and @proc_vama in (2,3) begin -- inreg. cheltuiala TVA neded.
		set @cont_deb=@CtChTVANed
		set @cont_cred=(case when @cont_ven='' then (case when left(@cont_factura,3)='408' then @ct_tva_nx else @ct_tva_ded end) else @cont_ven end)
		set @nr_pozitie=@nr_poz_doc+(case when @bugetari=1 and @cont_interm<>'' or @tip='RS' then 0 else 914 end)
		exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,@valuta_poz,@curs_poz,@suma_val_poz,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
	end
end
if ((@ignor_4428_avans=0 and left(@cont_de_stoc,3)  in ('409','232') or @ignor_4428_docff=0 and left(@cont_de_stoc,3) in ('408','167')) and (@proc_vama<>1 or @gasit_dvi=1) and @atr_ct_stoc=1) 
begin --TVA in avans
	set @cont_deb=@cont_de_stoc
	set @cont_cred=@ct_tva_nx
	set @suma_poz=@suma_tva
	set @suma_val_poz=(case when @curs_poz>0 and @suma_tva>0 and isnumeric(@grupa)=1 then dbo.rot_val(@suma_tva/@curs,2) else 0 end)
	set @nr_pozitie=0
	exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,@valuta_poz,@curs_poz,@suma_val_poz,'',@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
end
if ((@gasit_dvi=0 or @acc_imp_dvi=0) and @tip_misc<>'V' and @tip_gest in ('A','V') and left(@cont_de_stoc,2) in ('37','35')) 
begin --not DVI sau DVOT
	--tva neex pe stoc
	set @cont_deb=@cont_de_stoc
	set @cont_cred=@cont_interm
	set @suma_poz=dbo.rot_val((case when left(@cont_de_stoc,1)='8' then 0 when @tip_gest in ('A','V') then @cant*dbo.rot_val(@pret_amanunt*@tva_nx/(100.00+@tva_nx),@nr_zec_nx) else 0 end),2)
	set @nr_pozitie=@nr_poz_doc+852
	exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
	--adaos pe stoc
	set @cont_cred=@gest_prim
	set @suma_poz=(case when left(@cont_de_stoc,1)='8' then 0 when @tip_gest in ('A','V') then dbo.rot_val(@cant*@pret_amanunt,2)-dbo.rot_val(@cant*@pret_de_stoc,2)-(case when @ttlr=1 and @tip_gest='A' then dbo.rot_val(@cant*@acc_cump,2) else 0 end)-dbo.rot_val(@cant*dbo.rot_val(@pret_amanunt*@tva_nx/(100.00+@tva_nx),@nr_zec_nx),2) else 0 end)
	set @nr_pozitie=@nr_poz_doc+873
	exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
end
if (@gasit_dvi=1) 
begin --DVI sau DVOT
	set @cont_deb=(case when @tip_nom='R' and left(@cont_nom,3)='371' and 1=0 then '378.'+RTrim(@grupa_nom)+'03' else @cont_de_stoc end)
	if (@cont_cif<>'') begin --single CIF
		set @cont_cred=@cont_cif
		set @suma_poz=dbo.rot_val(@pret_vanzare,2)
		set @explic_excep=RTrim(@den_tert_cif)+' DVI - C.I.F'
		set @valuta_poz=(case when @t_extern_cif=1 and @valuta_cif<>'' then @valuta_cif else '' end)
		set @curs_poz=(case when @t_extern_cif=1 and @valuta_cif<>'' then @curs_cif else 0 end)
		set @suma_val_poz=@pret_am_pred
		set @nr_pozitie=@nr_poz_doc+640
		exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,@valuta_poz,@curs_poz,@suma_val_poz,@explic_excep,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
		set @valuta_poz=(case when @t_extern=1 and @valuta<>'' then @valuta else '' end)
		set @curs_poz=(case when @t_extern=1 and @valuta<>'' then @curs else 0 end)
	end
	--inreg. pt. fact. (multi) CIF se fac in procedura de antet
	if /*@den_tert_vama<>'' and*/ @fact_comis in ('','D')
	begin
		--taxe vamale
		set @cont_deb=(case when @tip_nom='R' and left(@cont_nom,3)='371' and 1=0 then '378.'+RTrim(@grupa_nom)+'01' else @cont_de_stoc end)
		set @cont_cred=(case when @cont_vama<>'' then @cont_vama else @cont_fact_vama end)
		set @suma_poz=dbo.rot_val(@taxe_vama,2)
		set @explic_excep=RTrim(@den_tert_vama)+' DVI - taxe vamale'
		set @nr_pozitie=@nr_poz_doc+477
		exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_excep,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi 
		if @fara_com=0 
		begin 
			--comision vamal
			set @cont_deb=(case when @tip_nom='R' and left(@cont_nom,3)='371' and 1=0 then '378.'+RTrim(@grupa_nom)+'02' else @cont_de_stoc end)
			set @cont_cred=@cont_com_vama
			set @suma_poz=dbo.rot_val(@supratx_vama,2)
			set @explic_excep=RTrim(@den_tert_vama)+' DVI - comision vamal'
			set @nr_pozitie=@nr_poz_doc+560
			exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_excep,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
		
		end
		if @acc_imp_dvi=1 and @tert_vama<>''  and @cont_vama_suprataxe<>''
		begin --accize import dvi
			set @cont_deb=(case when @tip_nom='R' and left(@cont_nom,3)='371' and 1=0 then '378.'+RTrim(@grupa_nom)+'04' else @cont_de_stoc end)
			set @cont_cred=@cont_vama_suprataxe
			set @suma_poz=dbo.rot_val(@acc_cump,2)
			set @explic_excep=RTrim(@den_tert_vama)+' DVI - accize'
			set @nr_pozitie=@nr_poz_doc+70
			exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_excep,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
		end
	end 
end

if (@ttlr=1) 
begin --taxa timbru literar receptii
	set @cont_deb=@cont_de_stoc
	set @cont_cred=@grupa
	set @suma_poz=dbo.rot_val(@cant*@acc_cump,2)
	set @explic_excep='Timbru literar '+@tip+' '+@numar+' '+@gest+' '+@tert+' '+@factura
	set @nr_pozitie=@nr_poz_doc+1000
	exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_excep,@utilizator,@nr_pozitie,@locm,@comanda,@jurnal,@gasit_dvi
end

end
