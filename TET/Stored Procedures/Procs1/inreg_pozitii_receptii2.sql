--***
create procedure inreg_pozitii_receptii2
@sub char(9), @tip char(2), @numar varchar(20), @data datetime, @tip_nom char(1), @barcod char(30), @cant float, @acc_cump float, 
@gest_prim varchar(40), @cont_interm varchar(40), @acc_dat float, @locm char(9), @comanda char(40), @jurnal char(3), @nr_poz_doc int output, @utilizator char(10), @gasit_dvi bit

as begin

declare @cont_deb varchar(40), @cont_cred varchar(40), @suma_poz float, @explic_poz char(50)

if @tip_nom='F' and left(@barcod, 1)='8' and abs(@acc_cump)>=0.01 and @jurnal='MFX' begin
	set @cont_deb=left(@barcod, 13)
	set @cont_cred=''
	set @suma_poz=dbo.rot_val(@cant*@acc_cump, 2)
	set @explic_poz='Amortizare af. grd. neutilizare'
	exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_poz_doc output,@locm,@comanda,@jurnal,@gasit_dvi
end
if @tip_nom='F' and abs(@acc_dat)>=0.01 and @jurnal='MFX' begin
	set @cont_deb=@gest_prim
	set @cont_cred=@cont_interm
	set @suma_poz=dbo.rot_val(@cant*@acc_dat, 2)
	set @explic_poz='Val. amortizata'
	exec scriuPozincon @sub,@tip,@numar,@data,@cont_deb,@cont_cred,@suma_poz,'',0,0,@explic_poz,@utilizator,@nr_poz_doc output,@locm,@comanda,@jurnal,@gasit_dvi
end
end
