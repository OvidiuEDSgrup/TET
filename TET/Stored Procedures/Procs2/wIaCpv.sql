--***
create procedure wIaCpv (@sesiune varchar(50) = null, @parxml xml = null)
as
declare @eroare varchar(2000)
select @eroare=''
begin try
	if object_id('tempdb..#c') is not null drop table #c
	if object_id('tempdb..#cpv_fltdiacritice') is not null drop table #cpv_fltdiacritice
	
	declare	@top varchar(20), @topint int, @ierarhie varchar(20)
		,@denumire varchar(500), @cod varchar(500)
		,@desfasurare varchar(20), @cunomenclator varchar(1)
		,@infmin varchar(20)
	select	@top=isnull(@parxml.value('(row/@top)[1]','varchar(500)'),'nimic'),
			@ierarhie=isnull(@parxml.value('(row/@ierarhie)[1]','varchar(500)'),'N'),
			@denumire=replace(replace(@parxml.value('(row/@denumire)[1]','varchar(500)'),'â','a'),'î','i'),
			@cod=@parxml.value('(row/@cod)[1]','varchar(500)'),
			@cunomenclator=isnull(@parxml.value('(row/@cunomenclator)[1]','varchar(500)'),''),
			@desfasurare=isnull(@parxml.value('(row/@desfasurare)[1]','varchar(500)'),'N'),
			@infmin=isnull(@parxml.value('(row/@infmin)[1]','varchar(20)'),'N'),
			@topint=100
	
	select @infmin=(case when left(@infmin,1) in ('D','1') then 1 else 0 end)
		--> daca sunt completate filtre incompatibile cu ierarhia se trece automat pe modul lista
	select @ierarhie=(case when left(@ierarhie,1) in ('D','1') and @top='nimic' and @infmin=0 then 1 else 0 end)
	
	--> tratare top
	begin try	--> pt ca isnumeric nu e suficient pt a determina ca e int facem try catch
		select @topint=convert(int, @top)
	end try
	begin catch
		select @topint=100
	end catch
	
	--> tratare desfasurare
	select @desfasurare=(case when left(@desfasurare,1) in ('D','1') then 10 else '0' end)

	
	--> tratare @cunomenclator
	select @cunomenclator=(case left(@cunomenclator,1) when '' then '' when 'D' then '1' else '0' end)
	
	select @denumire='%'+replace(@denumire,' ','%')+'%',
		@cod=@cod+'%'
	
	--> pt ca planul de executie e [!@$@#%$#@^%] sunt nevoit sa recurg la o copie a tabelei cpv pentru filtrarea pe denumire care sa mearga bine si pt diacritice; cazul pt care ar merge rau varianta directa este:
					-->   exec wiacpv @parxml='<row denumire='pastai' ierarhie='da'/>'
	select *, replace(replace(convert(varchar(500),c.denumire),'â','a'),'î','i') denumireptfiltrare into #cpv_fltdiacritice from cpv c
	
	declare @comanda_str nvarchar(max)
	select @comanda_str=''
		--> deoarece planul de executie e foarte gresit scriu dinamic restul:
	select @comanda_str=@comanda_str+'
	select c.id, c.idparinte, c.cod, c.denumire, row_number() over (order by c.cod) as ordine--, pret, departament, codcas
			, "#000000" culoare
			, denumireptfiltrare
			--> flag de filtrare: daca randul corespunde filtrarilor va avea valoarea 1 altfel 0
				--> e nevoie de asta in loc sa se filtreze propriu-zis pentru a se putea crea ierarhia
			, 1 as filtrat
	into #c
	from #cpv_fltdiacritice c'

	if @denumire is not null
	select @comanda_str=@comanda_str+'	
		update #c set filtrat=filtrat*(case when denumireptfiltrare like @denumire then 1 else 0 end)'
	
	if @cod is not null
	select @comanda_str=@comanda_str+'
		update #c set filtrat=filtrat*(case when cod like @cod then 1 else 0 end)'
	
	if @infmin=1
	select @comanda_str=@comanda_str+'
		update #c set filtrat=filtrat*(case when not exists (select 1 from cpv f where #c.id=f.idparinte) then 1 else 0 end)'
	
	if @cunomenclator ='1'
	select @comanda_str=@comanda_str+'
		update #c set filtrat=filtrat*(case when exists (select 1 from legCpvNomencl l where l.idcpv=#c.id) then 1 else 0 end)'
	
	if @cunomenclator ='0'
	select @comanda_str=@comanda_str+'
		update #c set filtrat=filtrat*(case when not exists (select 1 from legCpvNomencl l where l.idcpv=#c.id) then 1 else 0 end)'
/*	
	update #c set filtrat = 1
	where f_1=1 and f_2=1 and f_3=1 and f_4=1 and f_5=1
*/
	--> datele se pot afisa in doua forme: lista simpla sau ierarhic:
	if @ierarhie='0'
	select @comanda_str=@comanda_str+'
		select top (@topint) * from #c
			where filtrat=1
			order by cod
		for xml raw'
	else
	select @comanda_str=@comanda_str+'
		begin
		--> stabilirea filtrarilor astfel incat sa se aduca datele care corespund filtrarilor cu tot cu subarbore si noduri superioare:
			--> culoarea albastra =  linie care se incadreaza in filtrari, excluzand nivelele luate pe langa pentru ierarhie:
			update #c set culoare="#0000FF" from #c where filtrat=1
			--> alias: j = jos = nivel inferior, s = sus = nivel superior
			
					--> retin numar liniile modificate sa stiu cand sa ies din cele doua bucle: atunci cand nu s-a mai modificat nici o linie, adica nranterior e egal cu nrcurent
			declare @nranterior int, @nrcurent int
			
				--> setez filtrarile pe subarbori:
			select @nranterior=0, @nrcurent=1
			while @nranterior<>@nrcurent
			begin
				update j set filtrat=1 from #c j
					where filtrat=0 
						and exists (select 1 from #c s where s.filtrat=1 and s.id=j.idparinte)
				select @nranterior=@nrcurent
				select @nrcurent=count(1) from #c where filtrat=1
			end
			
				--> setez filtrarile pe niveluri superioare:
			
			select @nranterior=0, @nrcurent=1
			while @nranterior<>@nrcurent
			begin
				update s set filtrat=1 from #c s
					where filtrat=0
						and exists (select 1 from #c j where j.filtrat=1 and s.id=j.idparinte)
				select @nranterior=@nrcurent
				select @nrcurent=count(1) from #c where filtrat=1
			end
			
				--> elimin datele care nu se incadreaza in filtrare:
			delete #c where filtrat=0
			
		--> compunerea select-ului final:
			declare @nivel int,
				@recursiv varchar(max),	--> expresia care se repeta - recurenta
				@curent varchar(max),	--> temporar, pentru procesarea @recursiv
				@iterativ varchar(max),	--> expresia finala
				@nivel_str varchar(20)	--> @nivel ca varchar
				
			select @nivel=2
				--> tag-urile de inlocuit se semnaleaza cu [<tag>]:
			select @recursiv="(select id, idparinte, cod, denumire, ordine, culoare, [_expandat] _expandat"+char(10)+
								"	,[xml]"+char(10)+
							"from #c [c1] where [c1].idparinte=[c].id order by cod for xml raw, type)"
			
			select @iterativ="select (
			select id, idparinte, cod, denumire, ordine, culoare, "+(case when @desfasurare<1 then """Nu""" else """Da""" end)+" _expandat
				,(select id, idparinte, cod, denumire, ordine, culoare, "+(case when @desfasurare<2 then """Nu""" else """Da""" end)+" _expandat
					,[xml] from #c c1 where c1.idparinte=c.id order by cod for xml raw, type)
			from #c c where not exists (select 1 from cpv p where p.id=c.idparinte)
			order by cod for xml raw, type
			)
			for xml path(""Ierarhie""), root(""Date"")"
			
			while (@nivel<8)
			begin
				select @nivel_str=convert(varchar(20),@nivel)
				--> tratez modificarile necesare: alias-urile tabelelor
				select @curent=
					replace(
						replace(
							replace(
								@recursiv,
								"[c1]","c"+convert(varchar(20),@nivel)
									),
							"[c]","c"+convert(varchar(20),@nivel-1)
						),
						"[_expandat]",(case when @desfasurare<@nivel then """Nu""" else """Da""" end)
					)

				--> adaug nivelul urmator:
				select @iterativ=replace(@iterativ,"[xml]",@curent)
				select @nivel=@nivel+1
			end
			--> elimin variabila de completat cu expresia:
			select @iterativ=replace(@iterativ,",[xml]","")
			exec (@iterativ)
			
		end'
	
	select @comanda_str=replace(@comanda_str,'"','''')
	exec sp_executesql @comanda_str, N'@top varchar(20), @topint int, @ierarhie varchar(20)
		,@denumire varchar(500), @cod varchar(500)
		,@desfasurare varchar(20), @cunomenclator varchar(1)
		,@infmin varchar(20)'
		,@top=@top, @topint=@topint, @ierarhie=@ierarhie
		,@denumire=@denumire, @cod=@cod
		,@desfasurare=@desfasurare, @cunomenclator=@cunomenclator
		,@infmin=@infmin
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' ('+ OBJECT_NAME(@@PROCID)+')'
end catch

if object_id('tempdb..#c') is not null drop table #c
if object_id('tempdb..#cpv_fltdiacritice') is not null drop table #cpv_fltdiacritice

if len(@eroare)>0 raiserror(@eroare, 16,1)
