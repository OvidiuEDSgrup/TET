--***
create function fIaInterventii (@sesiune varchar(50),@parXML XML)
--(@datajos datetime, @datasus datetime, @pMasina varchar(20), @pElement varchar(20))
returns @interventii table (masina varchar(20), den_masina varchar(40), nr_inmatriculare varchar(20), element varchar(20),
		denumire varchar(60), tip varchar(50), fisa varchar(20), data datetime, km decimal(20,2), 
		explicatii varchar(200), tipInterval varchar(50), tipMasina varchar(50), bord decimal(20,2), scadenta smallint)
as
begin

--set transaction isolation level READ UNCOMMITTED
if exists(select * from sysobjects where name='fIaInterventiiSP')
	insert into @interventii(masina, den_masina, nr_inmatriculare, element,
		denumire, tip, fisa, data, km, 
		explicatii, um, scadenta)
	select masina, den_masina, nr_inmatriculare, element,
		denumire, tip, fisa, data, km, 
		explicatii, um, scadenta
		from dbo.fIaInterventiiSP(@sesiune,@parXML)

declare @eroare varchar(1000),  @pMasina varchar(20), @pElement varchar(20), @datajos datetime, @datasus datetime, @den_masina varchar(50),
		@codMasina varchar(40), @tipinterventii varchar(50), @cautare varchar(200), @denumire varchar(100), @fltElement varchar(100),
		@tipMasina varchar(100), @dinMacheta int, 
		@recomandate varchar(20),	--> recomandate: 0=toate, 1=scadente, 2=nescadente
		@eliminScadenteIncluse smallint		-->	@eliminScadenteIncluse: 0=nu, 1= se vor elimina interventiile scadente care sunt incluse in alte interventii scadente
set @eroare=''

begin
	/*	--tst	pt teste
	declare @pMasina varchar(20), @pElement varchar(20), @datajos datetime, @datasus datetime
	select @datajos='2011-1-1',@datasus='2011-8-31', @pMasina='1'--,@pElement='casco'
		-- precedenta: select * from fisamasina(@datajos, @datasus, @pMasina, @pElement,null)
	--*/
	---------------------------------------
	declare @primazimasina datetime	--< data de la care se incepe calculul estimarilor recomandarilor, daca nu exista suficiente date pentru estimari (cel putin doua orebord sau kmbord in elemactivitati pe masina)
	select @primazimasina='1901-1-1'	--< este nevoie de o discutie aici (?)
	/*dateadd(M,1,
	convert(datetime,
	convert(varchar(4),(select max(val_numerica) from par where par.Parametru='ANULIMPL' and Tip_parametru='GE'))+'-'+
	convert(varchar(2),(select max(val_numerica) from par where par.Parametru='LUNAIMPL' and Tip_parametru='GE'))+'-1')
	)*/

	select 
	@pElement=REPLACE(ISNULL(@parXML.value('(/row/@element)[1]', 'varchar(40)'), ''), ' ', '%'), 
	@den_masina=REPLACE(ISNULL(@parXML.value('(/row/@den_masina)[1]', 'varchar(40)'), ''), ' ', '%'),
	@codMasina=REPLACE(ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(40)'), ''), ' ', '%'),
	@datajos=isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'),'1901-1-1'),
	@datasus=isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'),'2100-1-1'),
	@tipinterventii=isnull(@parXML.value('(/row/@tipinterventii)[1]', 'varchar(50)'),''),
	@cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(50)'),''),
	@denumire=isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'),''),
	@fltElement=replace(isnull(@parXML.value('(/row/@fltElement)[1]', 'varchar(100)'),''),' ','%'),
	@tipMasina=replace(isnull(@parXML.value('(/row/@tipMasina)[1]', 'varchar(100)'),''),' ','%'),
	@dinMacheta=(case when isnull(@parXML.value('(/row/@tip)[1]', 'varchar(100)'),'')='' then 0 else 1 end),
	@recomandate=isnull(@parXML.value('(/row/@recomandate)[1]', 'varchar(20)'),'0'),
	@eliminScadenteIncluse=isnull(@parXML.value('(/row/@eliminScadenteIncluse)[1]', 'smallint'),1)
	
	if (@dinMacheta=1) set @codMasina=rtrim(@codMasina)+'%'
	if (len(@cautare)=1 or @cautare like 'Recomand%' or @cautare like 'Efectuat%')
	begin
		set @tipinterventii=@cautare
		set @cautare=''
	end
	select @recomandate=(case when @recomandate='scadente' then '1' when @recomandate='nescadente' then '2' when @recomandate='' then '0' else @recomandate end)
	set @tipinterventii=left(@tipinterventii,1)				--> tipinterventii E/R/<toate>
	declare @efectuate table(masina varchar(50), nr_inmatriculare varchar(50), element varchar(50),
		denumire varchar(200), tip varchar(1), fisa varchar(20), data datetime, km decimal(20,2), 
		ultima int, valoare decimal(20,2), explicatii varchar(1000),um2 varchar(10), data_ultima datetime,
		um varchar(10), numar_pozitie int, tip_activitate varchar(20))
/**	selectare informatii masini si filtrare, pe cat posibil*/
	declare @masini table(cod_masina varchar(20), denumire varchar(100), grupa varchar(10), numeGrupa varchar(100), tip_masina varchar(20), numeTip varchar(100),
			tip_activitate varchar(10), nr_inmatriculare varchar(20), bord int Primary key clustered(cod_masina))

	declare @element_km varchar(20), @element_ore varchar(20)
	--select @element_km='Kmef', @element_ore='OL'
	select @element_km='Kmbord', @element_ore='OREBORD,ORENOU'
	
	insert into @masini (cod_masina, denumire, grupa, numeGrupa, tip_masina, numeTip, tip_activitate, nr_inmatriculare, bord)
	select m.cod_masina, max(m.denumire), max(m.grupa), max(g.Denumire) as nume_grupa, max(g.tip_masina) as tip_masina, max(t.Denumire) as numeTip, max(t.tip_activitate), max(m.nr_inmatriculare),
			max(ea.valoare)
	from masini m left join grupemasini g on m.grupa=g.Grupa
			left join tipmasini t on g.tip_masina=t.Cod
			left join dbo.BordMM(null,null) ea on ea.masina=m.cod_masina
/*			left join elemactivitati ea on ea.Data=a.Data and ea.Tip=a.Tip and ea.Fisa=a.Fisa 
					and (t.tip_activitate='P' and ea.Element=@element_km or t.tip_activitate='L' and CHARINDEX(rtrim(ea.Element),@element_ore)<>0)*/
	where	(@den_masina='' or m.denumire like'%'+@den_masina+'%')
			and (@codMasina='' or m.cod_masina like @codMasina)
			and (@denumire='' or m.denumire like'%'+@denumire+'%')
			and (@tipMasina='' or t.Denumire like '%'+replace(@tipMasina,' ','%')+'%')
	group by cod_masina
/**	interventii efecutate; se foloseste si pentru a calcula interventiile recomandate */
	insert into @efectuate (masina, nr_inmatriculare, element,
		denumire, tip, fisa, data, km,
		ultima, valoare, explicatii, um2, data_ultima, um, numar_pozitie, tip_activitate)
	select m.cod_masina masina, m.nr_inmatriculare, e.cod element, e.denumire, 
	left(a.tip,1) tip, 
	convert(varchar(20),ea.fisa), ea.data, --dbo.kmbord(m.cod_masina, ea.data, ea.fisa, ea.numar_pozitie) 
	convert(decimal(20,2),isnull(eb.Valoare,0)) km,
	row_number() over (partition by m.cod_masina, e.cod order by ea.data desc) as ultima,
	c.Interval as valoare, pa.Explicatii explicatii, e.UM2, ea.data as data_ultima, e.UM,
	ea.numar_pozitie, m.tip_activitate
	from @masini m
		inner join activitati a on m.cod_masina=a.masina
		inner join pozactivitati pa on /*pa.Tip=a.Tip and pa.Fisa=a.Fisa and pa.Data=a.Data*/ a.idActivitati=pa.idActivitati
		inner join elemactivitati ea on /*a.fisa=ea.fisa and a.data=ea.data and a.tip=ea.tip and pa.Numar_pozitie=ea.Numar_pozitie*/ pa.idPozActivitati=ea.idPozActivitati
		inner join elemactivitati eb on /*ea.fisa=eb.fisa and ea.data=eb.data and ea.Tip=eb.Tip and ea.Numar_pozitie=eb.Numar_pozitie*/	ea.idPozActivitati=eb.idPozActivitati
					and (m.tip_activitate='P' and eb.Element=@element_km or m.tip_activitate='L' and CHARINDEX(rtrim(eb.Element),@element_ore)<>0)
		inner join elemente e on e.cod=ea.element
		inner join elemtipm et on m.tip_masina=et.tip_masina and et.element=e.cod
		left join coefmasini c on c.Masina=m.cod_masina and e.Cod=c.Coeficient
	where (isnull(@pMasina, '')='' or rtrim(m.cod_masina)=@pMasina)
		and (@den_masina='' or m.denumire like'%'+@den_masina+'%')
		and (isnull(@pElement, '')='' or e.cod=@pElement) and e.tip='I'
		and a.tip in ('FI') -- ce tipuri de interventii mai sunt?
		
	-- se marcheaza ultimele interventii efectuate 
/**	interventii efecutate si recomandate */
	declare @tinterventii table(masina varchar(20), nr_inmatriculare varchar(20), element varchar(20),	--> tabela cu interventii
		denumire varchar(60), tip varchar(1), fisa varchar(20), data datetime, km decimal(20,2), 
		--ultima int, valoare decimal(20,2), 
		explicatii varchar(100),
		um2 varchar(3), data_ultima datetime, km_ultimi decimal(20,2),	--> data_ultima, km_ultimi retin valorile anterioare (efectuate) pentru recomandare
		um varchar(3), scadentaInclusa smallint)	-->	scadentaInclusa semnaleaza care interventii scadente sunt incluse in alte interventii scadente (si ar trebui eliminate)
	
	declare @uinterventii table(masina varchar(20), nr_inmatriculare varchar(20), element varchar(20),	--> tabela cu structura similara cu @tinterventii, care va contine ultimele interventii efectuate
		denumire varchar(60), tip varchar(1), fisa varchar(20), data datetime, km decimal(20,2), 
		--ultima int, valoare decimal(20,2), 
		explicatii varchar(100),
		um2 varchar(3), data_ultima datetime, km_ultimi decimal(20,2),
		um varchar(3), rang int
		)	--> data_ultima, km_ultimi retin valorile anterioare (efectuate) pentru recomandare
	
	declare @rinterventii table(masina varchar(20), nr_inmatriculare varchar(20), element varchar(20),	--> tabela cu structura similara cu @tinterventii, care va contine recomandari
		denumire varchar(60), tip varchar(1), fisa varchar(20), data datetime, km decimal(20,2), 
		--ultima int, valoare decimal(20,2), 
		explicatii varchar(100),
		um2 varchar(3), data_ultima datetime, km_ultimi decimal(20,2),
		um varchar(3), ordine int,  tip_activitate varchar(1), scadenta smallint)	--> data_ultima, km_ultimi retin valorile anterioare (efectuate) pentru recomandare
	insert into @tinterventii(masina, nr_inmatriculare, element,
			denumire, tip, fisa, data, km,
			explicatii, um2, data_ultima, km_ultimi, um, scadentaInclusa)
		select e.masina, e.nr_inmatriculare, e.element, e.denumire, 
				convert(varchar(20),e.tip), convert(varchar(20),e.fisa),  e.data, e.km, e.explicatii, 
					e.UM2, data as data_ultima, isnull(km,0) as km_ultimi, e.UM, 0
		from @efectuate e where e.data between @datajos and @datasus
	--> partea de generare recomandari	
	if (@tipinterventii<>'E')
	begin
	--set @codMasina=@codMasina
		insert into @uinterventii(masina, nr_inmatriculare, element,
			denumire, tip, fisa, data, km,
			explicatii, um2, data_ultima, km_ultimi, um, rang)
		select e.masina, e.nr_inmatriculare, isnull(ci.elCorespondent,e.element), e.denumire, 
				convert(varchar(20),e.tip), convert(varchar(20),e.fisa),  e.data, e.km, e.explicatii, 
					e.UM2, data as data_ultima, isnull(km,0) as km_ultimi, e.UM,
				dense_rank() over (partition by e.masina,isnull(ci.elCorespondent,e.element)
									order by e.km desc, c.interval desc)
		from @efectuate e left join corespondenteInterventii ci on e.element=ci.elReparatie
			left join coefmasini c on c.Masina=e.masina and c.Coeficient=isnull(ci.ElCorespondent,e.element)
		where e.ultima=1

		insert into @rinterventii(masina, nr_inmatriculare, element,
			denumire, tip, fisa, data, km,
			explicatii, um2, data_ultima, km_ultimi, um, ordine, tip_activitate, scadenta)
		select m.cod_masina, m.nr_inmatriculare, e.cod, e.denumire, 
				'R' tip,'<Recomandare>' Fisa
				--,(case when e.um2<>'D' then e.Interval+isnull(i.km,0) else 0 end)
				,(case when i.data is not null and e.um2='D' then dateadd(M,c.Interval,i.data) 
						else '1901-1-1' end) data,
				(case when e.um2<>'D' then c.Interval+isnull(i.km,0) else 0 end) km, 
				'' explicatii, e.UM2, i.data as data_ultima, isnull(i.km,0) as km_ultimi, e.UM,0, m.tip_activitate,
				(case when e.um2<>'D' and isnull(i.km,0)+c.Interval<m.bord or e.um2='D' and dateadd(M,c.Interval,i.data)<getdate() then 1 else 0 end) scadenta
		from @uinterventii i
			inner join @masini m on m.cod_masina=i.masina and i.rang=1
			inner join coefmasini c on c.Masina=m.cod_masina
			inner join elemente e on e.Cod=c.Coeficient and e.cod=i.element
		where e.tip='I'
				
		declare @scadente_de_sters table(rang int, masina varchar(20), element varchar(20))
		insert into @scadente_de_sters (rang, masina, element)
		select dense_rank() over (partition by i.masina order by cf.interval desc), i.masina, c.ElCorespondent from @rinterventii i inner join corespondenteInterventii c on i.element=c.ElReparatie
				inner join coefmasini cf on cf.Masina=i.masina and cf.Coeficient=c.ElCorespondent
		where i.scadenta=1
		
		update r set scadenta=(case when s.rang>1 then 2 else 1 end) from @rinterventii r inner join @scadente_de_sters s on r.element=s.element and r.masina=s.masina and r.scadenta=1
		if @eliminScadenteIncluse=1	delete @rinterventii where scadenta>1
	/**	calcul date estimative (luni daca se masoara in kilometri, kilometri daca se masoara in luni)
			Fie K= numar de kilometri (efectivi) parcursi in total de masina
				L= intervalul (in luni) in care au fost parcursi K
					- L se calculeaza prin diferenta (in zile) max(pozactivitati.data_sosirii)-min(pozactivitati.data_plecarii) din dreptul elem 'KmEf',
						inmultit cu 12 (luni pe an) si impartit la 365 de zile (impartire cu rezultat cu zecimale)
			
			Pentru elemente masurate in luni (UM2='D') - se cunoaste LC=numar luni - se pot afla kilometri estimati KE dupa formula
				KE=(LC*K)/L
				
			Pentru elemente masurate in kilometri (UM2='A') - se cunoaste KC=numar kilometri - se pot afla zilele estimate LE dupa formula	
				LE=(KC*L)/K
	*/
	--	delete from @rinterventii where data>@datasus
		
		--> calcule date/km estimativi pentru recomandari:
		declare @statistica table(masina varchar(20), element varchar(20), val_max decimal(20,2),
					val_min decimal(20,2), val_sum decimal(20,2), data_max datetime,
					data_min datetime, zile int)
		insert into @statistica(masina, element, val_max, val_min, val_sum, data_max, data_min,
					zile)
		select a.masina, ea.element, max(ea.valoare) as val_max, min(ea.valoare) as val_min,
			sum(ea.valoare) as val_sum,
				max(pa.data) as data_max, min (pa.data) as data_min,
				datediff(d,min(pa.Data),max(pa.Data)) zile
		from elemactivitati ea
			inner join activitati a on ea.Fisa=a.Fisa and ea.Tip=a.Tip
			inner join pozactivitati pa on ea.Fisa=pa.Fisa and ea.Tip=pa.Tip
				and ea.Numar_pozitie=pa.Numar_pozitie and pa.Data_plecarii>'1901-1-1'
			inner join @masini m on m.cod_masina=a.Masina
				and (m.Tip_activitate='P' and ea.element like @element_km or m.Tip_activitate='L' and ea.element like @element_ore)
		group by ea.element, a.masina

		declare @date_estimate table(element varchar(20), UM2A bit, masina varchar(20),	--> daca se inlocuieste UM2 de tip varchar cu UMA de tip bit (si conditiile corespunzator) se castiga un pic de performanta
					km_estimati decimal(20,2), zile_estimate decimal(20,2), data_ultima datetime,
					km_ultimi decimal(20,2))
		insert into @date_estimate (element ,UM2A ,masina, km_estimati, zile_estimate, data_ultima,
					km_ultimi)
		select e.Cod as element,(case when e.um2='A' then 1 else 0 end) UM2A, a.masina,
			(case when a.zile=0 or e.UM2<>'D' then 0 else
			(a.val_max*c.interval)/
				(convert(float,a.zile*12)/365) end) as km_estimati,
			(case when convert(float,a.val_max)=0 or e.UM2<>'A' then 0 else
				(convert(float,c.interval)*
					convert(float,a.zile))
				/convert(float,(case when a.val_max=a.val_min then 1
						else a.val_max-a.val_min end)) end) as zile_estimate, 
			a.Data_max as data_ultima, 
			a.val_max as km_ultimi 
		from @statistica a
		inner join coefmasini c on c.Masina=a.Masina
		inner join elemente e on c.Coeficient=e.Cod
--		inner join @masini m on m.cod_masina=a.Masina
		where --(m.Tip_activitate='P' and a.element like @element_km or m.Tip_activitate='L' and a.element like @element_ore) and
			e.UM2 in ('D','A')
		--group by ea.element, a.masina, e.Cod
		--/*
		update @date_estimate set
			km_estimati=km_ultimi+round(km_estimati,0),
			zile_estimate=round((case when zile_estimate>10000 then 10000 else zile_estimate end),3)

		--/*		
		update i set	i.km=(case when e.UM2A=0 then e.km_estimati
									--when e.km_ultimi>i.km then e.km_ultimi
									else i.km end),
						i.Data=(case when e.UM2A=1 then dateadd(d,e.zile_estimate,i.data_ultima) else i.Data end)
		from @rinterventii i
		inner join @date_estimate e on i.masina=e.Masina and i.element=e.element
			--and i.tip='R' --*/
		--*/--*/--*/--*/--*/
	end
	insert into @tinterventii(masina, nr_inmatriculare, element,
			denumire, tip, fisa, data, km,
			explicatii, um2, data_ultima, km_ultimi, um, scadentaInclusa)
	select r.masina, r.nr_inmatriculare, r.element,
			max(r.denumire), 'R' tip, max(r.fisa), max(r.data), max(r.km),
			max(r.explicatii), max(r.um2), max(r.data_ultima), max(r.km_ultimi), max(r.um), max(r.scadenta--case when r.scadenta>1 then 1 else 0 end
			)
		from @rinterventii r left join @masini m on r.masina=m.cod_masina
		where @recomandate='0' or (@recomandate='2' and (r.um2='A' and r.km>=m.bord or r.um2='D' and data>=getdate()))
				or (@recomandate='1' and (r.um2='A' and r.km<m.bord or r.um2='D' and data<getdate()))
		group by r.masina, r.nr_inmatriculare, r.element--, r.tip

/**	select-ul final */
	insert into @interventii(masina, den_masina, nr_inmatriculare,
		element, denumire, tip, fisa, data, km,
		explicatii, tipInterval, tipMasina, bord, scadenta)
    select
		rtrim(i.masina) as masina,
		RTRIM(m.denumire) as den_masina,
		rtrim(i.masina) as nr_inmatriculare,
		rtrim(i.element) as element,
		rtrim(i.denumire) as denumire,
		i.tip,
		rtrim(convert(varchar(20),i.fisa)) as fisa,
		i.data as data,
		rtrim(i.km)as km,
		rtrim(i.explicatii) explicatii, 
		i.um2 as tipInterval,
		rtrim(m.numeTip) as tipMasina,
		m.bord, i.scadentaInclusa
    from @tinterventii i--where tip<>'R' or data>=@datajos
		inner join @masini m on m.cod_masina=i.masina
	 where ((@fltElement='' or i.denumire like '%'+@fltElement+'%') or (@fltElement='' or i.element like '%'+@fltElement+'%'))
		 and (@tipinterventii not in ('E','R') or @tipinterventii='E' and tip<>'R' or @tipinterventii=tip)
		 and (@cautare='' or convert(varchar(20),fisa)=@cautare or element like @cautare+'%')
	order by i.tip, i.km--,i.data, data_ultima, i.masina, i.element, i.fisa	
	return
end
end
