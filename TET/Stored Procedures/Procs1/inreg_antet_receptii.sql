--***
create procedure inreg_antet_receptii @nr_document varchar(20),@dataj datetime,@datas datetime
as 
begin

declare @gfetch int,@gsb char(9),@gtip char(2),@gnumar varchar(20),@gdata datetime,
@sb char(9),@tip char(2),@numar varchar(20),@data datetime,@cod char(20),@gest char(9),@tip_gest char(1),
@cant float,@tva_nx int,@pret_valuta float,@pret_de_stoc float,@tip_nom char(1),@cont_nom varchar(40),@grupa_nom char(13),
@pret_vanzare float,@pret_am_pred float,@pret_amanunt float,@suma_TVA float,@acc_cump float,@acc_dat float,
@cont_de_stoc varchar(40),@atr_ct_stoc float,@tip_ct_stoc char(1),@cont_factura varchar(40),@cont_ven varchar(40),@cont_interm varchar(40),
@tert char(13),@factura char(20),@gest_prim varchar(40),@tip_misc char(1),@nr_dvi char(25),@grupa char(13),@den_tert char(30),@t_extern bit,
@valuta char(3),@curs float,@disc float,@proc_vama float,@supratx_vama float,@locm char(9),@comanda char(40),@jurnal char(3),
@gasit_dvi bit,@tert_cif char(13),@cont_cif varchar(40),@valuta_cif char(3),@curs_cif float,
@tert_vama char(13),@cont_vama varchar(40),@cont_fact_vama varchar(40),@cont_com_vama varchar(40),
@cont_vama_suprataxe varchar(40),@fact_comis char(40),@den_tert_vama char(30),@den_tert_cif char(30),@t_extern_cif bit,@fara_com bit,
@Sub char(9),@ttla bit,@ttlr bit,@rotvalrec bit,@nrzec int,@acc_imp_dvi bit,@inv_rul44 bit,@bugetari bit,
@Ct4426 varchar(40),@Ct4427 varchar(40),@Ct4428 varchar(40),@ignor_4428_avans bit,@ignor_4428_docff bit,@nr_zec_nx int,@lScriuDif bit,@CtChTVANed varchar(40),--@TVAnedStoc int, 
@tot_val_prestare float,@tot_val_asycuda float,@tot_suma_cif float,@tot_valuta_cif float,
@nr_poz_doc int,@nr_poz_RQ int,@nr_poz_RP int,@cont_deb varchar(40),
@g_DVI bit,@gct_deb_tva_vama varchar(40),@glocm char(9),@gcom char(40),@gjurnal char(3),
@gct_stoc varchar(40),@gacc_cump float,@gacc_dat float,@gct_deb_cif_netva varchar(40),@gpret_vanz float,@gct_cif varchar(40),
@barcod char(30),@cotaTVA float,@utilizator char(10), @taxe_vama float

exec luare_date_par 'GE','SUBPRO',0,0,@Sub output
exec luare_date_par 'GE','TIMBRULIT',@ttla output,0,''
exec luare_date_par 'GE','TIMBRULT2',@ttlr output,0,''
exec luare_date_par 'GE','ROTUNJR',@rotvalrec output,@nrzec output,''
if @rotvalrec=0 set @nrzec=2
exec luare_date_par 'GE','ACCIMP',@acc_imp_dvi output,0,''
exec luare_date_par 'GE','INV44',@inv_rul44 output,0,''
exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
exec luare_date_par 'GE','CDTVA',0,0,@Ct4426 output
exec luare_date_par 'GE','CCTVA',0,0,@Ct4427 output
exec luare_date_par 'GE','CNEEXREC',0,0,@Ct4428 output
exec luare_date_par 'GE','NEEXAV',@ignor_4428_avans output,0,''
exec luare_date_par 'GE','NEEXDOCFF',@ignor_4428_docff output,0,''
exec luare_date_par 'GE','ROTUNJTNX',0,@nr_zec_nx output,''
exec luare_date_par 'GE','FARACOMV',@fara_com output,0,''
exec luare_date_par 'GE','GENDIFRM',@lScriuDif output,0,''
exec luare_date_par 'GE','CCTVANED',0,0,@CtChTVANed output
--exec luare_date_par 'GE','TVANEDST',@TVAnedStoc output,0,''
set @utilizator = isnull(dbo.fIaUtilizator(null),'')

delete from pozncon where subunitate=@sub and tip in ('RM','RS') and numar between 
	RTRIM(@nr_document) and RTRIM(@nr_document)+(case when @nr_document<>'' then '' else 'zzzzzzzzzzzzz' end)
	and data between @dataj and @datas
delete from pozincon where subunitate=@sub and tip_document in ('RM','RS') and numar_document between 
	RTRIM(@nr_document) and RTRIM(@nr_document)+(case when @nr_document<>'' then '' else 'zzzzzzzzzzzzz' end)
	and data between @dataj and @datas 

declare tmprec cursor for
	select p.subunitate,p.tip,p.numar,p.data,p.cod,p.gestiune,isnull(g.tip_gestiune,'') as tip_gest,
	p.cantitate,p.TVA_neexigibil,p.pret_valuta,p.pret_de_stoc,
	isnull(n.tip,'') as tip_nom,isnull(n.cont,'') as cont_nom,isnull(n.grupa,'') as grupa_nom,
	p.pret_vanzare,p.pret_amanunt_predator,p.pret_cu_amanuntul,p.TVA_deductibil,p.accize_cumparare,p.accize_datorate,
	p.cont_de_stoc,isnull(c1.sold_credit,0) as atrib_ct_stoc,isnull(c1.tip_cont,'') as tip_ct_stoc,p.cont_factura,p.cont_venituri,p.cont_intermediar,
	p.tert,p.factura,p.gestiune_primitoare,p.tip_miscare,p.numar_dvi,p.grupa,isnull(t1.denumire,'') as den_tert,isnull(t1.tert_extern,0) as tert_extern,
	p.valuta,p.curs,p.discount,p.procent_vama,p.suprataxe_vama,p.loc_de_munca,p.comanda,p.jurnal,
	(case when b.numar_DVI is null then 0 else 1 end) as gasit_DVI,
	isnull(b.tert_cif,'') as tert_cif,isnull(b.cont_cif,'') as cont_cif,isnull(b.valuta_cif,'') as valuta_cif,isnull(b.curs,0) as curs_cif,
	isnull(b.tert_vama,'') as tert_vama,isnull(b.cont_vama,'') as cont_vama,isnull(b.cont_tert_vama,'') as cont_factura_vama,
	isnull(b.cont_com_vam,'') as cont_comision_vama,isnull(b.cont_vama_suprataxe,'') as cont_vama_suprataxe,isnull(b.factura_comis,'') as factura_comis,
	isnull(t2.denumire,'') as den_tert_vama,isnull(t3.denumire,'') as den_tert_cif,isnull(t3.tert_extern,0) as tert_extern_cif,p.barcod,p.cota_TVA,isnull(p.detalii.value('(/*/@taxe_vama)[1]','float'),p.TVA_deductibil)
	from pozdoc p
	left outer join gestiuni g on g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune
	left outer join nomencl n on n.cod=p.cod
	left outer join conturi c1 on c1.subunitate=p.subunitate and c1.cont=p.cont_de_stoc
	left outer join terti t1 on t1.subunitate=p.subunitate and t1.tert=p.tert
	left outer join dvi b on b.subunitate=p.subunitate and b.numar_receptie=p.numar and b.data_DVI=p.data
	left outer join terti t2 on t2.subunitate=p.subunitate and t2.tert=isnull(b.tert_vama,'')
	left outer join terti t3 on t3.subunitate=p.subunitate and t3.tert=isnull(b.tert_cif,'')
	where p.subunitate=@Sub and p.tip in ('RM','RS') and (@nr_document='' or p.numar=@nr_document) and p.data between @dataj and @datas
	order by p.subunitate,p.tip,p.data,p.numar

open tmprec
fetch next from tmprec into @sb,@tip,@numar,@data,@cod,@gest,@tip_gest,@cant,@tva_nx,@pret_valuta,@pret_de_stoc,@tip_nom,@cont_nom,@grupa_nom,
	@pret_vanzare,@pret_am_pred,@pret_amanunt,@suma_TVA,@acc_cump,@acc_dat,@cont_de_stoc,@atr_ct_stoc,@tip_ct_stoc,@cont_factura,@cont_ven,@cont_interm,
	@tert,@factura,@gest_prim,@tip_misc,@nr_dvi,@grupa,@den_tert,@t_extern,@valuta,@curs,@disc,@proc_vama,@supratx_vama,@locm,@comanda,@jurnal,
	@gasit_dvi,@tert_cif,@cont_cif,@valuta_cif,@curs_cif,@tert_vama,@cont_vama,@cont_fact_vama,@cont_com_vama,@cont_vama_suprataxe,@fact_comis,
	@den_tert_vama,@den_tert_cif,@t_extern_cif,@barcod,@cotaTVA,@taxe_vama
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @gsb=@sb
	set @gtip=@tip
	set @gnumar=@numar
	set @gdata=@data
	set @g_DVI=@gasit_dvi
	set @gct_deb_tva_vama=(case when @cont_ven<>'' then @cont_ven when left(@cont_factura,3)='408' then @Ct4428 else @Ct4426 end)
	set @glocm=@locm
	set @gcom=@comanda
	set @gjurnal=@jurnal
	set @gct_stoc=@cont_de_stoc
	set @gacc_cump=@acc_cump
	set @gacc_dat=@acc_dat
	set @gct_deb_cif_netva=(case when @tip_nom='R' and left(@cont_nom,3)='371' and 1=0 then '378.'+RTrim(@grupa_nom)+'03' else @cont_de_stoc end)
	set @gpret_vanz=@pret_vanzare
	set @gct_cif=@cont_cif

	exec calcul_prestari @gsb,@gnumar,@gdata,@tot_val_prestare output,@tot_val_asycuda output
	exec calcul_cif @gsb,@gnumar,@gdata,@tot_suma_cif output,@tot_valuta_cif output 
	set @nr_poz_doc=100
	while @gsb=@sb and @gtip=@tip and @gnumar=@numar and @gdata=@data and @gfetch=0
	begin
		--chem pt. pozitii
		set @CtChTVANed=(case when @proc_vama=3 then @cont_de_stoc else @CtChTVANed end)
		exec inreg_pozitii_receptii @ttla,@ttlr,@nrzec,@acc_imp_dvi,@inv_rul44,@bugetari,@Ct4426,@Ct4427,@Ct4428,@ignor_4428_avans,@ignor_4428_docff,@nr_zec_nx,
			@sb,@tip,@numar,@data,@cod,@gest,@tip_gest,@cant,@tva_nx,@pret_valuta,@pret_de_stoc,@tip_nom,@cont_nom,@grupa_nom,@pret_vanzare,@pret_am_pred,@pret_amanunt,@suma_TVA,@acc_cump,@acc_dat,
			@cont_de_stoc,@atr_ct_stoc,@tip_ct_stoc,@cont_factura,@cont_ven,@cont_interm,@tert,@factura,@gest_prim,@tip_misc,@nr_dvi,@grupa,@den_tert,@t_extern,@valuta,@curs,@disc,
			@proc_vama,@supratx_vama,@locm,@comanda,@jurnal,@gasit_dvi,@tert_cif,@cont_cif,@valuta_cif,@curs_cif,@tert_vama,@cont_vama,@cont_fact_vama,@cont_com_vama,@cont_vama_suprataxe,
			@fact_comis,@den_tert_vama,@den_tert_cif,@t_extern_cif,@nr_poz_doc output,@utilizator,@fara_com,@CtChTVANed,@cotaTVA,@taxe_vama
		
		exec inreg_pozitii_receptii2 @sb,@tip,@numar,@data,@tip_nom,@barcod,@cant,@acc_cump,@gest_prim,@cont_interm,@acc_dat,@locm,@comanda,@jurnal,@nr_poz_doc output,@utilizator,@gasit_dvi
				
		--DVI sau DVOT cu multi CIF
		if (@gasit_dvi=1 and @cont_cif='' and @pret_vanzare<>0) begin 
			set @cont_deb=(case when @tip_nom='R' and left(@cont_nom,3)='371' and 1=0 then '378.'+RTrim(@grupa_nom)+'03' else @cont_de_stoc end)
				set @nr_poz_RQ=0
				exec inreg_fact_cif @sb,@tip,@numar,@data,0,@cont_deb,@pret_vanzare,@tot_suma_cif,@locm,@comanda,@jurnal,@utilizator,@gasit_dvi,@nr_poz_doc,@nr_poz_RQ output
		end
		--comisionar vamal/prestator
		set @nr_poz_RP=0
		if (@acc_cump<>0 or @acc_dat<>0) 
			exec inreg_fact_prestari @sb,@tip,@numar,@data,0,@cont_de_stoc,@acc_cump,@acc_dat,@tot_val_prestare,@tot_val_asycuda,@locm,@comanda,@jurnal,@utilizator,@gasit_DVI,@nr_poz_doc,@nr_poz_RP output
		
		fetch next from tmprec into @sb,@tip,@numar,@data,@cod,@gest,@tip_gest,@cant,@tva_nx,@pret_valuta,@pret_de_stoc,@tip_nom,@cont_nom,@grupa_nom,
			@pret_vanzare,@pret_am_pred,@pret_amanunt,@suma_TVA,@acc_cump,@acc_dat,@cont_de_stoc,@atr_ct_stoc,@tip_ct_stoc,@cont_factura,@cont_ven,@cont_interm,
			@tert,@factura,@gest_prim,@tip_misc,@nr_dvi,@grupa,@den_tert,@t_extern,@valuta,@curs,@disc,@proc_vama,@supratx_vama,@locm,@comanda,@jurnal,
			@gasit_dvi,@tert_cif,@cont_cif,@valuta_cif,@curs_cif,@tert_vama,@cont_vama,@cont_fact_vama,@cont_com_vama,@cont_vama_suprataxe,@fact_comis,
			@den_tert_vama,@den_tert_cif,@t_extern_cif,@barcod,@cotaTVA,@taxe_vama
		set @gfetch=@@fetch_status
	end
	
	if @g_DVI=1 exec inreg_dvi @gsb,@gtip,@gnumar,@gdata,@g_DVI,@gct_deb_tva_vama,@nr_poz_doc,@glocm,@gcom,@gjurnal,@utilizator 
	
	exec inreg_fact_prestari @gsb,@gtip,@gnumar,@gdata,1,@gct_stoc,@gacc_cump,@gacc_dat,@tot_val_prestare,@tot_val_asycuda,@glocm,@gcom,@gjurnal,@utilizator,@g_DVI,@nr_poz_doc,@nr_poz_RP output
	
	if @gct_cif='' exec inreg_fact_cif @gsb,@gtip,@gnumar,@gdata,1,@gct_deb_cif_netva,@gpret_vanz,@tot_suma_cif,@glocm,@gcom,@gjurnal,@utilizator,@g_dvi,@nr_poz_doc,@nr_poz_RQ output
	
	if @lScriuDif=1 exec inreg_rec_diferente @gsb,@gtip,@gnumar,@gdata,@gjurnal
end
close tmprec
deallocate tmprec
end
