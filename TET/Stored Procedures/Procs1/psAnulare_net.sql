--***
/**	proc. anulare net	*/
Create
procedure [dbo].[psAnulare_net] 
@DataJ datetime, @DataS datetime, @Marca char(6)
As
Begin
--	pozitia cu ultima zi din luna
	update net set Venit_total=0,VENIT_NET=0,Impozit=0,Rest_de_plata=0,Asig_sanatate_din_net=0,
	Pensie_suplimentara_3=0,Somaj_1=0,Asig_sanatate_din_impozit=0,Asig_sanatate_din_CAS=0,Coef_tot_ded=0,
	VEN_NET_IN_IMP=0,Ded_baza=0,Ded_suplim=0,VENIT_BAZA=0,Chelt_prof=0,
	Debite_externe=0,Rate=0,Debite_interne=0,Cont_curent=0,CAS=0,Somaj_5=0,Fond_de_risc_1=0,
	Camera_de_munca_1=0,Asig_sanatate_pl_unitate=0,Baza_CAS=0
	where Data=@DataS and (@Marca='' or Marca=@Marca)

--	pozitia cu prima zi din luna	
	update net set Somaj_5=0,Ded_baza=0,Ded_suplim=0 
	where Data=@DataJ and (@Marca='' or Marca=@Marca)
End
