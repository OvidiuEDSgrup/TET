--***
/**Functia este folosita de procedura wRUIaObiective pentru a genera obiectivele ierarhic*/
Create function wfRUIaObiectiveCopii (@IDObiectivParinte int)
returns XML
Begin
	declare @doc xml
	
	return
	(
	select top 100 rtrim(o.ID_obiectiv) as id_obiectiv, rtrim(o.Denumire) as grupare, 
		rtrim(o.Denumire) as denumire, rtrim(o.Categorie) as categorie,
		(case when o.Categorie='1' then 'Companie' when o.Categorie='2' then 'Departament' when o.Categorie='3' then 'Individual' else '' end) as den_categorie,
		rtrim(o.Tip_obiectiv) as tip_obiectiv, (case when o.Tip_obiectiv='1' then 'Dezvoltare' when o.Tip_obiectiv='2' then 'Invatare' end) as den_tip_obiectiv,
		rtrim(o.ID_obiectiv_parinte) as id_obiectiv_parinte, rtrim(o1.Denumire) as den_obiectiv_parinte, 
		rtrim(o.Loc_de_munca) as lm, rtrim(isnull(lm.Denumire,'')) as denlm, 
		CONVERT(char(10),o.Data_inceput,101) as data_inceput, CONVERT(char(10),o.Data_sfarsit,101) as data_sfarsit, 
		convert(int,year(o.Data_sfarsit)) as an, 
		rtrim(o.Actiuni_realizare) as actiuni_realizare, rtrim(o.Actiuni_dezvoltare) as actiuni_dezvoltare, 
		rtrim(o.Rezultate) as rezultate, 
		dbo.wfRUIaObiectiveCopii(o.ID_obiectiv)
	from RU_obiective o 
		left outer join RU_obiective o1 on o.ID_obiectiv_parinte=o1.ID_obiectiv
		left outer join lm on o.Loc_de_munca=lm.Cod
	where o.ID_obiectiv_parinte=@IDObiectivParinte

	for xml raw
	)

end

