--***
/**	procedura desc. plati salarii	*/
Create procedure  descarc_plati_salarii
as
begin
	declare @Cont_impozit char(20), @Cont_CASI char(20), @Cont_CASSI char(20), @Cont_SomajI char(20), @Cont_CASU char(20), @Cont_CASSU char(20), @Cont_SomajU char(20), @Cont_FAMBP char(20), @Cont_CCI char(20), @Cont_FGAR char(20), 
	@Cont_ITM char(20), @Cont_CNPH char(20), @Cont_penalitati char(20), @Cont_TVA char(20), @Data datetime, @Data_doc datetime, @Numar char(20), @suma float, @explicatii char(50), @cont char(20), @Cont_corespondent char(20), @Plata_incasare char(2), @Tip char(1), @Element char(1), @Tert char(13), @Factura char(20), @Subunitate char(9), @vTert char(13), @vFactura char(20), 
	@cLoc_de_munca char(9), @cComanda char(20)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output
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
	Set @Cont_CNPH=dbo.iauParA('PS','N-CPH-CRE')
	Set @Cont_penalitati='6581'
	Set @Cont_TVA=dbo.iauParA('GE','CPTVA')

	declare descarc_plati_salarii cursor For
	Select a.Tip, a.Element, a.Tert, a.Factura, b.Data, max(b.data1) as Data_doc, max(b.Numar_document), max(c.cont), 
		(case when a.Factura='CASI' then @Cont_CASI when a.Factura='CASSI' then @Cont_CASSI 
		when a.Factura='SOMAJI' then @Cont_SomajI when a.Factura='IMPOZIT' then @Cont_impozit 
		when a.Factura='CASU' then @Cont_CASU when a.Factura='CASSU' then @Cont_CASSU
		when a.Factura='SOMAJU' then @Cont_SomajU when a.Factura='FAMBP' then @Cont_FAMBP 
		when a.Factura='CCI' then @Cont_CCI when a.Factura='FGAR' then @Cont_FGAR
		when a.Factura='COMISITM' then @Cont_ITM when a.Factura='CNPH' then @Cont_CNPH 
		when a.Factura='PENALITATI' then @Cont_Penalitati when a.Factura='TVA' then @Cont_TVA 
		else (case when a.Tip='P' and a.Element='F' then isnull((select max(Cont_de_tert) from facturi f where f.Subunitate=@Subunitate and f.Tip=0x54 and f.Tert=a.Tert and f.Factura=a.Factura),'') else '' end) end) as Cont_corespondent,
		sum(a.suma), rtrim((case when a.Tip='P' and a.Element='F' then max(e.denumire) else max(a.explicatii) end))
	from prog_plin a, extprogpl b, ccontaiban c, terti e
	where a.tip='P' and (a.element='D' or a.element='F') and /*a.stare=0 and*/ a.Bifat=1 and a.tip=b.tip and a.element=b.element and a.data=b.data and a.tert=b.tert and a.factura=b.factura and b.cont_platitor=c.cod and e.subunitate=@Subunitate and e.tert=a.tert
	group by a.Tip, a.Element, a.Tert, a.Factura, b.Data

	open descarc_plati_salarii
	fetch next from descarc_plati_salarii into 
	@Tip, @Element, @Tert, @Factura, @Data, @Data_doc, @Numar, @Cont, @Cont_corespondent, @suma, @explicatii
	While @@fetch_status = 0 
	Begin
		Set @cLoc_de_munca=(case when @Element='F' then isnull((select max(Loc_de_munca) from facturi f where f.Subunitate=@Subunitate and f.Tip=0x54 and f.Tert=@Tert and f.Factura=@Factura),'') else '' end)
		Set @cComanda=(case when @Element='F' then isnull((select max(Comanda) from facturi f where f.Subunitate=@Subunitate and f.Tip=0x54 and f.Tert=@Tert and f.Factura=@Factura),'') else '' end)
		Set @vTert=(case when @Element='F' then @Tert else '' end)
		Set @vFactura=(case when @Element='F' then @Factura else '' end)
		Set @Plata_incasare=(case when @Element='F' then 'PF' else 'PD' end)

		exec scriuPozplin @Cont, @Data_doc, @Numar, @Plata_incasare, @vTert, @vFactura, 
		@Cont_corespondent, @Suma, '', 0, 0, 0, 0, @Explicatii, @cLoc_de_munca, @cComanda, '', 0, ''
		update prog_plin set Stare=1 where Stare=0 and tip=@Tip and element=@Element 
			and Tert=@Tert and Factura=@Factura and Data=@Data
	
		fetch next from descarc_plati_salarii into 
		@Tip, @Element, @Tert, @Factura, @Data, @Data_doc, @Numar, @Cont, @Cont_corespondent, @suma, @explicatii
	End
	close descarc_plati_salarii
	Deallocate descarc_plati_salarii
	return
end
