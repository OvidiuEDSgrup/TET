--***
/**	functie Contributii Legea 118	*/
Create
function  fPSContributiiL118 (@DataJ datetime, @DataS datetime, @MarcaJ char(6), @MarcaS char(6), @LocmJ char(9), 
@LocmS char(9)) 
returns @ContributiiL118 table (Data datetime, Marca char(6), Loc_de_munca char(9), Valoare_diminuare decimal(10), 
Baza_CAS decimal(10), CAS decimal(10,2), Baza_somaj decimal(10), Somaj decimal(10,2), Baza_CASS decimal(10), CASS decimal(10,2), Baza_CCI decimal(10), CCI decimal(10,2), Baza_FG decimal(10), Fond_garantare decimal(10,2), Baza_Fambp decimal(10), 
Fambp decimal(10,2), Baza_ITM decimal(10), Itm decimal(10,2))
as
begin
insert @ContributiiL118
select n.Data, n.Marca, c.Loc_de_munca, -c.Suma_corectie as Valoare_diminuare, 
(case when CAS<>0 then -c.Suma_corectie else 0 end) as Baza_CAS, CAS, 
(case when Somaj_5<>0 then -c.Suma_corectie else 0 end) as Baza_somaj, Somaj_5, 
(case when Asig_sanatate_pl_unitate<>0 then -c.Suma_corectie else 0 end) as Baza_CASS, Asig_sanatate_pl_unitate, 
(case when Ded_suplim<>0 then -c.Suma_corectie else 0 end) as Baza_CCI, Ded_suplim, 
(case when Chelt_prof<>0 then -c.Suma_corectie else 0 end) as Baza_FG, Chelt_prof, 
(case when Fond_de_risc_1<>0 then -c.Suma_corectie else 0 end) as Baza_Fambp, Fond_de_risc_1, 
(case when Camera_de_munca_1<>0 then -c.Suma_corectie else 0 end) as Baza_ITM, Camera_de_munca_1
from net n
left outer join corectii c on c.Data=dbo.bom(n.Data) and c.Marca=n.Marca
where n.data between @DataJ and @DataS and n.data=DateAdd(day,1,dbo.bom(n.data)) 
and (@MarcaJ='' or n.Marca between @MarcaJ and @MarcaS) 
and (@LocmJ='' or n.Loc_de_munca between @LocmJ and @LocmS)
return
end
