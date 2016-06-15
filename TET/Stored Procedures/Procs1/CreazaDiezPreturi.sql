create procedure CreazaDiezPreturi 
AS
	
	IF not exists (select 1 from tempdb..syscolumns sc where sc.id=object_id('tempdb.dbo.#preturi') and sc.NAME = 'umprodus')
		alter table #preturi ADD umprodus varchar(3)

	alter table #preturi 
		add pret_vanzare decimal(12,5), discount decimal(12,5), pret_amanunt decimal(12,5), 
			pret_vanzare_discountat decimal(12,5), pret_amanunt_discountat decimal(12,5), 
			valuta varchar(6),curs decimal(12,5),tipPret char(1),calculat int default 0,pret_vanzare_vechi decimal(12,5),pret_amanunt_vechi decimal(12,5),inpromotie int
	/*
		Tip_pret va fi ca si tip_categorie 
			1 = Pret Vanzare
			2 = Pret cu Amanuntul
		Coloana calculat reprezinta faptul ca un pret a fost calculat sau nu
		Toate update-urile se vor face doar pe cele necalculate
	*/
