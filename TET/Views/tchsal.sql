/* view de cheltuieli salariale*/
create view dbo.tchsal as
select year(a.Data) as Anul, month(a.Data) as Luna, a.Marca, b.nume, a.Loc_de_munca, a.VENIT_TOTAL as Venit, 
a.Pensie_suplimentara_3 as CAS_indiv, a.Somaj_1 as Somaj_1, a.Impozit as Impozit, 
a.Somaj_5 as Somaj_5, a.Fond_de_risc_1 as Fonduri, a.Camera_de_Munca_1 as Camera_de_munca, a.Asig_sanatate_pl_unitate as Asigurari_unitate, 
a.Asig_sanatate_din_impozit+a.Asig_sanatate_din_net+a.Asig_sanatate_din_CAS as As_sanatate, a.CAS,
isnull((select Ind_c_medical_CAS+CMCAS from brut where marca=a.marca and Loc_de_munca=a.Loc_de_munca and year(data) =year(a.data)  and month(data)=month(a.data)),0) as CM_CAS, 
isnull((select Ind_c_medical_unitate+CMunitate from brut where marca=a.marca and Loc_de_munca=a.Loc_de_munca and year(data) =year(a.data)  and month(data)=month(a.data)),0) as CM_unit 
from net a, personal b
where a.marca=b.marca
