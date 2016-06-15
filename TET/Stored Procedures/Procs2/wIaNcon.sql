--***
create procedure wIaNcon @sesiune varchar(50), @parXML xml
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaNconSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wIaNconSP @sesiune, @parXML output
	return @returnValue
end
declare @Sub char(9),@iDoc int, @utilizator varchar(20),@mesaj varchar(200), @explicatii varchar(400)
begin try
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	exec sp_xml_preparedocument @iDoc output, @parXML

	select top 100 
		rtrim(d.subunitate) as subunitate, 
		rtrim(d.tip) as tip, 
		rtrim(d.numar) as numar, 
		convert(char(10),d.data,101) as data, 
		max(convert(decimal(14, 2), d.valoare)) as valoare,  
		max(convert(int, d.nr_pozitii)) as numarpozitii, 
		MAX(rtrim(p.explicatii)) as explicatii,  
		MAX(rtrim(l.denumire)) as denlm, 
		MAX(rtrim(c.descriere)) as dencomanda, 
		MAX(rtrim(t.denumire)) as dentert, 
		(case when d.tip='NC' then 0 else 1 end) as _nemodificabil, 
		(CASE when max(d.Valoare) <= 0 then'#FF0000' when d.tip='NC' then'#000000' else '#808080' end) as culoare
	from ncon d
		cross join OPENXML(@iDoc, '/row')
		WITH
		(
			tip varchar(2) '@tip'
			,numar varchar(20) '@numar'
			,data_jos datetime '@datajos'
			,data_sus datetime '@datasus'
			,data datetime '@data' 
			,ftip varchar(2) '@f_tip'
			,fnumar varchar(20) '@f_numar'
			,flm varchar(20) '@f_lm'
			,fcomanda varchar(20) '@f_comanda'
			,valoare_minima float '@valoarejos'
			,valoare_maxima float '@valoaresus'	
			,explicatii varchar(400) '@f_explicatii'	
		) as fx 
		left outer join pozncon p on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data
		left outer join lm l on l.Cod=p.Loc_munca 
		left outer join comenzi c on c.Subunitate=d.Subunitate and c.Comanda=left(p.Comanda,20) 
		left outer join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert 
	where d.subunitate=@Sub --and d.tip = 'NC' 
		and d.numar like isnull(fx.numar, '') + '%' 
		--and d.tip like isnull(fx.tip, '') + '%' 
		and d.data between isnull(fx.data_jos, '01/01/1901') and (case when isnull(fx.data_sus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.data_sus end)
		and (isnull(p.Loc_munca,'') like ISNULL(fx.flm,'')+'%' or isnull(l.Denumire,'') like '%'+ISNULL(fx.flm,'')+'%')
		and (isnull(left(p.comanda,20),'') like ISNULL(fx.fcomanda,'')+'%' )
		and (fx.data is null or d.data=fx.data)
		and d.valoare between isnull(fx.valoare_minima, -99999999999) and isnull(fx.valoare_maxima, 99999999999)
		--and d.tip in ('NC') 
		and d.tip like isnull(fx.ftip, '') + '%'
		and d.numar like isnull(fx.fnumar, '') + '%'
		and (dbo.f_areLMFiltru(@utilizator) =0 or exists(select (1) from LMFiltrare pr
			where pr.utilizator=@utilizator and pr.cod=p.Loc_munca)) 
		and (NULLIF(fx.explicatii,'') is null or p.explicatii like '%'+replace(fx.explicatii,' ','%')+'%')
	group by d.Subunitate, d.Tip, d.Numar, d.Data 
	order by d.data desc 
	for xml raw

	exec sp_xml_removedocument @iDoc 
end try
begin catch
	set @mesaj = '(wIaNcon)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
