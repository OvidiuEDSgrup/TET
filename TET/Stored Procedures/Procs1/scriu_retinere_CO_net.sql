--***
/**	proc. scriu retinere CO net	*/
Create procedure scriu_retinere_CO_net
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @pLocm char(9)
As
Begin try
	declare @Cod_benef_CO_net char(13)
	Set @Cod_benef_CO_net=dbo.iauParA('PS','CODBCO')

	delete from resal 
	where data between @dataJos and @dataSus and (@pMarca='' or marca=@pMarca) and Cod_beneficiar=@Cod_benef_CO_net
		and Numar_document='CONET'+ltrim(rtrim(convert(char(2),month(Data))))+right(convert(char(4),year(Data)),2)

	insert into resal (Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, 
		Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
	select Data, Marca, @Cod_benef_CO_net, 'CONET'+ltrim(rtrim(convert(char(2),month(Data))))+right(convert(char(4),year(Data)),2),
		Data, sum(Indemnizatie_CO), 0, 0, sum(Indemnizatie_CO), 0, 0, 0
	from concodih
	where data between @dataJos and @dataSus and (@pMarca='' or marca=@pMarca) and Tip_concediu='9'
	Group by Data, Marca
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura scriu_retinere_CO_net (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

