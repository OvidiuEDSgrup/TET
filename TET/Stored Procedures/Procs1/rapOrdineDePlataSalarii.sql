--***
Create procedure rapOrdineDePlataSalarii @idOP int, @afisareDateEmiterii int=0
as
begin try
	set transaction isolation level read uncommitted

	declare @sub varchar(9), @utilizator varchar(20),  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
		@denunit VARCHAR(100), @adresa VARCHAR(100), @strada VARCHAR(100), @numar VARCHAR(100), @bloc varchar(10), @scara VARCHAR(10), @apartament VARCHAR(10), 
		@sector int, @codfisc VARCHAR(100), @judet varchar(100), @localit varchar(100), 
		@contbanca VARCHAR(100), @codBIC VARCHAR(100), @banca varchar(100), @separator varchar(10), @nrevidenta varchar(100)
	set @utilizator = dbo.fIaUtilizator(null) 
	
	select	@sub=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @sub end),
			@denunit=(case when parametru='NUME' then rtrim(val_alfanumerica) else @denunit end),
			@codfisc=(case when parametru='CODFISC' then rtrim(val_alfanumerica) else @codfisc end),
			@judet=(case when parametru='JUDET' then rtrim(val_alfanumerica) else @judet end),
			@localit=(case when parametru='LOCALIT' then rtrim(val_alfanumerica) else @localit end),
			@strada=(case when parametru='STRADA' then rtrim(val_alfanumerica) else @strada end),
			@numar=(case when parametru='NUMAR' then rtrim(val_alfanumerica) else @numar end),
			@bloc=(case when parametru='BLOC' then rtrim(val_alfanumerica) else @bloc end),
			@scara=(case when parametru='SCARA' then rtrim(val_alfanumerica) else @scara end),
			@apartament=(case when parametru='APARTAM' then rtrim(val_alfanumerica) else @apartament end),
			@sector=(case when parametru='SECTOR' then rtrim(val_numerica) else @sector end),
			@contBanca=(case when parametru='CONTBC' then rtrim(val_alfanumerica) else @contBanca end),
			@codBIC=(case when parametru='CODBIC' then rtrim(val_alfanumerica) else @codBIC end),
			@banca=(case when parametru='BANCA' then rtrim(val_alfanumerica) else @banca end)
	from par
	where Tip_parametru='GE' and Parametru in ('SUBPRO','NUME','CODFISC','ADRESA','JUDET','SEDIU','CONTBC','CODBIC','BANCA')
		or Tip_parametru='PS' and Parametru in ('STRADA','NUMAR','BLOC','SCARA','APARTAM','LOCALIT','SECTOR')

	set @adresa=(case when @localit<>'' then ' loc. ' else '' end)+rtrim(@localit)
			+(case when @strada<>'' then ' str. ' else '' end)+rtrim(@strada)+(case when @numar<>'' then ' nr. ' else '' end)+rtrim(@numar)
			+(case when @bloc<>'' then ' bl. ' else '' end)+rtrim(@bloc)+(case when @scara<>'' then ' sc. ' else '' end)+rtrim(@scara)
			+(case when @apartament<>'' then ' ap. ' else '' end)+rtrim(@apartament)
			+(case when @sector<>0 then ' sector '+rtrim(convert(varchar(10),@sector)) else '' end)
			+(case when @judet<>'' then ' jud. ' else '' end)+rtrim(@judet)

	set @separator='%23'	-- in loc de #
--	numarul de evidenta al platii este momentan suspendat (nu trebuie completat pentru ordine de plata/foi de varsamint). 
--	la ordine de plata ar trebui doar la Decizii de impunere si Procese verbale constatare contraventii. Nu e cazul nostru. Asta am primit pe email de la ANAF.
	set @nrevidenta=''

	select po.idPozOP, o.cont_contabil, isnull(po.detalii.value('/row[1]/@nrop', 'varchar(20)'),'') as nrop, @denunit as platitor, 
--	am inlocuit datele de pe tert cu cele din parametrii (de la Angajatorul am inteles ca tot timpul la platitor trebuie sa apara datele unitatii).
--		rtrim(isnull(t.detalii.value('/row[1]/@cifop', 'varchar(20)'),t.cod_fiscal)) as cifplatitor, 
		@codfisc as cifplatitor, 
--		rtrim((case when t.Cod_fiscal<>@codfisc then t.Adresa else @adresa end)) as adresaplatitor, 
		@adresa as adresaplatitor, 
		rtrim(isnull(c.detalii.value('/row[1]/@codiban', 'varchar(50)'),@contBanca)) as codibanplatitor, 
		rtrim(isnull(c.detalii.value('/row[1]/@codbic', 'varchar(50)'),@codBIC)) as codbicplatitor, 
		rtrim(isnull(c.detalii.value('/row[1]/@banca', 'varchar(100)'),@banca)) as bancaplatitor,
		rtrim(t.Denumire) as beneficiar, rtrim(isnull(t.detalii.value('/row[1]/@cifop', 'varchar(20)'),t.cod_fiscal)) as cifbeneficiar,	rtrim(t.Cont_in_banca) as codibanbeneficiar, 
		isnull(t.detalii.value('/row[1]/@codbic', 'varchar(20)'),'TREZROBU') codbicbeneficiar, 
		'Trezorerie operativa Municipiul '+rtrim(isnull(l.oras,t.Localitate)) as bancabeneficiar, 
		po.explicatii as explicatii, (case when @afisareDateEmiterii=1 then convert(char(10),o.Data,103) else '' end) as dataemiterii, 
		suma as suma, dbo.Nr2Text (suma)  as sumalitere, 'N' as tiptransfer, 
		convert(varchar(max),'') as codbara
	into #OP
	from PozOrdineDePlata po
		left outer join OrdineDePlata o on o.idOP=po.idOP
		left outer join terti t on t.Subunitate=@sub and t.Tert=po.tert
		left outer join conturi c on c.Subunitate=@sub and c.Cont=o.cont_contabil
		left outer join localitati l on l.cod_oras=t.Localitate
	where po.idOP=@idOP and po.suma<>0

	update #OP set codbara=@separator+rtrim(nrop)+@separator+','+rtrim(convert(varchar(20),(case when round(suma,0) = suma then round(suma,0) else suma end)))+','
			+@separator+rtrim(platitor)+@separator+','+rtrim(cifplatitor)+','+@separator+rtrim(adresaplatitor)+@separator+','
			+@separator+(case when left(cont_contabil,4)='5311' then '' else rtrim(codibanplatitor) end)+@separator+','
			+@separator+(case when left(cont_contabil,4)='5311' then '' else rtrim(codbicplatitor) end)+@separator+','
			+@separator+rtrim(beneficiar)+@separator+','+rtrim(rtrim(cifbeneficiar))+','+@separator+rtrim(codibanbeneficiar)+@separator+','+@separator+rtrim(codbicbeneficiar)
			+@separator+','+rtrim(@nrevidenta)+','+@separator+rtrim(explicatii)+@separator+','+rtrim(dataemiterii)

	select idPozOP, nrop, platitor, cifplatitor, adresaplatitor, codibanplatitor, codbicplatitor, bancaplatitor,
		beneficiar, cifbeneficiar,	codibanbeneficiar, codbicbeneficiar, bancabeneficiar, 
		explicatii, dataemiterii, suma, sumalitere, tiptransfer, codbara
	from #OP

end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapOrdineDePlataSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapOrdineDePlataSalarii @dataJos='05/01/2013', @dataSus='05/31/2013'
*/
