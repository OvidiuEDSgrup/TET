--***
/**	proc.calcul taxa post Salubris	*/
Create procedure  scriu_retinere_taxap_Salubris
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLocm char(9)
As
Begin
	--06.08.2009 modificat calculul sumei la cerinta Salubris: suma fixa 2.5 in loc de 3 si procent 1.1 in loc de 1 cu intregire la 1. 
	declare @Sir_benef_pens_alim char(200), @Cod_benef_taxap char(13)
	Set @Sir_benef_pens_alim=dbo.iauParA('PS','GPENSALIM')
	Set @Cod_benef_taxap=dbo.iauParA('PS','CODBTP')

	delete from resal 
	where data between @dataJos and @dataSus 
		and (@pMarca='' or marca=@pMarca) and Cod_beneficiar=@Cod_benef_taxap
		and Numar_document='TAXAP'+ltrim(rtrim(convert(char(2),month(Data))))+right(convert(char(4),year(Data)),2)

	insert into resal (Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, 
		Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
	select Data, Marca, @Cod_benef_taxap, 'TAXAP'+ltrim(rtrim(convert(char(2),month(Data))))++right(convert(char(4),year(Data)),2),
	Data, sum(ceiling(2.5+Retinere_progr_la_lichidare*1.1/100)), 0, 0, sum(ceiling(2.5+Retinere_progr_la_lichidare*1.1/100)), 0, 0, 0
	from resal 
	where data between @dataJos and @dataSus and (@pMarca='' or marca=@pMarca) 
		and charindex(','+rtrim(ltrim(Cod_beneficiar))+',',rtrim(@Sir_benef_pens_alim))>0
	group by Data, Marca
End
