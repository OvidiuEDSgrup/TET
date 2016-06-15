--***
create procedure wOPModificarePreturi @sesiune varchar(50), @parXML xml                
as              
/* Procedura primeste ca parametru o gestiune, dataj, datas
	a. Intr-o gestiune si intr-o zi este permis un singur pret cu amanuntul datorita faptului ca poate fi determinat un singur stoc in ziua respectiva.
	Procedura va genera automat modificarile de pret (cu Transfer) pentru codurile al caror pret cu amanuntul din stocuri difera de cel din preturi.
	Se da obligatoriu pe o singura zi si ia preturile modificate incepand cu data respectiva. Calculeaza stocul (cufstocuri=1) pana la ziua precedenta
	si modifica preturile aferente stocului respectiv.
	Se presupune ca fiecarei gestiuni i se asociaza o categorie de pret, altfel se ia 1
	Ex. apel: exec wOPModificarePreturi '','<parametri gestiune="CJ01" data="06/11/2012" cod="01DKPGAPP0010" cufstocuri="0"/>' 
		se verifica modificari de pret la 11.06.2012
		daca se da cufstocuri="1" se calculeza stoc cu fStocuriCen la 10.06.2012
	-- recomandam cufstocuri="0", adica ne bazam pe tabela stocuri (se da cu fstocuri doar la implementare, pentru zille din urma, dar recomandam alinierea, vezi mai jos
	-- pentru aliniere se foloseste wOPAlinierPreturi
*/
begin

declare @subunitate varchar(9),@gestiune varchar(9),@userASiS varchar(20),@pdata datetime,@pX xml,@cod varchar(20),
	@cuFStocuri int, @codfs varchar(20), @gestfs varchar(9), @datafs datetime

select @gestiune= ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(9)'), ''),
@pdata = @parXML.value('(/*/@data)[1]', 'datetime'),
@cod=ISNULL(@parXML.value('(/*/@cod)[1]', 'varchar(20)'), ''),
@cuFStocuri= ISNULL(@parXML.value('(/*/@cufstocuri)[1]', 'int'), 0)

begin try 

	exec wIaUtilizator @sesiune,@userASiS
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output              
		
	create table #preturi(gestiune varchar(20),cod_produs varchar(20),pret_cu_amanuntul float,cantitate float,codiprimitor varchar(13))

	-- categorii de preturi / gestiuni
	declare @CategGest table(gest varchar(50), categ int)
	insert into @CategGest(gest,categ)
	select g.cod_gestiune,isnull((case when pr.valoare='' then '1' else pr.valoare end),'1') as categ_pret 
	from gestiuni g
	left outer join proprietati pr on pr.tip='GESTIUNE' and pr.cod_proprietate='CATEGPRET' and pr.cod=g.cod_gestiune
	where g.tip_gestiune='A' 
	and (@gestiune='' or g.Cod_gestiune=@gestiune)

	insert into #preturi(gestiune,cod_produs,pret_cu_amanuntul,cantitate)
	select 
		c.gest as gestiune,
		cod_produs, 
		isnull(pretUrm.Pret_cu_amanuntul, p.Pret_cu_amanuntul) Pret_cu_amanuntul,
		convert(float,0) as cantitate
	from preturi p
	inner join @CategGest c on c.categ=p.UM
	outer apply /*filtrat pt. preturi promo care expira (altfel returneaza null)*/ 
		(select top 1 pret_cu_amanuntul 
			from preturi p2 
			where p.Data_superioara=dateadd(day,-1,@pdata) and p2.Cod_produs=p.Cod_produs and p2.um in (1,p.UM)
				and @pdata between p2.Data_inferioara and p2.Data_superioara
			order by p2.UM desc) pretUrm
	where 
	(@cod='' or p.Cod_produs=@cod)
	and p.Tip_pret in ('1','2')
	and (p.Data_inferioara=@pdata or p.tip_pret=2 and p.Data_superioara=dateadd(day,-1,@pdata))

	if (select count(*) from #preturi)=0
	begin
		select 'Nu aveti modificari de pret in perioada selectata' as textMesaj for xml raw, root('Mesaje')
		return
	end

	if @cuFStocuri=1
	begin
		if @cod='' set @codfs=null
		if @gestiune='' set @gestfs=null else set @gestfs=@gestiune
		set @datafs=DATEADD(day,-1,@pdata)
	end
	
	create table #stocuri(subunitate varchar(9),tip_gestiune varchar(1),gestiune varchar(20),cod varchar(20),cod_intrare varchar(20),pret float,pret_cu_amanuntul float,stoc float,tva_neexigibil int)
	if @cuFStocuri=1
	begin
	--	/*
		declare @p xml
		select @p=(select @datafs dDataSus, @codfs cCod, @gestfs cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, 'D' TipStoc
		for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p
		
	--*/
		insert into #stocuri
		select st.subunitate,st.tip_gestiune,st.gestiune as gestiune,st.cod,st.cod_intrare,st.pret,st.pret_cu_amanuntul,st.stoc,st.tva_neexigibil
			from --dbo.fStocuriCen(@datafs,@codfs,@gestfs,null,1,1,1,'D',null,null,null,null,null,null,null,null) st
				#docstoc st
			inner join #preturi pr on st.subunitate=@subunitate and st.cod=pr.cod_produs and st.gestiune=pr.gestiune
			where ABS(st.stoc)>=0.001
		if object_id('tempdb..#docstoc') is not null drop table #docstoc
	end
	else
		insert into #stocuri
		select st.subunitate,st.tip_gestiune,st.cod_gestiune as gestiune,st.cod,st.cod_intrare,st.pret,st.pret_cu_amanuntul,st.stoc,st.tva_neexigibil
			from stocuri st
			inner join #preturi pr on st.subunitate=@subunitate and st.cod=pr.cod_produs and st.Cod_gestiune=pr.gestiune
			where @cuFStocuri=0 and subunitate=@subunitate and ABS(st.stoc)>=0.001

	select gestiune
	into #gest
	from #preturi
	group by gestiune
	order by gestiune

	select top 1 @gestiune=gestiune from #gest

	while @gestiune is not null
	begin
	
		declare @numar varchar(20)
		select @numar='MP'+right(ltrim(rtrim(@gestiune)),6)

		declare @input XMl
		set @input=(select rtrim(@subunitate) as '@subunitate','TE' as '@tip',
			@numar as '@numar', @pdata as '@data',
			(
			 	select pr.gestiune as '@gestiune',pr.gestiune as '@gestprim',
				rtrim(pr.cod_produs) as '@cod',convert(decimal(12,5),st.pret) as '@pstoc',
				convert(decimal(12,5),st.stoc) as '@cantitate',
				rtrim(st.cod_intrare) as '@codintrare',convert(decimal(12,2),st.tva_neexigibil) as '@tva_neexigibil',
				pr.codiprimitor as '@codiprimitor'
				from #preturi pr 
				left outer join #stocuri st on st.cod=pr.cod_produs and st.gestiune=pr.gestiune
				where abs(st.pret_cu_amanuntul-pr.Pret_cu_amanuntul)>=0.001 and	pr.gestiune=@gestiune
					and st.stoc>0.0009 
				for xml Path,type)
			for xml Path,type)
	
		--Sterg documentul eventual generat anterior
		delete from pozdoc where subunitate=@subunitate and tip='TE' and numar=@numar and data=@pdata
		
		exec wScriuPozdoc @sesiune,@input --Merge foarte incet

		-- Dupa scrierea in pozdoc trebuie sa trimitem la Reincadrare Iesiri
		set @pX=(
			select @pdata as dataj,'2999-12-31' as datas, @gestiune as gestiune, @cod as cod
			for xml raw)
		exec wOPReincadrareIesiri @sesiune, @pX 

		delete from #gest where @gestiune=gestiune
		set @gestiune=null
		select top 1 @gestiune=gestiune from #gest	
	end

	drop table #stocuri
	drop table #preturi
	drop table #gest
		
	
end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare='wOPModificarePreturi:'+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
end
