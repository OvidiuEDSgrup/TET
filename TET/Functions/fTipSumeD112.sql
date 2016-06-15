-- functie ce returneaza denumirea tipurilor de sume cuprinse in D112 pe sectiuni.
create function fTipSumeD112(@datalunii datetime)
returns @tipsume table 
	(ordine int, cod varchar(20), den_suma varchar(1000))
begin
	declare @versiune int
	set @versiune=(case when @datalunii>='01/01/2014' then 2 else 1 end)

--	sume sectiunea AsiguratA
	insert into @tipsume
	select 1, 'A_1', 'Tip asigurat din punct de vedere al contractului de munca' union all
	select 2, 'A_2', 'Pensionar' union all
	select 3, 'A_3', 'Tip contract de munca din punct de vedere al timpului de lucru' union all
	select 4, 'A_4', 'Ore norma zilnica contract' union all
	select 15, 'A_5', 'Baza de calcul pentru contributia la fondul de garantare' union all
	select 5, 'A_6', 'Ore lucrate efectiv in luna' union all	
	select 6, 'A_7', 'Ore suspendate in luna' union all
	select 7, 'A_8', 'Total zile lucrate' union all
	select 9, 'A_9', 'Baza Contributie Individuala SOMAJ' union all
	select 10, 'A_10', 'Contributie Individuala SOMAJ' union all
	select 11, 'A_11', 'Baza Contributie Individuala SANATATE' union all
	select 12, 'A_12', 'Contributie Individuala SANATATE' union all
	select 13, 'A_13', 'Baza Contributie Individuala ASIGURARI SOCIALE plafonata' union all
	select 14, 'A_14', 'Contributie Individuala ASIGURARI SOCIALE' union all
	select 8, 'A_20', (case when @versiune=2 then 'Baza Contributie Individuala ASIGURARI SOCIALE neplafonata'	else 'Venit brut realizat' end)

--	sume sectiunea AsiguratB1	
	insert into @tipsume
	select 1, 'B1_1', 'Tip asigurat din punct de vedere al contractului de munca' union all
	select 2, 'B1_2', 'Pensionar' union all
	select 3, 'B1_3', 'Tip contract de munca din punct de vedere al timpului de lucru' union all
	select 4, 'B1_4', 'Ore norma zilnica contract' union all
	select 11, 'B1_5', 'Baza de calcul pentru contributia la fondul de garantare' union all
	select 5, 'B1_6', 'Ore lucrate efectiv in luna' union all	
	select 6, 'B1_7', 'Ore suspendate in luna' union all
	select 7, 'B1_8', 'Din care ore somaj tehnic in luna, beneficiare de scutire' union all
	select 9, 'B1_9', 'Zile somaj tehnic beneficiare de scutire' union all
	select 10, 'B1_10', 'Baza de calcul la contributia Individuala SOMAJ' union all
	select 8, 'B1_15', 'Total zile lucrate'

--	sume sectiunea AsiguratB11
	insert into @tipsume
	select 1, 'B11_1', 'Motiv scutire' union all
	select 2, 'B11_2', 'ANGAJATOR-Suma pentru care se beneficiaza de scutire SOMAJ' union all
	select 3, 'B11_3', 'ANGAJATOR-Suma pentru care se beneficiaza de scutire SANATATE' union all
	select 4, 'B11_41', 'ANGAJATOR-Suma pentru care se beneficiaza de scutire ASIGURARI SOCIALE  SI ASIGURARI PENTRU ACCIDENTE DE MUNCA SI BOLI PROFESIONALE in  conditii normale de munca' union all
	select 5, 'B11_42', 'ANGAJATOR-Suma pentru care se beneficiaza de scutire ASIGURARI SOCIALE  SI ASIGURARI PENTRU ACCIDENTE DE MUNCA SI BOLI PROFESIONALE in  conditii deosebite de munca' union all
	select 6, 'B11_43', 'ANGAJATOR-Suma pentru care se beneficiaza de scutire ASIGURARI SOCIALE  SI ASIGURARI PENTRU ACCIDENTE DE MUNCA SI BOLI PROFESIONALE in  conditii speciale de munca' union all	
	select 7, 'B11_5', 'ASIGURAT-Suma pt. care se beneficiaza de scutire SOMAJ' union all
	select 8, 'B11_6', 'ASIGURAT-Suma pt. care se beneficiaza de scutire SANATATE' union all
	select 9, 'B11_71', 'ASIGURAT-Suma pt. care se beneficiaza de scutire CAS in  conditii normale de munca' union all
	select 10, 'B11_72', 'ASIGURAT-Suma pt. care se beneficiaza de scutire CAS in  conditii deosebite de munca' union all
	select 11, 'B11_73', 'ASIGURAT-Suma pt. care se beneficiaza de scutire CAS in  conditii speciale de munca'

--	sume sectiunea AsiguratB234
	insert into @tipsume
	select 1, 'B2_1', 'Indicativ conditii speciale' union all
	select 2, 'B2_2', 'Zile lucrate �n conditii normale' union all
	select 3, 'B2_3', 'Zile lucrate in conditii deosebite' union all
	select 4, 'B2_4', 'Zile lucrate �n conditii speciale' union all
	select 5, 'B2_5', (case when @versiune=2 then 'Baza Contributie Individuala ASIGURARI SOCIALE neplafonata - conditii normale' else 'Venit brut realizat - conditii normale' end) union all
	select 6, 'B2_6', (case when @versiune=2 then 'Baza Contributie Individuala ASIGURARI SOCIALE neplafonata - conditii deosebite' else 'Venit brut realizat - conditii deosebite' end) union all	
	select 7, 'B2_7', (case when @versiune=2 then 'Baza Contributie Individuala ASIGURARI SOCIALE neplafonata - conditii speciale' else 'Venit brut realizat - conditii speciale' end) union all
	select 1, 'B3_1', 'Zile Indemnizatii in conditii normale' union all
	select 2, 'B3_2', 'Zile Indemnizatii in conditii deosebite' union all
	select 3, 'B3_3', 'Zile Indemnizatii in conditii speciale' union all
	select 6, 'B3_4', 'Zile prestatii suportate din FAAMBP' union all
	select 7, 'B3_5', 'Zile de concediu fara plata indemnizatie pt. cresterea copilului dupa primele 3 nasteri' union all
	select 4, 'B3_6', 'Total zile lucratoare concediu medical (conform O.U.G. 158/2005)' union all
	select 8, 'B3_7', 'Baza de calcul a CAS aferenta indemnizatiilor (conform O.U.G. 158/2005) - asigurat' union all
	select 5, 'B3_8', 'Total zile lucratoare concediu medical pentru accidente de munca' union all
	select 10, 'B3_9', 'Suma prestatii de asigurari sociale suportata din FAAMBP' union all
	select 9, 'B3_10', 'Suma prestatii de asigurari sociale suportata de angajator (conform Legii 346/2002)' union all	
	select 11, 'B3_11', 'Total venit asigurat din indemnizatii/prestatii' union all
	select 12, 'B3_12', 'Total indemnizatie sanatate suportata de angajator (cf.O.U.G.158/2005)' union all
	select 13, 'B3_13', 'Total indemnizatie sanatate suportata din FNUASS' union all
	select 1, 'B4_1', 'Total zile lucrate' union all
	select 2, 'B4_2', 'Total zile somaj tehnic benficiare de scutire' union all
	select 3, 'B4_3', 'Baza Contributie Individuala SOMAJ' union all
	select 4, 'B4_4', 'Contributie Individuala SOMAJ' union all	
	select 5, 'B4_5', 'Baza Contributie Individuala SANATATE' union all
	select 6, 'B4_6', 'Contributie Individuala SANATATE' union all
	select 7, 'B4_7', 'Baza Contributie Individuala ASIGURARI SOCIALE plafonata' union all
	select 8, 'B4_8', 'Contributie Individuala ASIGURARI SOCIALE' union all
	select 9, 'B4_14', 'Baza de calcul pentru contributia la fondul de garantare'

--	sume sectiunea AsiguratB234
	insert into @tipsume
	select 1, 'D_1', 'Seria certificatului de concediu medical' union all
	select 2, 'D_2', 'Numarul certificatului de concediu medical' union all
	select 3, 'D_3', 'Seria certificatului de concediu medical initial' union all
	select 4, 'D_4', 'Numarul certificatului de concediu medical initial' union all
	select 5, 'D_5', 'Data acordarii certificatului medical (zz.ll.aaaa)' union all
	select 6, 'D_6', 'Data inceput valabilitate CM' union all	
	select 7, 'D_7', 'Data incetare valabilitate CM' union all
	select 8, 'D_8', 'Codul numeric personal al copilului' union all
	select 9, 'D_9', 'Codul indemnizatiei notat pe certificatul de concediu medical' union all
	select 10, 'D_10', 'Locul de prescriere a certificatului medical' union all
	select 11, 'D_11', 'Cod urgenta medico-chirurgicala' union all
	select 12, 'D_12', 'Cod boala infectocontagioasa grupa A' union all
	select 13, 'D_13', 'Numarul avizului medicului expert' union all
	select 14, 'D_14', 'Zile prestatii (zile lucratoare) suportate de angajator' union all
	select 15, 'D_15', 'Zile prestatii (zile lucratoare) suportate de FNUASS' union all
	select 16, 'D_16', 'Total Zile prestatii (zile lucratoare) aferente concediului medical' union all
	select 17, 'D_17', 'Suma venituri ultimele 6 luni' union all	
	select 18, 'D_18', 'Numar de zile aferente veniturilor din ultimele 6 luni' union all
	select 19, 'D_19', 'Media zilnica a bazei de calcul' union all
	select 20, 'D_20', 'Indemnizatie sanatate suportata de angajator' union all
	select 21, 'D_21', 'Indemnizatie sanatate suportata din FNUASS'

--	sume sectiunea AsiguratE1
	insert into @tipsume
	select 1, 'E1_1', 'Venit brut' union all
	select 2, 'E1_2', 'Contributii sociale obligatorii' union all
	select 3, 'E1_3', 'Numar persoane aflate in intretinere' union all
	select 4, 'E1_4', 'Deduceri personale' union all
	select 5, 'E1_5', 'Alte deduceri' union all
	select 6, 'E1_6', 'Venit baza de calcul al impozitului' union all	
	select 7, 'E1_7', 'Impozit retinut'

--	sume sectiunea AsiguratE2
	insert into @tipsume
	select 1, 'E2_1', 'Venit brut' union all
	select 2, 'E2_2', 'Contributii sociale obligatorii' union all
	select 3, 'E2_3', 'Venit baza de calcul al impozitului' union all	
	select 4, 'E2_4', 'Impozit retinut'

--	sume sectiunea AsiguratE3
	insert into @tipsume
	select 1, 'E3_1', 'Sectiunea' union all
	select 2, 'E3_2', 'Tip asigurat' union all
	select 3, 'E3_3', 'Functie de baza' union all
	select 4, 'E3_4', 'Tip venit referitor la  perioada de raportare  (P sau A)' union all
	select 5, 'E3_5', 'Perioada venitului din  alta perioada decat cea  de referinta - luna si an inceput' union all
	select 6, 'E3_6', 'Perioada venitului din  alta perioada decat cea  de referinta - luna si an sfarsit' union all	
	select 7, 'E3_7', 'Justif. venitului din alta perioada decat cea de raportare (tip venit referitor la perioada=A).' union all
	select 8, 'E3_8', 'Venit brut' union all
	select 9, 'E3_9', 'Contributii sociale obligatorii' union all
	select 10, 'E3_10', 'Contravaloarea tichetelor de masa' union all
	select 11, 'E3_11', 'Numar persoane aflate in intretinere' union all
	select 12, 'E3_12', 'Deduceri personale' union all
	select 13, 'E3_13', 'Alte deduceri' union all
	select 14, 'E3_14', 'Venit baza de calcul al impozitului' union all
	select 15, 'E3_15', 'Impozit retinut' union all
	select 16, 'E3_16', 'Suma incasata'

	return
end
