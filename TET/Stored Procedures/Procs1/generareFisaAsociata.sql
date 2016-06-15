--***
create procedure generareFisaAsociata @tip varchar(2), @numar varchar(20), @data datetime
as
begin try
	declare @numarAsoc varchar(20), @masinaAsoc varchar(20), @tipMasinaAsoc varchar(20), @comandaMasinaAsoc varchar(20), @lmMasinaAsoc varchar(20), @eroare varchar(254)
	
	select @masinaAsoc=tert from activitati where tip=@tip and fisa=@numar and data=@data
	select @tipMasinaAsoc=tip_masina, @comandaMasinaAsoc=Comanda, @lmMasinaAsoc=loc_de_munca
	from masini where cod_masina=@masinaAsoc
	set @numarAsoc='R'+LEFT(@numar,19)

	delete from activitati where tip=@tip and fisa=@numarAsoc and data=@data
	delete from pozactivitati where tip=@tip and fisa=@numarAsoc and data=@data
	delete from elemactivitati where tip=@tip and fisa=@numarAsoc and data=@data
	
	INSERT INTO activitati (Tip,Fisa,Data,Masina,Comanda,Loc_de_munca,Comanda_benef,lm_benef,Tert,
		Marca,Marca_ajutor,Jurnal)
	select Tip,@numarAsoc,Data,@masinaAsoc,@comandaMasinaAsoc,@lmMasinaAsoc,Comanda_benef,lm_benef,'',
			Marca,@numar/*Marca_ajutor*/,/*'MMX'*/Jurnal
	from activitati 
	where tip=@tip and fisa=@numar and data=@data

	INSERT INTO pozactivitati(Tip, Fisa, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, 
		Ora_plecarii, Sosire, Data_sosirii, Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, 
		Tert, Marca, Utilizator, Data_operarii, Ora_operarii, Alfa1, Alfa2, Val1, Val2, Data1/*, idActivitati*/)
	select Tip, @numarAsoc, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, 
			Ora_plecarii, Sosire, Data_sosirii, Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, 
			Tert, Marca, Utilizator, Data_operarii, Ora_operarii, Alfa1, Alfa2, 0, Val2, Data1/*, idActivitati*/
	from pozactivitati 
		where tip=@tip and fisa=@numar and data=@data and Val1=1

	INSERT INTO elemactivitati (Tip, Fisa, Data, Numar_pozitie, Element, Valoare,
		Tip_document, Numar_document, Data_document/*, idpozactivitati*/)
	select ea.Tip, @numarAsoc, ea.Data, ea.Numar_pozitie, Element, Valoare,
		Tip_document, Numar_document, Data_document/*, idpozactivitati*/
	from elemactivitati ea
		inner join pozactivitati pa on pa.Tip=ea.Tip and pa.Fisa=ea.Fisa and pa.Data=ea.Data and pa.Numar_pozitie=ea.Numar_pozitie and pa.Val1=1
	where ea.tip=@tip and ea.fisa=@numar and ea.data=@data
		and exists (select 1 from elemtipm et where et.Tip_masina=@tipMasinaAsoc and et.element=ea.element)
end try
 
begin catch  
	set @eroare='generareFisaAsociata: '+rtrim(ERROR_MESSAGE())
	raiserror(@eroare, 11, 1) 		
end catch

/*if isnull(@eroare,'')='' 
begin
	update activitati set stare=2 where tip=@tip and fisa=@numarAsoc and data=@data
end*/
