--***
create procedure wIaUtilaje @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaUtilajeSP' and type='P')      
	exec wIaUtilajeSP @sesiune,@parXML      
else      
begin
set transaction isolation level READ UNCOMMITTED

declare	@codMasina varchar(20), @tipMasina varchar(20), @nrInmatriculare varchar(15), @cSub varchar(13),
@denumire varchar(40), @nrInventar varchar(13), @grupa varchar(3), @lm varchar(9), @comanda varchar(20)

select 
	@cSub=ISNULL(@parXML.value('(/row/@cSub)[1]', 'varchar(13)'), '1'), 
	@codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), ''), 
	@tipMasina=REPLACE(ISNULL(@parXML.value('(/row/@tipMasina)[1]', 'varchar(20)'), ''), ' ', '%') ,
	@nrInmatriculare=REPLACE(ISNULL(@parXML.value('(/row/@nrInmatriculare)[1]', 'varchar(15)'), ''), ' ', '%'), 
	@denumire=REPLACE(ISNULL(@parXML.value('(/row/@denumire)[1]', 'varchar(40)'), ''), ' ', '%'), 
	@nrInventar=REPLACE(ISNULL(@parXML.value('(/row/@nrInventar)[1]', 'varchar(13)'), ''), ' ', '%'), 
	@grupa=REPLACE(ISNULL(@parXML.value('(/row/@grupa)[1]', 'varchar(3)'), ''), ' ', '%'),
	@lm=REPLACE(ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(9)'), ''), ' ', '%'),
	@comanda=REPLACE(ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(9)'), ''), ' ', '%')

	select top 100 
	rtrim(m.cod_masina) as codMasina, RTRIM(t.Denumire) as tip_masina, RTRIM(m.nr_inmatriculare) as nr_inmatriculare,
	RTRIM(m.denumire) as denumire, RTRIM(m.nr_inventar) as nr_inventar, RTRIM(m.loc_de_munca) as lm, 
	RTRIM(lm.Denumire) as den_lm, RTRIM(m.Comanda) as comanda, RTRIM(c.Descriere) as den_comanda, 
	rtrim(m.grupa) as grupa, rtrim(g.denumire) as denGrupa, 
	ltrim(str(CO.Valoare,12,2)) as CO, ltrim(str(cRezervor.Valoare,12,2)) as cRezervor, ltrim(str(cVara.Valoare,12,2)) as cVara, 
	ltrim(str(cIarna.Valoare,12,2)) as cIarna,
	-- elemtnte urmarite
	isnull((select top 1 ltrim(str(valoare,12,2)) from elemactivitati ea inner join activitati a on a.Tip=ea.Tip and a.Fisa=ea.Fisa and a.Data=ea.Data 
	  where a.Masina=m.cod_masina and ea.Element='RESTESTU' order by ea.Data desc, ea.Fisa desc, ea.Numar_pozitie desc),0) as RESTESTU,
	isnull((select top 1 ltrim(str(valoare,12,2)) from elemactivitati ea inner join activitati a on a.Tip=ea.Tip and a.Fisa=ea.Fisa and a.Data=ea.Data 
	  where a.Masina=m.cod_masina and ea.Element='OREBORD' order by ea.Data desc, ea.Fisa desc, ea.Numar_pozitie desc),0) as OREBORD,
	-- elemente implementare
	isnull((select ltrim(str(max(valoare),12,2)) from valelemimpl v where v.Masina=m.cod_masina and v.Element='OREBORD'),0) as OREBORDImpl,
	isnull((select ltrim(str(max(valoare),12,2)) from valelemimpl v where v.Masina=m.cod_masina and v.Element='RestDecl'),0) as RestDeclImpl
	from masini m
	left outer join grupemasini g on g.grupa=m.grupa
	inner join tipmasini t on g.tip_masina=t.Cod
	left outer join lm on m.loc_de_munca = lm.Cod
	left outer join comenzi c on c.Subunitate=@cSub and c.Comanda=m.Comanda
	left outer join coefmasini CO on CO.Masina=m.cod_masina and CO.Coeficient='CO'
	left outer join coefmasini cRezervor on cRezervor.Masina=m.cod_masina and cRezervor.Coeficient='cRezervor'
	left outer join coefmasini cVara on cVara.Masina=m.cod_masina and cVara.Coeficient='cVara'
	left outer join coefmasini cIarna on cIarna.Masina=m.cod_masina and cIarna.Coeficient='cIarna'	
	where t.Tip_activitate='L'
	and (@codMasina='' or m.cod_masina like'%'+@codMasina+'%')
	and (@tipMasina='' or t.Denumire like '%'+@tipMasina+'%')
	and (@denumire='' or m.denumire like '%'+@denumire+'%')
	and (@nrInventar='' or m.nr_inventar like '%'+@nrInventar+'%')
	and (@grupa='' or m.grupa like '%'+@grupa+'%')
	and (@lm='' or lm.Denumire like '%'+@lm+'%')
	and (@comanda='' or c.Descriere like '%'+@comanda+'%')
	order by patindex('%'+@denumire+'%',m.denumire),1
	
	for xml raw      
end

