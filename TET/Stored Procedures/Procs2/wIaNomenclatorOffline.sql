--***
create procedure wIaNomenclatorOffline @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaNomenclatorOfflineSP' and type='P')
begin
	exec wIaNomenclatorOfflineSP @sesiune, @parXML 
	return 0
end

begin try

	declare @utilizator varchar(10),@gestutiliz varchar(13), @categoriePret int, @rezultat varchar(max), @data datetime

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	set @gestutiliz = dbo.wfProprietateUtilizator('GESTPV',@utilizator)
	set @categoriePret=(select rtrim(valoare) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz)
	set @data=GETDATE()

	if @categoriePret=0 or @categoriePret is null 
		set @categoriePret=1

	IF OBJECT_ID('tempdb..#preturi') IS NOT NULL
			drop table #preturi
	create table #preturi(cod varchar(20), categPret varchar(10), pretvanzare varchar(30), pretamanunt varchar(30), 
		constraint PK_preturi primary key(cod, categpret))

	insert #preturi(cod, categPret, pretvanzare, pretamanunt)
	select rtrim(preturi.Cod_produs), rtrim(preturi.UM) , convert(varchar(100),convert(decimal(18,5),min(preturi.Pret_vanzare))), 
		convert(varchar(100),convert(decimal(18,5),min(preturi.Pret_cu_amanuntul)))
		from preturi 
		inner join 
			(select Cod_produs,um,MAX(data_inferioara) as data_inferioara
				from preturi
				where @data > preturi.data_inferioara and @data <= preturi.data_superioara  
				group by Cod_produs,um) 
				as unpret on preturi.cod_produs=unpret.cod_produs and preturi.UM=unpret.um and 
				preturi.Data_inferioara=unpret.data_inferioara
		group by preturi.Cod_produs, preturi.um

	select 
		upper(RTRIM(n.cod)) as "@cod",
		rtrim(n.Denumire) as "@denumire",
		RTRIM(n.Tip) as "@tip",
		RTRIM(n.UM) as "@um",
		convert(decimal(12,2), n.cota_tva) as "@cotatva",
		RTRIM(c.Cod_de_bare) as "@barcode",
		'Pret: ' + convert(varchar(100),isnull(p.pretamanunt,0)) + ' lei' as "@info"
		,
		(
			select p.categPret as "@categpret", p.pretvanzare as "@pretvanzare", p.pretamanunt as "@pretamanunt"
				from #preturi p where n.Cod=p.Cod
			for xml path('categorie'), type
		) as 'categPret'
		/*
		, -- daca trebuie stocul. Daca trebuie cu TE automat, trebuie tratata listagestiuni
		(
		select RTRIM(s.cod_gestiune) as "@codgestiune", 
		convert(decimal(12,3),sum(s.stoc)) as "@stoc"
		from stocuri s 
		where n.cod= s.Cod and ABS(s.Stoc)>0.001
		group by s.Cod, s.Cod_gestiune
		for xml path('gestiune'), type
		) as 'stocuri'
		*/
	from nomencl n
	left join #preturi p on p.cod=n.Cod and p.categPret=@categoriePret
	left join codbare c on n.Cod=c.Cod_produs -- daca sunt mai multe coduri de bare asociate la un produs, va vedea mai multe linii in PVria cu aleasi produs.
	where n.Tip in ('A', 'M', 'P', 'S')
	for xml path('row'),root('Date')

end try
begin catch
	declare @mesaj varchar(max)
	set @mesaj = ERROR_MESSAGE() + ' (wIaNomenclatorOffline)'
end catch

begin try
	IF OBJECT_ID('tempdb..#preturi') IS NOT NULL
		drop table #preturi
end try
begin catch
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)	
