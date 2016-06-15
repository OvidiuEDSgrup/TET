--***
/** procedura pt. citire date din tabela obiective **/
Create procedure wRUIaObiective @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaObiectiveSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaObiectiveSP @sesiune, @parXML output
	return @returnValue
end

declare @filtruLm varchar(30), @filtruTip varchar(30), @filtruCategorie varchar(30), 
	@filtruAn int, @utilizator char(10), @mesaj varchar(200), @doc xml
begin try
	select
		@filtruLm = isnull(@parXML.value('(/row/@f_denlm)[1]', 'varchar(50)'), ''),
		@filtruTip = isnull(@parXML.value('(/row/@f_tipob)[1]', 'varchar(30)'), ''),
		@filtruCategorie = isnull(@parXML.value('(/row/@f_categorie)[1]', 'varchar(30)'), ''),
		@filtruAn = @parXML.value('(/row/@f_an)[1]', 'int')
	select @filtruLm = replace(@filtruLm,' ','%'), 
		@filtruTip = replace(@filtruTip,' ','%'), 
		@filtruCategorie = replace(@filtruCategorie,' ','%')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

set @doc=
	(
	select top 100 rtrim(o.ID_obiectiv) as id_obiectiv, rtrim(o.Denumire) as grupare, 
		rtrim(o.Denumire) as denumire, rtrim(o.Categorie) as categorie,
		(case when o.Categorie='1' then 'Companie' when o.Categorie='2' then 'Departament' when o.Categorie='3' then 'Individual' else '' end) as den_categorie,
		rtrim(o.Tip_obiectiv) as tip_obiectiv, (case when o.Tip_obiectiv='1' then 'Dezvoltare' when o.Tip_obiectiv='2' then 'Invatare' end) as den_tip_obiectiv,
		rtrim(o.ID_obiectiv_parinte) as id_obiectiv_parinte, rtrim(o1.Denumire) as den_obiectiv_parinte, 
		rtrim(o.Loc_de_munca) as lm, rtrim(isnull(lm.Denumire,'')) as denlm, 
		CONVERT(char(10),o.Data_inceput,101) as data_inceput, CONVERT(char(10),o.Data_sfarsit,101) as data_sfarsit, 
		convert(char(4),year(o.Data_sfarsit)) as an, 
		rtrim(o.Actiuni_realizare) as actiuni_realizare, rtrim(o.Actiuni_dezvoltare) as actiuni_dezvoltare, 
		rtrim(o.Rezultate) as rezultate, 
		dbo.wfRUIaObiectiveCopii(o.ID_obiectiv)
	from RU_obiective o 
		left outer join RU_obiective o1 on o.ID_obiectiv_parinte=o1.ID_obiectiv
		left outer join lm on o.Loc_de_munca=lm.Cod
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and o.Loc_de_munca=lu.cod
	where o.Categorie='1' and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)	
		and	isnull(lm.Denumire,'') like '%' + @filtruLm + '%'
		and (@filtruAn is null or year(o.Data_sfarsit)=@filtruAn)
		and (case when o.Categorie='1' then 'Companie' when o.Categorie='2' then 'Departament' when o.Categorie='3' then 'Individual' else '' end) like '%' + @filtruCategorie + '%'
		and (case when o.Tip_obiectiv='1' then 'Dezvoltare' when o.Tip_obiectiv='2' then 'Invatare' end) like '%' + @filtruTip + '%'
	order by convert(char(4),year(o.Data_sfarsit)), o.ID_obiectiv
	for xml raw,root('Ierarhie'),type
	)
	
	if @doc is not null
		set @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')	
	
	select @doc for xml path('Date')

end try

begin catch
	set @mesaj = '(wRUIaObiective) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
