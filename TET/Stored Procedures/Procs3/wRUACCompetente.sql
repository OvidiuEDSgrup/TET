/** procedura pentru auto-complete competente **/
--***
Create procedure wRUACCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUACCompetenteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUACCompetenteSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @lista_lm int, @searchText varchar(80), @tip varchar(2), @codMeniu varchar(2), @id_evaluat int, @codfunctie char(6), @id_domeniu int, @mesaj varchar(200)

begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@codMeniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''),
		@id_evaluat=ISNULL(@parXML.value('(/row/@id_evaluat)[1]', 'int'), ''),
		@id_domeniu=ISNULL(@parXML.value('(/row/@id_domeniu)[1]', 'int'), 0),
		@codfunctie=ISNULL(@parXML.value('(/row/linie/@cod)[1]', 'char(6)'), '') 
	set @searchText=REPLACE(@searchText, ' ', '%')
	
	select c.ID_competenta as cod, rtrim(c.Denumire) as denumire, 
		'Tip: '+rtrim((case when rtrim(c.tip_competenta)='1' then '1-TEHNICA' when rtrim(c.tip_competenta)='2' then '2-MANAGERIALA' else '3-GENERALA' end))+' Domeniu: '+RTRIM(d.Denumire) as info
	from RU_competente c
		left outer join RU_domenii d on d.ID_domeniu=c.ID_domeniu
	where (c.ID_competenta like @searchText + '%' or c.Descriere like '%' + @searchText + '%' or c.Denumire like '%' + @searchText + '%')
		and (@id_domeniu=0 or c.ID_domeniu=@id_domeniu)
--	filtrez dupa Domeniu atasat locurilor de munca care s-au definit ca proprietate LOCMUNCA a utilizatorului
		and (@lista_lm=0 or c.ID_domeniu in (select Valoare from proprietati where tip='LM' and Cod_proprietate='DOMENIU' 
		and Cod in (select Cod from LMFiltrare lu where lu.utilizator=@utilizator)))
--	daca tip=FC -> filtrez dupa Domeniul atasat locului de munca de care apartine functia pe care se face atasarea competentelor 
		and (@tip<>'FC' or c.ID_domeniu in 
		(select distinct pd.Valoare from functii f 
			left outer join proprietati pd on pd.tip='FUNCTII' and pd.Cod=f.Cod_functie and pd.Cod_proprietate='DOMENIU' and pd.Valoare<>''
		where f.Cod_functie=@codfunctie) 
--	daca FC atunci filtrez doar competentele tata (cele care nu au ID competenta parinte)
		and isnull(c.ID_competenta_parinte,0)=0)
--	daca codMeniu=EV -> filtrez dupa Domeniul atasat locului de munca de care apartine evaluatul
		and (@codMeniu<>'EV' or c.ID_domeniu in 
		(select distinct pd.Valoare from RU_persoane p 
			left outer join proprietati pd on pd.tip='FUNCTII' and pD.Cod=p.Cod_functie and pD.Cod_proprietate='DOMENIU' and pd.Valoare<>''
		where p.ID_pers=@id_evaluat))
	order by c.ID_competenta
	for xml raw
end try
begin catch
	set @mesaj = '(wRUACCompetente) '+ERROR_MESSAGE()
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	

