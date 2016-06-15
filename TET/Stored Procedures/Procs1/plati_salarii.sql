--***
/**	procedura plati salarii	*/
Create procedure plati_salarii 
	(@dIncLPrec datetime, @dSfLPrec datetime, @pTip char(1), @pElement char(1))
as
begin
	declare @sume table 
		(Data datetime, Rest_de_plata float, Impozit float, CASI float, CASSI float, SomajI float, CASU float, CASSU float, 
		SomajU float, FAMBP float, CCI float, Fond_garantare float, Cotiz_hand float, Comision_ITM float) 
	declare @plati_salarii table 
		(Tip char(1), Element char(1), Data datetime, Tert char(13), Factura char(20), Explicatii char(50), 
		Suma float, Valuta char(3), Suma_valuta float, Stare int, Data_scadentei datetime, bifat bit)

	declare @Judet char(25), @ComITM float, @Cont_impozit char(20), @Cont_CASI char(20), @Cont_CASSI char(20), 
	@Cont_SomajI char(20), @Cont_CASU char(20), @Cont_CASSU char(20), @Cont_SomajU char(20), @Cont_FAMBP char(20), 
	@Cont_CCI char(20), @Cont_FGAR char(20), @Cont_ITM char(20), @Subunitate char(9), @nAn float, @nLuna float, 
	@cData_curenta char(10)

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output
	Set @nAn=dbo.iauParN('PS','ANUL')
	Set @nLuna=dbo.iauParN('PS','LUNA')
	Set @cData_curenta=isnull(rtrim((select val_alfanumerica from par where tip_parametru='PS' and parametru=rtrim(host_id())+'D')) ,'01'+'/'+(case when @nLuna<10 then '0' else '' end)+ rtrim(convert(char(2),@nLuna))+'/'+convert(char(4),@nAn))
	Set @dIncLPrec=convert(datetime, @cData_curenta, 104) 
	Set @dSfLPrec=dbo.eom(convert(datetime, @cData_curenta, 104))
	Set @Judet=dbo.iauParA('PS','JUDET')
	Set @ComITM=dbo.iauParN('PS','1%-CAMERA')
	Set @Cont_impozit=dbo.iauParA('PS','N-I-PMACC')
	Set @Cont_CASI=dbo.iauParA('PS','N-AS-P3AC')
	Set @Cont_CASSI=dbo.iauParA('PS','N-ASNEAC')
	Set @Cont_SomajI=dbo.iauParA('PS','N-ASSJ1AC')
	Set @Cont_CASU=dbo.iauParA('PS','N-AS-33%C')
	Set @Cont_CASSU=dbo.iauParA('PS','N-AS-AS5C')
	Set @Cont_SomajU=dbo.iauParA('PS','N-ASSJP5C')
	Set @Cont_FAMBP=dbo.iauParA('PS','N-AS-FR1C')
	Set @Cont_CCI=dbo.iauParA('PS','N-AS-CCIC')
	Set @Cont_FGAR=dbo.iauParA('PS','N-ASFGARC')
	Set @Cont_ITM=dbo.iauParA('PS','N-MUNCA-C')

	if @pTip=''
		Set @pTip='P'
	if @pElement=''
		Set	@pElement='D' 
	insert into @sume(Data, Rest_de_plata, Impozit, CASI, CASSI, SomajI, CASU, CASSU, SomajU, FAMBP ,CCI , Fond_garantare, Cotiz_hand, Comision_ITM) 
	select dateadd(month, 1, n.data), Sum(Rest_de_plata), sum(n.Impozit+n.Diferenta_impozit), 
	sum(n.Pensie_suplimentara_3) as CASI, sum(n.Asig_sanatate_din_net+n.Asig_sanatate_din_impozit) as CASSI,
	sum(n.Somaj_1) as SomajI, sum(n.CAS_de_virat) as CASU, sum(n.Asig_sanatate_pl_unitate+n.CASS_AMBP) as CASSU,
	sum(n.Somaj_5-(n.Subventii_somaj_art8076+n.Subventii_somaj_art8576+n.Subventii_somaj_art172+n.Scut_art_80+n.Scut_art_85)) as SomajU, 
	sum(n.Fond_de_risc_1-(n.Asig_sanatate_din_impozit+n.CMFAMBP+n.CCI_fambp)) as FAMBP, 
	sum(n.CCI+n.CCI_fambp-(n.Ind_c_medical_cas+n.CMCAS)) as CCI, sum(n.Fond_garantare) as Fond_garantare, 
	sum(n.Cotiz_hand) as Cnph, sum(n.Camera_de_munca_1) as Comision_Itm
	from dbo.fluturas_centralizat(@dIncLPrec, @dSfLPrec ,'','zzz','','ZZZ',0,'N',0,'3','7',0,'',0,'',0,'',0,'',0,'1',0,'',1,'T',0,'P',0,',','',0,0,'',Null,Null, Null) n
	where n.data between @dIncLPrec and @dSfLPrec and (@pTip='' or @pTip='P') 
	group by dateadd(month, 1, n.data) 

	insert into @plati_salarii(Tip, Element, Data, Tert, Factura, Explicatii, Suma, Valuta, Suma_valuta, Stare, Data_scadentei, Bifat) 
	select 'P', 'D', data, 'Salarii', 'RESTPL', 'Rest de plata', Rest_de_plata, '', 0, 0, data, 0
	from @sume a
	where Rest_de_plata>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='SALARII') 
	union all
	select 'P','D',data,'IMPOZIT','IMPOZIT','BUGETUL DE STAT',Impozit,'',0,0,data, 0
	from @sume a
	where Impozit>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='IMPOZIT') 
	union all 
	select 'P','D',data,'ASIGURARI','CASI','BUGETELE ASIG.SOC. SI FD.SPEC.',CASI,'',0,0,data,0
	from @sume a
	where a.CASI>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='CASI') 
	union all 
	select 'P','D',data,'ASIGURARI','CASSI','BUGETELE ASIG.SOC. SI FD.SPEC.',CASSI,'',0,0,data,0
	from @sume a
	where CASSI>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='CASSI') 
	union all 
	select 'P','D',data,'ASIGURARI','SOMAJI','BUGETELE ASIG.SOC. SI FD.SPEC.',SomajI,'',0,0,data,0
	from @sume a
	where SomajI>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='SOMAJI') 
	union all 
	select 'P','D',data,'ASIGURARI','CASU','BUGETELE ASIG.SOC. SI FD.SPEC.',CASU,'',0,0,data,0
	from @sume a
	where CASU>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='CASU') 
	union all 
	select 'P','D',data,'ASIGURARI','CASSU','BUGETELE ASIG.SOC. SI FD.SPEC.',CASSU,'',0,0,data,0
	from @sume a
	where CASSU>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='CASSU') 
	union all 
	select 'P','D',data,'ASIGURARI','SOMAJU','BUGETELE ASIG.SOC. SI FD.SPEC.',SomajU,'',0,0,data,0
	from @sume a
	where SomajU>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='SOMAJU') 
	union all 
	select 'P','D',data,'ASIGURARI','FAMBP','BUGETELE ASIG.SOC. SI FD.SPEC.',Fambp,'',0,0,data,0
	from @sume a
	where Fambp>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='FAMBP') 
	union all 
	select 'P','D',data,'ASIGURARI','CCI','BUGETELE ASIG.SOC. SI FD.SPEC.',CCI,'',0,0,data,0
	from @sume a
	where CCI>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='CCI') 
	union all 
	select 'P','D',data,'ASIGURARI','FGAR','BUGETELE ASIG.SOC. SI FD.SPEC.',Fond_garantare,'',0,0,data,0
	from @sume a
	where Fond_garantare>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='FGAR')
	union all 
	select 'P','D',data,'ASIGURARI','CNPH','BUGETELE ASIG.SOC. SI FD.SPEC.',Cotiz_hand,'',0,0,data,0
	from @sume a
	where Cotiz_hand>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ASIGURARI' and p.factura='CNPH') 
	union all 
	select 'P','D',data,'ITM','COMISITM','Comision pentru cartea de munca '+rtrim(convert(char(10),@ComITM)),Comision_ITM,'',0,0,data,0
	from @sume a
	where Comision_Itm>0 and not exists (select 1 from prog_plin p where p.tip='P' and p.element='D' and p.data=a.data and p.tert='ITM')

	insert into prog_plin(Tip, Element, Data, Tert, Factura, Explicatii, Suma, Valuta, Suma_valuta, Stare, Data_scadentei, Bifat) 
	select Tip, Element, Data, Tert, Factura, Explicatii, Suma, Valuta, Suma_valuta, Stare, Data_scadentei, Bifat from @plati_salarii

	insert into extprogpl 
	(Tip, Element, Data, Tert, Factura, Numar_document, Suma_platita, Detalii_plata, Cont_platitor, IBAN_beneficiar, Banca_beneficiar, Alfa1, Alfa2, Alfa3, Val1, Val2, Val3, Data1, Data2, Data3)
	select a.Tip, a.Element, a.Data, a.Tert, a.Factura, '', a.Suma, a.explicatii, 
	isnull((select top 1 max(b.cont_platitor) from extprogpl b where 
	a.tip=b.tip and a.element=b.element and a.tert=b.tert group by data, b.tip, b.Element, b.Tert order by data desc),''), 
	isnull((select top 1 max(b.IBAN_beneficiar) from extprogpl b where 
	a.tip=b.tip and a.element=b.element and a.tert=b.tert group by data, b.tip, b.Element, b.Tert order by data desc),isnull(b.Cont_in_banca,'')), 
	isnull((select top 1 max(b.Banca_beneficiar) from extprogpl b where 
	a.tip=b.tip and a.element=b.element and a.tert=b.tert group by data, b.tip, b.Element, b.Tert order by data desc),'Trezorerie operativa Municipiul '+rtrim(isnull(b.Localitate,''))), 
	isnull((select top 1 max(b.Alfa1) from extprogpl b where 
	a.tip=b.tip and a.element=b.element and a.tert=b.tert group by data, b.tip, b.Element, b.Tert order by data desc),'TREZROBU'), 
	'', '', 0, 0, 0, convert(datetime, convert(char(10), getdate(), 104), 104), '01/01/1901', '01/01/1901'
	from @plati_salarii a
		left outer join terti b on b.Subunitate=@Subunitate and b.Tert=a.Tert

	return
end
