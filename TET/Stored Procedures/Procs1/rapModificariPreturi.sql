
create procedure rapModificariPreturi @sesiune varchar(50), @categpret varchar(20)=NULL, @grupa varchar(20)=NULL, 
	@cod_articol varchar(20)=NULL, @den_articol varchar(100)=NULL, @tip_pret varchar(10), @dataSus datetime, @dataJos datetime,
	@gestiune varchar(20)=NULL
as 

begin try

	if object_id ('tempdb.dbo.#modpreturi') is not null drop table #modpreturi
	if object_id ('tempdb.dbo.#modpreturif') is not null drop table #modpreturif
	if object_id ('tempdb.dbo.#tippret') is not null drop table #tippret

	create table #tippret(TipPret char(1), Denumire varchar(30))
	insert into #tippret select TipPret, Denumire from dbo.fTipPret()

	select ROW_NUMBER() over (partition by p.Cod_produs, p.UM order by p.Data_inferioara) as rand,
		rtrim(p.Cod_produs) as codArticol, rtrim(n.Denumire) as denArticol, rtrim(g.Denumire) as denGrupa, p.UM as cod_categ, 
		rtrim(c.Denumire) as denumire_Categ, convert(decimal(12,3), p.Pret_vanzare) as pret_vanzare, 
		convert(decimal(12, 3), p.Pret_cu_amanuntul) as pret_amanunt, convert(char(10), p.Data_inferioara, 101) as datai, 
		convert(char(10), p.Data_superioara, 101) as datas,	rtrim(tp.Denumire) as tip_pret
	into #modpreturi
	from preturi p
	inner join categpret c on c.Categorie=p.UM
	left outer join nomencl n on n.Cod=p.Cod_produs
	left outer join grupe g on g.Grupa=n.Grupa
	left outer join #tippret tp on tp.TipPret=p.Tip_pret
	where (@tip_pret='t' or p.Tip_pret=@tip_pret)
		and (@categpret is null or p.UM=@categpret)
		and (@cod_articol is null or p.Cod_produs=@cod_articol)
		and (@den_articol is null or n.Denumire like '%'+@den_articol+'%')
		and (@grupa is null or g.Grupa=@grupa)
	order by p.Cod_produs

	select mp.*, mpa.pret_amanunt as pret_amanunt_vechi
	into #modpreturif
	from #modpreturi mp
	left join #modpreturi mpa on mp.codArticol=mpa.codArticol and mp.cod_categ=mpa.cod_categ and mp.rand=mpa.rand+1

	-- calcul de stoc
	if @gestiune is null
	begin
		select * from #modpreturif mpf
		where mpf.datai between convert(char(10), @dataJos, 101) and convert(char(10), @dataSus, 101) 
	end
	else
	begin
		declare @parXML xml
		select @parXML=(select
			dateadd(dd, -1, convert(varchar(20),@dataJos,102)) dDataJos,
			dateadd(dd, -1, convert(varchar(20),@dataSus,102)) dDataSus,
			@cod_articol cCod, @gestiune cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, null TipStoc, null cCont, 
				@grupa cGrupa, null Locatie, null Comanda, null Contract, null Furnizor, null Lot
				,null lm, null as grupGestiuni, @sesiune sesiune
			for xml raw)
				
		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune=@sesiune, @parxml=@parxml
	
	select 
		mpf.codArticol, max(mpf.denArticol) as denArticol, max(mpf.denGrupa) as denGrupa, 
		max(mpf.cod_categ) as cod_Categ, max(mpf.denumire_Categ) as denumire_Categ,	max(mpf.pret_vanzare) as pret_vanzare, 
		max(mpf.pret_amanunt) as pret_amanunt, max(mpf.pret_amanunt_vechi) as pret_amanunt_vechi, max(mpf.datai) as datai, 
		max(mpf.datas) as datas, max(mpf.tip_pret) as tip_pret, max(@gestiune) as gestiune, sum(isnull(d.stoc, 0)) as stoc
	from #modpreturif mpf
	left join #docstoc d on d.cod=mpf.codArticol
	where mpf.datai between convert(char(10), @dataJos, 101) and convert(char(10), @dataSus, 101)
	group by mpf.codArticol

	end

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
