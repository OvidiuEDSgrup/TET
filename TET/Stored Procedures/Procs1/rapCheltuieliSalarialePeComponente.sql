/**	procedura pentru rapoartele web Cheltuieli salariale pe componente .... */
/*
	@desfpeliniicoloane=1	= rapoartele Cheltuieli salariale pe componente desfasurat pe linii.rdl, Cheltuieli salariale pe componente desfasurat pe coloane.rdl fara grupare
	@desfpeliniicoloane=0	= raportul Cheltuieli salariale pe componente.rdl cu grupare
*/
Create procedure rapCheltuieliSalarialePeComponente
	(@dataJos datetime, @dataSus datetime, @locm varchar(9)=null, @strict int=0, @comanda varchar(20)=null, @componenta varchar(100)=null, @cont varchar(13)=null, 
	@desfpeliniicoloane int=0, @nudoarconturicl6 int, @ordonare int, @centralizat int) 
as
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#pozncon') is not null drop table #pozncon

	declare @sub varchar(9), @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @sub=dbo.iauParA('GE','SUBPRO')
	SET @utilizator = dbo.fIaUtilizator('')
	IF @utilizator IS NULL
		RETURN -1

--	pune datele in tabela temporara filtrate si daca e cazul grupate
	select subunitate, tip, numar, data, cont_debitor, loc_munca, comanda, sum(suma) as suma, explicatii, (case when @desfpeliniicoloane=1 then Nr_pozitie else '' end) as Nr_pozitie 
	into #pozncon
	from pozncon 
	where Subunitate=@sub and Tip='PS' and Numar like 'SAL%' and Data between @datajos and @datasus 
		and (@locm is null or Loc_munca like rtrim(@locm)+(case when @strict=1 then '' else  '%' end)) 
		and (@nudoarconturicl6=1 or Cont_debitor like '6%')
		and (@comanda is null or (rtrim(ltrim(@comanda))='' or Comanda = rtrim(ltrim(@comanda))))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=loc_munca))
	group by subunitate, tip, numar, data, cont_debitor, loc_munca, comanda, explicatii, (case when @desfpeliniicoloane=1 then Nr_pozitie else '' end)

	select p.data as data_nc,
	(case when @centralizat=0 or @desfpeliniicoloane=1 then p.cont_debitor else 'Total' end) as cont_debitor, 
	p.loc_munca as lm_nc, rtrim(ltrim(substring(sl.comanda,20,20)))+(case when substring(sl.comanda,20,20)<>'' then ' - ' else '' end)+ rtrim(lm.cod)+' - '+lm.denumire as den_lm_nc, 
	p.comanda as comanda_nc, cc.descriere as den_comanda_nc, sum(p.suma) as suma_nc, max(p.explicatii) as explicatii_nc,
	dbo.eom(c.data) as data_comp, c.loc_de_munca as lm_comp, c.comanda as comanda_comp, c.cont as cont_comp, c.componenta as explicatii_comp, 
	(case when p.comanda='' and c.cont like '641%' then max(c.suma) else sum(c.suma) end) as suma_comp,
	(case when p.comanda='' and c.cont like '641%' then max(c.suma) else isnull(sum(c.suma),sum(p.suma)) end) as suma_calc, 
	(case when c.suma is null then ltrim(rtrim(p.cont_debitor))+'|'+ltrim(rtrim(ct.denumire_cont)) else ltrim(rtrim(p.cont_debitor))+'|'+ltrim(rtrim(c.componenta)) end) as element_filtrare, 
	(case 
		when p.cont_debitor like '641%' then 1
		when p.cont_debitor not like '641%' then 2 
		else 4 end) as ordonare_conturi,
	(case 
		when p.cont_debitor like '641%' and c.componenta like '%manopera%dir%' then 1
		when p.cont_debitor like '641%' and c.componenta not like '%manopera%dir%' then 2
		when p.cont_debitor not like '641%'  then 3
		else 4 end) as ordonare_componente, 
	ct.denumire_cont as den_cont
	from #pozncon p
		left outer join cheltcomp c on dbo.eom(c.data)=p.data and c.cont=p.cont_debitor and c.loc_de_munca=p.loc_munca and c.comanda=p.comanda
		left outer join lm on lm.cod=p.loc_munca
		left outer join comenzi cc on cc.Subunitate=p.Subunitate and cc.comanda=p.comanda
		left outer join speciflm sl on sl.loc_de_munca=lm.cod 
		left outer join conturi ct on ct.Subunitate=p.Subunitate and ct.cont=p.cont_debitor
	where (@componenta is null 
			or (case when c.suma is null then ltrim(rtrim(p.cont_debitor))+'|'+ltrim(rtrim(ct.denumire_cont)) 
				else ltrim(rtrim(p.cont_debitor))+'|'+ltrim(rtrim(c.componenta)) end) = ltrim(rtrim(@componenta)))
		and (@cont is null or p.cont_debitor like rtrim(@cont)+'%') 
	group by p.data, (case when @centralizat=0 or @desfpeliniicoloane=1 then p.cont_debitor else 'Total' end), p.loc_munca, 
		rtrim(ltrim(substring(sl.comanda,20,20)))+(case when substring(sl.comanda,20,20)<>'' then ' - ' else '' end)+ rtrim(lm.cod)+' - '+lm.denumire, 
		p.comanda, cc.descriere, dbo.eom(c.data), c.loc_de_munca, c.comanda, c.cont, c.componenta,
		(case when c.suma is null then ltrim(rtrim(p.cont_debitor))+'|'+ltrim(rtrim(ct.denumire_cont)) else ltrim(rtrim(p.cont_debitor))+'|'+ltrim(rtrim(c.componenta)) end), 
		(case 
			when p.cont_debitor like '641%' then 1
			when p.cont_debitor not like '641%'  then 2
			else 4 end),
		(case 
			when p.cont_debitor like '641%' and c.componenta like '%manopera%dir%' then 1
			when p.cont_debitor like '641%' and c.componenta not like '%manopera%dir%' then 2
			when p.cont_debitor not like '641%'  then 3
			else 4 end), 
		ct.denumire_cont,
		(case when @desfpeliniicoloane=1 then p.Nr_pozitie else '' end)
	order by (case when @ordonare=1 then p.loc_munca else p.comanda end), (case when @ordonare=2 then p.loc_munca else p.comanda end)
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapCheltuieliSalarialePeComponente (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#pozncon') is not null drop table #pozncon
