--***
create procedure wIaActivitati @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaActivitatiSP' and type='P')      
	exec wIaActivitatiSP @sesiune,@parXML      
else 

begin
declare	@tip varchar(2), @fisa varchar(10), @f_fisa varchar(10), @data datetime, @data_jos datetime, @data_sus datetime, 
	@cSub varchar(13), @f_masina varchar(20), @masina varchar(20),
	@comanda varchar(20), @lm varchar(9), @comanda_benef varchar(20), @lm_benef varchar(9), @nume_marca varchar(13)

select 
	@cSub=ISNULL(@parXML.value('(/row/@cSub)[1]', 'varchar(13)'), '1'), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'),''),
	@fisa=ISNULL(@parXML.value('(/row/@fisa)[1]', 'varchar(10)'), ''), 
	@f_fisa=REPLACE(ISNULL(@parXML.value('(/row/@f_fisa)[1]', 'varchar(10)'), ''), ' ', '%'), 
	@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),
	@data_jos=ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1901'),
	@data_sus=ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), '01/01/2099'),
	@masina=ISNULL(@parXML.value('(/row/@masina)[1]', 'varchar(20)'), ''), 
	@f_masina=REPLACE(ISNULL(@parXML.value('(/row/@f_masina)[1]', 'varchar(20)'), ''), ' ', '%'), 
	@comanda=REPLACE(ISNULL(@parXML.value('(/row/@f_comanda)[1]', 'varchar(20)'), ''), ' ', '%'), 
	@lm=REPLACE(ISNULL(@parXML.value('(/row/@f_lm)[1]', 'varchar(9)'), ''), ' ', '%'),
	@comanda_benef=REPLACE(ISNULL(@parXML.value('(/row/@f_comanda_benef)[1]', 'varchar(20)'), ''), ' ', '%'),	
	@lm_benef=REPLACE(ISNULL(@parXML.value('(/row/@f_lmbenef)[1]', 'varchar(9)'), ''), ' ', '%'),
	@nume_marca=REPLACE(ISNULL(@parXML.value('(/row/@nume_marca)[1]', 'varchar(13)'), ''), ' ', '%')
if @data<>'01/01/1901' -- chemat din pozitii document
begin
	set @data_jos=@data
	set @data_sus=@data
end
	
select top 100
	a.idActivitati,
	RTRIM(a.Tip) as tip,
	RTRIM(a.Fisa) as fisa, 
	convert(char(10),a.data,101) as data, 
	rtrim(a.Masina) as masina,
	RTRIM(m.denumire) as den_masina, 
	RTRIM(g.tip_masina) as tip_masina,
	rtrim(tm.Denumire) as den_tip_masina,
	RTRIM(a.Comanda) as comanda,
	RTRIM(isnull(c.Descriere,'')) as den_comanda, 
	RTRIM(a.Loc_de_munca) as lm,
	RTRIM(isnull(locm.Denumire,'')) as den_lm, 
	RTRIM(a.lm_benef) as lm_benef,
	RTRIM(isnull(lm_benef.Denumire,'')) as den_lm_benef, 
	RTRIM(a.Tert) as tert, 
	RTRIM(isnull(t.Denumire,'')) as den_tert, 
	RTRIM(a.Marca) as marca, 
	RTRIM(ISNULL(p.Nume,'')) as nume_marca,
	(select COUNT(1) from pozactivitati pa
			where a.tip=pa.tip and a.fisa=pa.fisa and a.data=pa.data) as nrpozitii,
	convert(decimal(10,2),isnull(
			(select top 1 ea.valoare from elemactivitati ea 
					inner join pozactivitati pa 
							on ea.Tip=pa.Tip and ea.Fisa=pa.Fisa and ea.Data=pa.Data and ea.Numar_pozitie=pa.Numar_pozitie
				where a.tip=ea.tip and a.fisa=ea.fisa and a.data=ea.data 
				and ea.Element='KmBord' order by pa.Data_plecarii desc, pa.Ora_plecarii desc, ea.numar_pozitie DESC),
			isnull((select v.valoare from valelemimpl v where v.masina=a.Masina and v.element='KmBord'), 0))) as 'KmBord',
	convert(decimal(10,2),isnull(
			(select top 1 ea.valoare from elemactivitati ea
					inner join pozactivitati pa 
							on ea.Tip=pa.Tip and ea.Fisa=pa.Fisa and ea.Data=pa.Data and ea.Numar_pozitie=pa.Numar_pozitie
				where a.tip=ea.tip and a.fisa=ea.fisa and a.data=ea.data 
				and ea.Element='RestEst' order by pa.Data_plecarii desc, pa.Ora_plecarii desc, ea.numar_pozitie DESC), 
		    isnull((select v.valoare from valelemimpl v
				where v.masina=a.Masina and v.element='RestEst'), 0))) as 'RestEst',
	convert(decimal(10,2),isnull(
			(select top 1 ea.valoare from elemactivitati ea
					inner join pozactivitati pa 
							on ea.Tip=pa.Tip and ea.Fisa=pa.Fisa and ea.Data=pa.Data and ea.Numar_pozitie=pa.Numar_pozitie
				where a.tip=ea.tip and a.fisa=ea.fisa and a.data=ea.data 
				and ea.Element='OREBORD' order by pa.Data_plecarii desc, pa.Ora_plecarii desc, ea.numar_pozitie DESC), 
			isnull((select v.valoare from valelemimpl v where v.masina=a.Masina and v.element='OREBORD'), 0))) as 'OREBORD',
	convert(decimal(10,2),isnull(
			(select top 1 ea.valoare from elemactivitati ea
					inner join pozactivitati pa 
							on ea.Tip=pa.Tip and ea.Fisa=pa.Fisa and ea.Data=pa.Data and ea.Numar_pozitie=pa.Numar_pozitie
				where a.tip=ea.tip and a.fisa=ea.fisa and a.data=ea.data 
				and ea.Element='RESTESTU' 
				order by pa.Data_plecarii desc, pa.Ora_plecarii desc, ea.numar_pozitie DESC), 	
			isnull((select v.valoare from valelemimpl v where v.masina=a.Masina and v.element='RESTESTU'), 0))) as 'RESTESTU'	
	from activitati a
		inner join masini m on a.Masina=m.cod_masina
		inner join grupemasini g on g.Grupa=m.grupa
		inner join tipmasini tm on tm.Cod=g.tip_masina
		left outer join comenzi c on c.Subunitate=@cSub and a.Comanda=c.Comanda
		left outer join lm locm on locm.Cod=a.Loc_de_munca
		left outer join lm lm_benef on lm_benef.Cod=a.lm_benef
		left outer join terti t on t.Subunitate=@cSub and t.Tert=a.Tert
		left outer join personal p on p.Marca=a.Marca	
			where (a.Tip = @tip or @tip='MA')
			and (@fisa='' or a.Fisa=@fisa)	
			and a.Fisa like '%'+@f_fisa+'%'	
	        and a.Data between @data_jos and @data_sus
			and (@masina='' or a.masina=@masina)
			and (m.denumire like '%'+@f_masina+'%' or a.masina like @f_masina+'%')
			and isnull(c.Descriere,'') like '%'+@comanda+'%'
			and isnull(locm.Denumire,'') like '%'+@lm+'%'
			and isnull(lm_benef.Denumire,'') like '%'+@lm_benef+'%'
			and isnull(p.Nume,'') like '%'+@nume_marca+'%'
		order by patindex('%'+@fisa+'%',a.Fisa),1
for xml raw      

end
