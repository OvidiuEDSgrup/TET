--***
create procedure calculSalarDeBaza @sesiune varchar(50), @parXML xml
as 
begin try  
	Declare @Bugetari int, @IndCondSuma int, @Sp1_suma int, @SalarBazaCuIndCond int, @SalarBazaCuSpSpec int, @SalarBazaCuSpCond1 int, @SpSpecificCuIndCond int, 
	@SporCondCuIndCond int, @SporCondCuSpSpec int, @SporCondCuSpCond1 int, 
	@IndCondCalc decimal(10), @BazaSpSpecific decimal(10), @BazaSporCond decimal(10), @SporCondInSalBaza decimal(10), @mesaj varchar(254)

	select	@Bugetari=max(case when parametru='UNITBUGET' then Val_logica else 0 end),
			@IndCondSuma=max(case when parametru='INDC-SUMA' then Val_logica else 0 end),
			@Sp1_suma=max(case when parametru='SC1-SUMA' then Val_logica else 0 end),
			@SalarBazaCuIndCond=max(case when parametru='SBAZA-IND' then Val_logica else 0 end),
			@SalarBazaCuSpSpec=max(case when parametru='S-BAZA-SP' then Val_logica else 0 end),
			@SalarBazaCuSpCond1=max(case when parametru='S-BAZA-S1' then Val_logica else 0 end),
			@SpSpecificCuIndCond=max(case when parametru='SPSP-IND' then Val_logica else 0 end),
			@SporCondCuIndCond=max(case when parametru='SPOR-IND' then Val_logica else 0 end),
			@SporCondCuSpSpec=max(case when parametru='SP-SPSP' then Val_logica else 0 end),
			@SporCondCuSpCond1=max(case when parametru='SPOR-SP1' then Val_logica else 0 end)
	from par where tip_parametru='PS' and parametru in ('UNITBUGET','INDC-SUMA','SC1-SUMA','SBAZA-IND','S-BAZA-SP','S-BAZA-S1','SPSP-IND','SPOR-IND','SP-SPSP','SPOR-SP1')

	select @IndCondCalc=0, @BazaSpSpecific=0, @BazaSporCond=0, @SporCondInSalBaza=0

--	update
	update #personalSalBaza 
	set 
--	variabile pentru calcul salar de baza (daca bugetari)
		@IndCondCalc=(case when @IndCondSuma=1 then Indemnizatia_de_conducere else round(Salar_de_incadrare*Indemnizatia_de_conducere/100,0) end),
		@BazaSpSpecific=(case when @Bugetari=1 then Salar_de_incadrare+(case when @SpSpecificCuIndCond=1 then @IndCondCalc else 0 end) else 0 end),
		@BazaSporCond=(case	when @Bugetari=1 
						then Salar_de_incadrare+(case when @SporCondCuIndCond=1 then @IndCondCalc else 0 end)
							+(case when @SporCondCuSpSpec=1 then @BazaSpSpecific*Spor_specific/100 else 0 end)
							+(case when @SporCondCuSpCond1=1 then (case when @Sp1_Suma=1 then Spor_conditii_1 else @BazaSpSpecific*Spor_conditii_1/100 end) else 0 end) 
						else 0 end),
		@SporCondInSalBaza=(case when @SalarBazaCuSpCond1=1 
							then (case when @SporCondCuSpCond1=1 then (case when @Sp1_suma=1 then Spor_conditii_1 else @BazaSpSpecific*Spor_conditii_1/100 end)
									else @BazaSporCond*Spor_conditii_1/100 end) else 0 end),
		Salar_de_baza=(case when @Bugetari=1 then Salar_de_incadrare+(case when @SalarBazaCuIndCond=1 then @IndCondCalc	else 0 end)
								+(case when @SalarBazaCuSpSpec=1 then @BazaSpSpecific*Spor_specific/100 else 0 end)+@SporCondInSalBaza  
						else Salar_de_incadrare end)
end try  
begin catch
	set @mesaj=ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesaj, 11, 1)
end catch
