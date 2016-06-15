--***
/**	procedura retineri CO Salubris	*/
Create
procedure calcul_retineri_CO_Salubris
	@pMarca char(6), @pData_inchisa datetime, @Retineri_CO float output
As
Begin
	declare @cCod_sindicat char(13), @Detaliere_retineri int, @Data_inchisa_1 datetime, @Codb_exceptie char(1000)
	Set @cCod_sindicat=dbo.iauParA('PS','SIND%')
	Set @Detaliere_retineri=dbo.iauParL('PS','SUBTIPRET')
	Set @Data_inchisa_1=dbo.eom(@pData_inchisa+1)
	Set @Codb_exceptie=dbo.iauParA('PS','CO-RET')
	
	Select @Retineri_CO=isnull(sum((case when a.Valoare_totala_pe_doc=0 or a.Cod_beneficiar=@cCod_sindicat then 0 
		else dbo.Valoare_minima(a.Retinere_progr_la_lichidare+a.Procent_progr_la_lichidare*p.Salar_de_incadrare/100,
		a.Valoare_totala_pe_doc-r.Valoare_retinuta_pe_doc,0) end))+
		sum((case when a.Valoare_totala_pe_doc=0 or a.Cod_beneficiar=@cCod_sindicat then 
		a.Retinere_progr_la_lichidare+a.Procent_progr_la_lichidare*p.Salar_de_incadrare/100 else 0 end)),0)
	from resal a 
		left outer join personal p on p.Marca=a.Marca
		left outer join benret b on a.Cod_beneficiar=b.Cod_beneficiar
		left outer join tipret c on b.Tip_retinere=c.Subtip
		left outer join resal r on r.Data=dbo.bom(a.Data)-1 and r.Marca=a.Marca and r.Cod_beneficiar=a.Cod_beneficiar and r.Numar_document=a.Numar_document
	where a.Marca=@pMarca and a.Data=@Data_inchisa_1 
		and not(p.Loc_ramas_vacant=1 and @Data_inchisa_1>dbo.eom(p.Data_plec))
		and left(a.Numar_document,5)<>'CONET' and charindex(','+rtrim(a.Cod_beneficiar)+',',@Codb_exceptie)=0
End
