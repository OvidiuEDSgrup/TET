--***
Create procedure wRUIaOrganigrama @sesiune varchar(50), @parXML xml
as  

declare @filtruFunctie varchar(30), @filtruLm varchar(30), @doc xml, @nLunaInch int, @LunaInchAlfa char(15), @nAnulInch int, @dDataInch datetime

select
	@filtruFunctie = isnull(@parXML.value('(/row/@f_functie)[1]', 'varchar(50)'), ''),
	@filtruLm = isnull(@parXML.value('(/row/@f_denlm)[1]', 'varchar(30)'), '')
	
	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dateadd(month,1,convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))

	select @filtruFunctie = replace(@filtruFunctie,' ','%'), 
		@filtruLm = replace(@filtruLm,' ','%')

set @doc=
	(
		select 
			o.ID_organigrama as id_organigrama, rtrim(o.Cod_functie) as codfunctie, rtrim(f.Denumire) as denfunctie, 
			rtrim(o.Cod_functie_parinte) as codfunctieparinte, rtrim(isnull(fp.denumire, '')) as denfunctieparinte, 
			o.ID_nivel as id_nivel, ni.Nivel_organigrama as nivel, rtrim(ni.Descriere) as descrierenivel, 
			o.Numar_posturi as nrposturi, o.Ordine_stat as ordinestat, 
			isnull((select count(1) from personal p where p.Cod_functie=o.Cod_functie and (CONVERT(int,p.loc_ramas_vacant)=0 or p.Data_plec>=@dDataInch)),0) as nrsal,
			convert(char(10),o.Data_inceput,101) as data_inceput, convert(char(10),o.Data_sfarsit,101) as data_sfarsit, 
			rtrim(lm.Denumire) as denlm, 
			dbo.wfRUIaOrganigramacopii(o.Cod_functie)
		from RU_organigrama o
			left outer join functii f on f.Cod_functie=o.Cod_functie
			left outer join functii fp on fp.Cod_functie=o.Cod_functie_parinte
			left outer join RU_nivele_organigrama ni on ni.ID_nivel=o.ID_nivel
			left outer join proprietati p on p.Tip='FUNCTII' and p.Cod=f.Cod_functie and p.Cod_proprietate='LM' and p.Valoare<>''
			left outer join lm on lm.Cod=p.Valoare
		where ni.Nivel_organigrama='1' 
			and	f.Denumire like '%' + @filtruFunctie + '%'
			and isnull(lm.Denumire,'') like '%' + @filtruLm + '%'
		order by 1
		for xml raw,root('Ierarhie'),type
	)

	if @doc is not null
		set @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')	
	
	select @doc for xml path('Date')
/*
#start populare
OG
C, OG, OG
Organigrama
#sfarsit populare
*/
