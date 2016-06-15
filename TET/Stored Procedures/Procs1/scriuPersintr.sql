--***
/**	procedura scriuPersintr	*/
Create
procedure scriuPersintr 
(@Data datetime, @Marca char(6), @Tip_intretinut char(1), @Cod_personal char(13), @Nume_pren char(50), 
@Grad_invalid char(1), @Coef_ded int, @Data_nasterii datetime, @Data_exp_ded datetime, @Data_exp_coasig datetime, 
@Venit_lunar decimal(10), @Deducere decimal(3,2), @Coasigurat char(1), @Tip_intretinut_2 char(1), 
@Valoare decimal(12,2), @Observatii varchar(50))
As
Begin 
--	scriere in persoane in intretinere (persintr)
	If isnull((select count(1) from persintr where Data=@Data and Marca=@Marca and Cod_personal=@Cod_personal),0)=1
		update persintr set Tip_intretinut=@Tip_intretinut, Cod_personal=@Cod_personal, Nume_pren=@Nume_pren, 
		Data=@Data, Grad_invalid=@Grad_invalid, Coef_ded=@Coef_ded, Data_nasterii=@Data_nasterii
		where Marca=@Marca and Data=@Data and Cod_personal=@Cod_personal
	Else 
		insert into persintr (Marca, Tip_intretinut, Cod_personal, Nume_pren, Data, Grad_invalid, Coef_ded, Data_nasterii)
		Select @Marca, @Tip_intretinut, @Cod_personal, @Nume_pren, @Data, @Grad_invalid, @Coef_ded, @Data_nasterii

--	scriere in extensie persoane in intretinere (extpersintr)
	If isnull((select count(1) from extpersintr where Data=@Data and Marca=@Marca and Cod_personal=@Cod_personal),0)=1
		update extpersintr set Data_exp_ded=@Data_exp_ded, Data_exp_coasig=@Data_exp_coasig, Venit_lunar=@Venit_lunar, Deducere=@Deducere, Coasigurat=@Coasigurat, Tip_intretinut_2=@Tip_intretinut_2, Valoare=@Valoare, Observatii=@Observatii
		where Marca=@Marca and Data=@Data and Cod_personal=@Cod_personal
	Else 
		insert into extpersintr (Data, Marca, Cod_personal, Data_exp_ded, Data_exp_coasig, Venit_lunar, Deducere, 
		Coasigurat, Tip_intretinut_2, Valoare, Observatii)
		Select @Data, @Marca, @Cod_personal, @Data_exp_ded, @Data_exp_coasig, @Venit_lunar, @Deducere, 
		@Coasigurat, @Tip_intretinut_2, @Valoare, @Observatii
End
