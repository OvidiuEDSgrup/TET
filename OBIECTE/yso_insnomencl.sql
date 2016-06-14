drop trigger yso_insnomencl
go
create trigger yso_insnomencl on nomencl instead of insert as

INSERT INTO nomencl
	(Cod
	,Tip
	,Denumire
	,UM
	,UM_1
	,Coeficient_conversie_1
	,UM_2
	,Coeficient_conversie_2
	,Cont
	,Grupa
	,Valuta
	,Pret_in_valuta
	,Pret_stoc
	,Pret_vanzare
	,Pret_cu_amanuntul
	,Cota_TVA
	,Stoc_limita
	,Stoc
	,Greutate_specifica
	,Furnizor
	,Loc_de_munca
	,Gestiune
	,Categorie
	,Tip_echipament)
SELECT 
	Cod
	,Tip
	,Denumire
	,UM
	,UM_1
	,Coeficient_conversie_1
	,UM_2
	,Coeficient_conversie_2
	,Cont
	,Grupa
	,Valuta
	,Pret_in_valuta
	,Pret_stoc
	,Pret_vanzare
	,Pret_cu_amanuntul
	,Cota_TVA
	,Stoc_limita
	,Stoc
	,Greutate_specifica
	,Furnizor
	,RTRIM(cod)
	,Gestiune
	,Categorie
	,Tip_echipament
  FROM inserted

