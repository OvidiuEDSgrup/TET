--***
Create procedure wIaCuantumDiurne @sesiune varchar(50), @parXML xml
as
begin try
	Declare @userASiS varchar(20), @filtruSalariat varchar(13), @filtruTara varchar(30), @filtruValuta varchar(30), @mesaj varchar(1000), @multiFirma int

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT 
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1
	
	set @filtruSalariat = isnull(@parXML.value('(/row/@f_salariat)[1]','varchar(6)'),'')
	set @filtruTara = isnull(@parXML.value('(/row/@f_tara)[1]','varchar(20)'),'')
	set @filtruValuta = isnull(@parXML.value('(/row/@f_valuta)[1]','varchar(20)'),'')
	set @filtruSalariat = Replace(@filtruSalariat,' ','%')    
 
	select top 100 rtrim(cd.loc_de_munca) as lm, rtrim(lm.denumire) as denlm, rtrim(cd.marca) as marca, rtrim(p.nume) as densalariat, 
		convert(varchar(10),cd.data_inceput,101) as datainceput, rtrim(cd.tara) as tara, rtrim(t.denumire) as dentara, rtrim(cd.Valuta) as valuta, 
		convert(decimal(12,2),cd.diurna) as diurna, convert(decimal(12,2),cd.diurna_neimpozabila) as diurnaneimp, cd.detalii as detalii, idPozitie 
	from CuantumDiurne cd   
		left outer join personal p on p.Marca=cd.Marca
		left outer join lm on lm.Cod=cd.Loc_de_munca
		left outer join tari t on cd.Tara=t.Cod_tara
		left outer join valuta v on v.Valuta=cd.Tara
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=cd.loc_de_munca
	where (@filtruSalariat='' or cd.Marca like @filtruSalariat+'%' or p.Nume like '%'+@filtruSalariat+'%') 
		and (@filtruTara='' or cd.Tara like '%'+@filtruTara+'%' or t.denumire like '%'+@filtruTara+'%')
		and (@filtruValuta='' or cd.Valuta like @filtruValuta+'%')
		and (@multiFirma=0 or dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	order by cd.data_inceput desc
	for xml raw
end try

begin catch
	set @mesaj =ERROR_MESSAGE()+' (wIaCuantumDiurne)'
	raiserror(@mesaj,11,1)
end catch
