--***
/**	functie pt. utilizata pt. generarea formularului de act aditional la contractul de munca */
Create function fActeAditionale 
	(@marca varchar(6), @data datetime, @data_act datetime, @DinAdeverintaVechime int)
returns @aActe_aditionale table
	(marca char(8), numar int, anul char(4), luna char(4), ziua int, nr_act char(10), data_act datetime, datavig_act datetime, modificare char(1000))
as 
Begin
	declare @nLunaInch int, @LunaInchAlfa char(15), @nAnulInch int, @dDataInch datetime

	set @nLunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @nAnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
	set @dDataInch=dbo.eom(convert(datetime,str(@nLunaInch,2)+'/01/'+str(@nAnulInch,4)))

	insert into @aActe_aditionale
	select p.marca, 0 as nr, year(p.data_angajarii_in_unitate) as anul, month(p.data_angajarii_in_unitate) as luna, day(p.data_angajarii_in_unitate) as ziua,
	(case when dbo.iauExtinfopVal(p.Marca,'CNTRITM')='' then ip.Nr_contract else dbo.iauExtinfopVal(p.Marca,'CNTRITM') end),
	(case when dbo.iauExtinfopVal(p.Marca,'CNTRITM')='' then dbo.iauExtinfopData(p.Marca,'DATAINCH') else dbo.iauExtinfopData(p.Marca,'CNTRITM') end), 
	p.Data_angajarii_in_unitate, 'INCHEIERE CIM'
	from personal p 
		left outer join infopers ip on p.marca=ip.marca
	where p.Marca=@marca and @DinAdeverintaVechime=1
	union all
	select  e.Marca, ROW_NUMBER() OVER(ORDER BY e.Marca, e.Data_inf) as nr,
	year(e.Data_inf) as anul, month(e.Data_inf) as luna, day(e.Data_inf) as luna, 
--	am modificat astfel si pt. celelate coduri de informatie sa se considere numarul/data actului aditional inainte de data intrarii in vigoare a modificarii
--	am tratat sa caute numarul si data actului aditional inainte cu cel mult o luna fata de data intrarii in vigoare 
--	si daca nu exista sa caute cu cel mult 21 de zile in fata (termenul de depunere al Revisalului) in raport cu data intrarii in vigoare
	(case when e.Cod_inf='DATAMDCTR' then 
		isnull((select top 1 Val_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='DATAMDCTRA' and e1.Data_inf between DateAdd(month,-1,e.Data_inf) and e.Data_inf order by e1.Data_inf desc),
		isnull((select top 1 Val_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='DATAMDCTRA' and e1.Data_inf between e.Data_inf and DateAdd(day,21,e.Data_inf) order by e1.Data_inf desc),''))
	else 
		isnull((select top 1 Val_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='AA' and e1.Data_inf between DateAdd(month,-1,e.Data_inf) and e.Data_inf order by e1.Data_inf desc),
		isnull((select top 1 Val_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='AA' and e1.Data_inf between e.Data_inf and DateAdd(day,21,e.Data_inf) order by e1.Data_inf desc),'')) end) 
	as Numar_act,
	(case when e.Cod_inf='DATAMDCTR' then 
		isnull((select top 1 Data_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='DATAMDCTRA' and e1.Data_inf between DateAdd(month,-1,e.Data_inf) and e.Data_inf order by e1.Data_inf desc),
		isnull((select top 1 Data_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='DATAMDCTRA' and e1.Data_inf between e.Data_inf and DateAdd(day,21,e.Data_inf) order by e1.Data_inf desc),''))
	else
		isnull((select top 1 Data_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='AA' and e1.Data_inf between DateAdd(month,-1,e.Data_inf) and e.Data_inf order by e1.Data_inf desc),
		isnull((select top 1 Data_inf from extinfop e1 where e1.Marca=e.Marca and e1.Cod_inf='AA' and e1.Data_inf between e.Data_inf and DateAdd(day,21,e.Data_inf) order by e1.Data_inf desc),'')) end) 
	as Data_act,
	e.Data_inf, 
	rtrim(convert(char(3),ROW_NUMBER() OVER (PARTITION by e.Marca ORDER BY e.Marca, e.Data_inf)))+'. '+
	(case when e.Cod_inf='CONDITIIM' then (case when isnull(i1.grupa_de_munca,'')='C' then 'Modificare din contract de munca cu timp partial' else 'Modificare contract din conditii de munca '+
		(case when isnull(i1.grupa_de_munca,'')='N' then 'normale' when isnull(i1.grupa_de_munca,'')='D' then 'deosebite' when isnull(i1.grupa_de_munca,'')='S' then 'speciale' end) end)+' in '+
		(case when rtrim(e.val_inf)='N' then 'conditii de munca normale' when rtrim(e.val_inf)='D' then 'conditii de munca deosebite' 
		when rtrim(e.val_inf)='S' then 'conditii de munca speciale' when rtrim(e.val_inf)='C' then 'contract de munca cu timp partial' end)+'.'
	when e.Cod_inf='DATAMDCTR' then (case when e.Val_inf='D' then 'Trecerea contractului individual de munca la perioada determinata ' else 'Prelungirea contractului individual de munca '+
		(case when e.val_inf='N' then 'pe perioada nedeterminata' 
		else ' pana la data '+(case when e.Data_inf<=@dDataInch then convert(char(10),isnull(i.Data_plec,''),103) 
		else (case when CONVERT(DATETIME,e.val_inf,103)>convert(DATETIME,p.Data_plec,103) then convert(char(10),e.val_inf,103) 
		else convert(char(10),p.Data_plec,103) end) end) end) end)+'.'
	when e.Cod_inf='DATAMRL' then 'Modificarea duratei muncii de la norma de '+isnull((select rtrim(convert(char(10),i.salar_lunar_de_baza)) from istpers i 
		where  i.data = dbo.eom(dateadd(m,-1,e.Data_inf)) and i.marca = e.Marca),'')+' ore/zi la norma de '+rtrim(convert(char(10),e.Procent))+' ore/zi.'
	when e.Cod_inf='DATAMFCT' then 'Modificare functie din '+
		isnull((select rtrim(f.denumire) from istpers i, functii f where i.cod_functie = f.cod_functie and i.data = dbo.eom(dateadd(m,-1,e.Data_inf)) and i.marca = e.Marca),'')+' cod COR '+
		isnull((select rtrim(fc.cod_functie) from functii_COR fc, istpers i, extinfop e1 where i.cod_functie = e1.marca and e1.Cod_inf='#CODCOR' 
			and i.data = dbo.eom(dateadd(m,-1,e.Data_inf)) and i.marca = e.Marca and e1.val_inf = fc.Cod_functie),'')
		+' in '+isnull((select rtrim(f.denumire) from functii f, extinfop e2 where e2.cod_inf = 'DATAMFCT' and month(e2.data_inf) = month(e.Data_inf) 
			and year(e2.data_inf) = year(e.Data_inf) and e2.marca = e.Marca and e2.val_inf = f.cod_functie),'')+
		' cod COR '+isnull((select rtrim(fc.cod_functie) from functii_COR fc, extinfop e3 where fc.cod_functie = e3.Val_inf and e3.Marca = e.Val_inf and e3.Cod_inf='#CODCOR'),'')+'.'
	when e.Cod_inf='DATAMLM' then 'Modificare loc de munca din '+isnull((select i.loc_de_munca 
		from istpers i where  i.data = dbo.eom(dateadd(m,-1,e.Data_inf)) and i.marca = e.Marca),'')+' in '+rtrim(e.val_inf)+'.'
	when e.Cod_inf='SALAR' then 'Modificarea salariului brut de incadrare de la '+
		isnull((select rtrim(convert(char(10),i.salar_de_incadrare)) from istpers i where  i.data = dbo.eom(dateadd(m,-1,e.Data_inf)) 
			and i.marca = e.Marca),0)+' lei la '+rtrim((case when e.Procent=0 then e.Val_inf else convert(char(10),e.Procent) end))+'.'
	else '' end) as modificare
	from extinfop e
		left outer join catinfop c on e.cod_inf = c.cod
		left outer join personal p on e.Marca=p.Marca
		left outer join istpers i on i.Marca=e.Marca and i.Data=dbo.EOM(e.Data_inf)
		left outer join istpers i1 on i1.Marca=e.Marca and i1.Data=dbo.eom(dateadd(m,-1,e.Data_inf))
	where (e.cod_inf in ('CONDITIIM','DATAMDCTR','DATAMRL','DATAMFCT','DATAMLM','SALAR') 
			or @DinAdeverintaVechime=1 and e.Cod_inf='AACONT' and not exists (select 1 from extinfop e1 
				where e1.Marca=e.Marca and e1.Cod_inf in ('CONDITIIM','DATAMDCTR','DATAMRL','DATAMFCT','DATAMLM','SALAR')))
		and (@marca='' and e.Data_inf=@data_act or e.marca = @marca)
		and (@DinAdeverintaVechime=1 or month(e.data_inf) = month(@data) and year(e.data_inf) = year(@data))
		and (e.val_inf != '' or e.procent != 0)
         
	return
End
