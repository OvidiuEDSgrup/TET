--***
/**	procedura pentru scriere data in tabela resal (retineri lunare salariati) */
Create 
procedure scriuResal 
(@Data datetime, @Marca char(6), @Cod_beneficiar char(13), @Numar_document char(10), @Data_document datetime, 
@Valoare_totala_pe_doc float, @Valoare_retinuta_pe_doc float, @Retinere_progr_la_avans float, 
@Retinere_progr_la_lichidare float, @Procent_progr_la_lichidare float, @Retinut_la_avans float, @Retinut_la_lichidare float)
As
Begin 
	If isnull((select count(1) from Resal where Data=@Data and Marca=@Marca and Cod_beneficiar=@Cod_beneficiar and Numar_document=@Numar_document),0)=1
		update Resal set Data_document=@Data_document, Valoare_totala_pe_doc=@Valoare_totala_pe_doc, 
			Retinere_progr_la_avans=@Retinere_progr_la_avans, Retinere_progr_la_lichidare=@Retinere_progr_la_lichidare, 
			Procent_progr_la_lichidare=@Procent_progr_la_lichidare
		where Data=@Data and Marca=@Marca and Cod_beneficiar=@Cod_beneficiar and Numar_document=@Numar_document
	Else 
		insert into Resal
		(Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, 
		Retinere_progr_la_avans, Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
		Select @Data, @Marca, @Cod_beneficiar, @Numar_document, @Data_document, @Valoare_totala_pe_doc, 
		@Valoare_retinuta_pe_doc, @Retinere_progr_la_avans, @Retinere_progr_la_lichidare, 
		@Procent_progr_la_lichidare, @Retinut_la_avans, @Retinut_la_lichidare
End
