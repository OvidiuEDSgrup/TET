--***
/**	procedura scriuConmed	*/
Create 
procedure scriuConmed 
(@Data datetime, @Marca char(6), @Tip_diagnostic char(2), @Data_inceput datetime, @Data_sfarsit datetime, 
@Zile_lucratoare int, @Zile_cu_reducere int, @Zile_luna_anterioara int,  @Indemnizatia_zi float, @Procent_aplicat float, 
@Indemnizatie_unitate float, @Indemnizatie_CAS float, @Baza_calcul float, @Zile_lucratoare_in_luna int, 
@Indemnizatii_calc_manual int, @Suma float, @Serie_certificat_CM char(10), @Nr_certificat_CM char(10), 
@Serie_certificat_CM_initial char(10), @Nr_certificat_CM_initial char(10), @Cod_urgenta char(5), @Cod_grupaA char(5), 
@Data_acordarii datetime, @Cnp_copil char(13), @Loc_prescriere int, @Medic_prescriptor char(50), 
@Unitate_sanitara char(50), @Nr_aviz_me char(10), @lSterg int, @Cod_diagnostic char(10)='', @Zile_calend_luna_ant int=0)
as
Begin 
	delete from conmed where @lSterg=1 and Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput 
	delete from infoconmed where @lSterg=1 and Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput 

--	scriere in conmed
	If @lSterg=0 and isnull((select count(1) from Conmed where Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput),0)=1
		update Conmed set Tip_diagnostic=@Tip_diagnostic, Data_sfarsit=@Data_sfarsit, Zile_lucratoare=@Zile_lucratoare, 
			Zile_luna_anterioara=@Zile_luna_anterioara, Indemnizatia_zi=@Indemnizatia_zi, Baza_calcul=@Baza_calcul, 
			Zile_lucratoare_in_luna=@Zile_lucratoare_in_luna, Indemnizatii_calc_manual=@Indemnizatii_calc_manual, Suma=@Suma,
			Indemnizatie_unitate=@Indemnizatie_unitate, Indemnizatie_CAS=@Indemnizatie_CAS
		where Marca=@Marca and Data=@Data and Data_inceput=@Data_inceput
	Else 
		insert into Conmed (Data, Marca, Tip_diagnostic, Data_inceput, Data_sfarsit, Zile_lucratoare, Zile_cu_reducere, Zile_luna_anterioara, Indemnizatia_zi, Procent_aplicat, Indemnizatie_unitate, Indemnizatie_CAS, Baza_calcul, Zile_lucratoare_in_luna, Indemnizatii_calc_manual, Suma)
		Select @Data, @Marca, @Tip_diagnostic, @Data_inceput, @Data_sfarsit, @Zile_lucratoare, @Zile_cu_reducere, @Zile_luna_anterioara, @Indemnizatia_zi, @Procent_aplicat, @Indemnizatie_unitate, @Indemnizatie_CAS, @Baza_calcul, @Zile_lucratoare_in_luna, @Indemnizatii_calc_manual, @Suma

--	scriere in infoconmed
	If @lSterg=0 and isnull((select count(1) from infoconmed where Data=@Data and Marca=@Marca and Data_inceput=@Data_inceput),0)=1
		update infoconmed set Serie_certificat_CM=@Serie_certificat_CM, Nr_certificat_CM=@Nr_certificat_CM, 
			Serie_certificat_CM_initial=@Serie_certificat_CM_initial, Nr_certificat_CM_initial=@Nr_certificat_CM_initial, 
			Zile_CAS=@Zile_calend_luna_ant, Cod_urgenta=@Cod_urgenta, Cod_boala_grpA=@Cod_grupaA, Data_acordarii=@Data_acordarii, Cnp_copil=@Cnp_copil, 
			Loc_prescriere=@Loc_prescriere, Medic_prescriptor=@Medic_prescriptor, Unitate_sanitara=@Unitate_sanitara, 
			Nr_aviz_me=@Nr_aviz_me, Alfa=@Cod_diagnostic
		where Marca=@Marca and Data=@Data and Data_inceput=@Data_inceput
	Else 
		insert into infoconmed (Data, Marca, Data_inceput, Serie_certificat_CM, Nr_certificat_CM, Serie_certificat_CM_initial, Nr_certificat_CM_initial, Indemnizatie_FAMBP, Zile_CAS, Zile_FAMBP, Cod_urgenta, Cod_boala_grpA, Data_rez, Data_acordarii, Cnp_copil, Loc_prescriere, Medic_prescriptor, Unitate_sanitara, Nr_aviz_me, Valoare, Valoare1, Alfa, Alfa1, Numar_pozitie)
		Select @Data, @Marca, @Data_inceput, @Serie_certificat_CM, @Nr_certificat_CM, @Serie_certificat_CM_initial, @Nr_certificat_CM_initial, 0, @Zile_calend_luna_ant, 0, @Cod_urgenta, @Cod_grupaA, '01/01/1901',@Data_acordarii, @Cnp_copil,@Loc_prescriere, @Medic_prescriptor, @Unitate_sanitara, @Nr_aviz_me, 0, 0, @Cod_diagnostic, '', 0

End
